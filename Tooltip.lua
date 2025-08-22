---@class AddOn
local AddOn = (select(2, ...))

local L = AddOn.L

local DEFAULT_COLOR = AddOn.DEFAULT_COLOR
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local ROLE_COLORS = setmetatable({
    DAMAGER = CreateColor(1, 0.5, 0),
    HEALER = CreateColor(0.3, 1, 0.3),
    NONE = CreateColor(0.5, 0.5, 0.5),
    TANK = CreateColor(0, 1, 1),
}, {
    ---@param t table<string, ColorMixin>
    ---@param k string
    ---@return ColorMixin
    __index = function(t, k)
        local v = DEFAULT_COLOR
        t[k] = v
        return v
    end,
})
local ROLE_ICONS = setmetatable({
    DAMAGER = " |TInterface\\LFGFrame\\LFGROLE.blp:16:16:0:0:64:16:16:32:0:16|t",
    HEALER = " |TInterface\\LFGFrame\\LFGROLE.blp:16:16:0:0:64:16:48:64:0:16|t",
    NONE = " |TInterface\\SpellShadow\\Spell-Shadow-Unacceptable:0|t",
    TANK = " |TInterface\\LFGFrame\\LFGROLE.blp:16:16:0:0:64:16:32:48:0:16|t",
}, {
    ---@param t table<string, string>
    ---@param k string
    ---@return string
    __index = function(t, k)
        local v = " |TInterface\\SpellShadow\\Spell-Shadow-Unacceptable:0|t"
        t[k] = v
        return v
    end,
})

local type = type

---@class Tooltip : GameTooltip
---@field lastUpdate? number
local Tooltip = CreateFrame("GameTooltip", (...) .. "Tooltip", UIParent, "GameTooltipTemplate") ---@diagnostic disable-line:assign-type-mismatch
AddOn.Tooltip = Tooltip

SharedTooltip_SetBackdropStyle(Tooltip, {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileEdge = true,
    tileSize = 8,
    edgeSize = 8,
    insets = {left = 2, right = 2, top = 2, bottom = 2},

    backdropBorderColor = CreateColor(0.8, 0.8, 0.8, 0.8),
    backdropColor = CreateColor(0, 0, 0, 0.8),
})

Tooltip.updateTooltipTimer = TOOLTIP_UPDATE_TIME

Tooltip:SetScript("OnShow", GameTooltip_CalculatePadding)
Tooltip:SetScript("OnUpdate", --
---@param self Tooltip
---@param elapsed number
function(self, elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + 1
    if self.lastUpdate >= 10 then
        local owner = self:GetOwner()
        if owner and owner.UpdateTooltip then owner:UpdateTooltip() end
        self.lastUpdate = 0
    end
end)

do -- SetTitle
    local r, g, b = HIGHLIGHT_FONT_COLOR:GetRGB()

    ---@param text string
    function Tooltip:SetTitle(text)
        self:ClearLines()
        self:AddLine(text, r, g, b)
    end
end

---@param numLines? number
function Tooltip:AddBlankLines(numLines) for i = 1, numLines or 1, 1 do self:AddLine(" ") end end

local doesSpellExist = C_Spell.DoesSpellExist

---@param spellIdOrName number|string
function Tooltip:SetSpell(spellIdOrName)
    if type(spellIdOrName) == "number" and doesSpellExist(spellIdOrName) then
        self:SetHyperlink("spell:" .. spellIdOrName)
    else
        self:SetTitle(L[spellIdOrName])
    end
end

local guidIsPlayer = C_PlayerInfo.GUIDIsPlayer

---@param guidOrName string
---@param playerInfo? PlayerInfo
function Tooltip:SetPlayerOrName(guidOrName, playerInfo)
    if guidIsPlayer(guidOrName) then
        if self:SetHyperlink("unit:" .. guidOrName) and playerInfo then
            local leftR, leftG, leftB = HIGHLIGHT_FONT_COLOR:GetRGB()
            local avgItemLevel = playerInfo.avgItemLevel
            local role = playerInfo.role
            local specID = playerInfo.specID

            self:AddBlankLines(((avgItemLevel and avgItemLevel > 0) or role or specID) and 1 or 0)

            if avgItemLevel and avgItemLevel > 0 then
                self:AddDoubleLine(L.ITEM_LEVEL, format("%.2f", playerInfo.avgItemLevel), leftR, leftG, leftB, leftR,
                                   leftG, leftB)
            end
            if role then
                local rightR, rightG, rightB = ROLE_COLORS[role]:GetRGB()
                self:AddDoubleLine(L.ROLE, L[role] .. ROLE_ICONS[role], leftR, leftG, leftB, rightR, rightG, rightB)
            end
            if specID then
                local id, name, description, icon, role, classFile, className = GetSpecializationInfoByID(specID)
                if name and icon then
                    self:AddDoubleLine(L.SPECIALIZATION, format("%s |T%s:0|t", name, icon), leftR, leftG, leftB, leftR,
                                       leftG, leftB)
                end
            end
        end
    else
        self:SetTitle(guidOrName)
    end
end

---@param leftText string|number
---@param rightText string|number
---@param leftColor ColorMixin
---@param rightColor? ColorMixin
function Tooltip:AddColoredDoubleLine(leftText, rightText, leftColor, rightColor)
    local leftR, leftG, leftB = leftColor:GetRGB()
    local rightR, rightG, rightB = (rightColor and rightColor or leftColor):GetRGB()
    self:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB)
