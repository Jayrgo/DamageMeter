---@class AddOn
local AddOn = (select(2, ...))

do -- CombatLogHandlers
    local COMBAT_LOG_FILTER_GROUP_NO_PET = AddOn.COMBAT_LOG_FILTER_GROUP_NO_PET

    local tAddMulti = AddOn.tAddMulti

    local CombatLog_Object_IsA = CombatLog_Object_IsA
    local GetTarget = AddOn.GetTarget
    local UnitIsFeignDeath = UnitIsFeignDeath
    local UnitTokenFromGUID = UnitTokenFromGUID

    ---@param segment Segment
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
    local function onDeath(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
                           destGUID, destName, destFlags, destRaidFlags)
        if destFlags and destFlags and CombatLog_Object_IsA(destFlags, COMBAT_LOG_FILTER_GROUP_NO_PET) then
            local unit = destGUID and UnitTokenFromGUID(destGUID)
            if unit and UnitIsFeignDeath(unit) then return end

            ---@type Death?
            local death = segment.death
            if not death then
                ---@class DeathData
                ---@field amount? number

                ---@class DeathTarget : DeathData, UnitTable
                ---@field timestamps? number[]
                ---@field events? table

                ---@class Death : DeathData
                death = {
                    ---@type table<string, DeathTarget>
                    targets = {},
                }
                segment.death = death
            end

            local target, isNew

            ---@type DeathTarget
            target, --
            isNew = GetTarget(death.targets, destGUID, destName, destFlags)
            tAddMulti("amount", 1, death, target)

            local timestamps = target.timestamps
            if timestamps then
                timestamps[#timestamps + 1] = timestamp
            else
                timestamps = {timestamp}
            end
        end
    end

    ---@param segment Segment
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
    ---@param recapID? number
    ---@param unconsciousOnDeath? number
    function AddOn.CombatLogHandlers.UNIT_DIED(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                               sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, recapID,
                                               unconsciousOnDeath)
        onDeath(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                destName, destFlags, destRaidFlags)
    end
end

local L = AddOn.L
local DEATH_TITLE = AddOn.GenerateHyperlink(L.DEATH, "mode", "death")
local DEATH_TITLE_MOD = AddOn.GenerateHyperlink(L.DEATH .. "*", "mode", "death")

local format = format
local max = max
local next = next
local tConcat = table.concat
local tInsert = table.insert
local tonumber = tonumber
local wipe = wipe
local time = time

local ArrayToPairs = AddOn.ArrayToPairs
local DropDownMenu = AddOn.DropDownMenu
local ExtractLink = AddOn.ExtractLink
local FillSpellTables = AddOn.FillSpellTables
local FillUnitTables = AddOn.FillUnitTables
local FormatNumber = AddOn.FormatNumber
local GetClassColor = AddOn.GetClassColor
local GetClassIcon = AddOn.GetClassIcon
local GetDamageClassColor = AddOn.GetDamageClassColor
local GetPlayerClass = AddOn.GetPlayerClass
local GetPlayerName = AddOn.GetPlayerName
local GetSpellIcon = AddOn.GetSpellIcon
local GetSpellName = AddOn.GetSpellName
local GetSpellTitleLink = AddOn.GetSpellTitleLink
local GetUnitTitleLink = AddOn.GetUnitTitleLink
local SortMenuInfos = AddOn.SortMenuInfos

---@param filter table
---@param data DeathData?
---@return number
local function getAmount(filter, data) return data and data.amount or 0 end

AddOn.Modes.death = {
    defaultFilter = {},
    getSubTitle = function(filter, segment, values, totalValue, maxValue)
        ---@type Death?
        local death = segment and segment.death
        if not death then return end

        return FormatNumber(death.amount)
    end,
    getTitle = function(filter, segment) return DEATH_TITLE end,
    getValues = function(filter, segment, values, texts, colors, icons, iconCoords)
        ---@type Death?
        local death = segment.death
        if not death then return end

        local maxAmount = 0

        for key, data in next, death.targets, nil do
            local amount = getAmount(filter, data)
            if amount > 0 then
                maxAmount = max(maxAmount, amount)

                FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
            end
        end

        return maxAmount
    end,
    perSecond = false,
    percent = true,
    tooltip = function(filter, segment, key, tooltip)
        ---@type Death?
        local death = segment.death
        if not death then return end

        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
    end,
}
AddOn.ModeNames.death = L.DEATH
AddOn.ModeKeys[#AddOn.ModeKeys + 1] = "death"
