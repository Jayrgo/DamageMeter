---@class AddOn
local AddOn = (select(2, ...))

local COMBAT_LOG_FILTER_PET = AddOn.COMBAT_LOG_FILTER_PET
local MAX_CACHED_EVENTS_PER_FRAME = AddOn.MAX_CACHED_EVENTS_PER_FRAME

local next = next
local strsplit = strsplit

local ActiveSegments = AddOn.ActiveSegments
local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer
local GetPlayerClass = AddOn.GetPlayerClass
local GetPlayerName = AddOn.GetPlayerName
local SafePack = AddOn.SafePack
local SafeUnpack = AddOn.SafeUnpack
local StartCombat = AddOn.StartCombat
local UnitClassBase = UnitClassBase
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitTokenFromGUID = UnitTokenFromGUID

local function nop() end

---@alias CheckCombatHandler fun(timestamp:number, hideCaster:boolean, sourceGUID?:string, sourceName?:string, sourceFlags?:number, sourceRaidFlags?:number, destGUID?:string, destName?:string, destFlags?:number, destRaidFlags?:number, ...:any):boolean?
---@type table<string, CheckCombatHandler>
local checkCombatHandlers = setmetatable({}, {
    ---@param t table<string, CheckCombatHandler>
    ---@param k string
    ---@return CheckCombatHandler
    __index = function(t, k)
        local v = nop
        t[k] = v
        return v
    end,
})
AddOn.CheckCombatHandlers = checkCombatHandlers

---@param timestamp number
---@param subEvent string
---@param ... any
local function checkCombat(timestamp, subEvent, ...)
    if checkCombatHandlers[subEvent](timestamp, ...) then StartCombat(timestamp) end
end

---@alias StaticCombatLogHandler fun(timestamp: number, hideCaster: boolean, sourceGUID?: string, sourceName?: string, sourceFlags?: number, sourceRaidFlags?: number, destGUID?: string, destName?: string, destFlags?: number, destRaidFlags?: number, ...: any)
---@type table<string, StaticCombatLogHandler>
local staticCombatLogHandlers = setmetatable({}, {
    ---@param t table<string, StaticCombatLogHandler>
    ---@param k string
    ---@return StaticCombatLogHandler
    __index = function(t, k)
        local v = nop
        t[k] = v
        return v
    end,
})
AddOn.StaticCombatLogHandlers = staticCombatLogHandlers

---@param timestamp number
---@param subEvent string
---@param ... any
local function handleStaticEvent(timestamp, subEvent, ...) staticCombatLogHandlers[subEvent](timestamp, ...) end

---@alias CombatLogHandler fun(segment: Segment, timestamp: number, hideCaster: boolean, sourceGUID?: string, sourceName?: string, sourceFlags?: number, sourceRaidFlags?: number, destGUID?: string, destName?: string, destFlags?: number, destRaidFlags?: number, ...: any)
---@type table<string, CombatLogHandler>
local combatLogHandlers = setmetatable({}, {
    ---@param t table<string, CombatLogHandler>
    ---@param k string
    ---@return CombatLogHandler
    __index = function(t, k)
        local v = nop
        t[k] = v
        return v
    end,
})
AddOn.CombatLogHandlers = combatLogHandlers

---@param segment Segment
---@param timestamp number
---@param subEvent string
---@param ... any
local function handleCombatLogEvent(segment, timestamp, subEvent, ...)
    combatLogHandlers[subEvent](segment, timestamp, ...)
end

---@type table<string, string?>
local names = {}

---@param unitToken string
local function updateName(unitToken)
    local name, realm = UnitName(unitToken)
    if name and name ~= "" then
        if realm and realm ~= "" then
            names[UnitGUID(unitToken)] = name .. " - " .. realm
        else
            names[UnitGUID(unitToken)] = name
        end
    end
end

---@param guid string
---@param default? string
---@return string
local function getName(guid, default)
    local name = names[guid]
    if not name then
        local unitToken = UnitTokenFromGUID(guid)
        if unitToken then
            name = UnitName(unitToken)
            names[guid] = name
        end
        if not name and GUIDIsPlayer(guid) then
            local name2, fullName, shortName = GetPlayerName(guid)
            names[guid] = fullName
        end
    end
    return name or default or "UNKNOWN"
end
AddOn.GetName = getName

---@type table<string, ClassFile?>
local classes = {}

---@param unitToken string
local function updateClass(unitToken)
    if UnitExists(unitToken) then
        local class = UnitClassBase(unitToken)
        if class then
            local guid = UnitGUID(unitToken)
            if guid then
                classes[guid] = class
                local unitType, _, serverID, instanceID, zoneUID, npcID, spawnUID = strsplit("-", guid)
                if unitType == "Creature" then if npcID then classes[npcID] = class end end
            end
            local name = UnitName(unitToken)
            if name then classes[name] = class end
        end
    end
end

