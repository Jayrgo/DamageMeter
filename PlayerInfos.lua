---@class AddOn
local AddOn = (select(2, ...))

local L = AddOn.L

local INVSLOT_BACK = INVSLOT_BACK
local INVSLOT_CHEST = INVSLOT_CHEST
local INVSLOT_HEAD = INVSLOT_HEAD
local INVSLOT_MAINHAND = INVSLOT_MAINHAND
local INVSLOT_OFFHAND = INVSLOT_OFFHAND
local INVSLOT_SHOULDER = INVSLOT_SHOULDER
local PLAYER_GUID = UnitGUID("player")

local copy = AddOn.Copy
local max = max

local DoesItemExistByID = C_Item.DoesItemExistByID
local GetAverageItemLevel = GetAverageItemLevel
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local GetInspectSpecialization = GetInspectSpecialization
local GetItemInventoryTypeByID = C_Item.GetItemInventoryTypeByID
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local InventoryType = Enum.InventoryType
local IsGUIDInGroup = IsGUIDInGroup
local IsItemDataCachedByID = C_Item.IsItemDataCachedByID
local RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitLevel = UnitLevel
local UnitTokenFromGUID = UnitTokenFromGUID

---@class PlayerInfo
---@field avgItemLevel? number
---@field inventory? table
---@field level? number
---@field role? string
---@field specID? number

---@class InspectFrame : Frame
---@field unit? string
local inspectFrame

---@type string?
local lastInspectUnit
---@type number?
local lastInspectRequest

hooksecurefunc(_G, "NotifyInspect", --
---@param unit UnitToken
function(unit)
    lastInspectUnit = unit
    lastInspectRequest = time()
end)

hooksecurefunc(_G, "ClearInspectPlayer", function()
    lastInspectUnit = nil
    lastInspectRequest = nil
end)

---@type table<string, number>
local inspectTries = {}
---@type table<string, PlayerInfo[]>
local playerInfos = setmetatable({}, {
    ---@param t table<string, PlayerInfo[]>
    ---@param k string
    ---@param v PlayerInfo[]
    __newindex = function(t, k, v)
        inspectTries[k] = 5
        rawset(t, k, v)
    end,
})

do
    local next = next

    local CanInspect = CanInspect
    local UnitIsDeadOrGhost = UnitIsDeadOrGhost
    local UnitTokenFromGUID = UnitTokenFromGUID
    local notifyInspect = NotifyInspect

    ---@type string?
    local lastGUID

    ---@param guid string
    ---@return boolean
    local function notifyInspectByGUID(guid)
        lastGUID = guid
        local unit = UnitTokenFromGUID(guid)
        if unit and CanInspect(unit, false) then
            notifyInspect(unit)
            return true
        else
            return false
        end
    end

    C_Timer.NewTicker(1, function()
        if UnitIsDeadOrGhost("player") then return end
        if not lastInspectRequest or (lastInspectRequest + 5) <= time() then
            local guid = next(playerInfos, lastGUID and playerInfos[lastGUID] and lastGUID or nil)
            if not guid then guid = next(playerInfos, nil) end
            while guid do
                local tries = inspectTries[guid] or 0
                if tries > 0 then
                    inspectTries[guid] = tries - 1
                    if notifyInspectByGUID(guid) then
                        return
                    else
                        guid = next(playerInfos, guid)
                    end
                else
                    playerInfos[guid] = nil
                    inspectTries[guid] = nil
                    guid = next(playerInfos, guid)
                end
            end
        end
    end)
end

---@param itemLink? string
---@return number?
local function getItemLevel(itemLink)
    if itemLink and DoesItemExistByID(itemLink) then
        if not IsItemDataCachedByID(itemLink) then
            RequestLoadItemDataByID(itemLink)
        else
            local effectiveILvl, isPreview, baseILvl = GetDetailedItemLevelInfo(itemLink)
            return effectiveILvl
        end
    end
end

