-- FleshWound_Data.lua
-- Handles data persistence and wound data structures for FleshWound.

local addonName, addonTable = ...
local Utils = addonTable.Utils

local Data = {}
addonTable.Data = Data

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
    Utils.FW_Print("Data initialized. Current Profile: " .. assignedProfile, false)
end



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
        addonTable.GUI:CloseAllDialogs()
        addonTable.GUI.currentTemporaryProfile = nil
        addonTable.GUI:UpdateProfileBanner()
    end
end


-- Create an empty profile if one does not exist already.
function Data:CreateProfile(profileName)
    if not self.FleshWoundData.profiles[profileName] then
        self.FleshWoundData.profiles[profileName] = { woundData = {} }
        Utils.FW_Print("Created new profile: " .. profileName, false)
    else
        Utils.FW_Print("Profile '" .. profileName .. "' already exists.", true)
    end
end

-- Delete a named profile if it isn't the current one.
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

function Data:RenameProfile(oldName, newName)
    local profiles = self.FleshWoundData.profiles
    local charProfiles = self.FleshWoundData.charProfiles
    if profiles[oldName] then
        if profiles[newName] then
            Utils.FW_Print("Profile '"..newName.."' already exists.", true)
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
            Utils.FW_Print("Renamed profile '"..oldName.."' to '"..newName.."'.", false)
        end
    else
        Utils.FW_Print("Profile '" .. oldName .. "' does not exist.", true)
    end
end


