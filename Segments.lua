---@class AddOn
local AddOn = (select(2, ...))

local L = AddOn.L

local copy = AddOn.Copy
local format = format
local min = min
local next = next
local setmetatable = setmetatable
local tRemove = table.remove
local tSort = table.sort
local time = time

local After = C_Timer.After
local CallOnAllGroupMembers = AddOn.CallOnAllGroupMembers
local FormatTimestamp = AddOn.FormatTimestamp
local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer
local GetActiveChallengeMapID = C_ChallengeMode.GetActiveChallengeMapID
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetCompletionInfo = C_ChallengeMode.GetCompletionInfo
local GetMapInfo = C_Map.GetMapInfo
local GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local GetPlayerInfos = AddOn.GetPlayerInfos
local GetPlayerName = AddOn.GetPlayerName
local IsChallengeModeActive = C_ChallengeMode.IsChallengeModeActive
local IsMatchActive = C_PvP.IsMatchActive
local UnitAffectingCombat = UnitAffectingCombat
local UnitGUID = UnitGUID

---@class Segment
---@field endTimestamp? number
---@field name? string
---@field roster? table<string, PlayerInfo>
---@field startTimestamp? number
---@field uiMapId? number
---@field [string] any
local SegmentMeta = {}
AddOn.SegmentMeta = SegmentMeta
SegmentMeta.__index = SegmentMeta

---@return number?
function SegmentMeta:GetStartTimestamp() return self.startTimestamp end

---@return number?
function SegmentMeta:GetEndTimestamp() return self.endTimestamp end

---@return number
function SegmentMeta:GetDuration() return (self.endTimestamp or time()) - (self.startTimestamp or time()) end

---@return string
function SegmentMeta:GetName()
    if self.name then
        return self.name
    else
        return format("%s - %s", FormatTimestamp(self.startTimestamp or time()),
                      FormatTimestamp(self.endTimestamp or time()))
    end
end

---@return string
function SegmentMeta:GetMapName()
    local info = GetMapInfo(self.uiMapId or 946)
    if info and info.name then return info.name end
    return L.UNKNOWN
end

---@type Segment[]
local segments = {}
AddOn.Segments = segments

---@type table<any, Segment>
local activeSegments = {}
AddOn.ActiveSegments = activeSegments

---@param key any
---@param timestamp? number
---@param name? string
---@param oldSegment? Segment
---@return Segment?
local function startSegment(key, timestamp, name, oldSegment)
    timestamp = timestamp or time()

    local activeSegment = activeSegments[key]
    if not activeSegment then
        if oldSegment then
            activeSegment = oldSegment
            wipe(oldSegment)
            oldSegment.startTimestamp = timestamp
            oldSegment.uiMapId = GetBestMapForUnit("player")
            oldSegment.name = name
        else
            activeSegment = setmetatable({
                startTimestamp = timestamp,
                uiMapId = GetBestMapForUnit("player"),
                name = name,
            }, SegmentMeta)
        end
    else
        activeSegment.startTimestamp = min(activeSegment.startTimestamp, timestamp)
    end
    activeSegments[key] = activeSegment

    local roster = activeSegment.roster
    if not roster then
        roster = {}
        activeSegment.roster = roster
    end
    CallOnAllGroupMembers(function(unitToken)
        local guid = UnitGUID(unitToken)
        if guid then
            local playerInfos = roster[guid]
            if not playerInfos then
                playerInfos = {}
                roster[guid] = playerInfos
            end
            GetPlayerInfos(guid, playerInfos)
        end
    end)

    return activeSegment
end
AddOn.StartSegment = startSegment

---@param a Segment
---@param b Segment
---@return boolean
local function segmentComp(a, b)
    local endTimestampA = a.endTimestamp or time()
    local endTimestampB = b.endTimestamp or time()
    if endTimestampA == endTimestampB then
        local startTimestampA = a.startTimestamp or time()
        local startTimestampB = b.startTimestamp or time()
        if startTimestampA == startTimestampB then
            return a:GetName() < b:GetName()
        else
            return startTimestampA < startTimestampB
        end
    else
        return endTimestampA < endTimestampB
    end
end

