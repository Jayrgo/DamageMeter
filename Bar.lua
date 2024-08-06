---@class AddOn
local AddOn = (select(2, ...))

local DEFAULT_HEIGHT = 18
local DEFAULT_COLOR = AddOn.DEFAULT_COLOR

local abs = abs

local Clamp = Clamp
local CreateFrame = CreateFrame
local CreateFramePool = CreateFramePool
local GetFramerate = GetFramerate

---@param self Bar
---@param value number
---@param smoothed? boolean
local function setValue(self, value, smoothed)
    self.value = value
    if not smoothed then self.statusBar:SetValue(value) end
end

---@param self Bar
---@param smoothed? boolean
---@return number
local function getValue(self, smoothed)
    if smoothed then
        return self.statusBar:GetValue() or 0
    else
        return self.value or 0
    end
end

---@param self Bar
---@param minValue number
---@param maxValue number
---@param smoothed? boolean
local function setMinMaxValues(self, minValue, maxValue, smoothed)
    if smoothed then
        local oldMinValue, oldMaxValue = self.statusBar:GetMinMaxValues()
        if (oldMinValue and oldMinValue == oldMinValue) and (oldMaxValue and oldMaxValue == oldMaxValue) and
            (oldMinValue ~= 0 or oldMaxValue ~= 0) then
            local oldValue = self.statusBar:GetValue()
            if oldValue and oldValue == oldValue then
                self.statusBar:SetMinMaxValues(minValue, maxValue)
                self.statusBar:SetValue((oldValue / (oldMaxValue - oldMinValue) * (maxValue - minValue)) + minValue)
                return
            end
        end
    end
    self.statusBar:SetMinMaxValues(minValue, maxValue)
end

---@param self Bar
---@return number
---@return number
local function getMinMaxValues(self)
    local minValue, maxValue = self.statusBar:GetMinMaxValues()
    return minValue or 0, maxValue or 0
end

---@param color? ColorMixin
local function setColor(self, color) self.statusBar:SetStatusBarColor((color or DEFAULT_COLOR):GetRGBA()) end

---@param texture? number|string
---@param texCoords? number[]
local function setIcon(self, texture, texCoords)
    local icon = self.icon

    icon:SetTexture(texture)

    local left, right, top, bottom
    if texCoords then left, right, top, bottom = unpack(texCoords) end
    icon:SetTexCoord(left or 0, right or 1, top or 0, bottom or 1)
end

---@param self Bar
---@param text? string
local function setTextLeft(self, text) self.textLeft:SetText(text) end

---@param self Bar
---@return string
local function getTextLeft(self) return self.textLeft:GetText() end ---@diagnostic disable-line:return-type-mismatch

---@param self Bar
---@param text? string
local function setTextRight(self, text) self.textRight:SetText(text) end

---@param self Bar
---@return string
local function getTextRight(self) return self.textRight:GetText() end ---@diagnostic disable-line:return-type-mismatch

---@param self Bar
---@param key any
---@param value any
local function setData(self, key, value) self.data[key] = value end

---@param self Bar
---@param key any
---@return any
local function getData(self, key) return self.data[key] end

---@param self Bar
local function resetData(self) wipe(self.data) end

---@param targetValue number
---@param newValue number
---@param minValue number
---@param maxValue number
---@return boolean
local function isCloseEnough(targetValue, newValue, minValue, maxValue)
    local range = maxValue - minValue
    if range > 0 then
        return abs((newValue - targetValue) / range) < 0.001
    else
        return true
    end
end

