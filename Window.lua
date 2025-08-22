---@class AddOn
local AddOn = (select(2, ...))

local L = AddOn.L

local format = format
local max = max
local min = min
local next = next
local setmetatable = setmetatable
local time = time
local tRemove = table.remove
local tSort = table.sort
local tostring = tostring
local wipe = wipe

local ActiveSegments = AddOn.ActiveSegments
local CreateBarPool = AddOn.CreateBarPool
local CreateColor = CreateColor
local CreateFrame = CreateFrame
local DeleteAllSegments = AddOn.DeleteAllSegments
local DeleteSegment = AddOn.DeleteSegment
local DropDownMenu = AddOn.DropDownMenu
local FormatNumber = AddOn.FormatNumber
local FormatPercentage = AddOn.FormatPercentage
local FormatSeconds = AddOn.FormatSeconds
local FormatTimestamp = AddOn.FormatTimestamp
local GetScreenWidth = GetScreenWidth
local IsModifierKeyDown = IsModifierKeyDown
local Mixin = AddOn.Mixin
local Mode = AddOn.Mode
local ModeKeys = AddOn.ModeKeys
local ModeName = AddOn.ModeName
local Segments = AddOn.Segments
local Tooltip = AddOn.Tooltip

---@alias WindowPoolPairs fun(table: table<Window, boolean>, index?: Window):Window, boolean
---@class WindowPool
---@field Acquire fun(window: WindowPool):Window
---@field Release fun(window: WindowPool, window: Window)
---@field ReleaseAll fun(window: WindowPool)
---@field EnumerateActive fun(window: WindowPool):WindowPoolPairs, Window
---@field GetNumActive fun(window: WindowPool):number
local windowPool

--[[ ---@param self WindowSegmentButton
---@param motion boolean
local function segmentButton_OnEnter(self, motion)
    Tooltip:SetOwner(self, "ANCHOR_RIGHT")
    Tooltip:SetTitle(L.SEGMENTS)
    Tooltip:Show()
end ]]

--[[ ---@param self WindowModeButton
---@param motion boolean
local function modeButton_OnEnter(self, motion)
    Tooltip:SetOwner(self, "ANCHOR_RIGHT")
    Tooltip:SetTitle(L.MODE)
    Tooltip:Show()
end ]]

---@param self WindowSettingsButton
---@param motion boolean
local function settingsButton_OnEnter(self, motion)
    Tooltip:SetOwner(self, "ANCHOR_RIGHT")
    Tooltip:SetText(L.SETTINGS)
    Tooltip:Show()
end

local function hideTooltip() Tooltip:Hide() end

---@param self ScrollFrame
---@param offset number
local function scrollFrame_OnMouseWheel(self, offset)
    self:SetVerticalScroll(max(0, min(self:GetVerticalScroll() - (offset * (IsModifierKeyDown() and 180 or 18)),
                                      self:GetVerticalScrollRange())))
end

---@param self ScrollFrame
---@param elapsed number
local function scrollFrame_OnUpdate(self, elapsed)
    self:SetVerticalScroll(max(0, min(self:GetVerticalScroll(), ---@diagnostic disable-line:param-type-mismatch
    self:GetVerticalScrollRange())))
end

---@param isChecked boolean
---@param value Segment
---@param arg Window
local function setSegment(isChecked, value, arg) arg:SetSegment(value) end

---@param self DropDownListButton
---@param value Segment
---@param arg Window
local function segmentOnEnter(self, value, arg)
    if value then
        Tooltip:SetOwner(self, "ANCHOR_RIGHT")
        Tooltip:SetTitle(value:GetName())
        Tooltip:AddLine(value:GetMapName())
        Tooltip:AddBlankLines(1)
        Tooltip:AddDoubleLine(L.START, FormatTimestamp(value:GetStartTimestamp() or time()))
        local endTimestamp = value:GetEndTimestamp()
        if endTimestamp then Tooltip:AddDoubleLine(L.END, FormatTimestamp(endTimestamp)) end
        Tooltip:AddDoubleLine(L.DURATION, FormatSeconds(value:GetDuration()))
        Tooltip:Show()
    else
        hideTooltip()
    end
end

