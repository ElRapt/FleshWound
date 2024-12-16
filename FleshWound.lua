-- FleshWound.lua
-- Main addon file that initializes the addon and handles events

local addonName, addonTable = ...

local L = addonTable.L


-- Create an Event Handler Module
local EventHandler = {}
addonTable.EventHandler = EventHandler  -- Expose to addonTable

function EventHandler:OnAddonLoaded(name)
    if name == addonName then
        -- Ensure FleshWoundData is initialized
        if not FleshWoundData then
            FleshWoundData = {}
        end
        
        -- Assign the global saved variable to our addonTable
        addonTable.FleshWoundData = FleshWoundData

        -- Now that addonTable.FleshWoundData is set, we can safely initialize Data
        if addonTable.Data and addonTable.Data.Initialize then
            addonTable.Data:Initialize()
        else
            print("Data module not found or does not have an Initialize method.")
        end

        -- Initialize GUI
        if addonTable.GUI and addonTable.GUI.Initialize then
            addonTable.GUI:Initialize()
        else
            print("GUI module not found or does not have an Initialize method.")
        end

        -- Initialize Comm
        if addonTable.Comm and addonTable.Comm.Initialize then
            addonTable.Comm:Initialize()
        end

        -- Print a localized loaded message
        -- Attempt to retrieve the version from the TOC file metadata
        local version = "Unknown"
        if GetAddOnMetadata then
            version = GetAddOnMetadata(addonName, "Version") or "Unknown"
        else
            -- Fallback if GetAddOnMetadata is not available
            version = "1.0.0"
        end
        
        local colorizedName = "|cFF00FF00FleshWound|r"
        print(colorizedName .. ": " .. format(L["Thank you for using FleshWound %s! Be safe out there."], version))
        

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

        addonTable.GUI:UpdateProfileBanner()

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
