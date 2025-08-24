---@class AddOn
local AddOn = select(2, ...)

local _G = _G
local DEFAULT_COLOR = AddOn.DEFAULT_COLOR
local DEFAULT_TEXTURE = AddOn.DEFAULT_TEXTURE
local DEFAULT_TEXTURE_STRING = AddOn.DEFAULT_TEXTURE_STRING
local DEFAULT_TEX_COORDS = AddOn.DEFAULT_TEX_COORDS
local SECONDS_PER_HOUR = 1 / 3600
local SECONDS_PER_MINUTE = 1 / 60
local SYMBOLIC_NEGATIVE_NUMBER = SYMBOLIC_NEGATIVE_NUMBER
local SYMBOLIC_POSITIVE_NUMBER = SYMBOLIC_POSITIVE_NUMBER

local abs = abs
local band = bit.band
local date = date
local floor = floor
local fmod = math.fmod
local format = format
local getmetatable = getmetatable
local huge = math.huge
local max = max
local min = min
local next = next
local select = select
local setmetatable = setmetatable
local strsplit = strsplit
local strsplittable = strsplittable
local tSort = table.sort
local tostring = tostring
local type = type
local unpack = unpack

local CreateColor = CreateColor
local Damageclass = Enum.Damageclass
local DoesSpellExist = C_Spell.DoesSpellExist
local FormatLink = LinkUtil.FormatLink
local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer
local GetItemQualityColor = C_Item.GetItemQualityColor
local GetNumGroupMembers = GetNumGroupMembers
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local C_GetSpellName = C_Spell.GetSpellName
local C_GetSpellTexture = C_Spell.GetSpellTexture
local IsEventValid = C_EventUtils.IsEventValid
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsSpellDataCached = C_Spell.IsSpellDataCached
local RequestLoadSpellData = C_Spell.RequestLoadSpellData
local UnitExists = UnitExists

---@type table<any, string>
local L = setmetatable({}, {
    ---@param t table<any, string>
    ---@param k any
    ---@return string
    __index = function(t, k)
        local v = tostring(_G[k] or k)
        t[k] = v
        return v
    end,
})
AddOn.L = L

local function nop() end
AddOn.nop = nop

---@generic T
---@param orig T
---@return T copy
local function shallowcopy(orig)
    if type(orig) == "table" then
        local copy = {}
        for key, value in next, orig, nil do copy[key] = value end
        return setmetatable(copy, getmetatable(orig))
    else
        return orig
    end
end

---@generic T
---@param orig T
---@return T copy
local function deepcopy(orig)
    if type(orig) == "table" then
        local copy = {}
        for key, value in next, orig, nil do copy[deepcopy(key)] = deepcopy(value) end
        return setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        return orig
    end
end

---@generic T
---@param orig T
---@param deep? boolean
---@return T copy
function AddOn.Copy(orig, deep) return deep and deepcopy(orig) or shallowcopy(orig) end

---@param ... any
---@return SafeTable
function AddOn.SafePack(...)
    ---@class SafeTable
    ---@field n number
    return {n = select("#", ...), ...}
end

---@param st SafeTable
---@return ...
function AddOn.SafeUnpack(st) return unpack(st, 1, st.n) end

---@param t table
---@param k any
---@param n number
local function tAdd(t, k, n)
    if n == 0 then return end
    t[k] = (t[k] or 0) + n
end
AddOn.tAdd = tAdd

---@param k any
---@param n number
---@param ... table
local function tAddMulti(k, n, ...)
    if n == 0 then return end
    for i = 1, select("#", ...), 1 do tAdd(select(i, ...), k, n) end
end
AddOn.tAddMulti = tAddMulti

---@param t table
---@param k any
---@param n number
local function tSetMax(t, k, n) t[k] = max(t[k] or -huge, n) end
AddOn.tSetMax = tSetMax

---@param k any
---@param n number
---@param ... table
local function tSetMaxMulti(k, n, ...) for i = 1, select("#", ...), 1 do tSetMax(select(i, ...), k, n) end end
AddOn.tSetMaxMulti = tSetMaxMulti