---@param self DropDownListButton
---@param value Segment
---@param arg Window
local function combatSegmentOnEnter(self, value, arg)
    Tooltip:SetOwner(self, "ANCHOR_RIGHT")
    Tooltip:SetTitle(value.name or L.CURRENT)
    Tooltip:AddLine(value:GetMapName())
    local startTimestamp = value:GetStartTimestamp()
    if startTimestamp then
        Tooltip:AddDoubleLine(L.START, FormatTimestamp(startTimestamp))
        local endTimestamp = value:GetEndTimestamp()
        if endTimestamp then Tooltip:AddDoubleLine(L.END, FormatTimestamp(endTimestamp)) end
        Tooltip:AddDoubleLine(L.DURATION, FormatSeconds(value:GetDuration()))
    end
    Tooltip:Show()
end

---@param self DropDownListButton
---@param value Segment
---@param arg Window
local function segmentOnLeave(self, value, arg) hideTooltip() end

---@param isChecked boolean
---@param value string
---@param arg Window
local function setMode(isChecked, value, arg) arg:SetMode(value) end

---@param isChecked boolean
---@param value any
---@param arg any
local function createWindow(isChecked, value, arg)
    local window = windowPool:Acquire()
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetMovable(true)
    window:SetResizable(true)
    window:Show()
end

---@param isChecked boolean
---@param value any
---@param arg Window
local function unlockWindow(isChecked, value, arg)
    arg:SetMovable(not isChecked)
    arg:SetResizable(not isChecked)
end

---@param isChecked boolean
---@param value any
---@param arg Window
local function closeWindow(isChecked, value, arg) windowPool:Release(arg) end

---@param value number
---@param total? number
---@param duration? number
---@return string
local function getValueText(value, total, duration)
    if total and total > 0 then
        if duration and duration > 0 then
            return format("%s (%s, %s)", FormatNumber(value), FormatNumber(value / duration),
                          FormatPercentage(value / total))
        else
            return format("%s (%s)", FormatNumber(value), FormatPercentage(value / total))
        end
    else
        if duration and duration > 0 then
            return format("%s (%s)", FormatNumber(value), FormatNumber(value / duration))
        else
            return format("%s", FormatNumber(value))
        end
    end
end

---@param a Bar
---@param b Bar
---@return boolean
local function barComp(a, b)
    local aValue = a:GetValue(false)
    local bValue = b:GetValue(false)
    if aValue == bValue then
        return tostring(a) < tostring(b)
    else
        return aValue > bValue
    end
end

