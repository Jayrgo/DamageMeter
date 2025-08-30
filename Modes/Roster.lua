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
local ExtractLink = AddOn.ExtractLink
local FormatNumber = AddOn.FormatNumber
local GenerateHyperlink = AddOn.GenerateHyperlink
local GetClassColor = AddOn.GetClassColor
local GetClassIcon = AddOn.GetClassIcon
local GetClassTextureAndName = AddOn.GetClassTextureAndName
local GetItemInfo = C_Item.GetItemInfo
local GetItemQualityColor = AddOn.GetItemQualityColor
local GetPlayerClass = AddOn.GetPlayerClass
local GetPlayerName = AddOn.GetPlayerName
local MenuResponseRefresh = MenuResponse.Refresh
local SortUnitNames = AddOn.SortUnitNames
local Tooltip = AddOn.Tooltip

local RosterMode = AddOn.RegisterMode("roster", L.MEMBERS)
if RosterMode then
    ---@param source string
    ---@return string
    local function getSourceTitle(source)
        return GenerateHyperlink(GetClassColor(GetPlayerClass(source)):WrapTextInColorCode(GetPlayerName(source)),
                                 "mode", "roster", "source", source)
    end

    ---@param frame Frame
    ---@param elementDescription ElementMenuDescriptionProxy
    local function onUnitEnter(frame, elementDescription)
        Tooltip:SetOwner(frame, "ANCHOR_RIGHT")
        Tooltip:SetHyperlink("unit:" .. elementDescription:GetData())
    end

    ---@param frame Frame
    ---@param elementDescription ElementMenuDescriptionProxy
    local function onUnitOrSpellLeave(frame, elementDescription) Tooltip:Hide() end

    ---@class RosterModeFilter
    RosterMode.DefaultFilter = {source = nil}

    do -- Title
        ---@type string[]
        local title = {}

        ---@param filter RosterModeFilter
        function RosterMode.Title(filter, segment)
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
        end
    end

    ---@param filter RosterModeFilter
    function RosterMode.Values(filter, segment, values, texts, colors, icons, iconCoords)
        local roster = segment.roster
        if not roster then return 0, false, false end

        local maxAmount = 0

        local source = filter.source
        if source then
            local playerInfos = roster[source]
            if not playerInfos then return 0, false, false end

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

        return maxAmount, false, false
    end

    ---@param filter RosterModeFilter
    function RosterMode.Menu(element, filter, segment)
        ---@type table<string, PlayerInfo>?
        local roster = segment and segment.roster

        if roster then
            ---@type string[]
            local playerKeys = {}
            for key, playerInfo in next, roster, nil do playerKeys[#playerKeys + 1] = key end
            SortUnitNames(playerKeys)

            ---@param data string
            ---@return boolean
            local function isSelected(data) return filter.source == data end
            ---@param data string|number
            ---@param menuInputData MenuInputData
            ---@param menu MenuProxy
            local function select(data, menuInputData, menu) filter.source = data end

            for i = 1, #playerKeys, 1 do
                local key = playerKeys[i]

                local class = GetPlayerClass(key)
                local radio = element:CreateRadio(
                                  GetClassColor(class):WrapTextInColorCode(GetClassTextureAndName(class,
                                                                                                  GetPlayerName(key))),
                                  isSelected, select, key)
                radio:SetOnEnter(onUnitEnter)
                radio:SetOnLeave(onUnitOrSpellLeave)
                radio:SetResponse(MenuResponseRefresh)
            end
        end
    end

    ---@param filter RosterModeFilter
    function RosterMode.OnClick(filter, key, button)
        local source = filter.source
        if source then
            if button == "RightButton" then filter.source = nil end
        else
            filter.source = key
        end
    end

    ---@param filter RosterModeFilter
    function RosterMode.OnHyperlink(filter, link, button)
        local linkData = ExtractLink(link)
        if linkData then
            linkData = ArrayToPairs(linkData)

            if linkData.mode == "roster" then filter.source = nil end
        end
    end

    ---@param filter RosterModeFilter
    function RosterMode.Tooltip(filter, segment, key, tooltip)
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
    end
end