---@param guid string
---@return ClassFile?
local function getClass(guid)
    local class = classes[guid]
    if not class then
        local unitType, _, serverID, instanceID, zoneUID, npcID, spawnUID = strsplit("-", guid)
        if unitType == "Creature" then
            if npcID then
                class = classes[npcID]
                if class then return class end
            end
        else
            npcID = nil
        end

        local unitToken = UnitTokenFromGUID(guid)
        if unitToken then
            class = UnitClassBase(unitToken)
            if npcID then
                classes[npcID] = class
                return class
            end
            local name = UnitName(unitToken)
            if name then
                class = classes[name]
                if not class then
                    class = UnitClassBase(unitToken)
                    classes[name] = class
                end
            end
        end
        if not class and GUIDIsPlayer(guid) then
            class = GetPlayerClass(guid)
            classes[guid] = class
        end
    end
    return class
end
AddOn.GetClass = getClass

---@type table<string, string?>
local petOwners = {}

---@param unitToken string
local function updatePet(unitToken)
    local petToken = unitToken .. "pet"
    local petGUID = UnitExists(petToken) and UnitGUID(petToken)

    if petGUID then
        petOwners[petGUID] = UnitGUID(unitToken)
        updateClass(petToken)
        updateName(petToken)
    end
end

---@type fun(petGUID:string):string
local findPetOwner
do -- findPetOwner
    ---@type GameTooltip
    ---@diagnostic disable-next-line:assign-type-mismatch
    local tooltip = CreateFrame("GameTooltip", nil, nil, "GameTooltipTemplate")
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

    local unitTooltipDataType = Enum.TooltipDataType.Unit

    ---@param petGUID string
    ---@return string
    function findPetOwner(petGUID)
        tooltip:ClearLines()
        tooltip:SetHyperlink("unit:" .. petGUID)
        --[[ tooltip:Show() ]]

        if tooltip:IsTooltipType(unitTooltipDataType) then ---@diagnostic disable-line:undefined-field
            local tooltipData = tooltip:GetPrimaryTooltipData() ---@diagnostic disable-line:undefined-field
            if tooltipData then
                local lines = tooltipData.lines
                if lines then
                    for i = 1, #lines, 1 do
                        local guid = lines[i].guid
                        if guid and guid ~= petGUID then
                            petOwners[petGUID] = guid
                            tooltip:Hide()
                            return guid
                        end
                    end
                end
            end
        end
        tooltip:Hide()
        return petGUID
    end
end

---@param petGUID string
---@return string
local function getPetOwner(petGUID) return petOwners[petGUID] or findPetOwner(petGUID) or petGUID end
AddOn.GetPetOwner = getPetOwner

local frame = CreateFrame("Frame")

---@type fun(timestamp:number, subEvent:string, ...)
local onCombatLogEvent = function() end

local combatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

frame:SetScript("OnEvent", --
---@param self Frame
---@param event WowEvent
---@param ... any
function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        onCombatLogEvent(combatLogGetCurrentEventInfo()) ---@diagnostic disable-line:param-type-mismatch
    elseif event == "PLAYER_TARGET_CHANGED" then
        updateClass("target")
    elseif event == "UNIT_PET" then
        ---@type UnitToken
        local unitTarget = ...

        updatePet(unitTarget)
    elseif event == "GROUP_ROSTER_UPDATE" then
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...

        if isInitialLogin or isReloadingUi then
            updateClass("player")
            updateName("player")
            updatePet("player")
        end
    else
        self:UnregisterEvent(event)
    end
end)
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

---@class CombatLogEventQueue
local eventQueue = {}
do -- CombatLogEventQueue
    local first = 0
    local last = -1
    local list = {}

    ---@param value SafeTable
    function eventQueue.Push(value)
        last = last + 1
        list[last] = value
    end

    ---@return SafeTable?
    function eventQueue.Pop()
        if first <= last then
            local value = list[first]
            list[first] = nil
            first = first + 1
            return value
        end
    end

    ---@param offset? number
    ---@return SafeTable?
    function eventQueue.Peek(offset)
        local index = first - (offset or 0)
        if index <= last then return list[index] end
    end
end

frame:SetScript("OnUpdate", --
---@param self Frame
---@param elapsed number
function(self, elapsed)
    local processedEvents = 0
    local event = eventQueue.Pop()
    while event do
        handleCombatLogEvent(SafeUnpack(event))
        processedEvents = processedEvents + 1
        if processedEvents < MAX_CACHED_EVENTS_PER_FRAME then
            event = eventQueue.Pop()
        else
            break
        end
    end
end)

local cacheEnabled

