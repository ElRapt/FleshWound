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

            -- Migrate old data format to new profiles format
            if FleshWoundData.woundData then
                local defaultProfileName = UnitName("player")
                FleshWoundData.profiles = FleshWoundData.profiles or {}
                FleshWoundData.profiles[defaultProfileName] = { woundData = FleshWoundData.woundData }
                FleshWoundData.currentProfile = defaultProfileName
                FleshWoundData.woundData = nil -- Remove old data
            end

            -- Ensure profiles table exists
            FleshWoundData.profiles = FleshWoundData.profiles or {}

            -- Ensure currentProfile is set
            if not FleshWoundData.currentProfile then
                FleshWoundData.currentProfile = UnitName("player") -- Default profile name is character name
            end

            -- If currentProfile does not exist in profiles, create it
            if not FleshWoundData.profiles[FleshWoundData.currentProfile] then
                FleshWoundData.profiles[FleshWoundData.currentProfile] = { woundData = {} }
            end

            -- Set addonTable.woundData to the woundData of the current profile
            addonTable.woundData = FleshWoundData.profiles[FleshWoundData.currentProfile].woundData

            -- Store the FleshWoundData in addonTable for access in other files
            addonTable.FleshWoundData = FleshWoundData

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
