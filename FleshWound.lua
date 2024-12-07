-- FleshWound.lua
-- Main addon file that initializes the addon and handles events

local addonName, addonTable = ...

local L = addonTable.L


-- Create an Event Handler Module
local EventHandler = {}
addonTable.EventHandler = EventHandler  -- Expose to addonTable

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

        -- Initialize Comm Module
        if addonTable.Comm and addonTable.Comm.Initialize then
            addonTable.Comm:Initialize()
        end

        -- Unregister the event after it's handled
        self.eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end


function addonTable:OpenReceivedProfile(profileName, profileData)
    local originalProfile = addonTable.FleshWoundData.currentProfile
    local originalWoundData = addonTable.woundData

    addonTable.woundData = profileData.woundData

    if addonTable.GUI and addonTable.GUI.UpdateRegionColors then
        addonTable.GUI:UpdateRegionColors()
    end
    if addonTable.GUI and addonTable.GUI.frame then
        addonTable.GUI.frame:Show()
    end

    if addonTable.GUI then
        addonTable.GUI.originalProfile = originalProfile
        addonTable.GUI.originalWoundData = originalWoundData
        addonTable.GUI.currentTemporaryProfile = profileName

        -- Update and show the banner (already implemented previously)
        if addonTable.GUI.tempProfileBannerFrame and addonTable.GUI.tempProfileBanner then
            addonTable.GUI.tempProfileBanner:SetText(format(addonTable.L["Viewing %s's Profile"], profileName))
            addonTable.GUI.tempProfileBannerFrame:Show()
        end

        -- Hide the profile button when viewing another player's profile
        if addonTable.GUI.frame and addonTable.GUI.frame.ProfileButton then
            addonTable.GUI.frame.ProfileButton:Hide()
        end
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
