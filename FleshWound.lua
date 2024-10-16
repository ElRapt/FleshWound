-- FleshWound.lua

local addonName, addonTable = ...

-- Create a frame to handle events
local eventFrame = CreateFrame("Frame")

-- Event handler function
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            -- Initialize SavedVariables
            if not FleshWoundData then
                FleshWoundData = {}
            end
            addonTable.woundData = FleshWoundData

            -- Initialize the main frame
            FleshWoundFrame = CreateFrame("Frame", "FleshWoundFrame", UIParent, "BackdropTemplate")
            FleshWoundFrame:SetPoint("CENTER")

            -- Call the OnLoad function, passing in FleshWoundFrame
            FleshWound_OnLoad(FleshWoundFrame)

            -- Unregister the event after it's handled
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnEvent)
