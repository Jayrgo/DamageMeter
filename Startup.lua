---@class AddOn
local AddOn = (select(2, ...))

AddOn.RegisterEvent("ADDON_LOADED", --
---@param addOnName string
---@param containsBindings boolean
function(addOnName, containsBindings)
    if addOnName == AddOn.NAME then
        local savedVars = type(DamageMeter_SavedVars) == "table" and DamageMeter_SavedVars or {}
        DamageMeter_SavedVars = nil

        AddOn.SetCacheEnabled(savedVars.parserCache)

        local segments = type(savedVars.segments) == "table" and savedVars.segments or {}
        for i = 1, #segments, 1 do
            AddOn.Segments[#AddOn.Segments + 1] = setmetatable(segments[i], AddOn.SegmentMeta)
        end

        local windows = type(savedVars.windows) == "table" and savedVars.windows or {}
        if #windows <= 0 then windows[1] = {} end
        for i = 1, #windows, 1 do
            local window = AddOn.WindowPool:Acquire()

            window:ClearAllPoints()
            local point, relativeTo, relativePoint, xOfs, yOfs
            if type(windows[i].pos) == "table" then
                point, relativeTo, relativePoint, xOfs, yOfs = unpack(windows[i].pos)
            end
            window:SetPoint(point or "CENTER", relativeTo or UIParent, relativePoint or "CENTER", xOfs or 0, yOfs or 0)

            local width, height = unpack(windows[i].size or {})
            window:SetSize(width or AddOn.DEFAULT_WINDOW_WIDTH, height or AddOn.DEFAULT_WINDOW_HEIGHT)

            window:SetMovable(windows[i].isMovable == nil and true or windows[i].isMovable)
            window:SetResizable(windows[i].isResizable == nil and true or windows[i].isResizable)

            window:SetMode(type(windows[i].modeKey) == "string" and windows[i].modeKey or "damageDone", true)
            window:SetFilter(type(windows[i].filter) == "table" and windows[i].filter)

            window:Show()
        end
    end
end)

AddOn.RegisterEvent("ADDONS_UNLOADING", --
---@param closingClient boolean
function(closingClient)
    local segments = {}
    for i = max(1, #AddOn.Segments - AddOn.MAX_SAVED_SEGMENTS), #AddOn.Segments, 1 do
        segments[#segments + 1] = AddOn.Segments[i]
    end

    local windows = {}
    for window in AddOn.WindowPool:EnumerateActive() do
        local point, relativeTo, relativePoint, xOfs, yOfs = window:GetPoint()
        windows[#windows + 1] = {
            pos = {point, relativeTo and relativeTo:GetName(), relativePoint, xOfs, yOfs},
            size = {window:GetSize()},
            isMovable = window:IsMovable(),
            isResizable = window:IsResizable(),
            modeKey = window:GetModeKey(),
            filter = window:GetFilter(),
        }
    end

    DamageMeter_SavedVars = {
        parserCache = AddOn.IsCacheEnabled(),
        segments = segments, --
        windows = windows, --
    }
end)
