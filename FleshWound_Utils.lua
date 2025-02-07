-- FleshWound_Utils.lua
-- Utility/helper functions for the FleshWound addon.
-- (Incorporates a standardized print function and a draggable-frame helper.)

local addonName, addonTable = ...

local Utils = {}
addonTable.Utils = Utils

-- A colorized prefix for all chat prints.
local prefixColor = "|cFF00FF00FleshWound:|r "

--[[---------------------------------------------------------------------------
    Returns the version of the addon as a string.
    If the version is not found, returns "0.0.0".
---------------------------------------------------------------------------]]--

function Utils.GetAddonVersion()
    local version = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
    return version or "0.0.0"
end


--[[---------------------------------------------------------------------------
    Prints a message to the chat window with a uniform prefix.
    Pass `isError = true` to also show in UIErrorsFrame in red.
---------------------------------------------------------------------------]]--
function Utils.FW_Print(msg, isError)
    if isError then
        UIErrorsFrame:AddMessage(prefixColor .. msg, 1.0, 0.0, 0.0, 5)
    else
        print(prefixColor .. msg)
    end
end

--[[---------------------------------------------------------------------------
    Helper to make a frame draggable. If you pass onStopCallback,
    it will be called after the user stops dragging.
---------------------------------------------------------------------------]]--
function Utils.MakeFrameDraggable(frame, onStopCallback)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(f)
        f:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if onStopCallback then
            onStopCallback(f)
        end
    end)
end
