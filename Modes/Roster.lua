---@class AddOn
local AddOn = (select(2, ...))

local L = AddOn.L

local DEFAULT_TEXTURE = AddOn.DEFAULT_TEXTURE
local INVSLOT_FIRST_EQUIPPED = INVSLOT_FIRST_EQUIPPED
local INVSLOT_LAST_EQUIPPED = INVSLOT_LAST_EQUIPPED

local format = format
local max = max
local next = next
local tConcat = table.concat
local wipe = wipe

local ArrayToPairs = AddOn.ArrayToPairs
local DropDownMenu = AddOn.DropDownMenu
local ExtractLink = AddOn.ExtractLink
local FormatNumber = AddOn.FormatNumber
local GenerateHyperlink = AddOn.GenerateHyperlink
local GetClassColor = AddOn.GetClassColor
local GetClassIcon = AddOn.GetClassIcon
local GetItemInfo = C_Item.GetItemInfo
local GetItemQualityColor = AddOn.GetItemQualityColor
local GetPlayerClass = AddOn.GetPlayerClass
local GetPlayerName = AddOn.GetPlayerName

---@param source string
---@return string
local function getSourceTitle(source)
    return GenerateHyperlink(GetClassColor(GetPlayerClass(source)):WrapTextInColorCode(GetPlayerName(source)), "mode",
                             "roster", "source", source)
end

---@type string[]
local title = {}

AddOn.Modes.roster = {
    defaultFilter = {source = nil},
    getSubTitle = function(filter, segment, values, totalValue, maxValue)
        local roster = segment and segment.roster
        if not roster then return end

        local source = filter.source
        if source then
            return FormatNumber(roster[source] and roster[source].avgItemLevel)
        else
            local count = 0
            for key, value in next, values, nil do count = count + 1 end
            if count > 0 then return FormatNumber(totalValue / count) end
        end
    end,
    getTitle = function(filter, segment)
        wipe(title)
        title[#title + 1] = GenerateHyperlink(L.MEMBERS, "mode", "roster")

        local roster = segment.roster
        if not roster then return title[1] end

        local source = filter.source
        if source then
            title[1] = title[1] .. "*"
            title[#title + 1] = getSourceTitle(source)
        end

        return tConcat(title, " - ")
    end,
    getValues = function(filter, segment, values, texts, colors, icons, iconCoords)
        local roster = segment.roster
        if not roster then return end

        local maxAmount = 0

        local source = filter.source
        if source then
            local playerInfos = roster[source]
            if not playerInfos then return end

            local inventory = playerInfos.inventory
            if inventory then
                for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, 1 do
                    local item = inventory[i]
                    if item then
                        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
                              itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
                              expacID, setID, isCraftingReagent = GetItemInfo(item)
                        if itemName then
                            maxAmount = max(maxAmount, itemLevel or 0)
                            values[i] = itemLevel
                            texts[i] = itemName
                            colors[i] = GetItemQualityColor(itemQuality)
                            icons[i] = itemTexture
                        end
                    end
                end
            end
        else
            for key, playerInfos in next, roster, nil do
                local avgItemLevel = playerInfos.avgItemLevel
                if avgItemLevel and avgItemLevel > maxAmount then maxAmount = avgItemLevel end
                values[key] = avgItemLevel
                texts[key] = GetPlayerName(key)
                local class = GetPlayerClass(key)
                colors[key] = GetClassColor(class)
                icons[key], iconCoords[key] = GetClassIcon(class)
            end
        end

        return maxAmount
    end,
    menu = function(filter, segment)
        local roster = segment.roster
        if not roster then return function() end end

        return function()
            ---@type MenuInfo[]
            local menuInfos = {}

            local func = function(isChecked, value, arg) filter.source = value end

            for key in next, roster, nil do
                menuInfos[#menuInfos + 1] = {
                    func = func,
                    isChecked = filter.source == key,
                    text = GetPlayerName(key),
                    textColor = GetClassColor(GetPlayerClass(key)),
                    value = key,
                }
            end

            menuInfos[#menuInfos + 1] = DropDownMenu:GetSeparatorInfo()
            menuInfos[#menuInfos + 1] = {
                func = function(isChecked, value, arg) filter.source = nil end,
                isNotCheckable = true,
                text = L.RESET,
            }

            return menuInfos
        end
    end,
    onClick = function(filter, key, button)
        local source = filter.source
        if source then
            if button == "RightButton" then filter.source = nil end
        else
            filter.source = key
        end
    end,
    onHyperlink = function(filter, link, button)
        local linkData = ExtractLink(link)
        if linkData then
            linkData = ArrayToPairs(linkData)

            if linkData.mode == "roster" then filter.source = nil end
        end
    end,
    perSecond = false,
    percent = false,
    tooltip = function(filter, segment, key, tooltip)
        local roster = segment.roster

        local source = filter.source
        if source then
            if not roster then return end

            local playerInfos = roster[source]
            if not playerInfos then return end

            local inventory = playerInfos.inventory
            if not inventory then return end

            local item = inventory[key]
            if not item then return end

            tooltip:SetHyperlink(item)
        else
            local playerInfos = roster and roster[key]
            tooltip:SetPlayerOrName(key, playerInfos)

            if playerInfos then
                local inventory = playerInfos.inventory
                if inventory then
                    tooltip:AddBlankLines(1)
                    for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, 1 do
                        local item = inventory[i]
                        if item then
                            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
                                  itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
                                  expacID, setID, isCraftingReagent = GetItemInfo(item)
                            if itemName then
                                tooltip:AddColoredDoubleLine(
                                    format("|T%s:0|t %s", itemTexture or DEFAULT_TEXTURE, itemName), itemLevel,
                                    GetItemQualityColor(itemQuality))
                            end
                        end
                    end
                end
            end
        end
    end,
}
AddOn.ModeNames.roster = L.MEMBERS
AddOn.ModeKeys[#AddOn.ModeKeys + 1] = "roster"
