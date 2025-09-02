---@class AddOn
local AddOn = select(2, ...)

local savedVars
local savedVarsPerChar

---@return string
local function get() return savedVarsPerChar.profile end
AddOn.GetProfile = get

local function save()
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
    savedVars.profiles[get()] = {parserCache = AddOn.IsCacheEnabled(), windows = windows}
end

---@param name string
local function load(name)
    AddOn.WindowPool:ReleaseAll()

    local profile = savedVars.profiles[name] or {}
    savedVars.profiles[name] = profile

    AddOn.SetCacheEnabled(profile.parserCache)

    local windows = type(profile.windows) == "table" and profile.windows or {}
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

    savedVarsPerChar.profile = name
end

---@return string[]
local function getAll()
    local profiles = {}

    for name, profile in next, savedVars.profiles, nil do profiles[#profiles + 1] = name end
    table.sort(profiles)

    return profiles
end
AddOn.GetProfiles = getAll

---@param name string
local function create(name)
    savedVars.profiles[name] = {}
    AddOn.ProtectedCall(load, name)
end

---@param name string
function AddOn.CreateProfile(name)
    save()
    create(name)
end

---@param name string
local function set(name)
    save()
    savedVarsPerChar.profile = name
    AddOn.ProtectedCall(load, name)
end
AddOn.SetProfile = set

---@param name string
function AddOn.DeleteProfile(name)
    savedVars.profiles[name] = nil

    local profiles = getAll()

    if #profiles <= 0 then
        create(UnitName("player") .. " - " .. GetRealmName())
    else
        load(profiles[1])
    end
end

AddOn.RegisterEvent("ADDON_LOADED", --
---@param addOnName string
---@param containsBindings boolean
function(addOnName, containsBindings)
    if addOnName == AddOn.NAME then
        savedVarsPerChar = type(DamageMeter_SavedVarsPerChar) == "table" and DamageMeter_SavedVarsPerChar or {}
        DamageMeter_SavedVarsPerChar = nil

        local profile = savedVarsPerChar.profile or UnitName("player") .. " - " .. GetRealmName()

        savedVars = type(DamageMeter_SavedVars) == "table" and DamageMeter_SavedVars or {}
        DamageMeter_SavedVars = nil

        savedVars.profiles = type(savedVars.profiles) == "table" and savedVars.profiles or {}
        if type(savedVars.profiles[profile]) ~= "table" then
            create(profile)
        else
            load(profile)
        end

        local segments = type(savedVars.segments) == "table" and savedVars.segments or {}
        for i = 1, #segments, 1 do
            AddOn.Segments[#AddOn.Segments + 1] = setmetatable(segments[i], AddOn.SegmentMeta)
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

    save()

    DamageMeter_SavedVars = {profiles = savedVars.profiles, segments = segments}

    DamageMeter_SavedVarsPerChar = savedVarsPerChar
end)
