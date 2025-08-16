---@class AddOn
local AddOn = select(2, ...)

---@diagnostic disable:undefined-field
if _G.Jayrgo_DebugTools_AddTable then _G.Jayrgo_DebugTools_AddTable(AddOn, ...) end
---@diagnostic enable:undefined-field

---@type string
AddOn.NAME = ...
AddOn.TITLE = C_AddOns.GetAddOnMetadata(AddOn.NAME, "Title")
AddOn.VERSION = C_AddOns.GetAddOnMetadata(AddOn.NAME, "Version")
AddOn.AUTHOR = C_AddOns.GetAddOnMetadata(AddOn.NAME, "Author")

---@type table<string, Mode>
AddOn.Modes = {}
---@type table<string, string>
AddOn.ModeNames = {}
---@type string[]
AddOn.ModeKeys = {}

AddOn.MAX_CACHED_EVENTS_PER_FRAME = 25
AddOn.MAX_SAVED_SEGMENTS = 100

AddOn.DEFAULT_COLOR = CreateColor(0.5, 0.5, 0.5, 1)

AddOn.DEFAULT_TEXTURE = "Interface\\WorldMap\\QuestionMark_Gold_64Grey"
AddOn.DEFAULT_TEXTURE_STRING = "|TInterface\\WorldMap\\QuestionMark_Gold_64Grey:0|t"
AddOn.DEFAULT_TEX_COORDS = {0, 1, 0, 1}

AddOn.DEFAULT_WINDOW_WIDTH = 300
AddOn.DEFAULT_WINDOW_HEIGHT = 170

AddOn.ATTACK_SPELL = 88163
AddOn.AUTO_ATTACK = 6603
AddOn.MELEE_SPELL = 260421
AddOn.COMBAT_LOG_FILTER_ENEMY = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_REACTION_HOSTILE,
                                        COMBATLOG_OBJECT_REACTION_NEUTRAL, COMBATLOG_OBJECT_CONTROL_MASK,
                                        COMBATLOG_OBJECT_TYPE_MASK)
AddOn.COMBAT_LOG_FILTER_FRIENDLY = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_REACTION_FRIENDLY,
                                           COMBATLOG_OBJECT_CONTROL_MASK, COMBATLOG_OBJECT_TYPE_MASK)
AddOn.COMBAT_LOG_FILTER_GROUP = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY,
                                        COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_REACTION_FRIENDLY,
                                        COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_CONTROL_NPC,
                                        COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_TYPE_NPC,
                                        COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN,
                                        COMBATLOG_OBJECT_TYPE_OBJECT)
AddOn.COMBAT_LOG_FILTER_GROUP_NO_PET = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY,
                                               COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_REACTION_FRIENDLY,
                                               COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_CONTROL_NPC,
                                               COMBATLOG_OBJECT_TYPE_PLAYER)
AddOn.COMBAT_LOG_FILTER_MINE = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY,
                                       COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PLAYER,
                                       COMBATLOG_OBJECT_TYPE_OBJECT)
AddOn.COMBAT_LOG_FILTER_PET = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_REACTION_MASK,
                                      COMBATLOG_OBJECT_CONTROL_MASK, COMBATLOG_OBJECT_TYPE_PET,
                                      COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_OBJECT)
AddOn.MASK_PHYSICAL = Enum.Damageclass.MaskPhysical
