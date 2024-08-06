---@class AddOn
local AddOn = (select(2, ...))

---@class DropDownMenu
local DropDownMenu = {}
AddOn.DropDownMenu = DropDownMenu

---@type GameTooltip
local Tooltip = AddOn.Tooltip or ---@diagnostic disable-line:undefined-field
AddOn.GameTooltip or ---@diagnostic disable-line:undefined-field
GameTooltip

---@type any
local openMenu
---@alias DropDownInitFunc fun(owner: any, level?: number, value: any)
---@type DropDownInitFunc
local initFunc = nop

---@param value? number
---@param default number
---@param minValue? number
---@param maxValue? number
---@return number
local function getNumber(value, default, minValue, maxValue)
    if type(value) == "number" then
        if minValue then value = max(minValue, value) end
        if maxValue then value = min(maxValue, value) end
        return value
    else
        return default
    end
end

---@class DropDownListButton : Button
local DropDownListButtonMixin = {}
do -- DropDownListButton
    function DropDownListButtonMixin:OnLoad()
        self:SetHeight(16)

        self:SetMotionScriptsWhileDisabled(true)

        self.Highlight = self:CreateTexture(nil, "BACKGROUND")
        self.Highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        self.Highlight:SetBlendMode("ADD")
        self.Highlight:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
        self.Highlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
        self.Highlight:Hide()

        self.Check = self:CreateTexture(nil, "ARTWORK")
        self.Check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
        self.Check:SetSize(16, 16)
        self.Check:SetPoint("LEFT", self, "LEFT", 0, 0)
        self.Check:SetTexCoord(0, 0.5, 0.5, 1)

        self.UnCheck = self:CreateTexture(nil, "ARTWORK")
        self.UnCheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
        self.UnCheck:SetSize(16, 16)
        self.UnCheck:SetPoint("LEFT", self, "LEFT", 0, 0)
        self.UnCheck:SetTexCoord(0.5, 1, 0.5, 1)

        ---@class DropDownMenuListButtonIcon : Texture
        ---@field tFitDropDownSizeX? boolean
        self.Icon = self:CreateTexture(nil, "ARTWORK")
        self.Icon:Hide()
        self.Icon:SetSize(16, 16)
        self.Icon:SetPoint("RIGHT", self, "RIGHT", 0, 0)

        self.ExpandArrow = self:CreateTexture(nil, "ARTWORK")
        self.ExpandArrow:SetSize(16, 16)
        self.ExpandArrow:SetPoint("RIGHT", self, "RIGHT", 0, 0)
        self.ExpandArrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")

        self.Text = self:CreateFontString(nil, "ARTWORK")
        self.Text:SetPoint("LEFT", self, "LEFT", -5, 0)
        self:SetFontString(self.Text)
        self:SetNormalFontObject("GameFontHighlightSmallLeft")
        self:SetHighlightFontObject("GameFontHighlightSmallLeft")
        self:SetDisabledFontObject("GameFontDisableSmallLeft")

        self:SetScript("OnClick", self.OnClick)
        self:SetScript("OnEnter", self.OnEnter)
        self:SetScript("OnLeave", self.OnLeave)
        --[[ self:SetScript("OnEnable", self.OnEnable) ]]
        --[[ self:SetScript("OnDisable", self.OnDisable) ]]
        self:SetScript("OnUpdate", self.OnUpdate)
    end

    ---@param button string
    ---@param down boolean
    function DropDownListButtonMixin:OnClick(button, down)
        local isDisabled = GetValueOrCallFunction(self, "isDisabled", self.value, self.arg)
        if isDisabled then return end

        local isChecked = self.isChecked
        if (type(isChecked) == "function") then isChecked = isChecked(self.value, self.arg) end

        if self.keepShownOnClick then
            if not self.isNotCheckable then
                if isChecked then
                    self.Check:Hide()
                    self.UnCheck:Show()
                    isChecked = false
                else
                    self.Check:Show()
                    self.UnCheck:Hide()
                    isChecked = true
                end
            end
        else
            DropDownMenu:Close(self.level)
        end
        if type(self.isChecked) ~= "function" then self.isChecked = isChecked end

        if not self.noPlaySound then PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end

        local func = self.func
        if func then func(isChecked, self.value, self.arg) end
    end

    function DropDownListButtonMixin:UpdateTooltip()
        if self:IsEnabled() then
            self.Highlight:Show()
            if self.tooltipLink then
                Tooltip:SetOwner(self, "ANCHOR_RIGHT")
                Tooltip:SetHyperlink(self.tooltipLink)
            elseif self.tooltipTitle then
                Tooltip:SetOwner(self, "ANCHOR_RIGHT")
                Tooltip:ClearLines()
                Tooltip:AddLine(self.tooltipTitle, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                                HIGHLIGHT_FONT_COLOR.b)
                if self.tooltipInstruction then
                    Tooltip:AddLine(self.tooltipInstruction, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
                end
                if self.tooltipText then
                    Tooltip:AddLine(self.tooltipText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
                                    true)
                end
                if self.tooltipWarning then
                    Tooltip:AddLine(self.tooltipWarning, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
                end
                Tooltip:Show()
            end
            if self.funcOnEnter then self.funcOnEnter(self, self.value, self.arg) end
            if self.hasArrow then
                local dropDownList
                local menu = GetValueOrCallFunction(self, "menu", self.value, self.arg)
                if menu then
                    dropDownList = DropDownMenu:Open(self.level + 1, self.value, openMenu, --
                    ---@param o any
                    ---@param l number
                    ---@param v any
                    function(o, l, v)
                        for i = 1, #menu, 1 do
                            local menuInfo = menu[i]
                            if menuInfo then DropDownMenu:AddButton(l, menuInfo) end
                        end
                    end, "TOPLEFT", self, "TOPRIGHT", 20, 0)
                else
                    dropDownList = DropDownMenu:Open(self.level + 1, self.value, openMenu, self.initFunc or initFunc,
                                                     "TOPLEFT", self, "TOPRIGHT", 20, 0)

                end
                if dropDownList then
                    dropDownList:RefreshSize()
                    if dropDownList:GetRight() > GetScreenWidth() then
                        dropDownList:ClearAllPoints()
                        dropDownList:SetPoint("TOPRIGHT", self, "TOPLEFT", -20, 0)
                    end
                end
            end
        elseif self.tooltipWhileDisabled then
            if self.tooltipLink then
                Tooltip:SetOwner(self, "ANCHOR_RIGHT")
                Tooltip:SetHyperlink(self.tooltipLink)
            elseif self.tooltipTitle then
                Tooltip:SetOwner(self, "ANCHOR_RIGHT")
                Tooltip:ClearLines()
                Tooltip:AddLine(self.tooltipText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                if self.tooltipInstruction then
                    Tooltip:AddLine(self.tooltipInstruction, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
                end
                if self.tooltipText then
                    Tooltip:AddLine(self.tooltipText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
                                    true)
                end
                if self.tooltipWarning then
                    Tooltip:AddLine(self.tooltipWarning, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
                end
                Tooltip:Show()
            end
        end
    end

    ---@param motion boolean
    function DropDownListButtonMixin:OnEnter(motion)
        DropDownMenu:Close(self.level + 1)
        self:UpdateTooltip()
    end

    ---@param motion boolean
    function DropDownListButtonMixin:OnLeave(motion)
        self.Highlight:Hide()
        Tooltip:Hide()
        if self:IsEnabled() and self.funcOnLeave then self.funcOnLeave(self, self.value, self.arg) end
    end

    ---@param elapsed number
    function DropDownListButtonMixin:OnUpdate(elapsed)
        if not self.updateSpeed then return end
        self.lastUpdate = (self.lastUpdate or 0) + elapsed
        if self.lastUpdate >= self.updateSpeed then self:Update() end
    end

    local DEFAULT_TEX_COORDS = {0, 1, 0, 1}

    function DropDownListButtonMixin:Update()
        self:SetDisabledFontObject("GameFontDisableSmallLeft")
        self:Enable()

        local isDisabled = GetValueOrCallFunction(self, "isDisabled", self.value, self.arg)
        local isNotCheckable = GetValueOrCallFunction(self, "isNotCheckable", self.value, self.arg)

        if self.isNotClickable then
            isDisabled = true
            self:SetDisabledFontObject("GameFontHighlightSmallLeft")
        end
        if self.isTitle then
            isDisabled = true
            isNotCheckable = true
            self:SetDisabledFontObject("GameFontNormalSmallLeft")
        end
        local text = self.Text
        if isDisabled then self:Disable() end
        self.ExpandArrow:SetShown(self.hasArrow)
        local check = self.Check
        local uncheck = self.UnCheck
        if self.isNotRadio then
            check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
            check:SetTexCoord(0.0, 0.5, 0.0, 0.5)
            uncheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
            uncheck:SetTexCoord(0.5, 1.0, 0.0, 0.5)
        else
            check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
            check:SetTexCoord(0.0, 0.5, 0.5, 1.0)
            uncheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
            uncheck:SetTexCoord(0.5, 1.0, 0.5, 1.0)
        end

        text:ClearAllPoints()
        if isNotCheckable then
            text:SetPoint("LEFT", self, "LEFT", 4, 0)
            check:Hide()
            uncheck:Hide()
        else
            text:SetPoint("LEFT", self, "LEFT", 22, 0)
            local isChecked = self.isChecked
            if type(isChecked) == "function" then isChecked = isChecked(self.value, self.arg) end
            if isChecked then
                check:Show()
                uncheck:Hide()
            else
                check:Hide()
                uncheck:Show()
            end
        end
        local icon = self.Icon
        icon:Hide()
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", self, "RIGHT", self.hasArrow and -16 or 0, 0)

        local atlas = GetValueOrCallFunction(self, "iconAtlas", self.value, self.arg)
        local texture = GetValueOrCallFunction(self, "iconTexture", self.value, self.arg)
        if atlas then
            icon:SetAtlas(atlas, false)
            icon:Show()
        elseif texture then
            icon:SetTexture(texture)
            icon:Show()
        end
        icon:SetTexCoord(unpack(GetValueOrCallFunction(self, "iconTexCoords", self.value, self.arg) or
                                    DEFAULT_TEX_COORDS))
        if self.iconWidth and self.iconWidth == -1 then
            icon:SetPoint("LEFT", self, "LEFT", 0, 0)
        else
            icon:SetWidth(self.iconWidth or 16)
        end
        if self.iconHeight and self.iconHeight == -1 then
            icon:SetPoint("TOP", self, "TOP", 0, 0)
            icon:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
        else
            icon:SetHeight(self.iconHeight or 16)
        end
        local textColor = GetValueOrCallFunction(self, "textColor", self.value, self.arg)
        if textColor then
            text:SetText(not self.iconOnly and
                             textColor:WrapTextInColorCode(
                                 GetValueOrCallFunction(self, "text", self.value, self.arg) or "") or "")
        else
            text:SetText(not self.iconOnly and GetValueOrCallFunction(self, "text", self.value, self.arg) or "")
        end

        self.lastUpdate = 0
    end

    ---@param info MenuInfo
    ---@param level number
    function DropDownListButtonMixin:SetInfo(info, level)
        self.level = level

        self.arg = info.arg
        self.func = info.func
        self.funcOnEnter = info.funcOnEnter
        self.funcOnLeave = info.funcOnLeave
        self.hasArrow = info.hasArrow
        self.iconAtlas = info.iconAtlas
        self.iconHeight = info.iconHeight
        self.iconOnly = info.iconOnly
        self.iconTexture = info.iconTexture
        self.iconTexCoords = info.iconTexCoords
        self.iconWidth = info.iconWidth
        self.isChecked = info.isChecked
        self.isDisabled = info.isDisabled
        self.initFunc = info.initFunc
        self.isNotCheckable = info.isNotCheckable
        self.isNotClickable = info.isNotClickable
        self.isNotRadio = info.isNotRadio
        self.isTitle = info.isTitle
        self.keepShownOnClick = info.keepShownOnClick
        self.menu = info.menu
        self.noPlaySound = info.noPlaySound
        self.text = info.text
        self.textColor = info.textColor
        self.tooltipInstruction = info.tooltipInstruction
        self.tooltipLink = info.tooltipLink
        self.tooltipText = info.tooltipText
        self.tooltipTitle = info.tooltipTitle
        self.tooltipWarning = info.tooltipWarning
        self.tooltipWhileDisabled = info.tooltipWhileDisabled
        self.updateSpeed = info.updateSpeed
        self.value = info.value

        self:Update()
    end

    ---@return number
    function DropDownListButtonMixin:GetPreferredWidth()
        local width = self:GetTextWidth() + 40
        if self.hasArrow then width = width + 10 end
        if self.isNotCheckable then width = width - 30 end
        if self.Icon:IsShown() then width = width + 20 end
        return width
    end
end

---@param self Button
local function initDropDownMenuButton(self)
    Mixin(self, DropDownListButtonMixin)
    self:OnLoad() ---@diagnostic disable-line
end

---@class DropDownList : ScrollFrame
---@field level? number
---@field GetVerticalScroll fun(self:DropDownList):number
---@field GetVerticalScrollRange fun(self:DropDownList):number
---@field SetScrollChild fun(self:DropDownList, scrollChild:Frame)
---@field SetVerticalScroll fun(self:DropDownList, offset:number)
local DropDownListMixin = {}
do -- DropDownList
    function DropDownListMixin:OnLoad()
        self:SetSize(1, 1)
        self:SetIgnoreParentScale(true)
        self:SetIgnoreParentAlpha(true)

        self.Backdrop = CreateFrame("Frame", nil, self, "DialogBorderDarkTemplate")
        self.Backdrop:SetPoint("TOPLEFT", self, "TOPLEFT", -15, 15)
        self.Backdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 15, -15)

        self.MenuBackdrop = CreateFrame("Frame", nil, self, "TooltipBackdropTemplate")
        self.MenuBackdrop:SetPoint("TOPLEFT", self, "TOPLEFT", -15, 15)
        self.MenuBackdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 15, -15)
        self.MenuBackdrop:SetFrameLevel(self.MenuBackdrop:GetFrameLevel() - 1)

        self.ScrollChild = CreateFrame("Frame", nil, self)
        self:SetScrollChild(self.ScrollChild)

        self.ButtonPool = CreateFramePool("Button", self.ScrollChild, nil, nil, false, initDropDownMenuButton)

        self:SetScript("OnShow", self.OnShow)
        self:SetScript("OnHide", self.OnHide)
        self:SetScript("OnUpdate", self.OnUpdate)
        self:SetScript("OnMouseWheel", self.OnMouseWheel)

        self:SetClampedToScreen(true)
        self:SetClampRectInsets(-20, -20, -20, -20)
    end

    function DropDownListMixin:OnShow()
        self:SetVerticalScroll(0)
        self.refreshSize = true
    end

    function DropDownListMixin:OnHide() self.ButtonPool:ReleaseAll() end

    ---@param elapsed number
    function DropDownListMixin:OnUpdate(elapsed) if self.refreshSize then self:RefreshSize() end end

    ---@param delta number
    function DropDownListMixin:OnMouseWheel(delta)
        self:SetVerticalScroll(max(0, min(self:GetVerticalScroll() - (delta * (IsModifierKeyDown() and 30 or 10)),
                                          self:GetVerticalScrollRange())))
    end

    ---@param displayMode? '"MENU"'
    function DropDownListMixin:SetDisplayMode(displayMode)
        if displayMode == "MENU" then
            self.Backdrop:Hide()
            self.MenuBackdrop:Show()
        else
            self.Backdrop:Show()
            self.MenuBackdrop:Hide()
        end
    end

    ---@return number
    function DropDownListMixin:GetMaxButtonWidth()
        local maxWidth = 0
        for button in self.ButtonPool:EnumerateActive() do maxWidth = max(maxWidth, button:GetPreferredWidth()) end
        return maxWidth
    end

    function DropDownListMixin:RefreshSize()
        local width = self:GetMaxButtonWidth() + 25
        local height = self.ButtonPool:GetNumActive() * 16
        self.ScrollChild:SetSize(width, height)
        self:SetSize(width, min(height, GetScreenHeight() * 0.5))

        for button in self.ButtonPool:EnumerateActive() do button:SetWidth(width) end

        self.refreshSize = false
    end

    ---@param info MenuInfo
    function DropDownListMixin:AddButton(info)
        ---@type DropDownListButton
        local button = self.ButtonPool:Acquire()
        button:SetInfo(info, self.level)
        button:Show()
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.ScrollChild, "TOPLEFT", 0, -((self.ButtonPool:GetNumActive() - 1) * 16))

        self.refreshSize = true
    end
end

local dropDownListPool = CreateFramePool("ScrollFrame", UIParent, nil, nil, false, --
---@param self ScrollFrame
function(self) Mixin(self, DropDownListMixin):OnLoad() end)

---@param level number
---@return DropDownList|nil
function dropDownListPool:GetFromLevel(level)
    ---@type DropDownList
    for dropDownList in self:EnumerateActive() do if dropDownList.level == level then return dropDownList end end
end

---@return MenuInfo
function DropDownMenu:CreateInfo()
    ---@class MenuInfo
    ---@field arg? any
    ---@field func? fun(isChecked: boolean, value: any, arg: any)
    ---@field funcOnEnter? fun(self: DropDownListButton, value: any, arg: any)
    ---@field funcOnLeave? fun(self: DropDownListButton, value: any, arg: any)
    ---@field hasArrow? boolean
    ---@field iconAtlas? string|fun(value: any, arg: any):string
    ---@field iconHeight? number -1 to expand
    ---@field iconOnly? boolean
    ---@field iconTexture? number|string|fun(value: any, arg: any):number|string
    ---@field iconTexCoords? number[]|fun(value: any, arg: any):number[]
    ---@field iconWidth? number -1 to epxand
    ---@field isChecked? boolean|fun(value: any, arg: any):boolean
    ---@field isDisabled? boolean
    ---@field initFunc? DropDownInitFunc
    ---@field isNotCheckable? boolean
    ---@field isNotClickable? boolean
    ---@field isNotRadio? boolean
    ---@field isTitle? boolean
    ---@field keepShownOnClick? boolean
    ---@field menu? MenuInfo[]|fun(value: any, arg: any):MenuInfo[]
    ---@field noPlaySound? boolean
    ---@field text? string|fun(value: any, arg: any):string
    ---@field textColor? ColorMixin|fun(value: any, arg: any):ColorMixin
    ---@field tooltipInstruction? string
    ---@field tooltipLink? string
    ---@field tooltipText? string
    ---@field tooltipTitle? string
    ---@field tooltipWarning? string
    ---@field tooltipWhileDisabled? boolean
    ---@field updateSpeed? number
    ---@field value? any
    return {}
end

---@param level? number
---@param info MenuInfo
---@param wipeInfo? boolean
function DropDownMenu:AddButton(level, info, wipeInfo)
    level = getNumber(level, 1, 1, dropDownListPool:GetNumActive())
    --[[ assert(type(info) == "table") ]]

    local dropDownList = dropDownListPool:GetFromLevel(level)
    if dropDownList then dropDownList:AddButton(info) end
    if wipeInfo then wipe(info) end
end

---@return MenuInfo
function DropDownMenu:GetSeparatorInfo()
    return {
        hasArrow = false,
        iconHeight = 8,
        iconOnly = true,
        iconTexture = "Interface\\Common\\UI-TooltipDivider-Transparent",
        iconWidth = -1,
        isTitle = true,
    }
end

---@param level? number
---@param info? MenuInfo
function DropDownMenu:AddSeparator(level, info)
    info = info and wipe(info) or {}

    info.hasArrow = false
    info.iconHeight = 8
    info.iconOnly = true
    info.iconTexture = "Interface\\Common\\UI-TooltipDivider-Transparent"
    info.iconWidth = -1
    info.isTitle = true

    self:AddButton(level, info)
    wipe(info)
end

---@return number
local function getUIScale()
    if C_CVar.GetCVar("useUIScale") == "1" then ---@diagnostic disable-line 
        return min(UIParent:GetScale(), tonumber(C_CVar.GetCVar("uiscale"))) ---@diagnostic disable-line
    else
        return UIParent:GetScale()
    end
end

---@param level? number
---@param value any
---@param owner any
---@param init DropDownInitFunc
---@param point FramePoint
---@param relativeTo? Region|string
---@param relativePoint FramePoint
---@param xOffset number
---@param yOffset number
---@return DropDownList|nil
function DropDownMenu:Open(level, value, owner, init, point, relativeTo, relativePoint, xOffset, yOffset)
    ---@type DropDownList
    local dropDownList = dropDownListPool:Acquire()
    dropDownList.level = level
    dropDownList:SetScale(getUIScale())
    dropDownList:SetDisplayMode(owner.displayMode)
    init(owner, level, value)
    if dropDownList.ButtonPool:GetNumActive() > 0 then
        dropDownList:SetParent(owner)
        dropDownList:SetFrameStrata("FULLSCREEN_DIALOG")
        dropDownList:ClearAllPoints()
        dropDownList:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
        dropDownList:Show()
        return dropDownList
    else
        dropDownListPool:Release(dropDownList)
    end
end

---@param xOffset number
---@param yOffset number
local function getCursorPoint(xOffset, yOffset)
    local uiScale = getUIScale()
    local cursorX, cursorY = GetCursorPosition()
    return "BOTTOMLEFT", nil, "BOTTOMLEFT", (xOffset or 0) + (cursorX / uiScale), (yOffset or 0) + (cursorY / uiScale)
end

---@param level? number
---@param value any
---@param owner any
---@param initFun function
---@param point? FramePoint|'"curosr"'
---@param relativeTo? Region|string
---@param relativePoint? FramePoint
---@param xOffset? number
---@param yOffset? number
function DropDownMenu:Toggle(level, value, owner, initFun, point, relativeTo, relativePoint, xOffset, yOffset)
    level = getNumber(level, 1, 1)
    initFunc = initFunc or owner.InitDropDown
    xOffset = getNumber(xOffset, 0)
    yOffset = getNumber(yOffset, 0)

    if owner == openMenu then
        self:Close(1)
    else
        if level == 1 then self:Close(1) end
        local uiScale = getUIScale()
        if point and point == "curosr" then
            point, relativeTo, relativePoint, xOffset, yOffset = getCursorPoint(xOffset, yOffset)
            point = "TOPLEFT"
        end
        point = point or "TOPLEFT"
        local dropDownList = self:Open(level, value, owner, initFun, point, relativeTo, relativePoint or "BOTTOMLEFT",
                                       xOffset, yOffset)
        if dropDownList then
            openMenu = owner
            initFunc = initFun

            dropDownList:RefreshSize()

            point, relativeTo, relativePoint, xOffset, yOffset = dropDownList:GetPoint() ---@diagnostic disable-line
            local offLeft = dropDownList:GetLeft() / uiScale
            local offRight = (GetScreenWidth() - dropDownList:GetRight()) / uiScale
            local offTop = (GetScreenHeight() - dropDownList:GetTop()) / uiScale
            local offBottom = dropDownList:GetBottom() / uiScale

            local xAddOffset = 0
            local yAddOffset = 0
            if offLeft < 0 then
                xAddOffset = -offLeft
            elseif offRight < 0 then
                xAddOffset = offRight
            end

            if offTop < 0 then
                yAddOffset = offTop
            elseif offBottom < 0 then
                yAddOffset = -offBottom
            end

            dropDownList:ClearAllPoints()
            dropDownList:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset)
        else
            initFunc = nop
            openMenu = nil
        end
    end
end

---@param menuList MenuInfo[]
---@param owner any
---@param point? FramePoint|'"curosr"'
---@param relativeTo? Region
---@param relativePoint? FramePoint
---@param xOffset? number
---@param yOffset? number
function DropDownMenu:EasyMenu(menuList, owner, point, relativeTo, relativePoint, xOffset, yOffset)
    --[[ assert(type(menuList) == "table") ]]
    self:Toggle(1, nil, owner, --
    ---@param o any
    ---@param l number
    ---@param v any
    function(o, l, v)
        for i = 1, #menuList, 1 do
            local menuInfo = menuList[i]
            if menuInfo then self:AddButton(l, menuInfo) end
        end
    end, point, relativeTo, relativePoint, xOffset, yOffset)
end

---@param level? number
function DropDownMenu:Close(level)
    level = getNumber(level, 1, 1)
    ---@type DropDownList
    for dropDownList in dropDownListPool:EnumerateActive() do
        if dropDownList.level >= level then dropDownListPool:Release(dropDownList) end
    end
    if level == 1 then
        initFunc = nop
        openMenu = nil
    end
end

---@class DropDownToggleButton : Button
local DropDownToggleButtonMixin = {}
do -- DropDownToggleButton
    function DropDownToggleButtonMixin:OnLoad()
        self:RegisterForMouse("LeftButtonDown", "LeftButtonUp") ---@diagnostic disable-line
    end

    ---@param button string
    ---@param event WowEvent
    function DropDownToggleButtonMixin:HandlesGlobalMouseEvent(button, event)
        return event == "GLOBAL_MOUSE_DOWN" and button == "LeftButton"
    end
end

---@class DropDownMenuButton : Button
---@field point? FramePoint
---@field relativeTo? Region|string
---@field relativePoint? FramePoint
---@field xOffset? number
---@field yOffset? number
---@field InitFunc? function
---@field displayMode? '"MENU"'
local DropDownMenuButtonMixin = {}
DropDownMenu.DropDownMenuButtonMixin = DropDownMenuButtonMixin
do -- DropDownMenuButton
    function DropDownMenuButtonMixin:OnLoad()
        DropDownToggleButtonMixin.OnLoad(self)

        self:SetScript("OnEnter", self.OnEnter)
        self:SetScript("OnLeave", self.OnLeave)
        self:SetScript("OnMouseDown", self.OnMouseDown)
    end

    ---@param motion boolean
    function DropDownMenuButtonMixin:OnEnter(motion)
        local parent = self:GetParent()
        local script = parent and parent.GetScript and parent:GetScript("OnEnter") ---@diagnostic disable-line
        if script then script(parent, motion) end
    end

    ---@param motion boolean
    function DropDownMenuButtonMixin:OnLeave(motion)
        local parent = self:GetParent()
        local script = parent and parent.GetScript and parent:GetScript("OnLeave") ---@diagnostic disable-line
        if script then script(parent, motion) end
    end

    ---@param button string
    function DropDownMenuButtonMixin:OnMouseDown(button)
        if self:IsEnabled() then
            local f = self.InitFunc
            if f then
                DropDownMenu:Toggle(1, nil, self, f, self.point or "curosr", self.relativeTo, self.relativePoint,
                                    self.xOffset or 8, self.yOffset or -22)
            end
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
    end
end

---@class DropDownMenuFrame : Frame
---@field InitFunc? function
local DropDownMenuMixin = {}
do -- DropDownMenuFrame
    ---@param self Frame
    ---@param motion boolean
    local function TextFrame_OnEnter(self, motion)
        self:UpdateTooltip() ---@diagnostic disable-line
    end

    ---@param self Frame
    ---@param motion boolean
    local function TextFrame_OnLeave(self, motion) Tooltip:Hide() end

    ---@param self Frame
    local function TextFrame_UpdateTooltip(self)
        local text = self.Text ---@diagnostic disable-line
        if text and (text:IsTruncated() or text.tooltipForce) then
            Tooltip:SetOwner(self, "ANCHOR_CURSOR")
            if text.tooltipTitle then
                Tooltip:ClearLines()
                Tooltip:AddLine(text.tooltipTitle, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                                HIGHLIGHT_FONT_COLOR.b)
            end
            local tooltipText = text.tooltipText or text:GetText()
            local color = text.tooltipTextColor or NORMAL_FONT_COLOR
            if type(tooltipText) == "table" then
                for i = 1, #tooltipText, 1 do
                    Tooltip:AddLine(tooltipText[i], color.r, color.g, color.b, text.tooltipWrap)
                end
            else
                Tooltip:AddLine(tooltipText, color.r, color.g, color.b, text.tooltipWrap)
            end
            Tooltip:Show()
        else
            Tooltip:Hide()
        end
    end

    function DropDownMenuMixin:OnLoad()
        self:SetHeight(32)

        ---@type Texture
        self.Left = self:CreateTexture(nil, "ARTWORK")
        self.Left:SetSize(25, 64)
        self.Left:SetPoint("RIGHT", self, "LEFT", 0, 0)
        self.Left:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
        self.Left:SetTexCoord(0, 0.1953125, 0, 1)

        ---@type Texture
        self.Middle = self:CreateTexture(nil, "ARTWORK")
        self.Middle:SetHeight(64)
        self.Middle:SetPoint("LEFT", self, "LEFT", 0, 0)
        self.Middle:SetPoint("RIGHT", self, "RIGHT", 0, 0)
        self.Middle:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
        self.Middle:SetTexCoord(0.1953125, 0.8046875, 0, 1)

        ---@type Texture
        self.Right = self:CreateTexture(nil, "ARTWORK")
        self.Right:SetSize(25, 64)
        self.Right:SetPoint("LEFT", self, "RIGHT", 0, 0)
        self.Right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
        self.Right:SetTexCoord(0.8046875, 1, 0, 1)

        ---@type DropDownMenuButton
        self.Button = Mixin(CreateFrame("Button", nil, self), DropDownMenuButtonMixin) ---@diagnostic disable-line
        self.Button:SetMotionScriptsWhileDisabled(true)
        self.Button:SetSize(24, 24)
        self.Button:SetPoint("RIGHT", self, "RIGHT", 9, 1)
        self.Button:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        self.Button:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
        self.Button:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
        self.Button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        self.Button.point = "TOPLEFT"
        self.Button.relativeTo = self
        self.Button.relativePoint = "BOTTOMLEFT"
        self.Button.xOffset = 0
        self.Button.yOffset = -7
        ---@param owner Region
        ---@param level number
        self.Button.InitFunc = function(owner, level)
            if self.InitFunc then
                self:InitFunc(level) ---@diagnostic disable-line
            end
        end

        ---@class DropdownMenuText : FontString
        self.Text = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallLeft")
        self.Text:SetWordWrap(false) ---@diagnostic disable-line
        self.Text:SetJustifyH("LEFT")
        self.Text:SetJustifyV("MIDDLE")
        self.Text:SetHeight(10)
        self.Text:SetPoint("TOPLEFT", self, "TOPLEFT", 2, 0)
        self.Text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -15, 0)

        ---@class DropdownMenuTextFrame : Frame
        self.Text.Frame = CreateFrame("Frame", nil, self)
        self.Text.Frame:SetPoint("TOPLEFT", self.Text, "TOPLEFT", 0, 0)
        self.Text.Frame:SetPoint("BOTTOMRIGHT", self.Text, "BOTTOMRIGHT", 0, 0)
        self.Text.Frame.Text = self.Text
        self.Text.Frame.UpdateTooltip = TextFrame_UpdateTooltip
        self.Text.Frame:SetScript("OnEnter", TextFrame_OnEnter)
        self.Text.Frame:SetScript("OnLeave", TextFrame_OnLeave)
    end

    ---@return string
    function DropDownMenuMixin:GetText()
        return self.Text:GetText() ---@diagnostic disable-line
    end

    ---@param text string
    function DropDownMenuMixin:SetText(text) self.Text:SetText(text) end

    ---@param format string
    ---@param ... any
    function DropDownMenuMixin:SetFormattedText(format, ...)
        self.Text:SetFormattedText(format, ...) ---@diagnostic disable-line
    end

    ---@param displayMode? '"MENU"'
    function DropDownMenuMixin:SetDisplayMode(displayMode)
        if displayMode == "MENU" then
            self.displayMode = displayMode

            self.Left:Hide()
            self.Middle:Hide()
            self.Right:Hide()

            local button = self.Button
            button:SetNormalTexture(nil)
            button:SetPushedTexture(nil)
            button:SetDisabledTexture(nil)
            button:SetHighlightTexture(nil)

            local text = self.Text
            button:ClearAllPoints()
            button:SetPoint("LEFT", text, "LEFT", -9, 0)
            button:SetPoint("RIGHT", text, "RIGHT", 6, 0)
        end
    end

    ---@param enabledFlag boolean
    function DropDownMenuMixin:SetEnabled(enabledFlag)
        self.Button:SetEnabled(enabledFlag)
        self.Text:SetFontObject(enabledFlag and "GameFontHighlightSmallLeft" or "GameFontDisableSmallLeft")
    end
end

hooksecurefunc(_G, "UIDropDownMenu_HandleGlobalMouseEvent", -- 
---@param button string
---@param event WowEvent
function(button, event)
    if event == "GLOBAL_MOUSE_DOWN" and (button == "LeftButton" or button == "RightButton") then
        for dropDownList in dropDownListPool:EnumerateActive() do if dropDownList:IsMouseOver() then return end end
        DropDownMenu:Close(1)
    end
end)
