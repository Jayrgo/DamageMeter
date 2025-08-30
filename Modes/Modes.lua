---@class AddOn
local AddOn = (select(2, ...))

local L = AddOn.L

local Copy = AddOn.Copy

---@type table<string, Mode>
local modes = {}
---@type table<string, string>
local names = {}
---@type string[]
local keys = {}

---@param key string
---@return Mode?
function AddOn.Mode(key) return modes[key] or #keys > 0 and modes[keys[1]] end

---@param key? string
---@return string
function AddOn.ModeName(key) return key and names[key] or L.UNKNOWN end

---@return string[]
function AddOn.ModeKeys() return Copy(keys) end

---@param key string
---@param name string
---@return Mode?
function AddOn.RegisterMode(key, name)
    if names[key] then return end

    ---@class Mode
    ---@field DefaultFilter? table
    ---@field Menu? fun(element:ElementMenuDescriptionProxy, filter: table, segment?: Segment)
    ---@field OnClick? fun(filter: table, key: any, button: string)
    ---@field OnHyperlink? fun(filter: table, link: string, button: string)
    ---@field Tooltip? fun(filter: table, segment: Segment, key: any, tooltip:Tooltip)
    local mode = {
        ---@param filter table
        ---@param segment? Segment
        ---@return string
        Title = function(filter, segment) return name end,
        ---@param filter table
        ---@param segment Segment
        ---@param values table<any, number>
        ---@param texts table<any, string>
        ---@param colors table<any, ColorMixin>
        ---@param icons table<any, string|number>
        ---@param iconCoords table<any, number[]>
        ---@return number maxAmount
        ---@return boolean perSecond
        ---@return boolean percent
        Values = function(filter, segment, values, texts, colors, icons, iconCoords) return 0, false, false end,
    }

    modes[key] = mode
    names[key] = name
    keys[#keys + 1] = key

    return mode
end