---@param parent? string|Region
---@param resetterFunc? fun(pool: BarPool, bar: Bar)
---@param initFunc? function(bar: Bar)
---@retrun BarPool
function AddOn.CreateBarPool(parent, resetterFunc, initFunc)
    ---@alias BarPoolPairs fun(table: table<Bar, boolean>, index?: Bar):Bar, boolean
    ---@class BarPool
    ---@field Acquire fun(pool: BarPool):Bar, boolean
    ---@field Release fun(pool: BarPool, bar:Bar)
    ---@field ReleaseAll fun(pool: BarPool)
    ---@field EnumerateActive fun(pool: BarPool):BarPoolPairs, Bar
    ---@field GetNumActive fun(pool: BarPool):number
    return CreateFramePool("Button", parent, nil, resetterFunc, false, function(frame)
        ---@class Bar : Button
        ---@field value? number
        local bar = frame

        bar:SetHeight(DEFAULT_HEIGHT)

        bar.statusBar = CreateFrame("StatusBar", nil, bar)
        bar.statusBar:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        bar.statusBar:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        bar.statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8", "BORDER")
        bar.statusBar:SetMinMaxValues(0, 1)
        bar.statusBar:SetValue(0)

        bar.icon = bar.statusBar:CreateTexture(nil, "OVERLAY")
        bar.icon:SetPoint("TOPLEFT", bar.statusBar, "TOPLEFT", 1, -1)
        bar.icon:SetSize(DEFAULT_HEIGHT - 2, DEFAULT_HEIGHT - 2)

        bar.textLeft = bar.statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
        bar.textLeft:SetPoint("TOPLEFT", bar.icon, "TOPRIGHT", 2, 0)
        bar.textLeft:SetPoint("BOTTOMRIGHT", bar.statusBar, "BOTTOM", -2, 1)

        bar.textRight = bar.statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightRight")
        bar.textRight:SetPoint("TOPLEFT", bar.statusBar, "TOP", 2, -1)
        bar.textRight:SetPoint("BOTTOMRIGHT", bar.statusBar, "BOTTOMRIGHT", -2, 1)

        local highlight = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        highlight:SetFrameLevel(bar:GetFrameLevel() + 100)
        highlight:Hide()
        highlight:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        highlight:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
        ---@diagnostic disable
        highlight.backdropInfo = {
            --[[ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", ]]
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            --[[ tileSize = 16, ]]
            tileEdge = true,
            edgeSize = 8,
            --[[ insets = {left = 1, right = 1, top = 0, bottom = 1}, ]]
        }
        highlight:OnBackdropLoaded()
        ---@diagnostic enable

        bar:SetScript("OnUpdate", --
        ---@param self Bar
        ---@param elapsed number
        function(self, elapsed)
            local currentValue = getValue(self, true)
            local minValue, maxValue = getMinMaxValues(self)
            local targetValue = getValue(self, false)
            local newValue = ((Clamp(targetValue, minValue, maxValue) - currentValue) * (60 / GetFramerate() * 0.2)) +
                                 currentValue
            if isCloseEnough(targetValue, newValue, minValue, maxValue) then
                setValue(self, targetValue, false)
            else
                self.statusBar:SetValue(newValue)
            end
        end)

        bar:SetScript("OnHide", --
        ---@param self Bar
        function(self)
            setMinMaxValues(self, 0, 0, false)
            setValue(self, 0, false)

            highlight:Hide()
        end)

        bar:SetScript("OnEnter", --
        ---@param self Bar
        ---@param motion boolean
        function(self, motion) highlight:Show() end)

        bar:SetScript("OnLeave", --
        ---@param self Bar
        ---@param motion boolean
        function(self, motion) highlight:Hide() end)

        bar.data = {}

        bar.SetValue = setValue
        bar.GetValue = getValue
        bar.SetMinMaxValues = setMinMaxValues
        bar.GetMinMaxValues = getMinMaxValues
        bar.SetColor = setColor
        bar.SetIcon = setIcon
        bar.SetTextLeft = setTextLeft
        bar.GetTextLeft = getTextLeft
        bar.SetTextRight = setTextRight
        bar.GetTextRight = getTextRight
        bar.SetData = setData
        bar.GetData = getData
        bar.ResetData = resetData

        if initFunc then initFunc(bar) end
    end)
end