---@param t table
---@param k any
---@param n number
local function tSetMin(t, k, n) t[k] = min(t[k] or huge, n) end
AddOn.tSetMin = tSetMin

---@param k any
---@param n number
---@param ... table
local function tSetMinMulti(k, n, ...) for i = 1, select("#", ...), 1 do tSetMin(select(i, ...), k, n) end end
AddOn.tSetMinMulti = tSetMinMulti

---@generic T
---@param t T[]
---@param k any
---@param v T
local function tAppend(t, k, v)
    if not t[k] then
        t[k] = {v}
    else
        t[k][#t[k] + 1] = v
    end
end
AddOn.tAppend = tAppend

---@generic T
---@param k any
---@param v T
---@param ... T[]
local function tAppendMulti(k, v, ...) for i = 1, select("#", ...) do tAppend(select(i, ...), k, v) end end
AddOn.tAppendMulti = tAppendMulti

---@generic T1, T2
---@param tbl T1
---@param ... T2
---@return T1|T2
function AddOn.Mixin(tbl, ...)
    for i = 1, select("#", ...), 1 do for k, v in next, select(i, ...), nil do tbl[k] = v end end
    return tbl
end

---@param tbl table
---@param value any
---@return boolean
local function tContains(tbl, value)
    for k, v in next, tbl, nil do if v == value then return true end end
    return false
end
AddOn.tContains = tContains

local formatSeconds
---@param seconds number
---@return string
formatSeconds = function(seconds)
    if seconds < 0 then
        return format(L.SYMBOLIC_NEGATIVE_NUMBER, formatSeconds(abs(seconds)))
    elseif seconds < 1 then
        return format(L.MILLISECONDS_ABBR, seconds * 1000)
    elseif seconds < 60 then
        return format(L.SECONDS_ABBR, seconds)
    elseif seconds < 3600 then
        local minutes = floor(fmod(seconds, 3600) / 60)
        seconds = floor(fmod(seconds, 60))
        if seconds > 0 then
            return format("%s%s%s", format(L.MINUTES_ABBR, minutes), L.TIME_UNIT_DELIMITER,
                          format(L.SECONDS_ABBR, seconds))
        else
            return format(L.MINUTES_ABBR, minutes)
        end
    else
        local hours = floor(fmod(seconds, 86400) * SECONDS_PER_HOUR)
        local minutes = floor(fmod(seconds, 3600) * SECONDS_PER_MINUTE)
        seconds = floor(fmod(seconds, 60))
        if seconds > 0 then
            if minutes > 0 then
                return format("%s%s%s%s%s", format(L.HOURS_ABBR, hours), L.TIME_UNIT_DELIMITER,
                              format(L.MINUTES_ABBR, minutes), L.TIME_UNIT_DELIMITER, format(L.SECONDS_ABBR, seconds))
            else
                return format("%s%s%s", format(L.HOURS_ABBR, hours), L.TIME_UNIT_DELIMITER,
                              format(L.SECONDS_ABBR, seconds))
            end
        elseif minutes > 0 then
            return format("%s%s%s", format(L.HOURS_ABBR, hours), L.TIME_UNIT_DELIMITER, format(L.MINUTES_ABBR, minutes))
        else
            return format(L.HOURS_ABBR, hours)
        end
    end
end
AddOn.FormatSeconds = formatSeconds

---@param timestamp number
---@return boolean
local function isToday(timestamp) return date("%Y-%m-%d", time()) == date("%Y-%m-%d", timestamp) end

---@param timestamp number
---@return string
function AddOn.FormatTimestamp(timestamp)
    ---@type string
    return date(isToday(timestamp) and "%H:%M:%S" or "%Y-%m-%d %H:%M:%S", timestamp)
end

local STEPS = {
    {
        breakpoint = (10 ^ 12) - 1,
        format = "%.1f" .. FOURTH_NUMBER_CAP_NO_SPACE, ---@diagnostic disable-line:undefined-field
        multiplier = 10 ^ -12,
    },
    {
        breakpoint = (10 ^ 9) - 1,
        format = "%.1f" .. THIRD_NUMBER_CAP_NO_SPACE, ---@diagnostic disable-line:undefined-field
        multiplier = 10 ^ -9,
    },
    {
        breakpoint = (10 ^ 6) - 1,
        format = "%.1f" .. SECOND_NUMBER_CAP_NO_SPACE, ---@diagnostic disable-line:undefined-field
        multiplier = 10 ^ -6,
    },
    {
        breakpoint = (10 ^ 3) - 1,
        format = "%.1f" .. FIRST_NUMBER_CAP_NO_SPACE, ---@diagnostic disable-line:undefined-field
        multiplier = 10 ^ -3,
    },
}
local NUM_STEPS = #STEPS

---@param value? number
---@param positiveSign? boolean
---@return string
function AddOn.FormatNumber(value, positiveSign)
    value = value or 0

    local negative = false
    if value < 0 then
        value = abs(value)
        negative = true
    end
    for i = 1, NUM_STEPS, 1 do
        local step = STEPS[i]
        if value >= step.breakpoint then
            if negative then
                return format(SYMBOLIC_NEGATIVE_NUMBER, format(step.format, value * step.multiplier))
            end
            return format(step.format, value * step.multiplier)
        end
    end
    if negative then return format(SYMBOLIC_NEGATIVE_NUMBER, format(floor(value) == value and "%d" or "%.2f", value)) end
    return positiveSign and format(SYMBOLIC_POSITIVE_NUMBER, format(floor(value) == value and "%d" or "%.2f", value)) or
               format(floor(value) == value and "%d" or "%.2f", value)
end

---@param percentage number
---@return string
function AddOn.FormatPercentage(percentage)
    percentage = percentage * 100
    return format( --[[ floor(percentage) == percentage and "%d%%" or  ]] "%.2f%%", percentage)
end

---@param func fun(unitToken:UnitToken):boolean?
---@param includePets? boolean
---@return boolean
function AddOn.CallOnAllGroupMembers(func, includePets)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers(), 1 do
            local unitToken = "raid" .. i
            if UnitExists(unitToken) then
                if func(unitToken) then return true end
                if includePets then
                    unitToken = "raidpet" .. i
                    if UnitExists(unitToken) then if func(unitToken) then return true end end
                end
            end
        end
    elseif IsInGroup() then
        if func("player") then return true end
        if includePets then
            local unitToken = "pet"
            if UnitExists(unitToken) then if func("pet") then return true end end
        end
        for i = 1, GetNumGroupMembers() - 1, 1 do
            local unitToken = "party" .. i
            if UnitExists(unitToken) then
                if func(unitToken) then return true end
                if includePets then
                    unitToken = "partypet" .. i
                    if UnitExists(unitToken) then if func(unitToken) then return true end end
                end
            end
        end
    else
        if func("player") then return true end
        if includePets then
            local unitToken = "pet"
            if UnitExists(unitToken) then if func("pet") then return true end end
        end
    end
    return false
end

---@type table<ClassFile, ColorMixin>
local CLASS_COLORS = {}
do
    for i = 1, #CLASS_SORT_ORDER, 1 do
        local classFilename = CLASS_SORT_ORDER[i]
        local color = C_ClassColor.GetClassColor(classFilename)
        CLASS_COLORS[classFilename] =
            CreateColor((color.r + 0.5) * 0.5, (color.g + 0.5) * 0.5, (color.b + 0.5) * 0.5, 1)
    end
end

---@param classFilename? ClassFile
---@return ColorMixin
local function GetClassColor(classFilename) return classFilename and CLASS_COLORS[classFilename] or DEFAULT_COLOR end
AddOn.GetClassColor = GetClassColor

---@type table<ClassFile, number[]>
local CLASS_TEX_COORDS = {}
---@type table<ClassFile, string>
local CLASS_TEXTURE_STRING = {}
for classFilename, coords in pairs(CLASS_ICON_TCOORDS) do
    local left, right, top, bottom = unpack(coords)
    CLASS_TEX_COORDS[classFilename] = {left, right, top, bottom}
    CLASS_TEXTURE_STRING[classFilename] = format(
                                              "|TInterface\\WorldStateFrame\\Icons-Classes:0:0:0:0:256:256:%d:%d:%d:%d|t",
                                              256 * left, 256 * right, 256 * top, 256 * bottom)
end

---@param classFilename? ClassFile
---@return number|string
---@return number[]
local function GetClassIcon(classFilename)
    if classFilename then return "Interface\\WorldStateFrame\\Icons-Classes", CLASS_TEX_COORDS[classFilename] end
    return DEFAULT_TEXTURE, DEFAULT_TEX_COORDS
end
AddOn.GetClassIcon = GetClassIcon

---@param classFilename? ClassFile
---@return string
local function GetClassTextureString(classFilename) return CLASS_TEXTURE_STRING[classFilename] or DEFAULT_TEXTURE_STRING end
AddOn.GetClassTextureString = GetClassTextureString

---@param classFilename? ClassFile
---@param name string
---@return string
function AddOn.GetClassTextureAndName(classFilename, name)
    return format("%s %s", GetClassTextureString(classFilename), name)
end

---@param spellId SpellID
---@return string
local function GetSpellName(spellId)
    if type(spellId) == "number" then
        if DoesSpellExist(spellId) then
            if not IsSpellDataCached(spellId) then
                RequestLoadSpellData(spellId)
                return L[spellId]
            else
                return C_GetSpellName(spellId) or L[spellId]
            end
        end
    end
    return L[spellId]
end
AddOn.GetSpellName = GetSpellName

---@param spellId SpellID
---@return number|string
---@return number[]
local function GetSpellIcon(spellId)
    if type(spellId) == "number" then
        if DoesSpellExist(spellId) then
            if not IsSpellDataCached(spellId) then
                RequestLoadSpellData(spellId)
                return DEFAULT_TEXTURE, DEFAULT_TEX_COORDS
            else
                local iconID, originalIconID = C_GetSpellTexture(spellId)
                if iconID then
                    return iconID, DEFAULT_TEX_COORDS
                elseif originalIconID then
                    return originalIconID, DEFAULT_TEX_COORDS
                end
            end
        end
    end
    return DEFAULT_TEXTURE, DEFAULT_TEX_COORDS
end
AddOn.GetSpellIcon = GetSpellIcon

---@type table<Enum.Damageclass, ColorMixin>
local DAMAGECLASS_COLORS = setmetatable({
    [Damageclass.MaskNone] = DEFAULT_COLOR,
    [Damageclass.MaskChaos] = CreateColor(0.66, 0, 1, 1),
    [Damageclass.MaskMagical] = CreateColor(0.66, 0, 1, 1),
    [Damageclass.All] = CreateColor(0.66, 0, 1, 1),
    [Damageclass.MaskPhysical] = CreateColor(0.9, 0.8, 0.5, 1),
    [Damageclass.MaskHoly] = CreateColor(1, 0.9, 0.5, 1),
    [Damageclass.MaskFire] = CreateColor(0.75, 0.5, 0.25, 1),
    [Damageclass.MaskNature] = CreateColor(0.4, 0.75, 0.4, 1),
    [Damageclass.MaskFrost] = CreateColor(0.5, 1, 1, 1),
    [Damageclass.MaskShadow] = CreateColor(0.5, 0.5, 1, 1),
    [Damageclass.MaskArcane] = CreateColor(0.75, 0.5, 0.75, 1),
}, {
    ---@param t table<Enum.Damageclass, ColorMixin>
    ---@param k Enum.Damageclass
    ---@return ColorMixin
    __index = function(t, k)
        ---@type ColorMixin[]
        local colors = {}

        if band(k, Damageclass.MaskPhysical) > 0 then colors[#colors + 1] = t[Damageclass.MaskPhysical] end
        if band(k, Damageclass.MaskHoly) > 0 then colors[#colors + 1] = t[Damageclass.MaskHoly] end
        if band(k, Damageclass.MaskFire) > 0 then colors[#colors + 1] = t[Damageclass.MaskFire] end
        if band(k, Damageclass.MaskNature) > 0 then colors[#colors + 1] = t[Damageclass.MaskNature] end
        if band(k, Damageclass.MaskFrost) > 0 then colors[#colors + 1] = t[Damageclass.MaskFrost] end
        if band(k, Damageclass.MaskShadow) > 0 then colors[#colors + 1] = t[Damageclass.MaskShadow] end
        if band(k, Damageclass.MaskArcane) > 0 then colors[#colors + 1] = t[Damageclass.MaskArcane] end

        ---@type ColorMixin
        local v
        local numColors = #colors
        if numColors > 0 then
            local r = 0
            local g = 0
            local b = 0
            for i = 1, numColors, 1 do
                r = r + colors[i].r
                g = g + colors[i].g
                b = b + colors[i].b
            end

            v = CreateColor(r / numColors, g / numColors, b / numColors, 1)
        else
            v = t[Damageclass.MaskNone]
        end

        t[k] = v
        return v
    end,
})

---@param class? Enum.Damageclass
---@return ColorMixin
local function GetDamageClassColor(class) return DAMAGECLASS_COLORS[class or Damageclass.MaskNone] end
AddOn.GetDamageClassColor = GetDamageClassColor

---@param text string
---@param texture number|string
---@param coords? number[]
---@retrun string
function AddOn.AppendTextToTexture(text, texture, coords)
    return coords and format("|T%1$s:0:0:0:0:0:0:%3$d:%4$d:%5$d:%6$d|t %2$s", texture, text, unpack(coords)) or
               format("|T%s:0|t %s", texture, text)
end

---@param linkDisplayText string
---@param ... string
---@return string
local function GenerateHyperlink(linkDisplayText, ...) return FormatLink("addon", linkDisplayText, NAME, ...) end
AddOn.GenerateHyperlink = GenerateHyperlink

---@param link string
---@return string[]?
function AddOn.ExtractLink(link)
    local linkType, name, data = strsplit(":", link, 3)
    if linkType == "addon" and name == NAME then return data and strsplittable(":", data) end
end

---@generic T
---@param t table<number, T>
---@return table<T, T>
function AddOn.ArrayToPairs(t)
    for i = 1, #t, 2 do t[t[i]] = t[i + 1] end
    return t
end

---@type table<Enum.ItemQuality, ColorMixin>
local ITEM_QUALITY_COLORS = setmetatable({}, {
    ---@param t table<Enum.ItemQuality, ColorMixin>
    ---@param k Enum.ItemQuality
    ---@return ColorMixin
    __index = function(t, k)
        local r, g, b = GetItemQualityColor(k)
        local v = CreateColor(r, g, b)
        t[k] = v
        return v
    end,
})

---@param itemQuality? Enum.ItemQuality
---@return ColorMixin
function AddOn.GetItemQualityColor(itemQuality) return itemQuality and ITEM_QUALITY_COLORS[itemQuality] or DEFAULT_COLOR end

---@type table<string, BasePlayerInfo>
local playerInfosByGUID = setmetatable({}, {
    ---@param t table<string, BasePlayerInfo>
    ---@param k string
    ---@return BasePlayerInfo
    __index = function(t, k)
        if GUIDIsPlayer(k) then
            local --
            ---@type string
            localizedClass, --
            ---@type ClassFile
            englishClass, --
            ---@type string
            localizedRace, --
            ---@type string
            englishRace, --
            ---@type number
            sex, --
            ---@type string
            name, --
            ---@type string
            realm = GetPlayerInfoByGUID(k)

            if name and name ~= "" then
                local fullName = name
                local shortName = name
                if realm and realm ~= "" then
                    fullName = name .. "-" .. realm
                    shortName = name .. L.FOREIGN_SERVER_LABEL
                end

                ---@class BasePlayerInfo
                local v = {
                    class = englishClass,
                    name = name,
                    realm = realm,
                    fullName = fullName,
                    shortName = shortName,
                    race = englishRace,
                    sex = sex,
                }
                t[k] = v
                return v
            else
                return {name = k}
            end
        end

        local v = {name = L[k]}
        t[k] = v
        return v
    end,
    __mode = "v",
})

---@param guid string
---@return ClassFile?
local function GetPlayerClass(guid) return playerInfosByGUID[guid].class end
AddOn.GetPlayerClass = GetPlayerClass

---@param guid string
---@return string name
---@return string? fullName
---@return string? shortName
local function GetPlayerName(guid)
    return playerInfosByGUID[guid].name, playerInfosByGUID[guid].fullName, playerInfosByGUID[guid].shortName
end
AddOn.GetPlayerName = GetPlayerName

---@param mode string
---@param unit string
---@param unitData? UnitTable
---@param unitType string
---@return string
function AddOn.GetUnitTitleLink(mode, unit, unitData, unitType)
    local name, class = GetPlayerName(unit), GetPlayerClass(unit) or unitData and unitData.class
    return GenerateHyperlink(GetClassColor(class):WrapTextInColorCode(name), "mode", mode, unitType, unit)
end

---@param mode string
---@param spell string|number
---@param spellData? SpellTable
---@return string
function AddOn.GetSpellTitleLink(mode, spell, spellData)
    return GenerateHyperlink(
               GetDamageClassColor(spellData and spellData.school):WrapTextInColorCode(GetSpellName(spell)), "mode",
               mode, "spell", spell)
end

---@param key string
---@param data UnitTable
---@param amount number
---@param values table<any, number>
---@param texts table<any, string>
---@param colors table<any, ColorMixin>
---@param icons table<any, string|number>
---@param iconCoords table<any, number[]>
function AddOn.FillUnitTables(key, data, amount, values, texts, colors, icons, iconCoords)
    values[key] = amount

    texts[key] = GetPlayerName(key)
    local class = GetPlayerClass(key) or data.class
    colors[key] = GetClassColor(class)
    icons[key], iconCoords[key] = GetClassIcon(class)
end

---@param key string|number
---@param data SpellTable
---@param amount number
---@param values table<any, number>
---@param texts table<any, string>
---@param colors table<any, ColorMixin>
---@param icons table<any, string|number>
---@param iconCoords table<any, number[]>
function AddOn.FillSpellTables(key, data, amount, values, texts, colors, icons, iconCoords)
    values[key] = amount

    texts[key] = GetSpellName(key)
    colors[key] = GetDamageClassColor(data.school)
    icons[key], iconCoords[key] = GetSpellIcon(key)
end

do -- SortUnitNames
    ---@param a string
    ---@param b string
    ---@return boolean
    local function comp(a, b) return GetPlayerName(a) < GetPlayerName(b) end

    ---@param spells string[]
    function AddOn.SortUnitNames(spells) tSort(spells, comp) end
end

do -- SortSpellNames
    ---@param a string|number
    ---@param b string|number
    ---@return boolean
    local function comp(a, b) return GetSpellName(a) < GetSpellName(b) end

    ---@param spells string[]|number[]
    function AddOn.SortSpellNames(spells) tSort(spells, comp) end
end

do -- Events
    ---@type table<WowEvent, fun(...)[]>
    local handlers = {}

    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", --
    ---@param self Frame
    ---@param event WowEvent
    ---@param ... any
    function(self, event, ...)
        local callbacks = handlers[event]

        if callbacks then
            for i = 1, #callbacks, 1 do callbacks[i](...) end
        else
            self:UnregisterEvent(event)
        end
    end)

    ---@param event WowEvent
    ---@param handler fun(...)
    function AddOn.RegisterEvent(event, handler)
        if not IsEventValid(event) then return end

        local callbacks = handlers[event]
        if not callbacks then
            callbacks = {}
            handlers[event] = callbacks
            frame:RegisterEvent(event)
        end

        if not tContains(callbacks, handler) then callbacks[#callbacks + 1] = handler end
    end
end