---@param enabled boolean
function AddOn.SetCacheEnabled(enabled)
    if enabled ~= cacheEnabled then
        cacheEnabled = enabled

        if enabled then
            onCombatLogEvent = function(timestamp, subEvent, ...)
                if not ActiveSegments.combat then checkCombat(timestamp, subEvent, ...) end
                handleStaticEvent(timestamp, subEvent, ...)

                for key, segment in next, ActiveSegments, nil do
                    eventQueue.Push(SafePack(segment, timestamp, subEvent, ...))
                end
            end
        else
            local event = eventQueue.Pop()
            while event do
                handleCombatLogEvent(SafeUnpack(event))
                event = eventQueue.Pop()
            end

            onCombatLogEvent = function(timestamp, subEvent, ...)
                if not ActiveSegments.combat then checkCombat(timestamp, subEvent, ...) end
                handleStaticEvent(timestamp, subEvent, ...)
                for key, segment in next, ActiveSegments, nil do
                    handleCombatLogEvent(segment, timestamp, subEvent, ...)
                end
            end
        end
    end
end
AddOn.SetCacheEnabled(false)

---@return boolean
function AddOn.IsCacheEnabled() return cacheEnabled end

---@param timestamp number
---@param hideCaster boolean
---@param sourceGUID? string
---@param sourceName? string
---@param sourceFlags? number
---@param sourceRaidFlags? number
---@param destGUID? string
---@param destName? string
---@param destFlags? number
---@param destRaidFlags? number
---@param spellId number
---@param spellName string
---@param spellSchool number
function staticCombatLogHandlers.SPELL_SUMMON(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                              sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId,
                                              spellName, spellSchool)
    if sourceGUID and destGUID and sourceGUID ~= "" and destGUID ~= "" then petOwners[destGUID] = sourceGUID end
end

local combatLog_Object_IsA = CombatLog_Object_IsA

---@param sources table<string, UnitTable>
---@param sourceGUID? string
---@param sourceName? string
---@param sourceFlags? number
---@return UnitTable
---@return boolean
---@return boolean
---@return string?
function AddOn.GetSource(sources, sourceGUID, sourceName, sourceFlags)
    local isNew = false
    local isPet = false
    if sourceFlags then isPet = combatLog_Object_IsA(sourceFlags, COMBAT_LOG_FILTER_PET) end

    local source = sourceGUID and sources[sourceGUID] or sourceName and sources[sourceName]
    if source then

        if not source.class and sourceGUID then source.class = getClass(sourceGUID) end
        return source, false, isPet, sourceName
    end

    sourceGUID = (sourceGUID and sourceGUID ~= "") and sourceGUID or nil

    local key

    if isPet and sourceGUID then
        local ownerGUID = getPetOwner(sourceGUID)

        if ownerGUID ~= sourceGUID then
            source = ownerGUID and sources[ownerGUID]
            if not source then
                source = {name = getName(ownerGUID), class = getClass(ownerGUID)}
                key = ownerGUID
                isNew = true
            end
        end
    elseif sourceGUID then
        source = {name = getName(sourceGUID, sourceName), class = getClass(sourceGUID)}
        key = GUIDIsPlayer(sourceGUID) and sourceGUID or sourceName or "UNKNOWN"
        isNew = true
    end
    if not source then
        source = {name = sourceName or "UNKNOWN"}
        key = sourceName or "UNKNOWN"
        isNew = true
    end

    if isNew then sources[key] = source end

    return source, isNew, isPet, sourceName
end

---@param spells table<string|number, SpellTable>
---@param spellId number|string
---@param spellSchool number
---@return SpellTable
---@return boolean isNew
function AddOn.GetSpell(spells, spellId, spellSchool)
    local isNew = false
    local spell = spells[spellId]
    if not spell then
        ---@class SpellTable
        spell = {school = spellSchool}
        isNew = true
    end

    if isNew then spells[spellId] = spell end

    return spell, isNew
end

---@param targets table<string, UnitTable>
---@param destGUID? string
---@param destName? string
---@param destFlags? number
---@return UnitTable
---@return boolean
function AddOn.GetTarget(targets, destGUID, destName, destFlags)
    local isNew = false
    local key

    local target = destGUID and targets[destGUID]
    if target then
        if not target.class and destGUID then target.class = getClass(destGUID) end
    else
        if destGUID and GUIDIsPlayer(destGUID) then
            target = {name = getName(destGUID, destName), class = getClass(destGUID)}
            isNew = true
            key = destGUID
        elseif destGUID then
            local name = getName(destGUID, destName) or "UNKNOWN"
            target = targets[name]
            if not target then
                target = {name = name, class = getClass(destGUID)}
                isNew = true
                key = name
            elseif not target.class then
                target.class = getClass(destGUID)
            end
        elseif destName then
            target = targets[destName]
            if not target then
                target = {name = destName}
                isNew = true
                key = destName
            end
        else
            target = targets["UNKNOWN"]
            if not target then
                target = {name = "UNKNOWN"}
                isNew = true
                key = "UNKNOWN"
            end
        end
    end

    if isNew then targets[key] = target end

    return target, isNew
end
