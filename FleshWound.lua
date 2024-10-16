-- FleshWound.lua
-- Main addon file

local addonName, addonTable = ...
addonTable.addonVersion = "1.0.0"

-- Create the main frame for the addon
local FleshWoundFrame = CreateFrame("Frame", "FleshWoundFrame", UIParent, "BackdropTemplate")
addonTable.FleshWoundFrame = FleshWoundFrame

-- Frame drag functions
function FleshWoundFrame_OnDragStart(self)
    self:StartMoving()
end

function FleshWoundFrame_OnDragStop(self)
    self:StopMovingOrSizing()
end

-- Initialize the frame
FleshWoundFrame:SetPoint("CENTER")
FleshWoundFrame:EnableMouse(true)
FleshWoundFrame:SetMovable(true)
FleshWoundFrame:SetScript("OnMouseDown", FleshWoundFrame_OnDragStart)
FleshWoundFrame:SetScript("OnMouseUp", FleshWoundFrame_OnDragStop)

-- Event handler function
local function OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        FleshWound_OnLoad(self)
        self:UnregisterEvent("ADDON_LOADED")
    end
end

FleshWoundFrame:RegisterEvent("ADDON_LOADED")
FleshWoundFrame:SetScript("OnEvent", OnEvent)
