-- FleshWound_Data.lua
-- Handles data persistence and wound data structures for FleshWound.

local addonName, addonTable = ...
local Utils = addonTable.Utils
local L = addonTable.L

local Data = {}
addonTable.Data = Data


--- Switches the current profile to the specified profileName.
--- If the profile does not exist, it is created.
--- Updates character profile mapping and refreshes GUI elements accordingly.
--- @param profileName string: The name of the profile to switch to.
function Data:SwitchProfile(profileName)
    local data = self.FleshWoundData
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local charKey = playerName .. "-" .. realmName

    if not data.profiles[profileName] then
        data.profiles[profileName] = { woundData = {} }
    end

    data.currentProfile = profileName
    data.charProfiles[charKey] = profileName  -- Persist the new assignment
    addonTable.woundData = data.profiles[profileName].woundData
    self.woundData = addonTable.woundData

    if addonTable.GUI then
        addonTable.GUI:UpdateRegionColors()
        if addonTable.Dialogs then
            addonTable.Dialogs:CloseAllDialogs()
        end
        addonTable.GUI:UpdateProfileBanner()
    end
end


--- Creates a new profile with the given profileName if it does not already exist.
--- Prints a message indicating whether the profile was created or already exists.
--- @param profileName string: The desired profile name.
function Data:CreateProfile(profileName)
    if not self.FleshWoundData.profiles[profileName] then
        self.FleshWoundData.profiles[profileName] = { woundData = {} }
        Utils.FW_Print(string.format(L.CREATE_PROFILE, "|cffff0000" .. profileName .. "|r"), false)
    else
        Utils.FW_Print(string.format(L.PROFILE_EXISTS_MSG, "|cffff0000" .. profileName .. "|r"), true)
    end
end

--- Deletes the specified profile if it exists and is not currently active.
--- If the profile is active or does not exist, an error message is printed.
--- @param profileName string: The name of the profile to delete.
function Data:DeleteProfile(profileName)
    local profiles = self.FleshWoundData.profiles
    if profiles[profileName] then
        if profileName == self.FleshWoundData.currentProfile then
            Utils.FW_Print(L.CANNOT_DELETE_CURRENT, true)
        else
            profiles[profileName] = nil
            Utils.FW_Print(string.format(L.DELETED_PROFILE, "|cffff0000" .. profileName .. "|r"), false)
        end
    else
        Utils.FW_Print(string.format(L.PROFILE_NOT_EXIST, "|cffff0000" .. profileName .. "|r"), true)
    end
end

--- Renames an existing profile from oldName to newName.
--- Updates all character mappings and the current profile if necessary.
--- Prints a message indicating the success or failure of the operation.
--- @param oldName string: The current profile name.
--- @param newName string: The new profile name.
function Data:RenameProfile(oldName, newName)
    local profiles = self.FleshWoundData.profiles
    local charProfiles = self.FleshWoundData.charProfiles
    if profiles[oldName] then
        if profiles[newName] then
            Utils.FW_Print(string.format(L.PROFILE_EXISTS_MSG, "|cffff0000" .. newName .. "|r"), true)
        else
            profiles[newName] = profiles[oldName]
            profiles[oldName] = nil

            -- Update charProfiles mapping for any characters using oldName
            for charKey, profileName in pairs(charProfiles) do
                if profileName == oldName then
                    charProfiles[charKey] = newName
                end
            end

            if self.FleshWoundData.currentProfile == oldName then
                self.FleshWoundData.currentProfile = newName
                if addonTable.GUI and addonTable.GUI.UpdateProfileBanner then
                    addonTable.GUI:UpdateProfileBanner()
                end
            end
            Utils.FW_Print(string.format(L.RENAMED_PROFILE, 
                "|cffff0000" .. oldName .. "|r", 
                "|cffff0000" .. newName .. "|r"), false)
        end
    else
        Utils.FW_Print(string.format(L.PROFILE_NOT_EXIST, "|cffff0000" .. oldName .. "|r"), true)
    end
end

--- Initializes the data module by setting up profiles, character-specific profile assignments, and the current profile.
--- Also prints an initialization message to indicate the active profile.
function Data:Initialize()
    self.FleshWoundData = addonTable.FleshWoundData or {}
    local data = self.FleshWoundData

    data.profiles = data.profiles or {}
    data.charProfiles = data.charProfiles or {}
    data.positions = data.positions or {}

    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local charKey = playerName .. "-" .. realmName

    local assignedProfile = data.charProfiles[charKey]

    if not assignedProfile then
        if not data.profiles[playerName] then
            self:CreateProfile(playerName)
        end
        assignedProfile = playerName
        data.charProfiles[charKey] = assignedProfile
    end

    self:SwitchProfile(assignedProfile)
    Utils.FW_Print(string.format(L.DATA_INITIALIZED, "|cffff0000" .. assignedProfile .. "|r"), false)


end


