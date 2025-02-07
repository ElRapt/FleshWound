-- FleshWound_Utils.lua
-- Utility/helper functions for the FleshWound addon.
-- (Incorporates a standardized print function and a draggable-frame helper.)

local addonName, addonTable = ...

local Utils = {}
addonTable.Utils = Utils

-- A colorized prefix for all chat prints.
local prefixColor = "|cFF00FF00FleshWound:|r "



--- Returns the version of the addon as a string.
--- @return string: The version of the addon.
function Utils.GetAddonVersion()
    local version = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
    return version or "0.0.0"
end


--- Prints a message to the chat frame.
--- @param msg string: The message to print.
--- @param isError boolean: If true, the message is printed in red to the UIErrorsFrame.
function Utils.FW_Print(msg, isError)
    if isError then
        UIErrorsFrame:AddMessage(prefixColor .. msg, 1.0, 0.0, 0.0, 5)
    else
        print(prefixColor .. msg)
    end
end

--- Helper function to make a frame draggable.
--- @param frame table: The frame to make draggable.
--- @param onStopCallback function: An optional callback function to call when dragging stops.
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
