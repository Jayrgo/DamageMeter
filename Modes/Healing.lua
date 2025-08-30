---@class AddOn
local AddOn = (select(2, ...))

do -- CombatLogHandlers
    local COMBAT_LOG_FILTER_GROUP = AddOn.COMBAT_LOG_FILTER_GROUP
    local COMBAT_LOG_FILTER_GROUP_NO_PET = AddOn.COMBAT_LOG_FILTER_GROUP_NO_PET

    local tAddMulti = AddOn.tAddMulti
    local tSetMaxMulti = AddOn.tSetMaxMulti
    local tSetMinMulti = AddOn.tSetMinMulti

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
    ---@param amount number
    ---@param overhealing? number
    ---@param absorbed? number
    ---@param critical boolean
    local function onHeal(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
                          destGUID, destName, destFlags, destRaidFlags, spellId, spellSchool, amount, overhealing,
                          absorbed, critical)
        if sourceFlags and CombatLog_Object_IsA(sourceFlags, COMBAT_LOG_FILTER_GROUP) then
            ---@type HealingDone?
            local healingDone = segment.healingDone
            if not healingDone then
                ---@class HealingDoneData
                ---@field amount? number
                ---@field overhealing? number
                ---@field absorbed? number
                ---@field numHits? number
                ---@field minHit? number
                ---@field maxHit? number
                ---@field numCrits? number
                ---@field petAmount? number
                ---@field petOverhealing? number
                ---@field petAbsorbed? number

                ---@class HealingDoneTarget : HealingDoneData, UnitTable

                ---@class HealingDoneSpell : HealingDoneData, SpellTable
                ---@field targets table<string, HealingDoneTarget>

                ---@class HealingDoneSource : HealingDoneData, UnitTable
                ---@field spells table<SpellID, HealingDoneSpell>
                ---@field targets table<string, HealingDoneTarget>

                ---@class HealingDone : HealingDoneData
                healingDone = {
                    ---@type table<string, HealingDoneSource>
                    sources = {},
                    ---@type table<SpellID, HealingDoneSpell>
                    spells = {},
                    ---@type table<string, HealingDoneTarget>
                    targets = {},
                }
                segment.healingDone = healingDone
            end

            local source, spell, target, sourceSpell, sourceTarget, spellTarget, sourceSpellTarget, isNew, isPet
            ---@type HealingDoneSource
            source, --
            isNew, isPet = GetSource(healingDone.sources, sourceGUID, sourceName, sourceFlags)
            if isNew then
                source.spells = {}
                source.targets = {}
            end

            ---@type HealingDoneSpell
            spell, --
            isNew = GetSpell(healingDone.spells, spellId, spellSchool)
            if isNew then spell.targets = {} end

            ---@type HealingDoneTarget
            target, --
            isNew = GetTarget(healingDone.targets, destGUID, destName, destFlags)

            ---@type HealingDoneSpell
            sourceSpell, --
            isNew = GetSpell(source.spells, spellId, spellSchool)
            if isNew then sourceSpell.targets = {} end

            ---@type HealingDoneTarget
            sourceTarget, --
            isNew = GetTarget(source.targets, destGUID, destName, destFlags)

            ---@type HealingDoneTarget
            spellTarget, --
            isNew = GetTarget(spell.targets, destGUID, destName, destFlags)

            ---@type HealingDoneTarget
            sourceSpellTarget, --
            isNew = GetTarget(sourceSpell.targets, destGUID, destName, destFlags)

            if isPet then
                tAddMulti("petAmount", amount, healingDone, source, spell, target, sourceSpell, sourceTarget,
                          spellTarget, sourceSpellTarget)

                if overhealing and overhealing > 0 then
                    tAddMulti("petOverhealing", overhealing, healingDone, source, spell, target, sourceSpell,
                              sourceTarget, spellTarget, sourceSpellTarget)
                end
                if absorbed and absorbed > 0 then
                    tAddMulti("petAbsorbed", absorbed, healingDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end

                tAddMulti("petNumHits", 1, healingDone, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                          sourceSpellTarget)

                tSetMinMulti("petMinHit", amount, healingDone, source, spell, target, sourceSpell, sourceTarget,
                             spellTarget, sourceSpellTarget)

                tSetMaxMulti("petMaxHit", amount, healingDone, source, spell, target, sourceSpell, sourceTarget,
                             spellTarget, sourceSpellTarget)

                if critical then
                    tAddMulti("petNumCrits", 1, healingDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
            else
                tAddMulti("amount", amount, healingDone, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                          sourceSpellTarget)

                if overhealing and overhealing > 0 then
                    tAddMulti("overhealing", overhealing, healingDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
                if absorbed and absorbed > 0 then
                    tAddMulti("absorbed", absorbed, healingDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end

                tAddMulti("numHits", 1, healingDone, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                          sourceSpellTarget)

                tSetMinMulti("minHit", amount, healingDone, source, spell, target, sourceSpell, sourceTarget,
                             spellTarget, sourceSpellTarget)

                tSetMaxMulti("maxHit", amount, healingDone, source, spell, target, sourceSpell, sourceTarget,
                             spellTarget, sourceSpellTarget)

                if critical then
                    tAddMulti("numCrits", 1, healingDone, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                              sourceSpellTarget)
                end
            end
        end
        if destFlags and CombatLog_Object_IsA(destFlags, COMBAT_LOG_FILTER_GROUP_NO_PET) then
            ---@type HealingTaken?
            local healingTaken = segment.healingTaken
            if not healingTaken then
                ---@class HealingTakenData
                ---@field amount? number
                ---@field overhealing? number
                ---@field absorbed? number
                ---@field numHits? number
                ---@field minHit? number
                ---@field maxHit? number
                ---@field numCrits? number

                ---@class HealingTakenSource : HealingTakenData, UnitTable

                ---@class HealingTakenSpell : HealingTakenData, SpellTable
                ---@field sources table<string, HealingTakenSource>

                ---@class HealingTakenTarget : HealingTakenData, UnitTable
                ---@field spells table<string|number, HealingTakenSpell>
                ---@field sources table<string, HealingTakenSource>

                ---@class HealingTaken : HealingTakenData
                healingTaken = {
                    ---@type table<string, HealingTakenTarget>
                    targets = {},
                    ---@type table<string|number, HealingTakenSpell>
                    spells = {},
                    ---@type table<string, HealingTakenSource>
                    sources = {},
                }
                segment.healingTaken = healingTaken
            end

            local target, spell, source, targetSpell, targetSource, spellSource, targetSpellSource, isNew
            ---@type HealingTakenTarget
            target, --
            isNew = GetTarget(healingTaken.targets, destGUID, destName, destFlags)
            if isNew then
                target.spells = {}
                target.sources = {}
            end

            ---@type HealingTakenSpell
            spell, --
            isNew = GetSpell(healingTaken.spells, spellId, spellSchool)
            if isNew then spell.sources = {} end

            ---@type HealingTakenSource
            source, --
            isNew = GetSource(healingTaken.sources, sourceGUID, sourceName, sourceFlags)

            ---@type HealingTakenSpell
            targetSpell, --
            isNew = GetSpell(target.spells, spellId, spellSchool)
            if isNew then targetSpell.sources = {} end

            ---@type HealingTakenSource
            targetSource, --
            isNew = GetSource(target.sources, sourceGUID, sourceName, sourceFlags)

            ---@type HealingTakenSource
            spellSource, --
            isNew = GetSource(spell.sources, sourceGUID, sourceName, sourceFlags)

            ---@type HealingTakenSource
            targetSpellSource, --
            isNew = GetSource(targetSpell.sources, sourceGUID, sourceName, sourceFlags)

            tAddMulti("amount", amount, healingTaken, target, spell, source, targetSpell, targetSource, spellSource,
                      targetSpellSource)

            if overhealing and overhealing > 0 then
                tAddMulti("overhealing", overhealing, healingTaken, target, spell, source, targetSpell, targetSource,
                          spellSource, targetSpellSource)
            end
            if absorbed and absorbed > 0 then
                tAddMulti("absorbed", absorbed, healingTaken, target, spell, source, targetSpell, targetSource,
                          spellSource, targetSpellSource)
            end

            tAddMulti("numHits", 1, healingTaken, target, spell, source, targetSpell, targetSource, spellSource,
                      targetSpellSource)

            tSetMinMulti("minHit", amount, healingTaken, target, spell, source, targetSpell, targetSource, spellSource,
                         targetSpellSource)

            tSetMaxMulti("maxHit", amount, healingTaken, target, spell, source, targetSpell, targetSource, spellSource,
                         targetSpellSource)

            if critical then
                tAddMulti("numCrits", 1, healingTaken, target, spell, source, targetSpell, targetSource, spellSource,
                          targetSpellSource)
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
    ---@param spellSchool number
    ---@param amount number
    ---@param overhealing? number
    ---@param absorbed? number
    ---@param critical boolean
    function AddOn.CombatLogHandlers.SPELL_HEAL(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId,
                                                spellName, spellSchool, amount, overhealing, absorbed, critical)
        onHeal(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName,
               destFlags, destRaidFlags, spellId, spellSchool, amount, overhealing, absorbed, critical)
    end

    AddOn.CombatLogHandlers.SPELL_PERIODIC_HEAL = AddOn.CombatLogHandlers.SPELL_HEAL
    AddOn.CombatLogHandlers.SPELL_BUILDING_HEAL = AddOn.CombatLogHandlers.SPELL_HEAL
end

local L = AddOn.L
local HEALING_DONE_TITLE = AddOn.GenerateHyperlink(L.HEALING_DONE, "mode", "healingDone")
local HEALING_DONE_TITLE_MOD = AddOn.GenerateHyperlink(L.HEALING_DONE .. "*", "mode", "healingDone")
local HEALING_TAKEN_TITLE = AddOn.GenerateHyperlink(L.HEALING_TAKEN, "mode", "healingTaken")
local HEALING_TAKEN_TITLE_MOD = AddOn.GenerateHyperlink(L.HEALING_TAKEN .. "*", "mode", "healingTaken")

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
local GetClassColor = AddOn.GetClassColor
local GetClassTextureAndName = AddOn.GetClassTextureAndName
local GetDamageClassColor = AddOn.GetDamageClassColor
local GetPlayerClass = AddOn.GetPlayerClass
local GetPlayerName = AddOn.GetPlayerName
local GetSpellIcon = AddOn.GetSpellIcon
local GetSpellName = AddOn.GetSpellName
local GetSpellTitleLink = AddOn.GetSpellTitleLink
local GetUnitTitleLink = AddOn.GetUnitTitleLink
local SortUnitNames = AddOn.SortUnitNames
local SortSpellNames = AddOn.SortSpellNames

---@param filter HealingDoneModeFilter | HealingTakenModeFilter
---@param data HealingDoneData|HealingTakenData?
---@return number
local function getAmount(filter, data)
    if not data then return 0 end

    local amount = data.amount or 0
    if not filter.overhealing then amount = amount - (data.overhealing or 0) end
    if filter.absorbed then amount = amount + (data.absorbed or 0) end
    if filter.pets then
        amount = amount + (data.petAmount or 0)
        if not filter.overhealing then amount = amount - (data.petOverhealing or 0) end
        if filter.absorbed then amount = amount + (data.petAbsorbed or 0) end
    end
    return amount
end

local HealingDoneMode = AddOn.RegisterMode("healingDone", L.HEALING_DONE)
if HealingDoneMode then
    ---@class HealingDoneModeFilter
    ---@field show "sources"|"spells"|"targets"
    ---@field source string?
    ---@field spell SpellID?
    ---@field target string?
    ---@field pets boolean
    ---@field overhealing boolean
    ---@field absorbed boolean

    function HealingDoneMode.Filter(segment)
        return {
            {
                Type = "select",
                Name = "show",
                Values = {
                    {Value = "sources", Title = L.SOURCES},
                    {Value = "spells", Title = L.SPELLS},
                    {Value = "targets", Title = L.TARGETS},
                },
                Default = "sources",
            },
            {
                Type = "select",
                Name = "source",
                Title = L.SOURCE,
                Default = nil,
                Nilable = true,
                Values = (function()
                    ---@type HealingDone?
                    local healingDone = segment and segment.healingDone
                    local values = {{Title = L.ALL, Value = nil}}

                    if healingDone then
                        ---@type string[]
                        local sourceKeys = {}
                        for key, sourceData in next, healingDone.sources, nil do
                            sourceKeys[#sourceKeys + 1] = key
                        end
                        SortUnitNames(sourceKeys)

                        for i = 1, #sourceKeys, 1 do
                            local key = sourceKeys[i]
                            local sourceData = healingDone.sources[key]

                            local class = GetPlayerClass(key) or sourceData.class
                            values[#values + 1] = {
                                Title = GetClassColor(class):WrapTextInColorCode(GetClassTextureAndName(class,
                                                                                                        GetPlayerName(
                                                                                                            key))),
                                Value = key,
                                Tooltip = HealingDoneMode.onUnitEnter,
                            }
                        end
                    end

                    return values
                end)(),
            },
            {
                Type = "select",
                Name = "spell",
                Title = L.SPELL,
                Default = nil,
                Nilable = true,
                Values = (function()
                    ---@type HealingDone?
                    local healingDone = segment and segment.healingDone
                    local values = {{Title = L.ALL, Value = nil}}

                    if healingDone then
                        ---@type string[]|number[]
                        local spellKeys = {}
                        for key, spellData in next, healingDone.spells, nil do
                            spellKeys[#spellKeys + 1] = key
                        end
                        SortSpellNames(spellKeys)

                        for i = 1, #spellKeys, 1 do
                            local key = spellKeys[i]
                            local spellData = healingDone.spells[key]

                            if spellData then
                                values[#values + 1] = {
                                    Title = GetDamageClassColor(spellData.school):WrapTextInColorCode(
                                        AppendTextToTexture(GetSpellName(key), GetSpellIcon(key))),
                                    Value = key,
                                    Tooltip = HealingDoneMode.onSpellEnter,
                                }
                            end
                        end
                    end

                    return values
                end)(),
            },
            {
                Type = "select",
                Name = "target",
                Title = L.TARGET,
                Default = nil,
                Nilable = true,
                Values = (function()
                    ---@type HealingDone?
                    local healingDone = segment and segment.healingDone
                    local values = {{Title = L.ALL, Value = nil}}

                    if healingDone then
                        ---@type string[]
                        local targetKeys = {}
                        for key, targetData in next, healingDone.targets, nil do
                            targetKeys[#targetKeys + 1] = key
                        end
                        SortUnitNames(targetKeys)

                        for i = 1, #targetKeys, 1 do
                            local key = targetKeys[i]
                            local targetData = healingDone.targets[key]

                            local class = GetPlayerClass(key) or targetData.class
                            values[#values + 1] = {
                                Title = GetClassColor(class):WrapTextInColorCode(GetClassTextureAndName(class,
                                                                                                        GetPlayerName(
                                                                                                            key))),
                                Value = key,
                                Tooltip = HealingDoneMode.onUnitEnter,
                            }
                        end
                    end

                    return values
                end)(),
            },
            {Type = "toggle", Name = "pets", Default = true, Title = L.PETS},
            {Type = "toggle", Name = "overhealing", Default = false, Title = L.OVERHEALING},
            {Type = "toggle", Name = "absorbed", Default = true, Title = L.ABSORBED},
        }
    end

    do -- Title
        ---@type string[]
        local title = {}

        ---@param filter HealingDoneModeFilter
        function HealingDoneMode.Title(filter, segment)
            wipe(title)
            title[#title + 1] = HEALING_DONE_TITLE

            ---@type HealingDone?
            local healingDone = segment and segment.healingDone
            if not healingDone then return title[1] end

            if filter.show ~= "sources" then title[1] = HEALING_DONE_TITLE_MOD end

            local source = filter.source
            local spell = filter.spell
            local target = filter.target

            if source then
                title[1] = HEALING_DONE_TITLE_MOD
                title[#title + 1] = GetUnitTitleLink("healingDone", source, healingDone.sources[source], "source")
            end
            if spell then
                title[1] = HEALING_DONE_TITLE_MOD
                title[#title + 1] = GetSpellTitleLink("healingDone", spell, healingDone.spells[spell])
            end
            if target then
                title[1] = HEALING_DONE_TITLE_MOD
                title[#title + 1] = GetUnitTitleLink("healingDone", target, healingDone.targets[target], "target")
            end

            return tConcat(title, " - ")
        end
    end

    ---@param filter HealingDoneModeFilter
    function HealingDoneMode.Values(filter, segment, values, texts, colors, icons, iconCoords)
        ---@type HealingDone?
        local healingDone = segment.healingDone
        if not healingDone then return 0, false, false end

        local show = filter.show
        local source = filter.source
        local spell = filter.spell
        local target = filter.target

        local maxAmount = 0

        if source then
            local sourceData = healingDone.sources[source]
            if not sourceData then return 0, false, false end

            if spell then
                local spellData = sourceData.spells[spell]
                if not spellData then return 0, false, false end

                if target then
                    local targetData = spellData.targets[target]
                    if not targetData then return 0, false, false end

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
                    if not targetData then return 0, false, false end

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
                    if not targetData then return 0, false, false end

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
                    for key, data in next, healingDone.sources, nil do
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
                    local spellData = healingDone.spells[spell]
                    if not spellData then return 0, false, false end

                    local amount = getAmount(filter, spellData.targets[target])
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "targets" then
                    local spellData = healingDone.spells[spell]
                    if not spellData then return 0, false, false end

                    local targetData = spellData.targets[target]
                    if not targetData then return 0, false, false end

                    local amount = getAmount(filter, targetData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            else
                if show == "sources" then
                    for key, data in next, healingDone.sources, nil do
                        local amount = getAmount(filter, data.spells[spell])
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "spells" then
                    local spellData = healingDone.spells[spell]
                    if not spellData then return 0, false, false end

                    local amount = getAmount(filter, spellData)
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "targets" then
                    local spellData = healingDone.spells[spell]
                    if not spellData then return 0, false, false end

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
            local targetData = healingDone.targets[target]
            if not targetData then return 0, false, false end

            if show == "sources" then
                for key, data in next, healingDone.sources, nil do
                    local amount = getAmount(filter, data.targets[target])
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, healingDone.spells, nil do
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
                for key, data in next, healingDone.sources, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, healingDone.spells, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "targets" then
                for key, data in next, healingDone.targets, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            end
        end

        return maxAmount, true, true
    end

    ---@param filter HealingDoneModeFilter
    function HealingDoneMode.OnClick(filter, key, button)
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

    ---@param filter HealingDoneModeFilter
    function HealingDoneMode.OnHyperlink(filter, link, button)
        local linkData = ExtractLink(link)
        if linkData then
            linkData = ArrayToPairs(linkData)

            if linkData.mode == "healingDone" then
                local source = linkData.source
                local spell = linkData.spell and tonumber(linkData.spell) or linkData.spell
                local target = linkData.target

                if source then
                    if button == "LeftButton" then filter.show = "spells" end
                    filter.source = source
                    filter.spell = nil
                    filter.target = nil
                elseif spell then
                    if button == "LeftButton" then filter.show = "targets" end
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
                        filter.overhealing = false
                        filter.absorbed = true
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

    ---@param filter HealingDoneModeFilter
    function HealingDoneMode.Tooltip(filter, segment, key, tooltip)
        ---@type HealingDone?
        local healingDone = segment.healingDone
        if not healingDone then return end

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

                        local sourceData = healingDone.sources[key]
                        if not sourceData then return end

                        local spellData = sourceData.spells[spell]
                        if not spellData then return end

                        for targetKey, data in next, spellData.targets, nil do
                            tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                        end
                        tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                    elseif show == "spells" then
                        tooltip:SetSpell(key)

                        local sourceData = healingDone.sources[source]
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

                    local sourceData = healingDone.sources[key]
                    if not sourceData then return end

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.targets[target]), data)
                    end
                    tooltip:ShowSpellAmounts(getAmount(filter, sourceData.targets[target]))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local sourceData = healingDone.sources[source]
                    if not sourceData then return end

                    local spellData = sourceData.spells[key]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = healingDone.sources[source]
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

                    local sourceData = healingDone.sources[key]
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

                    local sourceData = healingDone.sources[source]
                    if not sourceData then return end

                    local spellData = sourceData.spells[key]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = healingDone.sources[source]
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

                    for sourceKey, data in next, healingDone.sources, nil do
                        local spellData = data.spells[key]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[target]), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, healingDone.spells[key] and
                                                                    healingDone.spells[key].targets[target]))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for sourceKey, data in next, healingDone.sources, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, healingDone.spells[spell] and
                                                                    healingDone.spells[spell].targets[key]))
                end
            else
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = healingDone.sources[key]
                    if not sourceData then return end

                    local spellData = sourceData.spells[spell]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local spellData = healingDone.spells[key]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData)

                    for sourceKey, data in next, healingDone.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data.spells[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, amount)

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, amount)
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for sourceKey, data in next, healingDone.sources, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, healingDone.spells[spell] and
                                                                    healingDone.spells[spell].targets[key]))
                end
            end
        elseif target then
            if show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = healingDone.sources[key]
                if not sourceData then return end

                for spellKey, data in next, sourceData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[target]), data)
                end
                tooltip:ShowSpellAmounts(getAmount(filter, sourceData.targets[target]))
            elseif show == "spells" then
                tooltip:SetSpell(key)

                for sourceKey, data in next, healingDone.sources, nil do
                    local spellData = data.spells[key]
                    tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[target]), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, healingDone.spells[key] and
                                                                healingDone.spells[key].targets[target]))
            elseif show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = healingDone.targets[key]
                if not targetData then return end

                local amount = getAmount(filter, targetData)

                for sourceKey, data in next, healingDone.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, amount)

                for spellKey, data in next, healingDone.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ShowSpellAmounts(amount)
            end
        else
            if show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = healingDone.sources[key]
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

                local spellData = healingDone.spells[key]
                if not spellData then return end

                local amount = getAmount(filter, spellData)

                for sourceKey, data in next, healingDone.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.spells[key]), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, amount)

                for targetKey, data in next, spellData.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                end
                tooltip:ShowUnitAmounts(L.TARGET, amount)

            elseif show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = healingDone.targets[key]
                if not targetData then return end

                local amount = getAmount(filter, targetData)

                for sourceKey, data in next, healingDone.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, amount)

                for spellKey, data in next, healingDone.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ShowSpellAmounts(amount)
            end
        end
    end
