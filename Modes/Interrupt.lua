---@class AddOn
local AddOn = (select(2, ...))

do -- CheckCombatHandlers
    local COMBAT_LOG_FILTER_GROUP = AddOn.COMBAT_LOG_FILTER_GROUP

    local CombatLog_Object_IsA = CombatLog_Object_IsA

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
    ---@param spellId number|string
    ---@param spellSchool number
    ---@param extraSpellId number|string
    ---@param extraSchool number
    ---@return boolean?
    local function onInterrupt(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                               destName, destFlags, destRaidFlags, spellId, spellSchool, extraSpellId, extraSchool)
        if sourceFlags and CombatLog_Object_IsA(sourceFlags, COMBAT_LOG_FILTER_GROUP) then return true end
    end

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
    ---@param spellId number|string
    ---@param spellName string
    ---@param spellSchool number
    ---@param extraSpellId number|string
    ---@param extraSpellName string
    ---@param extraSchool number
    ---@return boolean?
    function AddOn.CheckCombatHandlers.SPELL_INTERRUPT(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                       sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
                                                       spellId, spellName, spellSchool, extraSpellId, extraSpellName,
                                                       extraSchool)
        return onInterrupt(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                           destName, destFlags, destRaidFlags, spellId, spellSchool, extraSpellId, extraSchool)
    end
end