---@param key any
---@param timestamp? number
---@param name? string
---@param saveCopy? boolean
---@return Segment?
local function stopSegment(key, timestamp, name, saveCopy)
    timestamp = timestamp or time()
    local activeSegment = activeSegments[key]
    if activeSegment then
        activeSegments[key] = nil
        activeSegment.endTimestamp = timestamp
        activeSegment.name = name or activeSegment.name
        if activeSegment:GetDuration() >= 5 then
            activeSegment = saveCopy and copy(activeSegment) or activeSegment
            segments[#segments + 1] = activeSegment
            tSort(segments, segmentComp)
        end
    end
    return activeSegment
end
AddOn.StopSegment = stopSegment

AddOn.RegisterEvent("PLAYER_LOGIN", --
function() startSegment("session", time(), L.SESSION) end)

AddOn.RegisterEvent("PLAYER_LOGOUT", --
function()
    stopSegment("encounter")
    stopSegment("challenge")
    stopSegment("pvp")
end)

AddOn.RegisterEvent("PLAYER_ENTERING_WORLD", --
---@param isInitialLogin boolean
---@param isReloadingUi boolean
function(isInitialLogin, isReloadingUi)
    if not IsChallengeModeActive() then stopSegment("challenge") end
    if IsMatchActive() then
        startSegment("pvp")

        After(1, function()
            local activeSegment = activeSegments.pvp
            if activeSegment then
                activeSegment.uiMapId = GetBestMapForUnit("player")
                activeSegment.name = activeSegment:GetMapName()
            end
        end)
    else
        stopSegment("pvp")
    end
end)

---@type Segment
local combatSegment = setmetatable({name = L.CURRENT}, SegmentMeta)

---@param timestamp number
local function startCombat(timestamp)
    if not activeSegments.combat then startSegment("combat", timestamp, L.CURRENT, combatSegment) end
end
AddOn.StartCombat = startCombat

---@return Segment
function AddOn.GetCombatSegment() return combatSegment end

AddOn.RegisterEvent("PLAYER_REGEN_DISABLED", --
function() startCombat(time()) end)

C_Timer.NewTicker(3, function(self)
    if CallOnAllGroupMembers(UnitAffectingCombat, true) then return end

    local activeSegment = stopSegment("combat", time(), nil, true)
    if activeSegment then
        activeSegment.name = nil
        ---@type DamageDone?
        local damageDone = activeSegment.damageDone
        if not damageDone then return end

        local targets = {}
        for target, targetData in next, damageDone.targets, nil do
            targets[target] = (targets[target] or 0) + (targetData.amount or 0)
            targets[target] = (targets[target] or 0) + (targetData.petAmount or 0)
        end

        local maxTarget
        local maxAmount = 0
        for target, amount in next, targets, nil do
            if amount > maxAmount then
                maxAmount = amount
                maxTarget = target
            end
        end
        if maxTarget then
            local name
            if GUIDIsPlayer(maxTarget) then
                local name2, fullName, shortName = GetPlayerName(maxTarget)
                name = fullName
            else
                name = L[maxTarget]
            end
            activeSegment.name = name
        end
    end
end)

local getActiveKeystoneInfo = C_ChallengeMode.GetActiveKeystoneInfo
local getDifficultyInfo = GetDifficultyInfo

AddOn.RegisterEvent("ENCOUNTER_START", --
---@param encounterID number
---@param encounterName string
---@param difficultyID number
---@param groupSize number
function(encounterID, encounterName, difficultyID, groupSize)
    if difficultyID == 8 then -- Mythic Keystone
        local activeKeystoneLevel, activeAffixIDs, wasActiveKeystoneCharged = getActiveKeystoneInfo()
        startSegment("encounter", time(),
                     format("%s (%s - %d) |TInterface\\RAIDFRAME\\ReadyCheck-Waiting:0|t", encounterName,
                            (getDifficultyInfo(difficultyID)), activeKeystoneLevel))
    else
        startSegment("encounter", time(), format("%s (%s) |TInterface\\RAIDFRAME\\ReadyCheck-Waiting:0|t",
                                                 encounterName, (getDifficultyInfo(difficultyID))))
    end
end)

AddOn.RegisterEvent("ENCOUNTER_END", --
---@param encounterID number
---@param encounterName string
---@param difficultyID number
---@param groupSize number
---@param success number
function(encounterID, encounterName, difficultyID, groupSize, success)
    if difficultyID == 8 then -- Mythic Keystone
        local activeKeystoneLevel, activeAffixIDs, wasActiveKeystoneCharged = getActiveKeystoneInfo()
        stopSegment("encounter", time(),
                    format("%s (%s) |TInterface\\RAIDFRAME\\ReadyCheck-%s:0|t", encounterName,
                           format(L.MYTHIC_LEVEL, activeKeystoneLevel),
                           success and success == 1 and "Ready" or "NotReady"))
    else
        stopSegment("encounter", time(),
                    format("%s (%s) |TInterface\\RAIDFRAME\\ReadyCheck-%s:0|t", encounterName,
                           (getDifficultyInfo(difficultyID)), success and success == 1 and "Ready" or "NotReady"))
    end
end)

AddOn.RegisterEvent("CHALLENGE_MODE_START", --
---@param mapID number
function(mapID)
    startSegment("challenge", time(), L.CHALLENGE_MODE)

    After(1, function()
        local activeSegment = activeSegments.challenge
        if activeSegment then
            local mapChallengeModeID = GetActiveChallengeMapID()
            if mapChallengeModeID then
                local name, id, timeLimit, texture, backgroundTexture = GetMapUIInfo(mapChallengeModeID)
                if name then
                    local activeKeystoneLevel, activeAffixIDs, wasActiveKeystoneCharged = getActiveKeystoneInfo()
                    activeSegment.name = format("%s (%s) |TInterface\\RAIDFRAME\\ReadyCheck-Waiting:0|t", name,
                                                format(L.MYTHIC_LEVEL, activeKeystoneLevel))
                end
            end
        end
    end)
end)

AddOn.RegisterEvent("CHALLENGE_MODE_COMPLETED", --
function()
    local activeSegment = activeSegments.challenge
    stopSegment("challenge", time())
    if activeSegment then
        local mapChallengeModeID, level, completionTime, onTime, keystoneUpgradeLevels, practiceRun,
              oldOverallDungeonScore, newOverallDungeonScore, isMapRecord, isAffixRecord, primaryAffix,
              isEligibleForScore, members = GetCompletionInfo()
        if mapChallengeModeID then
            if not practiceRun then
                local name, id, timeLimit, texture, backgroundTexture = GetMapUIInfo(mapChallengeModeID)
                if name then
                    activeSegment.name = format("%s (%s) |TInterface\\RAIDFRAME\\ReadyCheck-%s:0|t", name,
                                                format(L.MYTHIC_LEVEL, level), onTime and "Ready" or "NotReady")
                end
            end
        end
    end
end)

AddOn.RegisterEvent("PVP_MATCH_STATE_CHANGED", --
function()
    if IsMatchActive() then
        startSegment("pvp")

        After(1, function()
            local activeSegment = activeSegments.pvp
            if activeSegment then
                activeSegment.uiMapId = GetBestMapForUnit("player")
                activeSegment.name = activeSegment:GetMapName()
            end
        end)
    else
        stopSegment("pvp")
    end
end)

AddOn.RegisterEvent("PVP_MATCH_COMPLETE", --
---@param winner number
---@param duration number
function(winner, duration) stopSegment("pvp") end)

---@param segment Segment
function AddOn.DeleteSegment(segment)
    for key, activeSegment in next, activeSegments, nil do
        if activeSegment == segment then
            local name = activeSegment.name
            local uiMapId = activeSegment.uiMapId
            wipe(activeSegment)
            activeSegment.name = name
            activeSegment.uiMapId = uiMapId
            activeSegment.startTimestamp = time()
            return
        end
    end
    for i = 1, #segments, 1 do
        if segments[i] == segment then
            tRemove(segments, i)
            return
        end
    end
end

function AddOn.DeleteAllSegments()
    for key, activeSegment in next, activeSegments, nil do
        local name = activeSegment.name
        local uiMapId = activeSegment.uiMapId
        wipe(activeSegment)
        activeSegment.name = name
        activeSegment.uiMapId = uiMapId
        activeSegment.startTimestamp = time()
    end
    wipe(segments)
end

AddOn.RegisterEvent("GROUP_ROSTER_UPDATE", --
function()
    local roster = {}

    CallOnAllGroupMembers(function(unitToken)
        local guid = UnitGUID(unitToken)
        if guid then
            local playerInfos = {}
            roster[guid] = playerInfos
            GetPlayerInfos(guid, playerInfos)
        end
    end)

    for key, activeSegment in next, activeSegments, nil do
        if not activeSegment.roster then activeSegment.roster = {} end
        for guid, infos in next, roster, nil do
            local playerInfos = activeSegment.roster[guid]
            if not playerInfos then
                playerInfos = infos
                activeSegment.roster[guid] = playerInfos
            end
            GetPlayerInfos(guid, playerInfos)
        end
    end
end)
