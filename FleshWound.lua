-- FleshWound.lua
-- The main addon file that initializes the addon's modules on ADDON_LOADED.

local addonName, addonTable = ...
local L = addonTable.L
local Utils = addonTable.Utils

--[[---------------------------------------------------------------------------
  EventHandler: A small module to handle ADDON_LOADED and set up the addon.
---------------------------------------------------------------------------]]--
local EventHandler = {}
addonTable.EventHandler = EventHandler

function EventHandler:OnAddonLoaded(loadedName)
    if loadedName == addonName then
        -- Ensure global SV is present
        if not FleshWoundData then
            FleshWoundData = {}
        end
        addonTable.FleshWoundData = FleshWoundData

        -- Initialize Data
        if addonTable.Data and addonTable.Data.Initialize then
            addonTable.Data:Initialize()
        else
            Utils.FW_Print("Data module not found or missing Initialize method.", true)
        end

        -- Initialize GUI
        if addonTable.GUI and addonTable.GUI.Initialize then
            addonTable.GUI:Initialize()
        else
            Utils.FW_Print("GUI module not found or missing Initialize method.", true)
        end

        -- Initialize Comm
        if addonTable.Comm and addonTable.Comm.Initialize then
            addonTable.Comm:Initialize()
        end

        -- Attempt to retrieve the version from the TOC
        local version = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version") or "v1.0.0"

        Utils.FW_Print(string.format(L["Thank you for using FleshWound %s! Be safe out there."], version), false)

        self.eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end

--[[---------------------------------------------------------------------------
  Called when we receive a remote profile. Temporarily display that data until
  the user closes or reverts to their own profile.
---------------------------------------------------------------------------]]--
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
        addonTable.GUI:UpdateProfileBanner()

        -- Hide the profile button while viewing a remote profile
        if addonTable.GUI.frame and addonTable.GUI.frame.ProfileButton then
            addonTable.GUI.frame.ProfileButton:Hide()
        end
    end
end

-- Set up an event frame to handle ADDON_LOADED
EventHandler.eventFrame = CreateFrame("Frame")
EventHandler.eventFrame:RegisterEvent("ADDON_LOADED")
EventHandler.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        EventHandler:OnAddonLoaded(...)
    end
end)