---@param inventory table<number, string>
---@param specID? number
---@param level? number
---@return number?
local function getAverageItemLevelFromInventory(inventory, specID, level)
    if not inventory then return end

    local sumItemLevel = 0

    for i = INVSLOT_HEAD, INVSLOT_SHOULDER, 1 do
        local itemLink = inventory[i]
        sumItemLevel = sumItemLevel + (getItemLevel(itemLink) or 0)
    end
    for i = INVSLOT_CHEST, INVSLOT_BACK, 1 do
        local itemLink = inventory[i]
        sumItemLevel = sumItemLevel + (getItemLevel(itemLink) or 0)
    end

    local mainHandItemLink = inventory[INVSLOT_MAINHAND]
    local mainHandItemLevel = getItemLevel(mainHandItemLink) or 0
    local mainHandItemInventoryType = GetItemInventoryTypeByID(mainHandItemLink or 0) or InventoryType.IndexNonEquipType

    local offHandItemLink = inventory[INVSLOT_OFFHAND]
    local offHandItemLevel = getItemLevel(offHandItemLink) or 0
    local offHandItemInventoryType = GetItemInventoryTypeByID(offHandItemLink or 0) or InventoryType.IndexNonEquipType

    if specID and specID == 72 and level and level >= 11 then -- Fury Warrior - Titan's Grip
        if mainHandItemLink and offHandItemLink then
            if mainHandItemInventoryType == InventoryType.Index2HweaponType and offHandItemInventoryType ==
                InventoryType.Index2HweaponType then
                return (sumItemLevel + (2 * (max(mainHandItemLevel, offHandItemLevel)))) * 0.0625
            elseif mainHandItemInventoryType == InventoryType.Index2HweaponType or offHandItemInventoryType ==
                InventoryType.Index2HweaponType then
                if mainHandItemInventoryType == InventoryType.Index2HweaponType then
                    if mainHandItemLevel >= offHandItemLevel then
                        return (sumItemLevel + (2 * mainHandItemLevel)) * 0.0625
                    else
                        return (sumItemLevel + mainHandItemLevel + offHandItemLevel) * 0.0625
                    end
                else
                    if offHandItemLevel >= mainHandItemLevel then
                        return (sumItemLevel + (2 * offHandItemLevel)) * 0.0625
                    else
                        return (sumItemLevel + mainHandItemLevel + offHandItemLevel) * 0.0625
                    end
                end
            else
                return (sumItemLevel + mainHandItemLevel + offHandItemLevel) * 0.0625
            end
        elseif mainHandItemLink then
            if mainHandItemInventoryType == InventoryType.Index2HweaponType then
                return (sumItemLevel + (2 * mainHandItemLevel)) * 0.0625
            else
                return (sumItemLevel + mainHandItemLevel) * 0.0625
            end
        elseif offHandItemLink then
            if offHandItemInventoryType == InventoryType.Index2HweaponType then
                return (sumItemLevel + (2 * offHandItemLevel)) * 0.0625
            else
                return (sumItemLevel + offHandItemLevel) * 0.0625
            end
        else
            return sumItemLevel * 0.0625
        end
    else
        if mainHandItemLink and offHandItemLink then
            return (sumItemLevel + mainHandItemLevel + offHandItemLevel) * 0.0625
        elseif mainHandItemLink then
            if mainHandItemInventoryType == InventoryType.Index2HweaponType or mainHandItemInventoryType ==
                InventoryType.IndexRangedType or mainHandItemInventoryType == InventoryType.IndexRangedrightType then
                return (sumItemLevel + (2 * mainHandItemLevel)) * 0.0625
            else
                return (sumItemLevel + mainHandItemLevel) * 0.0625
            end
        elseif offHandItemLink then
            return (sumItemLevel + offHandItemLevel) * 0.0625
        else
            return (sumItemLevel + 1) * 0.0625
        end
    end
end

local getInventoryItemLink = GetInventoryItemLink

---@param unit UnitToken
---@return table<number, string>
local function getUnitInventory(unit)
    local inventory = {}
    for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, 1 do
        local itemLink = getInventoryItemLink(unit, i)
        if itemLink and DoesItemExistByID(itemLink) then
            if not IsItemDataCachedByID(itemLink) then RequestLoadItemDataByID(itemLink) end
            inventory[i] = itemLink
        end
    end
    return inventory
end

---@param guid string
---@param infos PlayerInfo
function AddOn.GetPlayerInfos(guid, infos)
    if guid ~= PLAYER_GUID then
        if not IsGUIDInGroup(guid) then return end
        local unit = UnitTokenFromGUID(guid)
        if unit and UnitExists(unit) then
            infos.level = UnitLevel(unit)
            infos.role = UnitGroupRolesAssigned(unit)
            if not playerInfos[guid] then
                playerInfos[guid] = {infos}
            else
                playerInfos[guid][#playerInfos[guid] + 1] = infos
            end
        end
    else
        local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
        infos.avgItemLevel = avgItemLevelEquipped
        infos.inventory = getUnitInventory("player")
        infos.level = UnitLevel("player")
        infos.role = UnitGroupRolesAssigned("player")
        local currentSpec = GetSpecialization()
        infos.specID = currentSpec and (GetSpecializationInfo(currentSpec))
    end
end

local clearInspectPlayer = ClearInspectPlayer

AddOn.RegisterEvent("INSPECT_READY", --
---@param inspecteeGUID string
function(inspecteeGUID)
    local infos = playerInfos[inspecteeGUID]
    if infos then
        local unit
        if lastInspectUnit and UnitGUID(lastInspectUnit) == inspecteeGUID then
            unit = lastInspectUnit
        else
            unit = UnitTokenFromGUID(inspecteeGUID)
        end
        if unit then
            local inventory = getUnitInventory(unit)
            local specID = GetInspectSpecialization(unit)
            local avgItemLevel = getAverageItemLevelFromInventory(inventory, specID, UnitLevel(unit))
            for i = 1, #infos, 1 do
                local inspectInfo = infos[i]
                inspectInfo.avgItemLevel = avgItemLevel
                inspectInfo.inventory = copy(inventory)
                inspectInfo.specID = specID
            end
        end
    end
    if not inspectFrame or not inspectFrame.unit then clearInspectPlayer() end
end)

AddOn.RegisterEvent("ADDON_LOADED", --
---@param addOnName string
---@param containsBindings boolean
function(addOnName, containsBindings)
    if addOnName == "Blizzard_InspectUI" then
        inspectFrame = _G.InspectFrame ---@diagnostic disable-line:undefined-field
    end
end)
