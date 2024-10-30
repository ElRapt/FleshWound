-- FleshWound.lua
-- Main addon file that initializes the addon and handles events

local addonName, addonTable = ...

-- Create an Event Handler Module
local EventHandler = {}
addonTable.EventHandler = EventHandler  -- Expose to addonTable

-- Handle ADDON_LOADED event
function EventHandler:OnAddonLoaded(name)
    if name == addonName then
        -- Initialize SavedVariables
        if not FleshWoundData then
            FleshWoundData = {}
        end

        -- Store the FleshWoundData in addonTable for access in other files
        addonTable.FleshWoundData = FleshWoundData

        -- Initialize Data Module
        if addonTable.Data and addonTable.Data.Initialize then
            addonTable.Data:Initialize()
        else
            print("Data module not found or does not have an Initialize method.")
        end

        -- Initialize GUI Module
        if addonTable.GUI and addonTable.GUI.Initialize then
            addonTable.GUI:Initialize()
        else
            print("GUI module not found or does not have an Initialize method.")
        end

        -- Unregister the event after it's handled
        self.eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end

-- Create the event frame and set scripts
EventHandler.eventFrame = CreateFrame("Frame")
EventHandler.eventFrame:RegisterEvent("ADDON_LOADED")
EventHandler.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        EventHandler:OnAddonLoaded(...)
    end
end)
