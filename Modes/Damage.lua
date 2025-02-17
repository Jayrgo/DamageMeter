---@class AddOn
local AddOn = (select(2, ...))

do -- CheckCombatHandlers
    local ATTACK_SPELL = AddOn.ATTACK_SPELL
    local COMBAT_LOG_FILTER_GROUP = AddOn.COMBAT_LOG_FILTER_GROUP
    local MASK_PHYSICAL = AddOn.MASK_PHYSICAL

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
    ---@param amount number
    ---@param overkill? number
    ---@param resisted? number
    ---@param blocked? number
    ---@param absorbed? number
    ---@param critical boolean
    ---@param glancing boolean
    ---@param crushing boolean
    ---@return boolean?
    local function onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                            destName, destFlags, destRaidFlags, spellId, spellSchool, amount, overkill, resisted,
                            blocked, absorbed, critical, glancing, crushing)
        if (sourceFlags and CombatLog_Object_IsA(sourceFlags, COMBAT_LOG_FILTER_GROUP)) or
            (destFlags and CombatLog_Object_IsA(destFlags, COMBAT_LOG_FILTER_GROUP)) then return true end
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
    ---@param amount number
    ---@param overkill number
    ---@param school number
    ---@param resisted number
    ---@param blocked number
    ---@param absorbed number
    ---@param critical boolean
    ---@param glancing boolean
    ---@param crushing boolean
    ---@param isOffHand boolean
    ---@return boolean?
    function AddOn.CheckCombatHandlers.SWING_DAMAGE(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                    sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
                                                    amount, overkill, school, resisted, blocked, absorbed, critical,
                                                    glancing, crushing, isOffHand)
        return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName,
                        destFlags, destRaidFlags, ATTACK_SPELL, school, amount, overkill, resisted, blocked, absorbed,
                        critical, glancing, crushing)
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
    ---@param spellId number
    ---@param spellName string
    ---@param spellSchool number
    ---@param amount number
    ---@param overkill number
    ---@param school number
    ---@param resisted number
    ---@param blocked number
    ---@param absorbed number
    ---@param critical boolean
    ---@param glancing boolean
    ---@param crushing boolean
    ---@param isOffHand boolean
    ---@return boolean?
    function AddOn.CheckCombatHandlers.SPELL_DAMAGE(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                    sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
                                                    spellId, spellName, spellSchool, amount, overkill, school, resisted,
                                                    blocked, absorbed, critical, glancing, crushing, isOffHand)
        return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName,
                        destFlags, destRaidFlags, spellId, spellSchool, amount, overkill, resisted, blocked, absorbed,
                        critical, glancing, crushing)
    end

    AddOn.CheckCombatHandlers.SPELL_PERIODIC_DAMAGE = AddOn.CheckCombatHandlers.SPELL_DAMAGE
    AddOn.CheckCombatHandlers.SPELL_BUILDING_DAMAGE = AddOn.CheckCombatHandlers.SPELL_DAMAGE
    AddOn.CheckCombatHandlers.DAMAGE_SHIELD = AddOn.CheckCombatHandlers.SPELL_DAMAGE
    AddOn.CheckCombatHandlers.DAMAGE_SPLIT = AddOn.CheckCombatHandlers.SPELL_DAMAGE
    AddOn.CheckCombatHandlers.RANGE_DAMAGE = AddOn.CheckCombatHandlers.SPELL_DAMAGE

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
    ---@param environmentalType number
    ---@param amount number
    ---@param overkill number
    ---@param school number
    ---@param resisted number
    ---@param blocked number
    ---@param absorbed number
    ---@param critical boolean
    ---@param glancing boolean
    ---@param crushing boolean
    ---@return boolean?
    function AddOn.CheckCombatHandlers.ENVIRONMENTAL_DAMAGE(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                            sourceRaidFlags, destGUID, destName, destFlags,
                                                            destRaidFlags, environmentalType, amount, overkill, school,
                                                            resisted, blocked, absorbed, critical, glancing, crushing)
        return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName,
                        destFlags, destRaidFlags, environmentalType, school, amount, overkill, resisted, blocked,
                        absorbed, critical, glancing, crushing)
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
    ---@param missType string
    ---@param isOffHand boolean
    ---@param amountMissed number
    ---@param critical boolean
    ---@return boolean?
    function AddOn.CheckCombatHandlers.SWING_MISSED(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                    sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
                                                    missType, isOffHand, amountMissed, critical)
        if missType == "ABSORB" then
            return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                            destName, destFlags, destRaidFlags, ATTACK_SPELL, MASK_PHYSICAL, amountMissed, 0, 0, 0,
                            amountMissed, critical, false, false)
        elseif missType == "BLOCK" then
            return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                            destName, destFlags, destRaidFlags, ATTACK_SPELL, MASK_PHYSICAL, amountMissed, 0, 0,
                            amountMissed, 0, critical, false, false)
        elseif missType == "RESIST" then
            return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                            destName, destFlags, destRaidFlags, ATTACK_SPELL, MASK_PHYSICAL, amountMissed, 0,
                            amountMissed, 0, 0, critical, false, false)
        end
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
    ---@param spellId number
    ---@param spellName string
    ---@param spellSchool number
    ---@param missType string
    ---@param isOffHand boolean
    ---@param amountMissed number
    ---@param critical boolean
    ---@return boolean?
    function AddOn.CheckCombatHandlers.SPELL_MISSED(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                    sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
                                                    spellId, spellName, spellSchool, missType, isOffHand, amountMissed,
                                                    critical)
        if missType == "ABSORD" then
            return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                            destName, destFlags, destRaidFlags, spellId, spellSchool, amountMissed, 0, 0, 0,
                            amountMissed, critical, false, false)
        elseif missType == "BLOCK" then
            return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                            destName, destFlags, destRaidFlags, spellId, spellSchool, amountMissed, 0, 0, amountMissed,
                            0, critical, false, false)
        elseif missType == "RESIST" then
            return onDamage(timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                            destName, destFlags, destRaidFlags, spellId, spellSchool, amountMissed, 0, amountMissed, 0,
                            0, critical, false, false)
        end
    end

    AddOn.CheckCombatHandlers.RANGE_MISSED = AddOn.CheckCombatHandlers.SPELL_MISSED
    AddOn.CheckCombatHandlers.SPELL_PERIODIC_MISSED = AddOn.CheckCombatHandlers.SPELL_MISSED
    AddOn.CheckCombatHandlers.SPELL_BUILDING_MISSED = AddOn.CheckCombatHandlers.SPELL_MISSED
    AddOn.CheckCombatHandlers.DAMAGE_SHIELD_MISSED = AddOn.CheckCombatHandlers.SPELL_MISSED
end

