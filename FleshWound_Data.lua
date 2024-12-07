-- FleshWound_Data.lua
-- Handles data persistence and wound data structures

local addonName, addonTable = ...
local Data = {}
addonTable.Data = Data  -- Expose the Data module to addonTable

-- Initialize woundData and profiles
function Data:Initialize()
    -- self.FleshWoundData should point to the saved variable table
    self.FleshWoundData = addonTable.FleshWoundData

    -- Migrate old data format to new profiles format
    if self.FleshWoundData.woundData then
        local defaultProfileName = UnitName("player")
        self.FleshWoundData.profiles = self.FleshWoundData.profiles or {}
        self.FleshWoundData.profiles[defaultProfileName] = { woundData = self.FleshWoundData.woundData }
        self.FleshWoundData.currentProfile = defaultProfileName
        self.FleshWoundData.woundData = nil -- Remove old data
    end

    -- Ensure profiles table exists
    self.FleshWoundData.profiles = self.FleshWoundData.profiles or {}

    -- Ensure currentProfile is set
    if not self.FleshWoundData.currentProfile then
        self.FleshWoundData.currentProfile = UnitName("player") -- Default profile name is character name
    end

    -- If currentProfile does not exist in profiles, create it
    if not self.FleshWoundData.profiles[self.FleshWoundData.currentProfile] then
        self.FleshWoundData.profiles[self.FleshWoundData.currentProfile] = { woundData = {} }
    end

    -- Set addonTable.woundData to the woundData of the current profile
    addonTable.woundData = self.FleshWoundData.profiles[self.FleshWoundData.currentProfile].woundData
    self.woundData = addonTable.woundData -- Also store in self for convenience
end

function Data:SwitchProfile(profileName)
    if not self.FleshWoundData.profiles[profileName] then
        self.FleshWoundData.profiles[profileName] = { woundData = {} }
    end
    self.FleshWoundData.currentProfile = profileName
    addonTable.woundData = self.FleshWoundData.profiles[profileName].woundData
    self.woundData = addonTable.woundData

    if addonTable.GUI then
        addonTable.GUI:UpdateRegionColors()
        addonTable.GUI:CloseAllDialogs()

        -- Since switching profiles means we’re on our own profile, clear any temporary profile
        addonTable.GUI.currentTemporaryProfile = nil

        -- Now update the banner to reflect the newly selected profile
        addonTable.GUI:UpdateProfileBanner()
    end
end
-- Function to create a new profile
function Data:CreateProfile(profileName)
    if not self.FleshWoundData.profiles[profileName] then
        self.FleshWoundData.profiles[profileName] = { woundData = {} }
    else
        print(format("Profile '%s' already exists.", profileName))
    end
end

-- Function to delete a profile
function Data:DeleteProfile(profileName)
    if self.FleshWoundData.profiles[profileName] then
        if profileName == self.FleshWoundData.currentProfile then
            print("Cannot delete the current profile.")
        else
            self.FleshWoundData.profiles[profileName] = nil
        end
    else
        print(format("Profile '%s' does not exist.", profileName))
    end
end

-- Function to rename a profile
function Data:RenameProfile(oldName, newName)
    if self.FleshWoundData.profiles[oldName] then
        if self.FleshWoundData.profiles[newName] then
            print(format("Profile '%s' already exists.", newName))
        else
            self.FleshWoundData.profiles[newName] = self.FleshWoundData.profiles[oldName]
            self.FleshWoundData.profiles[oldName] = nil
            if self.FleshWoundData.currentProfile == oldName then
                self.FleshWoundData.currentProfile = newName
            end
        end
    else
        print(format("Profile '%s' does not exist.", oldName))
    end
end
