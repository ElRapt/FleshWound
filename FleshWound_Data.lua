-- FleshWound_Data.lua
-- Handles data persistence and wound data structures

local addonName, addonTable = ...
local Data = {}
addonTable.Data = Data  -- Expose the Data module to addonTable

-- Initialize woundData and profiles
function Data:Initialize()
    -- self.FleshWoundData should point to the saved variable table
    self.FleshWoundData = addonTable.FleshWoundData

    -- Migrate old data format to new profiles format (if needed)
    if self.FleshWoundData.woundData then
        local defaultProfileName = UnitName("player")
        self.FleshWoundData.profiles = self.FleshWoundData.profiles or {}
        self.FleshWoundData.profiles[defaultProfileName] = { woundData = self.FleshWoundData.woundData }
        -- Remove old data
        self.FleshWoundData.woundData = nil
        -- (We don’t set self.FleshWoundData.currentProfile here, see below.)
    end

    -- Ensure profiles table exists
    self.FleshWoundData.profiles = self.FleshWoundData.profiles or {}

    -- NEW: Ensure we have a table for per-character assignments
    if not self.FleshWoundData.charProfiles then
        self.FleshWoundData.charProfiles = {}
    end

    -- Build a unique char key for this login
    local playerName = UnitName("player")
    local realmName  = GetRealmName()
    local charKey    = playerName .. "-" .. realmName

    -- If this char is unassigned, create (or reuse) a profile named after the character
    if not self.FleshWoundData.charProfiles[charKey] then
        if not self.FleshWoundData.profiles[playerName] then
            self:CreateProfile(playerName)
        end
        self.FleshWoundData.charProfiles[charKey] = playerName
    end

    -- Now switch to whichever profile is assigned for this char
    local assignedProfile = self.FleshWoundData.charProfiles[charKey]
    self:SwitchProfile(assignedProfile)

    -- All done!
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