do -- CombatLogHandlers
    local ATTACK_SPELL = AddOn.ATTACK_SPELL
    local COMBAT_LOG_FILTER_GROUP = AddOn.COMBAT_LOG_FILTER_GROUP
    local COMBAT_LOG_FILTER_GROUP_NO_PET = AddOn.COMBAT_LOG_FILTER_GROUP_NO_PET
    local MASK_PHYSICAL = AddOn.MASK_PHYSICAL

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
    ---@param overkill? number
    ---@param resisted? number
    ---@param blocked? number
    ---@param absorbed? number
    ---@param critical boolean
    ---@param glancing boolean
    ---@param crushing boolean
    local function onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
                            destGUID, destName, destFlags, destRaidFlags, spellId, spellSchool, amount, overkill,
                            resisted, blocked, absorbed, critical, glancing, crushing)
        if sourceFlags and CombatLog_Object_IsA(sourceFlags, COMBAT_LOG_FILTER_GROUP) then
            ---@type DamageDone?
            local damageDone = segment.damageDone
            if not damageDone then
                ---@class DamageDoneData
                ---@field amount? number
                ---@field overkill? number
                ---@field resisted? number
                ---@field blocked? number
                ---@field absorbed? number
                ---@field numHits? number
                ---@field minHit? number
                ---@field maxHit? number
                ---@field numCrits? number
                ---@field petAmount? number
                ---@field petOverkill? number
                ---@field petResisted? number
                ---@field petBlocked? number
                ---@field petAbsorbed? number
                ---@field groupAmount? number
                ---@field groupOverkill? number
                ---@field groupResisted? number
                ---@field groupBlocked? number
                ---@field groupAbsorbed? number
                ---@field groupNumHits? number
                ---@field groupMinHit? number
                ---@field groupMaxHit? number
                ---@field groupNumCrits? number
                ---@field petGroupAmount? number
                ---@field petGroupOverkill? number
                ---@field petGroupResisted? number
                ---@field petGroupBlocked? number
                ---@field petGroupAbsorbed? number
                ---@field petGroupNumHits? number
                ---@field petGroupMinHit? number
                ---@field petGroupMaxHit? number
                ---@field petGroupNumCrits? number

                ---@class DamageDoneTarget : DamageDoneData, UnitTable

                ---@class DamageDoneSpell : DamageDoneData, SpellTable
                ---@field targets table<string, DamageDoneTarget>

                ---@class DamageDoneSource : DamageDoneData, UnitTable
                ---@field spells table<SpellID, DamageDoneSpell>
                ---@field targets table<string, DamageDoneTarget>

                ---@class DamageDone : DamageDoneData
                damageDone = {
                    ---@type table<string, DamageDoneSource>
                    sources = {},
                    ---@type table<SpellID, DamageDoneSpell>
                    spells = {},
                    ---@type table<string, DamageDoneTarget>
                    targets = {},
                }
                segment.damageDone = damageDone
            end

            local source, spell, target, sourceSpell, sourceTarget, spellTarget, sourceSpellTarget, isNew, isPet
            ---@type DamageDoneSource
            source, --
            isNew, isPet = GetSource(damageDone.sources, sourceGUID, sourceName, sourceFlags)
            if isNew then
                source.spells = {}
                source.targets = {}
            end

            ---@type DamageDoneSpell
            spell, --
            isNew = GetSpell(damageDone.spells, spellId, spellSchool)
            if isNew then spell.targets = {} end

            ---@type DamageDoneTarget
            target, --
            isNew = GetTarget(damageDone.targets, destGUID, destName, destFlags)

            ---@type DamageDoneSpell
            sourceSpell, --
            isNew = GetSpell(source.spells, spellId, spellSchool)
            if isNew then sourceSpell.targets = {} end

            ---@type DamageDoneTarget
            sourceTarget, --
            isNew = GetTarget(source.targets, destGUID, destName, destFlags)

            ---@type DamageDoneTarget
            spellTarget, --
            isNew = GetTarget(spell.targets, destGUID, destName, destFlags)

            ---@type DamageDoneTarget
            sourceSpellTarget, --
            isNew = GetTarget(sourceSpell.targets, destGUID, destName, destFlags)

            if destFlags and CombatLog_Object_IsA(destFlags, COMBAT_LOG_FILTER_GROUP) then
                if isPet then
                    tAddMulti("petGroupAmount", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)

                    if overkill and overkill > 0 then
                        tAddMulti("petGroupOverkill", overkill, damageDone, source, spell, target, sourceSpell,
                                  sourceTarget, spellTarget, sourceSpellTarget)
                    end
                    if resisted and resisted > 0 then
                        tAddMulti("petGroupResisted", resisted, damageDone, source, spell, target, sourceSpell,
                                  sourceTarget, spellTarget, sourceSpellTarget)
                    end
                    if blocked and blocked > 0 then
                        tAddMulti("petGroupBlocked", blocked, damageDone, source, spell, target, sourceSpell,
                                  sourceTarget, spellTarget, sourceSpellTarget)
                    end
                    if absorbed and absorbed > 0 then
                        tAddMulti("petGroupAbsorbed", absorbed, damageDone, source, spell, target, sourceSpell,
                                  sourceTarget, spellTarget, sourceSpellTarget)
                    end

                    tAddMulti("petGroupNumHits", 1, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)

                    tSetMinMulti("petGroupMinHit", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                                 spellTarget, sourceSpellTarget)

                    tSetMaxMulti("petGroupMaxHit", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                                 spellTarget, sourceSpellTarget)

                    if critical then
                        tAddMulti("petGroupNumCrits", 1, damageDone, source, spell, target, sourceSpell, sourceTarget,
                                  spellTarget, sourceSpellTarget)
                    end
                else
                    tAddMulti("groupAmount", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)

                    if overkill and overkill > 0 then
                        tAddMulti("groupOverkill", overkill, damageDone, source, spell, target, sourceSpell,
                                  sourceTarget, spellTarget, sourceSpellTarget)
                    end
                    if resisted and resisted > 0 then
                        tAddMulti("groupResisted", resisted, damageDone, source, spell, target, sourceSpell,
                                  sourceTarget, spellTarget, sourceSpellTarget)
                    end
                    if blocked and blocked > 0 then
                        tAddMulti("groupBlocked", blocked, damageDone, source, spell, target, sourceSpell, sourceTarget,
                                  spellTarget, sourceSpellTarget)
                    end
                    if absorbed and absorbed > 0 then
                        tAddMulti("groupAbsorbed", absorbed, damageDone, source, spell, target, sourceSpell,
                                  sourceTarget, spellTarget, sourceSpellTarget)
                    end

                    tAddMulti("groupNumHits", 1, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)

                    tSetMinMulti("groupMinHit", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                                 spellTarget, sourceSpellTarget)

                    tSetMaxMulti("groupMaxHit", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                                 spellTarget, sourceSpellTarget)

                    if critical then
                        tAddMulti("groupNumCrits", 1, damageDone, source, spell, target, sourceSpell, sourceTarget,
                                  spellTarget, sourceSpellTarget)
                    end
                end
            elseif isPet then
                tAddMulti("petAmount", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                          spellTarget, sourceSpellTarget)

                if overkill and overkill > 0 then
                    tAddMulti("petOverkill", overkill, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
                if resisted and resisted > 0 then
                    tAddMulti("petResisted", resisted, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
                if blocked and blocked > 0 then
                    tAddMulti("petBlocked", blocked, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
                if absorbed and absorbed > 0 then
                    tAddMulti("petAbsorbed", absorbed, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end

                tAddMulti("petNumHits", 1, damageDone, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                          sourceSpellTarget)

                tSetMinMulti("petMinHit", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                             spellTarget, sourceSpellTarget)

                tSetMaxMulti("petMaxHit", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                             spellTarget, sourceSpellTarget)

                if critical then
                    tAddMulti("petNumCrits", 1, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
            else
                tAddMulti("amount", amount, damageDone, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                          sourceSpellTarget)

                if overkill and overkill > 0 then
                    tAddMulti("overkill", overkill, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
                if resisted and resisted > 0 then
                    tAddMulti("resisted", resisted, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
                if blocked and blocked > 0 then
                    tAddMulti("blocked", blocked, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end
                if absorbed and absorbed > 0 then
                    tAddMulti("absorbed", absorbed, damageDone, source, spell, target, sourceSpell, sourceTarget,
                              spellTarget, sourceSpellTarget)
                end

                tAddMulti("numHits", 1, damageDone, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                          sourceSpellTarget)

                tSetMinMulti("minHit", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                             spellTarget, sourceSpellTarget)

                tSetMaxMulti("maxHit", amount, damageDone, source, spell, target, sourceSpell, sourceTarget,
                             spellTarget, sourceSpellTarget)

                if critical then
                    tAddMulti("numCrits", 1, damageDone, source, spell, target, sourceSpell, sourceTarget, spellTarget,
                              sourceSpellTarget)
                end
            end
        end
        if destFlags and CombatLog_Object_IsA(destFlags, COMBAT_LOG_FILTER_GROUP_NO_PET) then
            ---@type DamageTaken?
            local damageTaken = segment.damageTaken
            if not damageTaken then
                ---@class DamageTakenData
                ---@field amount? number
                ---@field overkill? number
                ---@field resisted? number
                ---@field blocked? number
                ---@field absorbed? number
                ---@field numHits? number
                ---@field minHit? number
                ---@field maxHit? number
                ---@field numCrits? number
                ---@field groupAmount? number
                ---@field groupOverkill? number
                ---@field groupResisted? number
                ---@field groupBlocked? number
                ---@field groupAbsorbed? number
                ---@field groupNumHits? number
                ---@field groupMinHit? number
                ---@field groupMaxHit? number
                ---@field groupNumCrits? number

                ---@class DamageTakenSource : DamageTakenData, UnitTable

                ---@class DamageTakenSpell : DamageTakenData, SpellTable
                ---@field sources table<string, DamageTakenSource>

                ---@class DamageTakenTarget : DamageTakenData, UnitTable
                ---@field spells table<string|number, DamageTakenSpell>
                ---@field sources table<string, DamageTakenSource>

                ---@class DamageTaken : DamageTakenData
                damageTaken = {
                    ---@type table<string, DamageTakenTarget>
                    targets = {},
                    ---@type table<string|number, DamageTakenSpell>
                    spells = {},
                    ---@type table<string, DamageTakenSource>
                    sources = {},
                }
                segment.damageTaken = damageTaken
            end

            local target, spell, source, targetSpell, targetSource, spellSource, targetSpellSource, isNew
            ---@type DamageTakenTarget
            target, --
            isNew = GetTarget(damageTaken.targets, destGUID, destName, destFlags)
            if isNew then
                target.spells = {}
                target.sources = {}
            end

            ---@type DamageTakenSpell
            spell, --
            isNew = GetSpell(damageTaken.spells, spellId, spellSchool)
            if isNew then spell.sources = {} end

            ---@type DamageTakenSource
            source, --
            isNew = GetSource(damageTaken.sources, sourceGUID, sourceName, sourceFlags)

            ---@type DamageTakenSpell
            targetSpell, --
            isNew = GetSpell(target.spells, spellId, spellSchool)
            if isNew then targetSpell.sources = {} end

            ---@type DamageTakenSource
            targetSource, --
            isNew = GetSource(target.sources, sourceGUID, sourceName, sourceFlags)

            ---@type DamageTakenSource
            spellSource, --
            isNew = GetSource(spell.sources, sourceGUID, sourceName, sourceFlags)

            ---@type DamageTakenSource
            targetSpellSource, --
            isNew = GetSource(targetSpell.sources, sourceGUID, sourceName, sourceFlags)

            if sourceFlags and CombatLog_Object_IsA(sourceFlags, COMBAT_LOG_FILTER_GROUP) then
                tAddMulti("groupAmount", amount, damageTaken, target, spell, source, targetSpell, targetSource,
                          spellSource, targetSpellSource)

                if overkill and overkill > 0 then
                    tAddMulti("groupOverkill", overkill, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end
                if resisted and resisted > 0 then
                    tAddMulti("groupResisted", resisted, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end
                if blocked and blocked > 0 then
                    tAddMulti("groupBlocked", blocked, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end
                if absorbed and absorbed > 0 then
                    tAddMulti("groupAbsorbed", absorbed, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end

                tAddMulti("groupNumHits", 1, damageTaken, target, spell, source, targetSpell, targetSource, spellSource,
                          targetSpellSource)

                tSetMinMulti("groupMinHit", amount, damageTaken, target, spell, source, targetSpell, targetSource,
                             spellSource, targetSpellSource)

                tSetMaxMulti("groupMaxHit", amount, damageTaken, target, spell, source, targetSpell, targetSource,
                             spellSource, targetSpellSource)

                if critical then
                    tAddMulti("groupNumCrits", 1, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end
            else
                tAddMulti("amount", amount, damageTaken, target, spell, source, targetSpell, targetSource, spellSource,
                          targetSpellSource)

                if overkill and overkill > 0 then
                    tAddMulti("overkill", overkill, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end
                if resisted and resisted > 0 then
                    tAddMulti("resisted", resisted, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end
                if blocked and blocked > 0 then
                    tAddMulti("blocked", blocked, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end
                if absorbed and absorbed > 0 then
                    tAddMulti("absorbed", absorbed, damageTaken, target, spell, source, targetSpell, targetSource,
                              spellSource, targetSpellSource)
                end

                tAddMulti("numHits", 1, damageTaken, target, spell, source, targetSpell, targetSource, spellSource,
                          targetSpellSource)

                tSetMinMulti("minHit", amount, damageTaken, target, spell, source, targetSpell, targetSource,
                             spellSource, targetSpellSource)

                tSetMaxMulti("maxHit", amount, damageTaken, target, spell, source, targetSpell, targetSource,
                             spellSource, targetSpellSource)

                if critical then
                    tAddMulti("numCrits", 1, damageTaken, target, spell, source, targetSpell, targetSource, spellSource,
                              targetSpellSource)
                end
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
    ---@param amount number
    ---@param overkill number
    ---@param school number
    ---@param resisted number
    ---@param blocked number
    ---@param absorbed number
    ---@param critical boolean
    ---@param glancing boolean
    ---@param crushing boolean
    ---@param isOffHand boolean
    function AddOn.CombatLogHandlers.SWING_DAMAGE(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                  sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, amount,
                                                  overkill, school, resisted, blocked, absorbed, critical, glancing,
                                                  crushing, isOffHand)
        onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                 destName, destFlags, destRaidFlags, ATTACK_SPELL, school, amount, overkill, resisted, blocked,
                 absorbed, critical, glancing, crushing)
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
    ---@param spellId number
    ---@param spellName string
    ---@param spellSchool number
    ---@param amount number
    ---@param overkill number
    ---@param school number
    ---@param resisted number
    ---@param blocked number
    ---@param absorbed number
    ---@param critical boolean
    ---@param glancing boolean
    ---@param crushing boolean
    ---@param isOffHand boolean
    function AddOn.CombatLogHandlers.SPELL_DAMAGE(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                  sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
                                                  spellId, spellName, spellSchool, amount, overkill, school, resisted,
                                                  blocked, absorbed, critical, glancing, crushing, isOffHand)
        onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                 destName, destFlags, destRaidFlags, spellId, spellSchool, amount, overkill, resisted, blocked,
                 absorbed, critical, glancing, crushing)
    end

    AddOn.CombatLogHandlers.SPELL_PERIODIC_DAMAGE = AddOn.CombatLogHandlers.SPELL_DAMAGE
    AddOn.CombatLogHandlers.SPELL_BUILDING_DAMAGE = AddOn.CombatLogHandlers.SPELL_DAMAGE
    AddOn.CombatLogHandlers.DAMAGE_SHIELD = AddOn.CombatLogHandlers.SPELL_DAMAGE
    AddOn.CombatLogHandlers.DAMAGE_SPLIT = AddOn.CombatLogHandlers.SPELL_DAMAGE
    AddOn.CombatLogHandlers.RANGE_DAMAGE = AddOn.CombatLogHandlers.SPELL_DAMAGE

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
    ---@param environmentalType number
    ---@param amount number
    ---@param overkill number
    ---@param school number
    ---@param resisted number
    ---@param blocked number
    ---@param absorbed number
    ---@param critical boolean
    ---@param glancing boolean
    ---@param crushing boolean
    function AddOn.CombatLogHandlers.ENVIRONMENTAL_DAMAGE(segment, timestamp, hideCaster, sourceGUID, sourceName,
                                                          sourceFlags, sourceRaidFlags, destGUID, destName, destFlags,
                                                          destRaidFlags, environmentalType, amount, overkill, school,
                                                          resisted, blocked, absorbed, critical, glancing, crushing)
        onDamage(segment, timestamp, hideCaster, nil, "ENVIRONMENT_SUBHEADER", nil, nil, destGUID, destName, destFlags,
                 destRaidFlags, "ACTION_ENVIRONMENTAL_DAMAGE_" .. strupper(environmentalType), school, amount, overkill,
                 resisted, blocked, absorbed, critical, glancing, crushing)
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
    ---@param missType string
    ---@param isOffHand boolean
    ---@param amountMissed number
    ---@param critical boolean
    function AddOn.CombatLogHandlers.SWING_MISSED(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                  sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
                                                  missType, isOffHand, amountMissed, critical)
        if missType == "ABSORB" then
            onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                     destName, destFlags, destRaidFlags, ATTACK_SPELL, MASK_PHYSICAL, amountMissed, 0, 0, 0,
                     amountMissed, critical, false, false)
        elseif missType == "BLOCK" then
            onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                     destName, destFlags, destRaidFlags, ATTACK_SPELL, MASK_PHYSICAL, amountMissed, 0, 0, amountMissed,
                     0, critical, false, false)
        elseif missType == "RESIST" then
            onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                     destName, destFlags, destRaidFlags, ATTACK_SPELL, MASK_PHYSICAL, amountMissed, 0, amountMissed, 0,
                     0, critical, false, false)
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
    ---@param spellId number
    ---@param spellName string
    ---@param spellSchool number
    ---@param missType string
    ---@param isOffHand boolean
    ---@param amountMissed number
    ---@param critical boolean
    function AddOn.CombatLogHandlers.SPELL_MISSED(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags,
                                                  sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
                                                  spellId, spellName, spellSchool, missType, isOffHand, amountMissed,
                                                  critical)
        if missType == "ABSORD" then
            onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                     destName, destFlags, destRaidFlags, spellId, spellSchool, amountMissed, 0, 0, 0, amountMissed,
                     critical, false, false)
        elseif missType == "BLOCK" then
            onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                     destName, destFlags, destRaidFlags, spellId, spellSchool, amountMissed, 0, 0, amountMissed, 0,
                     critical, false, false)
        elseif missType == "RESIST" then
            onDamage(segment, timestamp, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
                     destName, destFlags, destRaidFlags, spellId, spellSchool, amountMissed, 0, amountMissed, 0, 0,
                     critical, false, false)
        end
    end

    AddOn.CombatLogHandlers.RANGE_MISSED = AddOn.CombatLogHandlers.SPELL_MISSED
    AddOn.CombatLogHandlers.SPELL_PERIODIC_MISSED = AddOn.CombatLogHandlers.SPELL_MISSED
    AddOn.CombatLogHandlers.SPELL_BUILDING_MISSED = AddOn.CombatLogHandlers.SPELL_MISSED
    AddOn.CombatLogHandlers.DAMAGE_SHIELD_MISSED = AddOn.CombatLogHandlers.SPELL_MISSED
end

local L = AddOn.L
local DAMAGE_DONE_TITLE = AddOn.GenerateHyperlink(L.DAMAGE_DONE, "mode", "damageDone")
local DAMAGE_DONE_TITLE_MOD = AddOn.GenerateHyperlink(L.DAMAGE_DONE .. "*", "mode", "damageDone")
local DAMAGE_TAKEN_TITLE = AddOn.GenerateHyperlink(L.DAMAGE_TAKEN, "mode", "damageTaken")
local DAMAGE_TAKEN_TITLE_MOD = AddOn.GenerateHyperlink(L.DAMAGE_TAKEN .. "*", "mode", "damageTaken")

local format = format
local max = max
local next = next
local tConcat = table.concat
local tInsert = table.insert
local tonumber = tonumber
local wipe = wipe

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
---@param data DamageDoneData|DamageTakenData?
---@return number
local function getAmount(filter, data)
    if not data then return 0 end

    local amount = data.amount or 0
    if not filter.overkill then amount = amount - (data.overkill or 0) end
    if filter.absorbed then amount = amount + (data.absorbed or 0) end
    amount = amount - (data.resisted or 0)
    amount = amount - (data.blocked or 0)
    if filter.group then
        amount = amount + (data.groupAmount or 0)
        if not filter.overkill then amount = amount - (data.groupOverkill or 0) end
        if filter.absorbed then amount = amount + (data.groupAbsorbed or 0) end
        amount = amount - (data.groupResisted or 0)
        amount = amount - (data.groupBlocked or 0)
        if filter.pets then
            amount = amount + (data.petGroupAmount or 0)
            if not filter.overkill then amount = amount - (data.petGroupOverkill or 0) end
            if filter.absorbed then amount = amount + (data.petGroupAbsorbed or 0) end
            amount = amount - (data.petGroupResisted or 0)
            amount = amount - (data.petGroupBlocked or 0)
        end
    end
    if filter.pets then
        amount = amount + (data.petAmount or 0)
        amount = amount - (data.petResisted or 0)
        amount = amount - (data.petBlocked or 0)
        if not filter.overkill then amount = amount - (data.petOverkill or 0) end
        if filter.absorbed then amount = amount + (data.petAbsorbed or 0) end
    end
    return amount > 0 and amount or 0
end

---@type string[]
local title = {}

AddOn.Modes.damageDone = {
    defaultFilter = {
        show = "sources",
        source = nil,
        spell = nil,
        target = nil,
        pets = true,
        overkill = false,
        absorbed = true,
        group = false,
    },
    getSubTitle = function(filter, segment, values, totalValue, maxValue)
        if not segment then return end

        if totalValue > 0 then
            return format("%s (%s)", FormatNumber(totalValue), FormatNumber(totalValue / segment:GetDuration()))
        end
    end,
    getTitle = function(filter, segment)
        wipe(title)
        title[#title + 1] = DAMAGE_DONE_TITLE

        ---@type DamageDone?
        local damageDone = segment and segment.damageDone
        if not damageDone then return title[1] end

        if filter.show ~= "sources" then title[1] = DAMAGE_DONE_TITLE_MOD end

        local source = filter.source
        local spell = filter.spell
        local target = filter.target

        if source then
            title[1] = DAMAGE_DONE_TITLE_MOD
            title[#title + 1] = GetUnitTitleLink("damageDone", source, damageDone.sources[source], "source")
        end
        if spell then
            title[1] = DAMAGE_DONE_TITLE_MOD
            title[#title + 1] = GetSpellTitleLink("damageDone", spell, damageDone.spells[spell])
        end
        if target then
            title[1] = DAMAGE_DONE_TITLE_MOD
            title[#title + 1] = GetUnitTitleLink("damageDone", target, damageDone.targets[target], "target")
        end

        return tConcat(title, " - ")
    end,
    getValues = function(filter, segment, values, texts, colors, icons, iconCoords)
        ---@type DamageDone?
        local damageDone = segment.damageDone
        if not damageDone then return end

        local show = filter.show
        local source = filter.source
        local spell = filter.spell
        local target = filter.target

        local maxAmount = 0

        if source then
            local sourceData = damageDone.sources[source]
            if not sourceData then return end

            if spell then
                local spellData = sourceData.spells[spell]
                if not spellData then return end

                if target then
                    local targetData = spellData.targets[target]
                    if not targetData then return end

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
                    if not targetData then return end

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
                    if not targetData then return end

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
                    for key, data in next, damageDone.sources, nil do
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
                    local spellData = damageDone.spells[spell]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData.targets[target])
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "targets" then
                    local spellData = damageDone.spells[spell]
                    if not spellData then return end

                    local targetData = spellData.targets[target]
                    if not targetData then return end

                    local amount = getAmount(filter, targetData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(target, targetData, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            else
                if show == "sources" then
                    for key, data in next, damageDone.sources, nil do
                        local amount = getAmount(filter, data.spells[spell])
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "spells" then
                    local spellData = damageDone.spells[spell]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData)
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "targets" then
                    local spellData = damageDone.spells[spell]
                    if not spellData then return end

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
            local targetData = damageDone.targets[target]
            if not targetData then return end

            if show == "sources" then
                for key, data in next, damageDone.sources, nil do
                    local amount = getAmount(filter, data.targets[target])
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, damageDone.spells, nil do
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
                for key, data in next, damageDone.sources, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, damageDone.spells, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "targets" then
                for key, data in next, damageDone.targets, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            end
        end

        return maxAmount
    end,
    menu = function(filter, segment)
        ---@type DamageDone?
        local damageDone = segment and segment.damageDone

        return function()
            ---@type MenuInfo[]
            return {
                {
                    func = function(isChecked, value, arg) filter.show = "sources" end,
                    isChecked = filter.show == "sources",
                    text = L.SOURCES,
                },
                {
                    func = function(isChecked, value, arg) filter.show = "spells" end,
                    isChecked = filter.show == "spells",
                    text = L.SPELLS,
                },
                {
                    func = function(isChecked, value, arg) filter.show = "targets" end,
                    isChecked = filter.show == "targets",
                    text = L.TARGETS,
                },
                damageDone and DropDownMenu:GetSeparatorInfo(),
                damageDone and {
                    hasArrow = true,
                    isNotCheckable = true,
                    menu = function(value, arg)
                        ---@type MenuInfo[]
                        local info = {}

                        local func = function(isChecked, value, arg) filter.source = value end
                        for key, sourceData in next, damageDone.sources, nil do
                            local class = GetPlayerClass(key) or sourceData.class
                            local icon, iconCoords = GetClassIcon(class)

                            info[#info + 1] = {
                                func = func,
                                iconTexCoords = iconCoords,
                                iconTexture = icon,
                                isChecked = filter.source == key,
                                text = GetPlayerName,
                                textColor = GetClassColor(class),
                                tooltipLink = "unit:" .. key,
                                updateSpeed = 2,
                                value = key,
                            }
                        end
                        SortMenuInfos(info)

                        tInsert(info, 1, {
                            func = function(isChecked, value, arg) filter.source = nil end,
                            isChecked = filter.source == nil,
                            text = L.ALL,
                        })
                        tInsert(info, 2, DropDownMenu:GetSeparatorInfo())

                        return info
                    end,
                    text = L.SOURCE,
                },
                damageDone and {
                    hasArrow = true,
                    isNotCheckable = true,
                    menu = function(value, arg)
                        ---@type MenuInfo[]
                        local info = {}

                        local func = function(isChecked, value, arg) filter.spell = value end
                        for key, spellData in next, damageDone.spells, nil do
                            local icon, iconCoords = GetSpellIcon(key)

                            info[#info + 1] = {
                                func = func,
                                iconTexCoords = iconCoords,
                                iconTexture = icon,
                                isChecked = filter.spell == key,
                                text = GetSpellName,
                                textColor = GetDamageClassColor(spellData.school),
                                tooltipLink = "spell:" .. key,
                                updateSpeed = 2,
                                value = key,
                            }
                        end
                        SortMenuInfos(info)

                        tInsert(info, 1, {
                            func = function(isChecked, value, arg) filter.spell = nil end,
                            isChecked = filter.spell == nil,
                            text = L.ALL,
                        })
                        tInsert(info, 2, DropDownMenu:GetSeparatorInfo())

                        return info
                    end,
                    text = L.SPELL,
                },
                damageDone and {
                    hasArrow = true,
                    isNotCheckable = true,
                    menu = function(value, arg)
                        ---@type MenuInfo[]
                        local info = {}

                        local func = function(isChecked, value, arg) filter.target = value end
                        for key, targetData in next, damageDone.targets, nil do
                            local class = GetPlayerClass(key) or targetData.class
                            local icon, iconCoords = GetClassIcon(class)

                            info[#info + 1] = {
                                func = func,
                                iconTexCoords = iconCoords,
                                iconTexture = icon,
                                isChecked = filter.target == key,
                                text = GetPlayerName,
                                textColor = GetClassColor(class),
                                tooltipLink = "unit:" .. key,
                                updateSpeed = 2,
                                value = key,
                            }
                        end
                        SortMenuInfos(info)

                        tInsert(info, 1, {
                            func = function(isChecked, value, arg) filter.target = nil end,
                            isChecked = filter.target == nil,
                            text = L.ALL,
                        })
                        tInsert(info, 2, DropDownMenu:GetSeparatorInfo())

                        return info
                    end,
                    text = L.TARGET,
                },
                DropDownMenu:GetSeparatorInfo(),
                {
                    func = function(isChecked, value, arg) filter.pets = not isChecked end,
                    isChecked = filter.pets,
                    isNotRadio = true,
                    text = L.PETS,
                },
                {
                    func = function(isChecked, value, arg) filter.overkill = not isChecked end,
                    isChecked = filter.overkill,
                    isNotRadio = true,
                    text = L.OVERKILL,
                },
                {
                    func = function(isChecked, value, arg) filter.absorbed = not isChecked end,
                    isChecked = filter.absorbed,
                    isNotRadio = true,
                    text = L.ABSORBED,
                },
                {
                    func = function(isChecked, value, arg) filter.group = not isChecked end,
                    isChecked = filter.group,
                    isNotRadio = true,
                    text = L.GROUP,
                },
                DropDownMenu:GetSeparatorInfo(),
                {
                    func = function(isChecked, value, arg)
                        filter.show = "sources"
                        filter.source = nil
                        filter.spell = nil
                        filter.target = nil
                        filter.pets = true
                        filter.overkill = false
                        filter.absorbed = true
                        filter.group = false
                    end,
                    isNotCheckable = true,
                    text = L.RESET,
                },
            }
        end
    end,
    onClick = function(filter, key, button)
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
    end,
    onHyperlink = function(filter, link, button)
        local linkData = ExtractLink(link)
        if linkData then
            linkData = ArrayToPairs(linkData)

            if linkData.mode == "damageDone" then
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
                        filter.overkill = false
                        filter.absorbed = true
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
    end,
    perSecond = true,
    percent = true,
    tooltip = function(filter, segment, key, tooltip)
        ---@type DamageDone?
        local damageDone = segment.damageDone
        if not damageDone then return end

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

                        local sourceData = damageDone.sources[key]
                        if not sourceData then return end

                        local spellData = sourceData.spells[spell]
                        if not spellData then return end

                        for targetKey, data in next, spellData.targets, nil do
                            tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                        end
                        tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, spellData))
                    elseif show == "spells" then
                        tooltip:SetSpell(key)

                        local sourceData = damageDone.sources[source]
                        if not sourceData then return end

                        local spellData = sourceData.spells[key]
                        if not spellData then return end

                        for targetKey, data in next, spellData.targets, nil do
                            tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                        end
                        tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, spellData))
                    elseif show == "targets" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                    end
                end
            elseif target then
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = damageDone.sources[key]
                    if not sourceData then return end

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.targets[target]), data)
                    end
                    tooltip:ProcessSpellAmounts(getAmount(filter, sourceData.targets[target]))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local sourceData = damageDone.sources[source]
                    if not sourceData then return end

                    local spellData = sourceData.spells[key]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = damageDone.sources[source]
                    if not sourceData then return end

                    local targetData = sourceData.targets[key]
                    if not targetData then return end

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                    end
                    tooltip:ProcessSpellAmounts(getAmount(filter, targetData))
                end
            else
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = damageDone.sources[key]
                    if not sourceData then return end

                    local amount = getAmount(filter, sourceData)

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessSpellAmounts(amount)

                    for targetKey, data in next, sourceData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, amount)
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local sourceData = damageDone.sources[source]
                    if not sourceData then return end

                    local spellData = sourceData.spells[key]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = damageDone.sources[source]
                    if not sourceData then return end

                    for spellKey, data in next, sourceData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                    end
                    tooltip:ProcessSpellAmounts(getAmount(filter, sourceData.targets[key]))
                end
            end
        elseif spell then
            if target then
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    for sourceKey, data in next, damageDone.sources, nil do
                        local spellData = data.spells[key]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[target]), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, damageDone.spells[key] and
                                                                       damageDone.spells[key].targets[target]))
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for sourceKey, data in next, damageDone.sources, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[key]), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, damageDone.spells[spell] and
                                                                       damageDone.spells[spell].targets[key]))
                end
            else
                if show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local sourceData = damageDone.sources[key]
                    if not sourceData then return end

                    local spellData = sourceData.spells[spell]
                    if not spellData then return end

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, spellData))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local spellData = damageDone.spells[key]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData)

                    for sourceKey, data in next, damageDone.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data.spells[key]), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, amount)

                    for targetKey, data in next, spellData.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, amount)
                elseif show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for sourceKey, data in next, damageDone.sources, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[key]), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, damageDone.spells[spell] and
                                                                       damageDone.spells[spell].targets[key]))
                end
            end
        elseif target then
            if show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = damageDone.sources[key]
                if not sourceData then return end

                for spellKey, data in next, sourceData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[target]), data)
                end
                tooltip:ProcessSpellAmounts(getAmount(filter, sourceData.targets[target]))
            elseif show == "spells" then
                tooltip:SetSpell(key)

                for sourceKey, data in next, damageDone.sources, nil do
                    local spellData = data.spells[key]
                    tooltip:AddAmount(sourceKey, getAmount(filter, spellData and spellData.targets[target]), data)
                end
                tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, damageDone.spells[key] and
                                                                   damageDone.spells[key].targets[target]))
            elseif show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = damageDone.targets[key]
                if not targetData then return end

                local amount = getAmount(filter, targetData)

                for sourceKey, data in next, damageDone.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ProcessUnitAmounts(L.SOURCE, amount)

                for spellKey, data in next, damageDone.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ProcessSpellAmounts(amount)
            end
        else
            if show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = damageDone.sources[key]
                if not sourceData then return end

                local amount = getAmount(filter, sourceData)

                for spellKey, data in next, sourceData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data), data)
                end
                tooltip:ProcessSpellAmounts(amount)

                for targetKey, data in next, sourceData.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                end
                tooltip:ProcessUnitAmounts(L.TARGET, amount)
            elseif show == "spells" then
                tooltip:SetSpell(key)

                local spellData = damageDone.spells[key]
                if not spellData then return end

                local amount = getAmount(filter, spellData)

                for sourceKey, data in next, damageDone.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.spells[key]), data)
                end
                tooltip:ProcessUnitAmounts(L.SOURCE, amount)

                for targetKey, data in next, spellData.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data), data)
                end
                tooltip:ProcessUnitAmounts(L.TARGET, amount)

            elseif show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = damageDone.targets[key]
                if not targetData then return end

                local amount = getAmount(filter, targetData)

                for sourceKey, data in next, damageDone.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ProcessUnitAmounts(L.SOURCE, amount)

                for spellKey, data in next, damageDone.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.targets[key]), data)
                end
                tooltip:ProcessSpellAmounts(amount)
            end
        end
    end,
}
AddOn.ModeNames.damageDone = L.DAMAGE_DONE
AddOn.ModeKeys[#AddOn.ModeKeys + 1] = "damageDone"

AddOn.Modes.damageTaken = {
    defaultFilter = {
        show = "targets",
        source = nil,
        spell = nil,
        target = nil,
        overkill = false,
        absorbed = false,
        group = true,
    },
    getSubTitle = function(filter, segment, values, totalValue, maxValue)
        if not segment then return end

        if totalValue > 0 then
            return format("%s (%s)", FormatNumber(totalValue), FormatNumber(totalValue / segment:GetDuration()))
        end
    end,
    getTitle = function(filter, segment)
        wipe(title)
        title[#title + 1] = DAMAGE_TAKEN_TITLE

        ---@type DamageTaken?
        local damageTaken = segment and segment.damageTaken
        if not damageTaken then return title[1] end

        if filter.show ~= "targets" then title[1] = DAMAGE_TAKEN_TITLE_MOD end

        local spell = filter.spell
        local target = filter.target
        local source = filter.source

        if target then
            title[1] = DAMAGE_TAKEN_TITLE_MOD
            title[#title + 1] = GetUnitTitleLink("damageTaken", target, damageTaken.targets[target], "target")
        end
        if spell then
            title[1] = DAMAGE_TAKEN_TITLE_MOD
            title[#title + 1] = GetSpellTitleLink("damageTaken", spell, damageTaken.spells[spell])
        end
        if source then
            title[1] = DAMAGE_TAKEN_TITLE_MOD
            title[#title + 1] = GetUnitTitleLink("damageTaken", source, damageTaken.sources[source], "source")
        end

        return tConcat(title, " - ")
    end,
    getValues = function(filter, segment, values, texts, colors, icons, iconCoords)
        ---@type DamageTaken?
        local damageTaken = segment.damageTaken
        if not damageTaken then return end

        local show = filter.show
        local target = filter.target
        local spell = filter.spell
        local source = filter.source

        local maxAmount = 0

        if target then
            local targetData = damageTaken.targets[target]
            if not targetData then return end

            if spell then
                local spellData = targetData.spells[spell]
                if not spellData then return end

                if source then
                    local sourceData = spellData.sources[source]
                    if not sourceData then return end

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
                    if not sourceData then return end

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
                    if not sourceData then return end

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
                    for key, data in next, damageTaken.targets, nil do
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
                    local spellData = damageTaken.spells[spell]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData.sources[source])
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "sources" then
                    local spellData = damageTaken.spells[spell]
                    if not spellData then return end

                    local sourceData = spellData.sources[source]
                    if not sourceData then return end

                    local amount = getAmount(filter, sourceData)
                    if amount > 0 then
                        maxAmount = amount

                        FillUnitTables(source, sourceData, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            else
                if show == "targets" then
                    for key, data in next, damageTaken.targets, nil do
                        local amount = getAmount(filter, data.spells[spell])
                        if amount > 0 then
                            maxAmount = max(maxAmount, amount)

                            FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                        end
                    end
                elseif show == "spells" then
                    local spellData = damageTaken.spells[spell]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData)
                    if amount > 0 then
                        maxAmount = amount

                        FillSpellTables(spell, spellData, amount, values, texts, colors, icons, iconCoords)
                    end
                elseif show == "sources" then
                    local spellData = damageTaken.spells[spell]
                    if not spellData then return end

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
            local sourceData = damageTaken.sources[source]
            if not sourceData then return end

            if show == "targets" then
                for key, data in next, damageTaken.targets, nil do
                    local amount = getAmount(filter, data.sources[source])
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, damageTaken.spells, nil do
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
                for key, data in next, damageTaken.targets, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "spells" then
                for key, data in next, damageTaken.spells, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            elseif show == "sources" then
                for key, data in next, damageTaken.sources, nil do
                    local amount = getAmount(filter, data)
                    if amount > 0 then
                        maxAmount = max(maxAmount, amount)

                        FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
                    end
                end
            end
        end

        return maxAmount
    end,
    menu = function(filter, segment)
        ---@type DamageTaken?
        local damageTaken = segment and segment.damageTaken

        return function()
            ---@type MenuInfo[]
            return {
                {
                    func = function(isChecked, value, arg) filter.show = "targets" end,
                    isChecked = filter.show == "targets",
                    text = L.TARGETS,
                },
                {
                    func = function(isChecked, value, arg) filter.show = "spells" end,
                    isChecked = filter.show == "spells",
                    text = L.SPELLS,
                },
                {
                    func = function(isChecked, value, arg) filter.show = "sources" end,
                    isChecked = filter.show == "sources",
                    text = L.SOURCES,
                },
                damageTaken and DropDownMenu:GetSeparatorInfo(),
                damageTaken and {
                    hasArrow = true,
                    isNotCheckable = true,
                    menu = function(value, arg)
                        ---@type MenuInfo[]
                        local info = {}

                        local func = function(isChecked, value, arg) filter.target = value end
                        for key, targetData in next, damageTaken.targets, nil do
                            local class = GetPlayerClass(key) or targetData.class
                            local icon, iconCoords = GetClassIcon(class)

                            info[#info + 1] = {
                                func = func,
                                iconTexCoords = iconCoords,
                                iconTexture = icon,
                                isChecked = filter.target == key,
                                text = GetPlayerName,
                                textColor = GetClassColor(class),
                                tooltipLink = "unit:" .. key,
                                updateSpeed = 2,
                                value = key,
                            }
                        end
                        SortMenuInfos(info)

                        tInsert(info, 1, {
                            func = function(isChecked, value, arg) filter.target = nil end,
                            isChecked = filter.target == nil,
                            text = L.ALL,
                        })
                        tInsert(info, 2, DropDownMenu:GetSeparatorInfo())

                        return info
                    end,
                    text = L.TARGET,
                },
                damageTaken and {
                    hasArrow = true,
                    isNotCheckable = true,
                    menu = function(value, arg)
                        ---@type MenuInfo[]
                        local info = {}

                        local func = function(isChecked, value, arg) filter.spell = value end
                        for key, spellData in next, damageTaken.spells, nil do
                            local icon, iconCoords = GetSpellIcon(key)

                            info[#info + 1] = {
                                func = func,
                                iconTexCoords = iconCoords,
                                iconTexture = icon,
                                isChecked = filter.spell == key,
                                text = GetSpellName,
                                textColor = GetDamageClassColor(spellData.school),
                                tooltipLink = "spell:" .. key,
                                updateSpeed = 2,
                                value = key,
                            }
                        end
                        SortMenuInfos(info)

                        tInsert(info, 1, {
                            func = function(isChecked, value, arg) filter.spell = nil end,
                            isChecked = filter.spell == nil,
                            text = L.ALL,
                        })
                        tInsert(info, 2, DropDownMenu:GetSeparatorInfo())

                        return info
                    end,
                    text = L.SPELL,
                },
                damageTaken and {
                    hasArrow = true,
                    isNotCheckable = true,
                    menu = function(value, arg)
                        ---@type MenuInfo[]
                        local info = {}

                        local func = function(isChecked, value, arg) filter.source = value end
                        for key, sourceData in next, damageTaken.sources, nil do
                            local class = GetPlayerClass(key) or sourceData.class
                            local icon, iconCoords = GetClassIcon(class)

                            info[#info + 1] = {
                                func = func,
                                iconTexCoords = iconCoords,
                                iconTexture = icon,
                                isChecked = filter.source == key,
                                text = GetPlayerName,
                                textColor = GetClassColor(class),
                                tooltipLink = "unit:" .. key,
                                updateSpeed = 2,
                                value = key,
                            }
                        end
                        SortMenuInfos(info)

                        tInsert(info, 1, {
                            func = function(isChecked, value, arg) filter.source = nil end,
                            isChecked = filter.source == nil,
                            text = L.ALL,
                        })
                        tInsert(info, 2, DropDownMenu:GetSeparatorInfo())

                        return info
                    end,
                    text = L.SOURCE,
                },
                DropDownMenu:GetSeparatorInfo(),
                {
                    func = function(isChecked, value, arg) filter.overkill = not isChecked end,
                    isChecked = filter.overkill,
                    isNotRadio = true,
                    text = L.OVERKILL,
                },
                {
                    func = function(isChecked, value, arg) filter.absorbed = not isChecked end,
                    isChecked = filter.absorbed,
                    isNotRadio = true,
                    text = L.ABSORBED,
                },
                {
                    func = function(isChecked, value, arg) filter.group = not isChecked end,
                    isChecked = filter.group,
                    isNotRadio = true,
                    text = L.GROUP,
                },
                DropDownMenu:GetSeparatorInfo(),
                {
                    func = function(isChecked, value, arg)
                        filter.show = "targets"
                        filter.target = nil
                        filter.spell = nil
                        filter.source = nil
                        filter.overkill = false
                        filter.absorbed = false
                        filter.group = true
                    end,
                    isNotCheckable = true,
                    text = L.RESET,
                },
            }
        end
    end,
    onClick = function(filter, key, button)
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
    end,
    onHyperlink = function(filter, link, button)
        local linkData = ExtractLink(link)
        if linkData then
            linkData = ArrayToPairs(linkData)

            if linkData.mode == "damageTaken" then
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
                        filter.overkill = false
                        filter.absorbed = false
                        filter.group = true
                    elseif button == "RightButton" then
                        filter.show = "targets"
                    end
                    filter.target = nil
                    filter.spell = nil
                    filter.source = nil
                end
            end
        end
    end,
    perSecond = true,
    percent = true,
    tooltip = function(filter, segment, key, tooltip)
        ---@type DamageTaken?
        local damageTaken = segment.damageTaken
        if not damageTaken then return end

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

                        local targetData = damageTaken.targets[key]
                        if not targetData then return end

                        local spellData = targetData.spells[spell]
                        if not spellData then return end

                        for sourceKey, data in next, spellData.sources, nil do
                            tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                        end
                        tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                    elseif show == "spells" then
                        tooltip:SetSpell(key)

                        local targetData = damageTaken.targets[target]
                        if not targetData then return end

                        local spellData = targetData.spells[key]
                        if not spellData then return end

                        for sourceKey, data in next, spellData.sources, nil do
                            tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                        end
                        tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                    elseif show == "sources" then
                        tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                    end
                end
            elseif source then
                if show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = damageTaken.targets[key]
                    if not targetData then return end

                    for spellKey, data in next, targetData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.sources[source]), data)
                    end
                    tooltip:ProcessSpellAmounts(getAmount(filter, targetData.sources[source]))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local targetData = damageTaken.targets[target]
                    if not targetData then return end

                    local spellData = targetData.spells[key]
                    if not spellData then return end

                    for sourceKey, data in next, spellData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                elseif show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = damageTaken.targets[target]
                    if not targetData then return end

                    local sourceData = targetData.sources[key]
                    if not sourceData then return end

                    for spellKey, data in next, targetData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.sources[key]), data)
                    end
                    tooltip:ProcessSpellAmounts(getAmount(filter, sourceData))
                end
            else
                if show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = damageTaken.targets[key]
                    if not targetData then return end

                    local amount = getAmount(filter, targetData)

                    for spellKey, data in next, targetData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessSpellAmounts(amount)

                    for sourceKey, data in next, targetData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, amount)
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local targetData = damageTaken.targets[target]
                    if not targetData then return end

                    local spellData = targetData.spells[key]
                    if not spellData then return end

                    for sourceKey, data in next, spellData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                elseif show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = damageTaken.targets[target]
                    if not targetData then return end

                    for spellKey, data in next, targetData.spells, nil do
                        tooltip:AddAmount(spellKey, getAmount(filter, data.sources[key]), data)
                    end
                    tooltip:ProcessSpellAmounts(getAmount(filter, targetData.sources[key]))
                end
            end
        elseif spell then
            if source then
                if show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    for targetKey, data in next, damageTaken.targets, nil do
                        local spellData = data.spells[key]
                        tooltip:AddAmount(targetKey, getAmount(filter, spellData and spellData.sources[source]), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, damageTaken.spells[key] and
                                                                       damageTaken.spells[key].sources[source]))
                elseif show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for targetKey, data in next, damageTaken.targets, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(targetKey, getAmount(filter, spellData and spellData.sources[key]), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, damageTaken.spells[spell] and
                                                                       damageTaken.spells[spell].sources[key]))
                end
            else
                if show == "targets" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    local targetData = damageTaken.targets[key]
                    if not targetData then return end

                    local spellData = targetData.spells[spell]
                    if not spellData then return end

                    for sourceKey, data in next, spellData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, getAmount(filter, spellData))
                elseif show == "spells" then
                    tooltip:SetSpell(key)

                    local spellData = damageTaken.spells[key]
                    if not spellData then return end

                    local amount = getAmount(filter, spellData)

                    for targetKey, data in next, damageTaken.targets, nil do
                        tooltip:AddAmount(targetKey, getAmount(filter, data.spells[key]), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, amount)

                    for sourceKey, data in next, spellData.sources, nil do
                        tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                    end
                    tooltip:ProcessUnitAmounts(L.SOURCE, amount)
                elseif show == "sources" then
                    tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                    for targetKey, data in next, damageTaken.targets, nil do
                        local spellData = data.spells[spell]
                        tooltip:AddAmount(targetKey, getAmount(filter, spellData and spellData.sources[key]), data)
                    end
                    tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, damageTaken.spells[spell] and
                                                                       damageTaken.spells[spell].sources[key]))
                end
            end
        elseif source then
            if show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = damageTaken.targets[key]
                if not targetData then return end

                for spellKey, data in next, targetData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.sources[source]), data)
                end
                tooltip:ProcessSpellAmounts(getAmount(filter, targetData.sources[source]))
            elseif show == "spells" then
                tooltip:SetSpell(key)

                for targetKey, data in next, damageTaken.targets, nil do
                    local spellData = data.spells[key]
                    tooltip:AddAmount(targetKey, getAmount(filter, spellData and spellData.sources[source]), data)
                end
                tooltip:ProcessUnitAmounts(L.TARGET, getAmount(filter, damageTaken.spells[key] and
                                                                   damageTaken.spells[key].sources[source]))
            elseif show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = damageTaken.sources[key]
                if not sourceData then return end

                local amount = getAmount(filter, sourceData)

                for targetKey, data in next, damageTaken.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data.sources[key]), data)
                end
                tooltip:ProcessUnitAmounts(L.TARGET, amount)

                for spellKey, data in next, damageTaken.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.sources[key]), data)
                end
                tooltip:ProcessSpellAmounts(amount)
            end
        else
            if show == "targets" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local targetData = damageTaken.targets[key]
                if not targetData then return end

                local amount = getAmount(filter, targetData)

                for spellKey, data in next, targetData.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data), data)
                end
                tooltip:ProcessSpellAmounts(amount)

                for sourceKey, data in next, targetData.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                end
                tooltip:ProcessUnitAmounts(L.SOURCE, amount)
            elseif show == "spells" then
                tooltip:SetSpell(key)

                local spellData = damageTaken.spells[key]
                if not spellData then return end

                local amount = getAmount(filter, spellData)

                for targetKey, data in next, damageTaken.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data.spells[key]), data)
                end
                tooltip:ProcessUnitAmounts(L.TARGET, amount)

                for sourceKey, data in next, spellData.sources, nil do
                    tooltip:AddAmount(sourceKey, getAmount(filter, data), data)
                end
                tooltip:ProcessUnitAmounts(L.SOURCE, amount)

            elseif show == "sources" then
                tooltip:SetPlayerOrName(key, segment.roster and segment.roster[key])

                local sourceData = damageTaken.sources[key]
                if not sourceData then return end

                local amount = getAmount(filter, sourceData)

                for targetKey, data in next, damageTaken.targets, nil do
                    tooltip:AddAmount(targetKey, getAmount(filter, data.sources[key]), data)
                end
                tooltip:ProcessUnitAmounts(L.TARGET, amount)

                for spellKey, data in next, damageTaken.spells, nil do
                    tooltip:AddAmount(spellKey, getAmount(filter, data.sources[key]), data)
                end
                tooltip:ProcessSpellAmounts(amount)
            end
        end
    end,
}
AddOn.ModeNames.damageTaken = L.DAMAGE_TAKEN
AddOn.ModeKeys[#AddOn.ModeKeys + 1] = "damageTaken"