do -- CombatLogHandlers
    local COMBAT_LOG_FILTER_GROUP = AddOn.COMBAT_LOG_FILTER_GROUP
    local COMBAT_LOG_FILTER_GROUP_NO_PET = AddOn.COMBAT_LOG_FILTER_GROUP_NO_PET

    local tAddMulti = AddOn.tAddMulti

    local CombatLog_Object_IsA = CombatLog_Object_IsA
    local GetSource = AddOn.GetSource
    local GetSpell = AddOn.GetSpell
    local GetTarget = AddOn.GetTarget

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
    ---@param spellId SpellID
    ---@param spellSchool number
    ---@param extraSpellId SpellID
    ---@param extraSchool number
    local function onInterrupt(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
                               destGUID, destName, destFlags, destRaidFlags, spellId, spellSchool, extraSpellId,
                               extraSchool)
        if sourceFlags and CombatLog_Object_IsA(sourceFlags, COMBAT_LOG_FILTER_GROUP) then
            ---@type Interrupt?
            local interrupt = segment.interrupt
            if not interrupt then
                ---@class InterruptData
                ---@field amount? number
                ---@field groupAmount? number
                ---@field petAmount? number
                ---@field petGroupAmount? number

                ---@class InterruptTarget : InterruptData, UnitTable

                ---@class InterruptSpell : InterruptData, SpellTable
                ---@field targets table<string, InterruptTarget>

                ---@class InterruptSource : InterruptData, UnitTable
                ---@field spells table<SpellID, InterruptSpell>
                ---@field targets table<string, InterruptTarget>

                ---@class Interrupt : InterruptData
                interrupt = {
                    ---@type table<string, InterruptSource>
                    sources = {},
                    ---@type table<SpellID, InterruptSpell>
                    spells = {},
                    ---@type table<string, InterruptTarget>
                    targets = {},
                }
                segment.interrupt = interrupt
            end

            local source, spell, target, sourceSpell, sourceTarget, spellTarget, sourceSpellTarget, isNew, isPet
            ---@type InterruptSource
            source, --
            isNew, isPet = GetSource(interrupt.sources, sourceGUID, sourceName, sourceFlags)
            if isNew then
                source.spells = {}
                source.targets = {}
            end

            ---@type InterruptSpell
            spell, --
            isNew = GetSpell(interrupt.spells, extraSpellId, extraSchool)
            if isNew then spell.targets = {} end

            ---@type InterruptTarget
            target, --
            isNew = GetTarget(interrupt.targets, destGUID, destName, destFlags)

            ---@type InterruptSpell
            sourceSpell, --
            isNew = GetSpell(source.spells, extraSpellId, extraSchool)
            if isNew then sourceSpell.targets = {} end

            ---@type InterruptTarget
            sourceTarget, --
            isNew = GetTarget(source.targets, destGUID, destName, destFlags)

            ---@type InterruptTarget
            spellTarget, --
            isNew = GetTarget(spell.targets, destGUID, destName, destFlags)

            ---@type InterruptTarget
            sourceSpellTarget, --
            isNew = GetTarget(sourceSpell.targets, destGUID, destName, destFlags)

            if destFlags and CombatLog_Object_IsA(destFlags, COMBAT_LOG_FILTER_GROUP_NO_PET) then
                if isPet then
                    tAddMulti("petGroupAmount", 1, interrupt, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                else
                    tAddMulti("groupAmount", 1, interrupt, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
            elseif isPet then
                tAddMulti("petAmount", 1, interrupt, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                          sourceSpellTarget)
            else
                tAddMulti("amount", 1, interrupt, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                          sourceSpellTarget)
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
    ---@param spellId number|string
    ---@param spellName string
    ---@param spellSchool number
    ---@param extraSpellId number|string
    ---@param extraSpellName string
    ---@param extraSchool number
    function AddOn.CombatLogHandlers.SPELL_INTERRUPT(segment, timestamp, hideCaster, sourceGUID, sourceName,
                                                     sourceFlags, sourceRaidFlags, destGUID, destName, destFlags,
                                                     destRaidFlags, spellId, spellName, spellSchool, extraSpellId,
                                                     extraSpellName, extraSchool)
        onInterrupt(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                    destName, destFlags, destRaidFlags, spellId, spellSchool, extraSpellId, extraSchool)
    end
end

local L = AddOn.L
local INTERRUPT_TITLE = AddOn.GenerateHyperlink(L.INTERRUPT, "mode", "interrupt")
local INTERRUPT_TITLE_MOD = AddOn.GenerateHyperlink(L.INTERRUPT .. "*", "mode", "interrupt")

local format = format
local max = max
local next = next
local tConcat = table.concat
local tonumber = tonumber
local wipe = wipe

local AppendTextToTexture = AddOn.AppendTextToTexture
local ArrayToPairs = AddOn.ArrayToPairs
local ExtractLink = AddOn.ExtractLink
local FillSpellTables = AddOn.FillSpellTables
local FillUnitTables = AddOn.FillUnitTables
local FormatNumber = AddOn.FormatNumber
local GetClassColor = AddOn.GetClassColor
local GetClassTextureAndName = AddOn.GetClassTextureAndName
local GetDamageClassColor = AddOn.GetDamageClassColor
local GetPlayerClass = AddOn.GetPlayerClass
local GetPlayerName = AddOn.GetPlayerName
local GetScreenHeight = GetScreenHeight
local GetSpellIcon = AddOn.GetSpellIcon
local GetSpellName = AddOn.GetSpellName
local GetSpellTitleLink = AddOn.GetSpellTitleLink
local GetUnitTitleLink = AddOn.GetUnitTitleLink
local MenuResponseRefresh = MenuResponse.Refresh
local SortUnitNames = AddOn.SortUnitNames
local SortSpellNames = AddOn.SortSpellNames
local Tooltip = AddOn.Tooltip

local InterruptMode = AddOn.RegisterMode("interrupt", L.INTERRUPT)
if InterruptMode then
    ---@param filter InterruptModeFilter
    ---@param data InterruptData?
    ---@return number
    local function getAmount(filter, data)
        if not data then return 0 end

        local amount = data.amount or 0
        if filter.group then
            amount = amount + (data.groupAmount or 0)
            if filter.pets then amount = amount + (data.petGroupAmount or 0) end
        end
        if filter.pets then amount = amount + (data.petAmount or 0) end
        return amount > 0 and amount or 0
    end

    ---@param frame Frame
    ---@param elementDescription ElementMenuDescriptionProxy
    local function onUnitEnter(frame, elementDescription)
        Tooltip:SetOwner(frame, "ANCHOR_RIGHT")
        Tooltip:SetHyperlink("unit:" .. elementDescription:GetData())
    end

    ---@param frame Frame
    ---@param elementDescription ElementMenuDescriptionProxy
    local function onSpellEnter(frame, elementDescription)
        Tooltip:SetOwner(frame, "ANCHOR_RIGHT")
        Tooltip:SetHyperlink("spell:" .. elementDescription:GetData())
    end

    ---@param frame Frame
    ---@param elementDescription ElementMenuDescriptionProxy
    local function onUnitOrSpellLeave(frame, elementDescription) Tooltip:Hide() end

    ---@class InterruptModeFilter
    InterruptMode.DefaultFilter = {
        show = "sources",
        source = nil,
        spell = nil,
        target = nil,
        pets = true,
        group = false,
    }

    ---@param filter InterruptModeFilter
    function InterruptMode.SubTitle(filter, segment, values, totalValue, maxValue)
        if not segment then return end

        if totalValue > 0 then
            return format("%s (%s)", FormatNumber(totalValue), FormatNumber(totalValue / segment:GetDuration()))
        end
    end

    do -- Title
        ---@type string[]
        local title = {}

        ---@param filter InterruptModeFilter
        function InterruptMode.Title(filter, segment)
            wipe(title)
            title[#title + 1] = INTERRUPT_TITLE

            ---@type Interrupt?
            local interrupt = segment and segment.interrupt
            if not interrupt then return title[1] end

            if filter.show ~= "sources" then title[1] = INTERRUPT_TITLE_MOD end

            local source = filter.source
            local spell = filter.spell
            local target = filter.target

            if source then
                title[1] = INTERRUPT_TITLE_MOD
                title[#title + 1] = GetUnitTitleLink("interrupt", source, interrupt.sources[source], "source")
            end
            if spell then
                title[1] = INTERRUPT_TITLE_MOD
                title[#title + 1] = GetSpellTitleLink("interrupt", spell, interrupt.spells[spell])
            end
            if target then
                title[1] = INTERRUPT_TITLE_MOD
                title[#title + 1] = GetUnitTitleLink("interrupt", target, interrupt.targets[target], "target")
            end

            return tConcat(title, " - ")
        end
    end

    ---@param filter InterruptModeFilter
    function InterruptMode.Values(filter, segment, values, texts, colors, icons, iconCoords)
        ---@type Interrupt?
        local interrupt = segment.interrupt
        if not interrupt then return 0, true, true end

        local show = filter.show
        local source = filter.source
        local spell = filter.spell
        local target = filter.target

        local maxAmount = 0

        if source then
            local sourceData = interrupt.sources[source]
            if not sourceData then return 0, true, true end

            if spell then
                local spellData = sourceData.spells[spell]
                if not spellData then return 0, true, true end

                if target then
                    local targetData = spellData.targets[target]
                    if not targetData then return 0, true, true end

                    local amount = getAmount(filter, targetData)
                    if amount > 0 then
                        maxAmount = amount

                        if show == "sources" then
                            FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                        elseif show == "spells" then
                            FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                        elseif show == "targets" then
                            FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                else
                    if show == "sources" then
                        local amount = getAmount(filter, spellData)
                        if amount > 0 then
                            maxAmount = amount

                            FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                        end
                    elseif show == "spells" then
                        local amount = getAmount(filter, spellData)
                        if amount > 0 then
                            maxAmount = amount

                            FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                        end
                    elseif show == "targets" then
                        for key, data in next, spellData.targets, nil do
                            local amount = getAmount(filter, data)
                            if amount > 0 then
                                maxAmount = max(maxAmount, amount)

                                FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                            end
                        end
                    end
                end
            elseif target then
                if show == "sources" then
                    local targetData = sourceData.targets[target]
                    if not targetData then return 0, true, true end

                    local amount = getAmount(filter, targetData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "spells" then
                    for key, data in next, sourceData.spells, nil do
                        local amount = getAmount(filter, data.targets[target])
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "targets" then
                    local targetData = sourceData.targets[target]
                    if not targetData then return 0, true, true end

                    local amount = getAmount(filter, targetData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            else
                if show == "sources" then
                    local amount = getAmount(filter, sourceData)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "spells" then
                    for key, data in next, sourceData.spells, nil do
                        local amount = getAmount(filter, data)
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "targets" then
                    for key, data in next, sourceData.targets, nil do
                        local amount = getAmount(filter, data)
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                end
            end
        elseif spell then
            if target then
                if show == "sources" then
                    for key, data in next, interrupt.sources, nil do
                        local spellData = data.spells[spell]
                        if spellData then
                            local targetData = spellData.targets[target]
                            if targetData then
                                local amount = getAmount(filter, targetData)
                                if amount > 0 then
                                    maxAmount = max(maxAmount, amount)

                                    FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                                end
                            end
                        end
                    end
                elseif show == "spells" then
                    local spellData = interrupt.spells[spell]
                    if not spellData then return 0, true, true end

                    local amount = getAmount(filter, spellData.targets[target])
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "targets" then
                    local spellData = interrupt.spells[spell]
                    if not spellData then return 0, true, true end

                    local targetData = spellData.targets[target]
                    if not targetData then return 0, true, true end

                    local amount = getAmount(filter, targetData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            else
                if show == "sources" then
                    for key, data in next, interrupt.sources, nil do
                        local amount = getAmount(filter, data.spells[spell])
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "spells" then
                    local spellData = interrupt.spells[spell]
                    if not spellData then return 0, true, true end

                    local amount = getAmount(filter, spellData)
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "targets" then
                    local spellData = interrupt.spells[spell]
                    if not spellData then return 0, true, true end

                    for key, data in next, spellData.targets, nil do
                        local amount = getAmount(filter, data)
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                end
            end
        elseif target then
            local targetData = interrupt.targets[target]
            if not targetData then return 0, true, true end

            if show == "sources" then
                for key, data in next, interrupt.sources, nil do
                    local amount = getAmount(filter, data.targets[target])
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, interrupt.spells, nil do
                    local amount = getAmount(filter, data.targets[target])
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "targets" then
                local amount = getAmount(filter, targetData)
                if amount > 0 then
                    maxAmount = amount

                    FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                end
            end
        else
            if show == "sources" then
                for key, data in next, interrupt.sources, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, interrupt.spells, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "targets" then
                for key, data in next, interrupt.targets, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            end
        end

        return maxAmount
    end

    ---@param filter InterruptModeFilter
    function InterruptMode.Menu(element, filter, segment)
        ---@type Interrupt?
        local interrupt = segment and segment.interrupt

        local source = element:CreateRadio(L.SOURCES, function(data) return filter.show == "sources" end,
                                           function(data, menuInputData, menu) filter.show = "sources" end)
        source:SetResponse(MenuResponseRefresh)

        local spell = element:CreateRadio(L.SPELLS, function(data) return filter.show == "spells" end,
                                          function(data, menuInputData, menu) filter.show = "spells" end)
        spell:SetResponse(MenuResponseRefresh)

        local target = element:CreateRadio(L.TARGETS, function(data) return filter.show == "targets" end,
                                           function(data, menuInputData, menu) filter.show = "targets" end)
        target:SetResponse(MenuResponseRefresh)

        element:CreateDivider()

        local sources = element:CreateButton(L.SOURCE, nop)
        sources:SetScrollMode(GetScreenHeight() * 0.5)
        do -- sources
            local radio = sources:CreateRadio(L.ALL, function(data) return filter.source == nil end,
                                              function(data, menuInputData, menu) filter.source = nil end)
            radio:SetResponse(MenuResponseRefresh)
        end
        sources:QueueDivider()

        local spells = element:CreateButton(L.SPELL, nop)
        spells:SetScrollMode(GetScreenHeight() * 0.5)
        do -- spells
            local radio = spells:CreateRadio(L.ALL, function(data) return filter.spell == nil end,
                                             function(data, menuInputData, menu) filter.spell = nil end)
            radio:SetResponse(MenuResponseRefresh)
        end
        spells:QueueDivider()

        local targets = element:CreateButton(L.TARGET, nop)
        targets:SetScrollMode(GetScreenHeight() * 0.5)
        do -- targets
            local radio = targets:CreateRadio(L.ALL, function(data) return filter.target == nil end,
                                              function(data, menuInputData, menu) filter.target = nil end)
            radio:SetResponse(MenuResponseRefresh)
        end
        targets:QueueDivider()

        if interrupt then
            do -- sources
                ---@type string[]
                local sourceKeys = {}
                for key, sourceData in next, interrupt.sources, nil do sourceKeys[#sourceKeys + 1] = key end
                SortUnitNames(sourceKeys)

                ---@param data string
                ---@return boolean
                local function isSelected(data) return filter.source == data end
                ---@param data string|number
                ---@param menuInputData MenuInputData
                ---@param menu MenuProxy
                local function select(data, menuInputData, menu) filter.source = data end

                for i = 1, #sourceKeys, 1 do
                    local key = sourceKeys[i]
                    local sourceData = interrupt.sources[key]

                    local class = GetPlayerClass(key) or sourceData.class
                    local radio = sources:CreateRadio(GetClassColor(class):WrapTextInColorCode(GetClassTextureAndName(
                                                                                                   class,
                                                                                                   GetPlayerName(key))),
                                                      isSelected, select, key)
                    radio:SetOnEnter(onUnitEnter)
                    radio:SetOnLeave(onUnitOrSpellLeave)
                    radio:SetResponse(MenuResponseRefresh)
                end
            end
            do -- spells
                ---@type string[]|number[]
                local spellKeys = {}
                for key, spellData in next, interrupt.spells, nil do spellKeys[#spellKeys + 1] = key end
                SortSpellNames(spellKeys)

                ---@param data string|number
                ---@return boolean
                local function isSelected(data) return filter.spell == data end
                ---@param data string|number
                ---@param menuInputData MenuInputData
                ---@param menu MenuProxy
                local function select(data, menuInputData, menu) filter.spell = data end

                for i = 1, #spellKeys, 1 do
                    local key = spellKeys[i]
                    local spellData = interrupt.spells[key]

                    if spellData then
                        local icon, iconCoords = GetSpellIcon(key)
                        local radio = spells:CreateRadio(GetDamageClassColor(spellData.school):WrapTextInColorCode(
                                                             AppendTextToTexture(GetSpellName(key), icon, iconCoords)),
                                                         isSelected, select, key)
                        radio:SetOnEnter(onSpellEnter)
                        radio:SetOnLeave(onUnitOrSpellLeave)
                        radio:SetResponse(MenuResponseRefresh)
                    end
                end
            end
            do -- targets
                ---@type string[]
                local targetKeys = {}
                for key, sourceData in next, interrupt.targets, nil do targetKeys[#targetKeys + 1] = key end
                SortUnitNames(targetKeys)

                ---@param data string
                ---@return boolean
                local function isSelected(data) return filter.target == data end
                ---@param data string
                ---@param menuInputData MenuInputData
                ---@param menu MenuProxy
                local function select(data, menuInputData, menu) filter.target = data end

                for i = 1, #targetKeys, 1 do
                    local key = targetKeys[i]
                    local targetData = interrupt.targets[key]

                    local class = GetPlayerClass(key) or targetData.class
                    local radio = targets:CreateRadio(GetClassColor(class):WrapTextInColorCode(GetClassTextureAndName(
                                                                                                   class,
                                                                                                   GetPlayerName(key))),
                                                      isSelected, select, key)
                    radio:SetOnEnter(onUnitEnter)
                    radio:SetOnLeave(onUnitOrSpellLeave)
                    radio:SetResponse(MenuResponseRefresh)
                end
            end
        end

        element:CreateDivider()

        element:CreateCheckbox(L.PETS, function(data) return filter.pets == true end,
                               function(data, menuInputData, menu) filter.pets = not filter.pets end)
        element:CreateCheckbox(L.GROUP, function(data) return filter.group == true end,
                               function(data, menuInputData, menu) filter.group = not filter.group end)
    end

    ---@param filter InterruptModeFilter
    function InterruptMode.OnClick(filter, key, button)
        local show = filter.show
        local source = filter.source
        local spell = filter.spell
        local target = filter.target

        if source then
            if spell then
                if target then
                    if show == "sources" then
                        if button == "LeftButton" then
                            filter.show = "spells"
                            filter.spell = nil
                            filter.target = nil
                        end
                    elseif show == "spells" then
                        if button == "LeftButton" then
                            filter.show = "targets"
                            filter.spell = nil
                            filter.target = nil
                        end
                    elseif show == "targets" then
                        if button == "LeftButton" then
                            filter.show = "sources"
                            filter.spell = nil
                            filter.target = nil
                        end
                    end
                else
                    if show == "sources" then
                        if button == "LeftButton" then
                            filter.show = "spells"
                            filter.spell = nil
                            filter.target = nil
                        end
                    elseif show == "spells" then
                        if button == "LeftButton" then
                            filter.show = "targets"
                            filter.spell = nil
                            filter.target = nil
                        end
                    elseif show == "targets" then
                        if button == "LeftButton" then
                            filter.show = "sources"
                            filter.source = nil
                            filter.spell = nil
                            filter.target = key
                        elseif button == "RightButton" then
                            filter.show = "spells"
                            filter.spell = nil
                        end
                    end
                end
            elseif target then
                if show == "sources" then
                    if button == "LeftButton" then
                        filter.show = "spells"
                        filter.spell = nil
                        filter.target = nil
                    end
                elseif show == "spells" then
                    if button == "LeftButton" then
                        filter.show = "targets"
                        filter.source = nil
                        filter.spell = key
                    elseif button == "RightButton" then
                        filter.show = "sources"
                        filter.source = nil
                    end
                elseif show == "targets" then
                    if button == "LeftButton" then
                        filter.show = "targets"
                        filter.spell = nil
                        filter.target = nil
                    end
                end
            else
                if show == "sources" then
                    --
                elseif show == "spells" then
                    if button == "LeftButton" then
                        filter.show = "targets"
                        filter.spell = key
                    elseif button == "RightButton" then
                        filter.show = "sources"
                        filter.source = nil
                    end
                elseif show == "targets" then
                    if button == "LeftButton" then
                        filter.show = "sources"
                        filter.source = nil
                        filter.spell = nil
                        filter.target = key
                    end
                end
            end
        elseif spell then
            if target then
                if show == "sources" then
                    if button == "LeftButton" then
                        filter.show = "spells"
                        filter.source = key
                        filter.spell = nil
                        filter.target = nil
                    end
                elseif show == "spells" then
                    if button == "LeftButton" then
                        filter.show = "sources"
                        filter.target = nil
                    end
                elseif show == "targets" then
                    if button == "LeftButton" then filter.show = "sources" end
                end
            else
                if show == "sources" then
                    if button == "LeftButton" then
                        filter.show = "targets"
                        filter.source = key
                    end
                elseif show == "spells" then
                    --
                elseif show == "targets" then
                    if button == "LeftButton" then
                        filter.show = "sources"
                        filter.target = key
                    end
                end
            end
        elseif target then
            if show == "sources" then
                if button == "LeftButton" then
                    filter.show = "spells"
                    filter.source = key
                    filter.spell = nil
                end
            elseif show == "spells" then
                if button == "LeftButton" then
                    filter.show = "sources"
                    filter.spell = key
                end
            elseif show == "targets" then
                --
            end
        else
            if show == "sources" then
                if button == "LeftButton" then
                    filter.show = "spells"
                    filter.source = key
                end
            elseif show == "spells" then
                if button == "LeftButton" then
                    filter.show = "targets"
                    filter.spell = key
                end
            elseif show == "targets" then
                if button == "LeftButton" then
                    filter.show = "sources"
                    filter.target = key
                end
            end
        end
    end

    ---@param filter InterruptModeFilter
    function InterruptMode.OnHyperlink(filter, link, button)
        local linkData = ExtractLink(link)
        if linkData then
            linkData = ArrayToPairs(linkData)

            if linkData.mode == "interrupt" then
                local source = linkData.source
                local spell = linkData.spell and tonumber(linkData.spell) or linkData.spell
                local target = linkData.target

                if source then
                    if button == "LeftButton" then filter.show = "spells" end
                    filter.source = source
                    filter.spell = nil
                    filter.target = nil
                elseif spell then
                    if button == "LeftButton" then filter.show = "sources" end
                    filter.source = nil
                    filter.spell = spell
                    filter.target = nil
                elseif target then
                    if button == "LeftButton" then filter.show = "sources" end
                    filter.source = nil
                    filter.spell = nil
                    filter.target = target
                else
                    if button == "LeftButton" then
                        filter.show = "sources"
                        filter.pets = true
                        filter.group = false
                    elseif button == "RightButton" then
                        filter.show = "sources"
                    end
                    filter.source = nil
                    filter.spell = nil
                    filter.target = nil
                end
            end
        end
    end

    ---@param filter InterruptModeFilter
    function InterruptMode.Tooltip(filter, segment, key, tooltip)
        ---@type Interrupt?
        local interrupt = segment.interrupt
        if not interrupt then return end

        local show = filter.show
        local source = filter.source
        local spell = filter.spell
        local target = filter.target

        if source then
            if spell then
                if target then
                    if show == "sources" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                    elseif show == "spells" then
                        tooltip:SetSpell(key)
                    elseif show == "targets" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                    end
                else
                    if show == "sources" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                        local sourceData = interrupt.sources[key]
                        if not sourceData then return end

                        local spellData = sourceData.spells[spell]
                        if not spellData then return end

                        for targetKey, data in next, spellData.targets, nil do
                            tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                        end
                        tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                    elseif show == "spells" then
                        tooltip:SetSpell(key)

                        local sourceData = interrupt.sources[source]
                        if not sourceData then return end

                        local spellData = sourceData.spells[key]
                        if not spellData then return end

                        for targetKey, data in next, spellData.targets, nil do
                            tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                        end
                        tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                    elseif show == "targets" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                    end
                end
            elseif target then
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = interrupt.sources[key]
                    if not sourceData then return end

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.targets[target]), data)
                    end
                    tooltip:ShowSpellAmounts(getAmount(filter, sourceData.targets[target]))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local sourceData = interrupt.sources[source]
                    if not sourceData then return end

                    local spellData = sourceData.spells[key]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = interrupt.sources[source]
                    if not sourceData then return end

                    local targetData = sourceData.targets[key]
                    if not targetData then return end

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                    end
                    tooltip:ShowSpellAmounts(getAmount(filter, targetData))
                end
            else
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = interrupt.sources[key]
                    if not sourceData then return end

                    local amount = getAmount(filter, sourceData)

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowSpellAmounts(amount)

                    for targetKey, data in next, sourceData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, amount)
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local sourceData = interrupt.sources[source]
                    if not sourceData then return end

                    local spellData = sourceData.spells[key]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = interrupt.sources[source]
                    if not sourceData then return end

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                    end
                    tooltip:ShowSpellAmounts(getAmount(filter, sourceData.targets[key]))
                end
            end
        elseif spell then
            if target then
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    for sourceKey, data in next, interrupt.sources, nil do
                        local spellData = data.spells[key]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[target]), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, interrupt.spells[key] and
                                                                    interrupt.spells[key].targets[target]))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for sourceKey, data in next, interrupt.sources, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, interrupt.spells[spell] and
                                                                    interrupt.spells[spell].targets[key]))
                end
            else
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = interrupt.sources[key]
                    if not sourceData then return end

                    local spellData = sourceData.spells[spell]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local spellData = interrupt.spells[key]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData)

                    for sourceKey, data in next, interrupt.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data.spells[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, amount)

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, amount)
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for sourceKey, data in next, interrupt.sources, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, interrupt.spells[spell] and
                                                                    interrupt.spells[spell].targets[key]))
                end
            end
        elseif target then
            if show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = interrupt.sources[key]
                if not sourceData then return end

                for spellKey, data in next, sourceData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[target]), data)
                end
                tooltip:ShowSpellAmounts(getAmount(filter, sourceData.targets[target]))
            elseif show == "spells" then
                tooltip:SetSpell(key)

                for sourceKey, data in next, interrupt.sources, nil do
                    local spellData = data.spells[key]
                    tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[target]), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, interrupt.spells[key] and
                                                                interrupt.spells[key].targets[target]))
            elseif show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = interrupt.targets[key]
                if not targetData then return end

                local amount = getAmount(filter, targetData)

                for sourceKey, data in next, interrupt.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, amount)

                for spellKey, data in next, interrupt.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ShowSpellAmounts(amount)
            end
        else
            if show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = interrupt.sources[key]
                if not sourceData then return end

                local amount = getAmount(filter, sourceData)

                for spellKey, data in next, sourceData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data), data)
                end
                tooltip:ShowSpellAmounts(amount)

                for targetKey, data in next, sourceData.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                end
                tooltip:ShowUnitAmounts(L.TARGET, amount)
            elseif show == "spells" then
                tooltip:SetSpell(key)

                local spellData = interrupt.spells[key]
                if not spellData then return end

                local amount = getAmount(filter, spellData)

                for sourceKey, data in next, interrupt.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.spells[key]), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, amount)

                for targetKey, data in next, spellData.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                end
                tooltip:ShowUnitAmounts(L.TARGET, amount)

            elseif show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = interrupt.targets[key]
                if not targetData then return end

                local amount = getAmount(filter, targetData)

                for sourceKey, data in next, interrupt.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, amount)

                for spellKey, data in next, interrupt.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ShowSpellAmounts(amount)
            end
        end
    end
end