end

do -- AddInstructionLine
    local r, g, b = GREEN_FONT_COLOR:GetRGB()

    ---@param text string
    function Tooltip:AddInstructionLine(text) self:AddLine(text, r, g, b) end
end

do
    local AppendTextToTexture = AddOn.AppendTextToTexture
    local FormatNumber = AddOn.FormatNumber
    local FormatPercentage = AddOn.FormatPercentage
    local GetClassColor = AddOn.GetClassColor
    local GetClassTextureString = AddOn.GetClassTextureString
    local GetDamageClassColor = AddOn.GetDamageClassColor
    local GetPlayerClass = AddOn.GetPlayerClass
    local GetPlayerName = AddOn.GetPlayerName
    local GetSpellIcon = AddOn.GetSpellIcon
    local GetSpellName = AddOn.GetSpellName

    local format = format
    local tSort = table.sort
    local wipe = wipe

    ---@type any[]
    local keys = {}
    ---@type table<any, number>
    local amounts = {}
    ---@type table<any, any>
    local datas = {}

    function Tooltip:WipeData()
        wipe(keys)
        wipe(amounts)
        wipe(datas)
    end

    ---@param key any
    ---@param amount number
    ---@param data any
    function Tooltip:AddAmount(key, amount, data)
        if amount > 0 then
            keys[#keys + 1] = key
            amounts[key] = amount
            datas[key] = data
        end
    end

    ---@param a any
    ---@param b any
    ---@return boolean
    local function comp(a, b) return amounts[a] > amounts[b] end

    ---@param a nil
    ---@param i number
    ---@return number?
    ---@return any?
    ---@return number?
    ---@return any?
    local function iter(a, i)
        i = i + 1
        local v = keys[i]
        if v then return i, v, amounts[v], datas[v] end
    end

    ---@return fun(a: any[], i: number):number?, any?, number?, any?
    ---@return nil
    ---@return number
    function Tooltip:EnumerateData() return iter, nil, 0 end

    ---@param totalAmount number
    function Tooltip:ShowSpellAmounts(totalAmount)
        tSort(keys, comp)
        self:AddBlankLines(1)
        self:AddDoubleLine(L.ABILITY, L.AMOUNT)
        for i, key, amount, data in self:EnumerateData() do
            if i > 3 then break end

            self:AddColoredDoubleLine(AppendTextToTexture(GetSpellName(key), GetSpellIcon(key)),
                                      format("%s (%s)", FormatNumber(amount), FormatPercentage(amount / totalAmount)),
                                      GetDamageClassColor(data.school))
        end
        self:WipeData()
    end

    ---@param title string
    ---@param totalAmount number
    function Tooltip:ProcessUnitAmounts(title, totalAmount)
        tSort(keys, comp)
        self:AddBlankLines(1)
        self:AddDoubleLine(title, L.AMOUNT)
        for i, key, amount, data in self:EnumerateData() do
            if i > 3 then break end

            local class = GetPlayerClass(key) or data.class
            self:AddColoredDoubleLine(format("%s %s", GetClassTextureString(class), GetPlayerName(key)),
                                      format("%s (%s)", FormatNumber(amount), FormatPercentage(amount / totalAmount)),
                                      GetClassColor(class))
        end
        self:WipeData()
    end
end