end

local HealingTakenMode = AddOn.RegisterMode("healingTaken", L.HEALING_TAKEN)
if HealingTakenMode then
    ---@class HealingTakenModeFilter
    ---@field show "targets"|"spells"|"sources"
    ---@field spell SpellID?
    ---@field target string?
    ---@field source string?
    ---@field overhealing boolean
    ---@field absorbed boolean

    function HealingTakenMode.Filter(segment)
        return {
            {
                Type = "select",
                Name = "show",
                Values = {
                    {Value = "targets", Title = L.TARGETS},
                    {Value = "spells", Title = L.SPELLS},
                    {Value = "sources", Title = L.SOURCES},
                },
                Default = "targets",
            },
            {
                Type = "select",
                Name = "target",
                Title = L.TARGET,
                Default = nil,
                Nilable = true,
                Values = (function()
                    ---@type HealingTaken?
                    local healingTaken = segment and segment.healingTaken
                    local values = {{Title = L.ALL, Value = nil}}

                    if healingTaken then
                        ---@type string[]
                        local targetKeys = {}
                        for key, targetData in next, healingTaken.targets, nil do
                            targetKeys[#targetKeys + 1] = key
                        end
                        SortUnitNames(targetKeys)

                        for i = 1, #targetKeys, 1 do
                            local key = targetKeys[i]
                            local targetData = healingTaken.targets[key]

                            local class = GetPlayerClass(key) or targetData.class
                            values[#values + 1] = {
                                Title = GetClassColor(class):WrapTextInColorCode(GetClassTextureAndName(class,
                                                                                                        GetPlayerName(
                                                                                                            key))),
                                Value = key,
                                Tooltip = HealingTakenMode.onUnitEnter,
                            }
                        end
                    end

                    return values
                end)(),
            },
            {
                Type = "select",
                Name = "spell",
                Title = L.SPELL,
                Default = nil,
                Nilable = true,
                Values = (function()
                    ---@type HealingTaken?
                    local healingTaken = segment and segment.healingTaken
                    local values = {{Title = L.ALL, Value = nil}}

                    if healingTaken then
                        ---@type string[]|number[]
                        local spellKeys = {}
                        for key, spellData in next, healingTaken.spells, nil do
                            spellKeys[#spellKeys + 1] = key
                        end
                        SortSpellNames(spellKeys)

                        for i = 1, #spellKeys, 1 do
                            local key = spellKeys[i]
                            local spellData = healingTaken.spells[key]

                            if spellData then
                                values[#values + 1] = {
                                    Title = GetDamageClassColor(spellData.school):WrapTextInColorCode(
                                        AppendTextToTexture(GetSpellName(key), GetSpellIcon(key))),
                                    Value = key,
                                    Tooltip = HealingTakenMode.onSpellEnter,
                                }
                            end
                        end
                    end

                    return values
                end)(),
            },
            {
                Type = "select",
                Name = "source",
                Title = L.SOURCE,
                Default = nil,
                Nilable = true,
                Values = (function()
                    ---@type HealingTaken?
                    local healingTaken = segment and segment.healingTaken
                    local values = {{Title = L.ALL, Value = nil}}

                    if healingTaken then
                        ---@type string[]
                        local sourceKeys = {}
                        for key, sourceData in next, healingTaken.sources, nil do
                            sourceKeys[#sourceKeys + 1] = key
                        end
                        SortUnitNames(sourceKeys)

                        for i = 1, #sourceKeys, 1 do
                            local key = sourceKeys[i]
                            local sourceData = healingTaken.sources[key]

                            local class = GetPlayerClass(key) or sourceData.class
                            values[#values + 1] = {
                                Title = GetClassColor(class):WrapTextInColorCode(GetClassTextureAndName(class,
                                                                                                        GetPlayerName(
                                                                                                            key))),
                                Value = key,
                                Tooltip = HealingTakenMode.onUnitEnter,
                            }
                        end
                    end

                    return values
                end)(),
            },
            {Type = "toggle", Name = "overhealing", Default = false, Title = L.OVERHEALING},
            {Type = "toggle", Name = "absorbed", Default = false, Title = L.ABSORBED},
        }
    end

    do -- Title
        ---@type string[]
        local title = {}

        ---@param filter HealingTakenModeFilter
        function HealingTakenMode.Title(filter, segment)
            wipe(title)
            title[#title + 1] = HEALING_TAKEN_TITLE

            ---@type HealingTaken?
            local healingTaken = segment and segment.healingTaken
            if not healingTaken then return title[1] end

            if filter.show ~= "targets" then title[1] = HEALING_TAKEN_TITLE_MOD end

            local spell = filter.spell
            local target = filter.target
            local source = filter.source

            if target then
                title[1] = HEALING_TAKEN_TITLE_MOD
                title[#title + 1] = GetUnitTitleLink("healingTaken", target, healingTaken.targets[target], "target")
            end
            if spell then
                title[1] = HEALING_TAKEN_TITLE_MOD
                title[#title + 1] = GetSpellTitleLink("healingTaken", spell, healingTaken.spells[spell])
            end
            if source then
                title[1] = HEALING_TAKEN_TITLE_MOD
                title[#title + 1] = GetUnitTitleLink("healingTaken", source, healingTaken.sources[source], "source")
            end

            return tConcat(title, " - ")
        end
    end

    ---@param filter HealingTakenModeFilter
    function HealingTakenMode.Values(filter, segment, values, texts, colors, icons, iconCoords)
        ---@type HealingTaken?
        local healingTaken = segment.healingTaken
        if not healingTaken then return 0, false, false end

        local show = filter.show
        local target = filter.target
        local spell = filter.spell
        local source = filter.source

        local maxAmount = 0

        if target then
            local targetData = healingTaken.targets[target]
            if not targetData then return 0, false, false end

            if spell then
                local spellData = targetData.spells[spell]
                if not spellData then return 0, false, false end

                if source then
                    local sourceData = spellData.sources[source]
                    if not sourceData then return 0, false, false end

                    local amount = getAmount(filter, sourceData)
                    if amount > 0 then
                        maxAmount = amount

                        if show == "targets" then
                            FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                        elseif show == "spells" then
                            FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                        elseif show == "sources" then
                            FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                else
                    if show == "targets" then
                        local amount = getAmount(filter, spellData)
                        if amount > 0 then
                            maxAmount = amount

                            FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                        end
                    elseif show == "spells" then
                        local amount = getAmount(filter, spellData)
                        if amount > 0 then
                            maxAmount = amount

                            FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                        end
                    elseif show == "sources" then
                        for key, data in next, spellData.sources, nil do
                            local amount = getAmount(filter, data)
                            if amount > 0 then
                                maxAmount = max(maxAmount, amount)

                                FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                            end
                        end
                    end
                end
            elseif source then
                if show == "targets" then
                    local sourceData = targetData.sources[source]
                    if not sourceData then return 0, false, false end

                    local amount = getAmount(filter, sourceData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "spells" then
                    for key, data in next, targetData.spells, nil do
                        local amount = getAmount(filter, data.sources[source])
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "sources" then
                    local sourceData = targetData.sources[source]
                    if not sourceData then return 0, false, false end

                    local amount = getAmount(filter, sourceData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            else
                if show == "targets" then
                    local amount = getAmount(filter, targetData)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "spells" then
                    for key, data in next, targetData.spells, nil do
                        local amount = getAmount(filter, data)
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "sources" then
                    for key, data in next, targetData.sources, nil do
                        local amount = getAmount(filter, data)
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                end
            end
        elseif spell then
            if source then
                if show == "targets" then
                    for key, data in next, healingTaken.targets, nil do
                        local spellData = data.spells[spell]
                        if spellData then
                            local sourceData = spellData.sources[source]
                            if sourceData then
                                local amount = getAmount(filter, sourceData)
                                if amount > 0 then
                                    maxAmount = max(maxAmount, amount)

                                    FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                                end
                            end
                        end
                    end
                elseif show == "spells" then
                    local spellData = healingTaken.spells[spell]
                    if not spellData then return 0, false, false end

                    local amount = getAmount(filter, spellData.sources[source])
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "sources" then
                    local spellData = healingTaken.spells[spell]
                    if not spellData then return 0, false, false end

                    local sourceData = spellData.sources[source]
                    if not sourceData then return 0, false, false end

                    local amount = getAmount(filter, sourceData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            else
                if show == "targets" then
                    for key, data in next, healingTaken.targets, nil do
                        local amount = getAmount(filter, data.spells[spell])
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "spells" then
                    local spellData = healingTaken.spells[spell]
                    if not spellData then return 0, false, false end

                    local amount = getAmount(filter, spellData)
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "sources" then
                    local spellData = healingTaken.spells[spell]
                    if not spellData then return 0, false, false end

                    for key, data in next, spellData.sources, nil do
                        local amount = getAmount(filter, data)
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                end
            end
        elseif source then
            local sourceData = healingTaken.sources[source]
            if not sourceData then return 0, false, false end

            if show == "targets" then
                for key, data in next, healingTaken.targets, nil do
                    local amount = getAmount(filter, data.sources[source])
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, healingTaken.spells, nil do
                    local amount = getAmount(filter, data.sources[source])
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "sources" then
                local amount = getAmount(filter, sourceData)
                if amount > 0 then
                    maxAmount = amount

                    FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                end
            end
        else
            if show == "targets" then
                for key, data in next, healingTaken.targets, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, healingTaken.spells, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "sources" then
                for key, data in next, healingTaken.sources, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            end
        end

        return maxAmount, true, true
    end

    ---@param filter HealingTakenModeFilter
    function HealingTakenMode.OnClick(filter, key, button)
        local show = filter.show
        local target = filter.target
        local spell = filter.spell
        local source = filter.source

        if target then
            if spell then
                if source then
                    if show == "targets" then
                        if button == "LeftButton" then
                            filter.show = "targets"
                            filter.spell = nil
                            filter.source = nil
                        end
                    elseif show == "spells" then
                        if button == "LeftButton" then
                            filter.show = "sources"
                            filter.spell = nil
                            filter.source = nil
                        end
                    elseif show == "sources" then
                        if button == "LeftButton" then
                            filter.show = "targets"
                            filter.spell = nil
                            filter.source = nil
                        end
                    end
                else
                    if show == "targets" then
                        if button == "LeftButton" then
                            filter.show = "spells"
                            filter.spell = nil
                            filter.source = nil
                        end
                    elseif show == "spells" then
                        if button == "LeftButton" then
                            filter.show = "sources"
                            filter.spell = nil
                            filter.source = nil
                        end
                    elseif show == "sources" then
                        if button == "LeftButton" then
                            filter.show = "targets"
                            filter.target = nil
                            filter.spell = nil
                            filter.source = key
                        elseif button == "RightButton" then
                            filter.show = "spells"
                            filter.spell = nil
                        end
                    end
                end
            elseif source then
                if show == "targets" then
                    if button == "LeftButton" then
                        filter.show = "spells"
                        filter.spell = nil
                        filter.source = nil
                    end
                elseif show == "spells" then
                    if button == "LeftButton" then
                        filter.show = "sources"
                        filter.target = nil
                        filter.spell = key
                    elseif button == "RightButton" then
                        filter.show = "targets"
                        filter.target = nil
                    end
                elseif show == "sources" then
                    if button == "LeftButton" then
                        filter.show = "sources"
                        filter.spell = nil
                        filter.source = nil
                    end
                end
            else
                if show == "targets" then
                    --
                elseif show == "spells" then
                    if button == "LeftButton" then
                        filter.show = "sources"
                        filter.spell = key
                    elseif button == "RightButton" then
                        filter.show = "targets"
                        filter.target = nil
                    end
                elseif show == "sources" then
                    if button == "LeftButton" then
                        filter.show = "targets"
                        filter.target = nil
                        filter.spell = nil
                        filter.source = key
                    end
                end
            end
        elseif spell then
            if source then
                if show == "targets" then
                    if button == "LeftButton" then
                        filter.show = "spells"
                        filter.target = key
                        filter.spell = nil
                        filter.source = nil
                    end
                elseif show == "spells" then
                    if button == "LeftButton" then
                        filter.show = "targets"
                        filter.source = nil
                    end
                elseif show == "sources" then
                    if button == "LeftButton" then filter.show = "targets" end
                end
            else
                if show == "targets" then
                    if button == "LeftButton" then
                        filter.show = "sources"
                        filter.target = key
                    end
                elseif show == "spells" then
                    --
                elseif show == "sources" then
                    if button == "LeftButton" then
                        filter.show = "targets"
                        filter.source = key
                    end
                end
            end
        elseif source then
            if show == "targets" then
                if button == "LeftButton" then
                    filter.show = "spells"
                    filter.target = key
                    filter.spell = nil
                end
            elseif show == "spells" then
                if button == "LeftButton" then
                    filter.show = "targets"
                    filter.spell = key
                end
            elseif show == "source" then
                --
            end
        else
            if show == "targets" then
                if button == "LeftButton" then
                    filter.show = "spells"
                    filter.target = key
                end
            elseif show == "spells" then
                if button == "LeftButton" then
                    filter.show = "sources"
                    filter.spell = key
                end
            elseif show == "sources" then
                if button == "LeftButton" then
                    filter.show = "targets"
                    filter.source = key
                end
            end
        end
    end

    ---@param filter HealingTakenModeFilter
    function HealingTakenMode.OnHyperlink(filter, link, button)
        local linkData = ExtractLink(link)
        if linkData then
            linkData = ArrayToPairs(linkData)

            if linkData.mode == "healingTaken" then
                local target = linkData.target
                local spell = linkData.spell and tonumber(linkData.spell) or linkData.spell
                local source = linkData.source
                if target then
                    if button == "LeftButton" then filter.show = "spells" end
                    filter.target = target
                    filter.source = nil
                    filter.spell = nil
                elseif spell then
                    if button == "LeftButton" then filter.show = "sources" end
                    filter.target = nil
                    filter.spell = spell
                    filter.source = nil
                elseif source then
                    if button == "LeftButton" then filter.show = "targets" end
                    filter.target = nil
                    filter.spell = nil
                    filter.source = source
                else
                    if button == "LeftButton" then
                        filter.show = "targets"
                        filter.overhealing = false
                        filter.absorbed = false
                    elseif button == "RightButton" then
                        filter.show = "targets"
                    end
                    filter.target = nil
                    filter.spell = nil
                    filter.source = nil
                end
            end
        end
    end

    ---@param filter HealingTakenModeFilter
    function HealingTakenMode.Tooltip(filter, segment, key, tooltip)
        ---@type HealingTaken?
        local healingTaken = segment.healingTaken
        if not healingTaken then return end

        local show = filter.show
        local target = filter.target
        local spell = filter.spell
        local source = filter.source

        if target then
            if spell then
                if source then
                    if show == "targets" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                    elseif show == "spells" then
                        tooltip:SetSpell(key)
                    elseif show == "sources" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                    end
                else
                    if show == "targets" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                        local targetData = healingTaken.targets[key]
                        if not targetData then return end

                        local spellData = targetData.spells[spell]
                        if not spellData then return end

                        for sourceKey, data in next, spellData.sources, nil do
                            tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                        end
                        tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                    elseif show == "spells" then
                        tooltip:SetSpell(key)

                        local targetData = healingTaken.targets[target]
                        if not targetData then return end

                        local spellData = targetData.spells[key]
                        if not spellData then return end

                        for sourceKey, data in next, spellData.sources, nil do
                            tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                        end
                        tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                    elseif show == "sources" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                    end
                end
            elseif source then
                if show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = healingTaken.targets[key]
                    if not targetData then return end

                    for spellKey, data in next, targetData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.sources[source]), data)
                    end
                    tooltip:ShowSpellAmounts(getAmount(filter, targetData.sources[source]))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local targetData = healingTaken.targets[target]
                    if not targetData then return end

                    local spellData = targetData.spells[key]
                    if not spellData then return end

                    for sourceKey, data in next, spellData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                elseif show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = healingTaken.targets[target]
                    if not targetData then return end

                    local sourceData = targetData.sources[key]
                    if not sourceData then return end

                    for spellKey, data in next, targetData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.sources[key]), data)
                    end
                    tooltip:ShowSpellAmounts(getAmount(filter, sourceData))
                end
            else
                if show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = healingTaken.targets[key]
                    if not targetData then return end

                    local amount = getAmount(filter, targetData)

                    for spellKey, data in next, targetData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowSpellAmounts(amount)

                    for sourceKey, data in next, targetData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, amount)
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local targetData = healingTaken.targets[target]
                    if not targetData then return end

                    local spellData = targetData.spells[key]
                    if not spellData then return end

                    for sourceKey, data in next, spellData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                elseif show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = healingTaken.targets[target]
                    if not targetData then return end

                    for spellKey, data in next, targetData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.sources[key]), data)
                    end
                    tooltip:ShowSpellAmounts(getAmount(filter, targetData.sources[key]))
                end
            end
        elseif spell then
            if source then
                if show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    for targetKey, data in next, healingTaken.targets, nil do
                        local spellData = data.spells[key]
                        tooltip:AddAmount(targetKey, getAmount(filter, spellData and spellData.sources[source]), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, healingTaken.spells[key] and
                                                                    healingTaken.spells[key].sources[source]))
                elseif show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for targetKey, data in next, healingTaken.targets, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(targetKey, getAmount(filter, spellData and spellData.sources[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, healingTaken.spells[spell] and
                                                                    healingTaken.spells[spell].sources[key]))
                end
            else
                if show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = healingTaken.targets[key]
                    if not targetData then return end

                    local spellData = targetData.spells[spell]
                    if not spellData then return end

                    for sourceKey, data in next, spellData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local spellData = healingTaken.spells[key]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData)

                    for targetKey, data in next, healingTaken.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data.spells[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, amount)

                    for sourceKey, data in next, spellData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ShowUnitAmounts(L.SOURCE, amount)
                elseif show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for targetKey, data in next, healingTaken.targets, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(targetKey, getAmount(filter, spellData and spellData.sources[key]), data)
                    end
                    tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, healingTaken.spells[spell] and
                                                                    healingTaken.spells[spell].sources[key]))
                end
            end
        elseif source then
            if show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = healingTaken.targets[key]
                if not targetData then return end

                for spellKey, data in next, targetData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.sources[source]), data)
                end
                tooltip:ShowSpellAmounts(getAmount(filter, targetData.sources[source]))
            elseif show == "spells" then
                tooltip:SetSpell(key)

                for targetKey, data in next, healingTaken.targets, nil do
                    local spellData = data.spells[key]
                    tooltip:AddAmount(targetKey, getAmount(filter, spellData and spellData.sources[source]), data)
                end
                tooltip:ShowUnitAmounts(L.TARGET, getAmount(filter, healingTaken.spells[key] and
                                                                healingTaken.spells[key].sources[source]))
            elseif show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = healingTaken.sources[key]
                if not sourceData then return end

                local amount = getAmount(filter, sourceData)

                for targetKey, data in next, healingTaken.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data.sources[key]), data)
                end
                tooltip:ShowUnitAmounts(L.TARGET, amount)

                for spellKey, data in next, healingTaken.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.sources[key]), data)
                end
                tooltip:ShowSpellAmounts(amount)
            end
        else
            if show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = healingTaken.targets[key]
                if not targetData then return end

                local amount = getAmount(filter, targetData)

                for spellKey, data in next, targetData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data), data)
                end
                tooltip:ShowSpellAmounts(amount)

                for sourceKey, data in next, targetData.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, amount)
            elseif show == "spells" then
                tooltip:SetSpell(key)

                local spellData = healingTaken.spells[key]
                if not spellData then return end

                local amount = getAmount(filter, spellData)

                for targetKey, data in next, healingTaken.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data.spells[key]), data)
                end
                tooltip:ShowUnitAmounts(L.TARGET, amount)

                for sourceKey, data in next, spellData.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                end
                tooltip:ShowUnitAmounts(L.SOURCE, amount)

            elseif show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = healingTaken.sources[key]
                if not sourceData then return end

                local amount = getAmount(filter, sourceData)

                for targetKey, data in next, healingTaken.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data.sources[key]), data)
                end
                tooltip:ShowUnitAmounts(L.TARGET, amount)

                for spellKey, data in next, healingTaken.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.sources[key]), data)
                end
                tooltip:ShowSpellAmounts(amount)
            end
        end
    end
end
