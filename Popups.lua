---@class AddOn
local AddOn = select(2, ...)

local L = AddOn.L

StaticPopupDialogs[AddOn.NAME .. "_DELETE_SEGMENT"] = {
    text = L.ARE_YOU_SURE_TO_DELETE_THE_SEGMENT,
    button1 = L.YES,
    button2 = L.NO,
    ---@param data Segment
    OnAccept = function(dialog, data) AddOn.DeleteSegment(data) end,
    hideOnEscape = true,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs[AddOn.NAME .. "_DELETE_ALL_SEGMENT"] = {
    text = L.ARE_YOU_SURE_TO_DELETE_ALL_SEGMENTS,
    button1 = L.YES,
    button2 = L.NO,
    OnAccept = function(dialog, data) AddOn.DeleteAllSegments() end,
    hideOnEscape = true,
    timeout = 0,
    whileDead = true,
}