windowPool = CreateFramePool("Frame", UIParent, nil, nil, false, --
---@param frame Frame
function(frame)
    ---@type table
    local filter = {}
    ---@type Segment?
    local segment = AddOn.GetCombatSegment()
    ---@type string
    local modeKey = "damageDone"
    ---@type Mode?
    local mode
    ---@type Segment
    local combatSegment = AddOn.GetCombatSegment()

    ---@class Window : Frame
    local window = frame

    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetSize(AddOn.DEFAULT_WINDOW_WIDTH, AddOn.DEFAULT_WINDOW_HEIGHT)
    window:SetClampedToScreen(true)

    ---@class WindowBackdrop : Frame
    local backdrop = CreateFrame("Frame", nil, window, "BackdropTemplate")
    backdrop:SetPoint("TOPLEFT", window, "TOPLEFT", 0, 0)
    backdrop:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", 0, 0)
    backdrop.backdropInfo = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    }
    backdrop.backdropColor = CreateColor(0, 0, 0, 0.2)
    backdrop.backdropColorAlpha = 0.2
    backdrop.backdropBorderColor = CreateColor(0.3, 0.3, 0.3, 0.3)
    backdrop.backdropBorderColorAlpha = 0.3
    backdrop.backdropBorderBlendMode = "ADD"
    backdrop:OnBackdropLoaded() ---@diagnostic disable-line

    ---@class WindowTitleBar : Frame
    local titleBar = CreateFrame("Frame", nil, window, "PanelDragBarTemplate")
    titleBar:SetPoint("TOPLEFT", window, "TOPLEFT", 0, 0)
    titleBar:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", 0, -18)

    ---@class WindowTitleBarBackdrop : Frame
    local titleBarBackdrop = CreateFrame("Frame", nil, titleBar, "BackdropTemplate")
    titleBarBackdrop:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 0, 0)
    titleBarBackdrop:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
    titleBarBackdrop.backdropInfo = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        --[[ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", ]]
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 0},
    }
    titleBarBackdrop.backdropColor = CreateColor(0, 0, 0, 0.6)
    titleBarBackdrop.backdropColorAlpha = 0.6
    titleBarBackdrop.backdropBorderColor = CreateColor(0, 0, 0, 0)
    titleBarBackdrop.backdropBorderColorAlpha = 0
    titleBarBackdrop.backdropBorderBlendMode = "ADD"
    titleBarBackdrop:OnBackdropLoaded() ---@diagnostic disable-line

    local titleBarFrame = CreateFrame("Frame", nil, titleBar)
    titleBarFrame:SetAllPoints()

    ---@class WindowSegmentButton : DropDownMenuButton
    local segmentButton = Mixin(CreateFrame("Button", nil, titleBarFrame), DropDownMenu.DropDownMenuButtonMixin)
    segmentButton:SetPoint("TOPLEFT", titleBarFrame, "TOPLEFT", 2, -2)
    segmentButton:SetPoint("BOTTOMRIGHT", titleBarFrame, "TOPLEFT", 18, -18)
    segmentButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled")
    segmentButton:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    segmentButton.displayMode = "MENU"
    segmentButton.OnEnter = function(self, motion)
        Tooltip:SetOwner(self, "ANCHOR_RIGHT")
        Tooltip:SetTitle(L.SEGMENTS)
        if segment ~= nil then
            Tooltip:AddLine(segment:GetName())
            local endTimestamp = segment:GetEndTimestamp()
            if endTimestamp then
                Tooltip:AddBlankLines(1)
                Tooltip:AddDoubleLine(L.START, AddOn.FormatTimestamp(segment:GetStartTimestamp() or time()))
                Tooltip:AddDoubleLine(L.END, AddOn.FormatTimestamp(endTimestamp))
                Tooltip:AddDoubleLine(L.DURATION, AddOn.FormatSeconds(segment:GetDuration()))
            end
        end
        Tooltip:Show()
    end
    segmentButton.OnLeave = hideTooltip
    segmentButton:OnLoad()
    ---@param self WindowSegmentButton
    ---@param level number
    ---@param value any
    segmentButton.InitFunc = function(self, level, value)
        if level == 1 then
            local info = DropDownMenu:CreateInfo()

            info.isTitle = true
            info.text = format(L.SEGMENTS_DROPDOWN_TITLE, #AddOn.Segments)
            DropDownMenu:AddButton(level, info, true)

            info.arg = window
            info.func = setSegment

            local current = AddOn.GetCombatSegment()
            info.funcOnEnter = combatSegmentOnEnter
            info.funcOnLeave = segmentOnLeave
            info.isChecked = current == segment
            info.text = L.CURRENT
            info.value = current
            DropDownMenu:AddButton(level, info, false)

            info.funcOnEnter = segmentOnEnter
            info.funcOnLeave = segmentOnLeave

            for key, activeSegment in next, ActiveSegments, nil do
                if activeSegment ~= current then
                    info.isChecked = activeSegment == segment
                    info.text = activeSegment:GetName()
                    info.value = activeSegment
                    DropDownMenu:AddButton(level, info, false)
                end
            end

            if #Segments > 0 then
                DropDownMenu:AddSeparator(level, info)

                info.arg = window
                info.func = setSegment
                info.funcOnEnter = segmentOnEnter
                info.funcOnLeave = segmentOnLeave

                for i = #Segments, 1, -1 do
                    local savedSegment = Segments[i]

                    info.isChecked = savedSegment == segment
                    info.text = savedSegment:GetName()
                    info.value = savedSegment
                    DropDownMenu:AddButton(level, info, false)
                end
            end
        end
    end

    ---@class WindowModeButton : DropDownMenuButton
    local modeButton = Mixin(CreateFrame("Button", nil, titleBarFrame), DropDownMenu.DropDownMenuButtonMixin)
    modeButton:SetPoint("TOPLEFT", segmentButton, "TOPRIGHT", 0, 0)
    modeButton:SetPoint("BOTTOMRIGHT", segmentButton, "BOTTOMRIGHT", 16, 0)
    modeButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-OfficerNote-Disabled")
    modeButton:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-OfficerNote-Up")
    modeButton.displayMode = "MENU"
    modeButton.OnEnter = function(self, motion)
        Tooltip:SetOwner(self, "ANCHOR_RIGHT")
        Tooltip:SetTitle(L.MODE)
        Tooltip:AddLine(ModeName(modeKey))
        Tooltip:Show()
    end
    modeButton.OnLeave = hideTooltip
    modeButton:OnLoad()
    ---@param self WindowModeButton
    ---@param level number
    ---@param value any
    modeButton.InitFunc = function(self, level, value)
        if level == 1 then
            local info = DropDownMenu:CreateInfo()

            info.arg = window
            info.func = setMode

            local modes = ModeKeys()
            for i = 1, #modes, 1 do
                local key = modes[i]

                info.hasArrow = false
                info.menu = nil
                if modeKey == key then
                    if segment and mode and mode.Menu then
                        info.hasArrow = true
                        info.menu = mode.Menu(filter, segment)
                    end
                end

                info.isChecked = modeKey == key
                info.text = ModeName(key)
                info.value = key
                DropDownMenu:AddButton(level, info, false)
            end
        end
    end

    ---@class WindowSettingsButton : DropDownMenuButton
    local settingsButton = Mixin(CreateFrame("Button", nil, titleBarFrame), DropDownMenu.DropDownMenuButtonMixin)
    settingsButton:SetPoint("TOPRIGHT", titleBarFrame, "TOPRIGHT", -2, -2)
    settingsButton:SetPoint("BOTTOMLEFT", titleBarFrame, "BOTTOMRIGHT", -18, 2)
    settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    settingsButton:GetNormalTexture():SetDesaturated(true) ---@diagnostic disable-line:undefined-field
    settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton", "BLEND")
    settingsButton.displayMode = "MENU"
    settingsButton.OnEnter = settingsButton_OnEnter
    settingsButton.OnLeave = hideTooltip
    settingsButton:OnLoad()
    ---@param self WindowSettingsButton
    ---@param level number
    ---@param value any
    settingsButton.InitFunc = function(self, level, value)
        if level == 1 then
            local info = DropDownMenu:CreateInfo()

            info.isTitle = true
            info.text = L.SETTINGS_DROPDOWN_TITLE
            DropDownMenu:AddButton(level, info, true)

            info.func = createWindow
            info.isNotCheckable = true
            info.text = L.CREATE_NEW_WINDOW
            DropDownMenu:AddButton(level, info, true)

            info.arg = window
            info.func = unlockWindow
            info.isChecked = window:IsMovable() and window:IsResizable()
            info.isNotRadio = true
            info.text = L.UNLOCK_WINDOW
            DropDownMenu:AddButton(level, info, true)

            info.arg = window
            info.func = closeWindow
            info.isDisabled = windowPool:GetNumActive() <= 1
            info.isNotCheckable = true
            info.text = L.CLOSE_WINDOW
            DropDownMenu:AddButton(level, info, true)

            DropDownMenu:AddSeparator(level, info)

            ---@diagnostic disable-next-line:duplicate-set-field
            info.func = function(isChecked, value, arg) if segment then DeleteSegment(segment) end end
            info.isNotCheckable = true
            info.text = L.DELETE_SEGMENT
            DropDownMenu:AddButton(level, info, true)

            ---@diagnostic disable-next-line:duplicate-set-field
            info.func = function(isChecked, value, arg) DeleteAllSegments() end
            info.isNotCheckable = true
            info.text = L.DELETE_ALL_SEGMENTS
            DropDownMenu:AddButton(level, info, true)

            DropDownMenu:AddSeparator(level, info)

            ---@diagnostic disable-next-line:duplicate-set-field
            info.func = function(isChecked, value, arg) AddOn.SetCacheEnabled(not isChecked) end
            info.isChecked = AddOn.IsCacheEnabled()
            info.isNotRadio = true
            info.text = L.CACHING_EVENTS
            DropDownMenu:AddButton(level, info, true)
        end
    end

    local textFrame = CreateFrame("Frame", nil, titleBarFrame)
    textFrame:SetPoint("TOPLEFT", modeButton, "TOPRIGHT", 2, 0)
    textFrame:SetPoint("BOTTOMRIGHT", settingsButton, "BOTTOMLEFT", -2, 0)
    textFrame:SetHyperlinksEnabled(true)
    textFrame:SetScript("OnHyperlinkClick", --
    ---@param self Frame
    ---@param link string
    ---@param text string
    ---@param button string
    ---@param region Region
    ---@param left number
    ---@param bottom number
    ---@param width number
    ---@param height number
    function(self, link, text, button, region, left, bottom, width, height)
        if mode and mode.OnHyperlink then mode.OnHyperlink(filter, link, button) end
    end)

    local textLeft = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    local textRight = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightRight")

    ---@class WindowScrollFrame : ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, window)
    scrollFrame:SetPoint("TOPLEFT", titleBarFrame, "BOTTOMLEFT", 3, -1)
    scrollFrame:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -3, 0)
    scrollFrame:SetScript("OnMouseWheel", scrollFrame_OnMouseWheel)
    scrollFrame:SetScript("OnUpdate", scrollFrame_OnUpdate)

    local barFrame = CreateFrame("Frame", nil, scrollFrame)
    barFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetScrollChild(barFrame) ---@diagnostic disable-line:param-type-mismatch
    scrollFrame:SetScript("OnSizeChanged", --
    ---@param self ScrollFrame
    ---@param width number
    ---@param height number
    function(self, width, height) barFrame:SetWidth(width) end)

    local resizeButton = CreateFrame("Button", nil, window, "PanelResizeButtonTemplate")
    resizeButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", 0, 0)
    resizeButton:Init(window, 200, 38) ---@diagnostic disable-line

    hooksecurefunc(window, "SetMovable", --
    ---@param self Window
    ---@param movable boolean
    function(self, movable)
        if not movable then
            titleBar:RegisterForDrag()
        else
            titleBar:RegisterForDrag("LeftButton")
        end
    end)
    window:SetMovable(true)

    hooksecurefunc(window, "SetResizable", --
    ---@param self Window
    ---@param resizable boolean
    function(self, resizable) resizeButton:SetShown(resizable) end)
    window:SetResizable(true)

    ---@type table<any, Bar>
    local activeBars = {}
    ---@type table<Bar, true>
    local usedBars = {}
    ---@type Bar[]
    local bars = {}
    ---@type Bar?
    local mouseOverBar

    ---@param bar Bar
    local function updateTooltip(bar)
        if not segment or not mode then
            Tooltip:Hide()
            return
        end

        Tooltip:SetOwner(bar, "ANCHOR_PRESERVE")
        Tooltip:ClearAllPoints()
        if (bar:GetRight() or 0) > (GetScreenWidth() * 0.5) then
            Tooltip:SetPoint("TOPRIGHT", bar, "TOPLEFT", 0, 0)
        else
            Tooltip:SetPoint("TOPLEFT", bar, "TOPRIGHT", 0, 0)
        end

        if mode.Tooltip then
            mode.Tooltip(filter, segment, bar:GetData("key"), Tooltip)
            Tooltip:Show()
        else
            Tooltip:Hide()
        end
    end

    ---@param bar Bar
    ---@param motion boolean
    local function bar_OnEnter(bar, motion)
        mouseOverBar = bar
        if motion then updateTooltip(bar) end
    end

    ---@param bar Bar
    ---@param motion boolean
    local function bar_OnLeave(bar, motion)
        mouseOverBar = nil
        Tooltip:Hide()
    end

    ---@param bar Bar
    ---@param button string
    ---@param down boolean
    local function bar_OnClick(bar, button, down)
        if not segment then return end
        if not mode then return end

        if mode.OnClick then mode.OnClick(filter, bar:GetData("key"), button) end
    end

    local barPool = CreateBarPool(barFrame, function(pool, bar)
        bar:Hide()
        bar:ClearAllPoints()
        usedBars[bar] = nil
        for k, v in next, activeBars, nil do
            if v == bar then
                activeBars[k] = nil
                break
            end
        end
    end)

    ---@param key any
    ---@return Bar
    local function getBar(key)
        local bar = activeBars[key]
        if bar then
            activeBars[key] = bar
            usedBars[bar] = true
            bars[#bars + 1] = bar
            return bar
        else
            local isNew
            bar, isNew = barPool:Acquire()
            activeBars[key] = bar
            usedBars[bar] = true
            bars[#bars + 1] = bar
            bar:SetData("key", key)
            bar:Show()
            if isNew then
                ---@diagnostic disable:inject-field
                bar.expand = true
                bar.UpdateTooltip = updateTooltip
                ---@diagnostic enable:inject-field

                bar:HookScript("OnEnter", bar_OnEnter)
                bar:HookScript("OnLeave", bar_OnLeave)
                bar:HookScript("OnClick", bar_OnClick)
                bar:RegisterForClicks("AnyUp")
            end

            return bar
        end
    end

    ---@type number
    local maxValue = 0
    ---@type boolean
    local perSecond = false
    ---@type boolean
    local percent = false
    ---@type number
    local totalValue = 0
    ---@type table<any, number>
    local values = {}
    ---@type table<any, string>
    local texts = {}
    ---@type table<any, ColorMixin>
    local colors = {}
    ---@type table<any, string|number>
    local icons = {}
    ---@type table<any, number[]>
    local iconCoords = {}

    local updateState = 1
    ---@type function[]
    local updates = setmetatable({
        function() end, -- skip
        function()
            wipe(usedBars)
            wipe(bars)
            wipe(values)
            wipe(texts)
            wipe(colors)
            wipe(icons)
            wipe(iconCoords)
        end,
        function()
            maxValue = 0
            totalValue = 0

            if not segment then return end
            if not mode then return end

            maxValue, perSecond, percent = mode.Values(filter, segment, values, texts, colors, icons, iconCoords)
            for key, value in next, values, nil do totalValue = totalValue + value end
        end,
        function()
            if not segment then return end
            if not mode then return end

            local duration = perSecond and segment:GetDuration() or nil
            local total = percent and (mouseOverBar and mouseOverBar:GetValue(false) or totalValue) or nil

            for key, value in next, values, nil do
                if value > 0 then
                    local bar = getBar(key)
                    bar:SetMinMaxValues(0, maxValue, true)
                    bar:SetValue(value, true)
                    bar:SetTextRight(getValueText(value, total, duration))
                    bar:SetColor(colors[key])
                    bar:SetIcon(icons[key], iconCoords[key])
                end
            end
        end,
        function() if #bars > 0 then tSort(bars, barComp) end end,
        function()
            local height = 0.1
            local lastBar
            for i = 1, #bars, 1 do
                local bar = bars[i]
                bar:ClearAllPoints()
                if lastBar then
                    bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, 0)
                    bar:SetPoint("TOPRIGHT", lastBar, "BOTTOMRIGHT", 0, 0)
                else
                    bar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 0, 0)
                    bar:SetPoint("TOPRIGHT", barFrame, "TOPRIGHT", 0, 0)
                end
                lastBar = bar
                height = height + bar:GetHeight()
            end
            barFrame:SetHeight(height)
        end,
        function() for bar in barPool:EnumerateActive() do if not usedBars[bar] then barPool:Release(bar) end end end,
        function()
            for i = 1, #bars, 1 do
                local bar = bars[i]
                bar:SetTextLeft(format("%d. %s", i, texts[bar:GetData("key")]))
            end
        end,
        function()
            if combatSegment.startTimestamp and not combatSegment.endTimestamp then
                segmentButton:GetNormalTexture():SetVertexColor(1, 0, 0, 1) ---@diagnostic disable-line:undefined-field
            else
                segmentButton:GetNormalTexture():SetVertexColor(1, 1, 1, 1) ---@diagnostic disable-line:undefined-field
            end

            if not mode then return end

            textLeft:SetText(mode.Title(filter, segment))
            textRight:SetText(mode.SubTitle and mode.SubTitle(filter, segment, values, totalValue, maxValue))
        end,
        function()
            local widthRight = textRight:GetUnboundedStringWidth()

            textLeft:ClearAllPoints()
            textRight:ClearAllPoints()
            if widthRight >= (textFrame:GetWidth() * 0.5) then
                textRight:SetPoint("TOPRIGHT", textFrame, "TOPRIGHT", -2, 0)
                textRight:SetPoint("BOTTOMLEFT", textFrame, "BOTTOM", 2, 0)
                textLeft:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 2, 0)
                textLeft:SetPoint("BOTTOMRIGHT", textFrame, "BOTTOM", -2, 0)
            else
                textRight:SetPoint("TOPRIGHT", textFrame, "TOPRIGHT", -2, 0)
                textRight:SetPoint("BOTTOMRIGHT", textFrame, "BOTTOMRIGHT", -2, 0)
                textLeft:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 2, 0)
                textLeft:SetPoint("BOTTOMRIGHT", textRight, "BOTTOMLEFT", -2, 0)
            end
        end,
    }, {
        ---@param t function[]
        ---@param k number
        ---@return function
        __index = function(t, k)
            local v = function() updateState = 1 end
            t[k] = v
            return v
        end,
    })

    window:SetScript("OnUpdate", --
    ---@param self Window
    ---@param elapsed number
    function(self, elapsed)
        updateState = updateState + 1
        updates[updateState]()
    end)

    ---@param selectedSegment Segment?
    function window:SetSegment(selectedSegment)
        updateState = 0
        segment = selectedSegment
    end

    ---@param key string
    function window:SetMode(key)
        updateState = 0
        modeKey = key
        mode = Mode(key)
        if mode then
            wipe(filter)
            for k, v in next, mode.DefaultFilter or {}, nil do filter[k] = v end
        end
    end
    window:SetMode(modeKey)

    ---@return string?
    function window:GetMode() return modeKey end
end)
AddOn.WindowPool = windowPool
