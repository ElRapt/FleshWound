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
            local FleshWoundFrame = CreateFrame("Frame", "FleshWoundFrame", UIParent, "BackdropTemplate")
            FleshWoundFrame:SetPoint("CENTER")
            addonTable.FleshWoundFrame = FleshWoundFrame  -- Store in addonTable

            -- Call the OnLoad function from FleshWound_GUI.lua
            if FleshWound_OnLoad then
                FleshWound_OnLoad(FleshWoundFrame)
            else
                print("FleshWound_OnLoad function not found in FleshWound_GUI.lua")
            end

            -- Unregister the event after it's handled
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnEvent)
