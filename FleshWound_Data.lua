-- FleshWound_Data.lua
-- Handles data persistence and wound data structures for FleshWound.

local addonName, addonTable = ...
local Utils = addonTable.Utils

local Data = {}
addonTable.Data = Data

--[[---------------------------------------------------------------------------
  Initialize is called on ADDON_LOADED. We set up profiles and character-to-profile
  assignments. Old migration code removed for clarity, assuming all players have
  the new format by now.
---------------------------------------------------------------------------]]--
function Data:Initialize()
    self.FleshWoundData = addonTable.FleshWoundData

    -- Ensure we have a table of profiles
    self.FleshWoundData.profiles = self.FleshWoundData.profiles or {}

    -- Ensure we have a table for per-character assignments
    if not self.FleshWoundData.charProfiles then
        self.FleshWoundData.charProfiles = {}
    end

    -- Also unify positions in a single table, if not present
    -- { main = {}, woundDialog = {}, ... }
    self.FleshWoundData.positions = self.FleshWoundData.positions or {}

    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local charKey = playerName.."-"..realmName

    -- If this char is unassigned, create (or reuse) a profile named after the character
    if not self.FleshWoundData.charProfiles[charKey] then
        if not self.FleshWoundData.profiles[playerName] then
            self:CreateProfile(playerName)
        end
        self.FleshWoundData.charProfiles[charKey] = playerName
    end

    -- Switch to whichever profile is assigned for this char
    local assignedProfile = self.FleshWoundData.charProfiles[charKey]
    self:SwitchProfile(assignedProfile)
    Utils.FW_Print("Data initialized. Current Profile: " .. assignedProfile, false)
end

--[[---------------------------------------------------------------------------
  Switch to the specified profile, create if missing, then update UI and wipe any
  temporary profile state.
---------------------------------------------------------------------------]]--
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
        addonTable.GUI.currentTemporaryProfile = nil
        addonTable.GUI:UpdateProfileBanner()
    end
end

--[[---------------------------------------------------------------------------
  Create an empty profile if one does not exist already.
---------------------------------------------------------------------------]]--
function Data:CreateProfile(profileName)
    if not self.FleshWoundData.profiles[profileName] then
        self.FleshWoundData.profiles[profileName] = { woundData = {} }
        Utils.FW_Print("Created new profile: " .. profileName, false)
    else
        Utils.FW_Print("Profile '" .. profileName .. "' already exists.", true)
    end
end

--[[---------------------------------------------------------------------------
  Delete a named profile if it isn't the current one.
---------------------------------------------------------------------------]]--
function Data:DeleteProfile(profileName)
    local profiles = self.FleshWoundData.profiles
    if profiles[profileName] then
        if profileName == self.FleshWoundData.currentProfile then
            Utils.FW_Print("Cannot delete the current profile.", true)
        else
            profiles[profileName] = nil
            Utils.FW_Print("Deleted profile '" .. profileName .. "'.", false)
        end
    else
        Utils.FW_Print("Profile '" .. profileName .. "' does not exist.", true)
    end
end

--[[---------------------------------------------------------------------------
  Rename an existing profile to a new name, if it doesn't already exist.
---------------------------------------------------------------------------]]--
function Data:RenameProfile(oldName, newName)
    local profiles = self.FleshWoundData.profiles
    if profiles[oldName] then
        if profiles[newName] then
            Utils.FW_Print("Profile '"..newName.."' already exists.", true)
        else
            profiles[newName] = profiles[oldName]
            profiles[oldName] = nil
            if self.FleshWoundData.currentProfile == oldName then
                self.FleshWoundData.currentProfile = newName
            end
            Utils.FW_Print("Renamed profile '"..oldName.."' to '"..newName.."'.", false)
        end
    else
        Utils.FW_Print("Profile '" .. oldName .. "' does not exist.", true)
    end
end
