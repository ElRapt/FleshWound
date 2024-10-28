-- FleshWound_Data.lua
-- Handles data persistence and wound data structures

local addonName, addonTable = ...
local woundData = addonTable.woundData or {}
addonTable.woundData = woundData

-- Function to switch profiles
function FleshWound_SwitchProfile(profileName)
    local FleshWoundData = addonTable.FleshWoundData
    if not FleshWoundData.profiles[profileName] then
        FleshWoundData.profiles[profileName] = { woundData = {} }
    end
    FleshWoundData.currentProfile = profileName
    addonTable.woundData = FleshWoundData.profiles[profileName].woundData

    -- Update any GUI elements that rely on woundData
    if UpdateRegionColors then
        UpdateRegionColors()
    end
    -- Close any open dialogs
    if CloseAllDialogs then
        CloseAllDialogs()
    end
end

-- Function to create a new profile
function FleshWound_CreateProfile(profileName)
    local FleshWoundData = addonTable.FleshWoundData
    if not FleshWoundData.profiles[profileName] then
        FleshWoundData.profiles[profileName] = { woundData = {} }
    else
        print("Profile '" .. profileName .. "' already exists.")
    end
end

-- Function to delete a profile
function FleshWound_DeleteProfile(profileName)
    local FleshWoundData = addonTable.FleshWoundData
    if FleshWoundData.profiles[profileName] then
        if profileName == FleshWoundData.currentProfile then
            print("Cannot delete the current profile.")
        else
            FleshWoundData.profiles[profileName] = nil
        end
    else
        print("Profile '" .. profileName .. "' does not exist.")
    end
end

-- Function to rename a profile
function FleshWound_RenameProfile(oldName, newName)
    local FleshWoundData = addonTable.FleshWoundData
    if FleshWoundData.profiles[oldName] then
        if FleshWoundData.profiles[newName] then
            print("Profile '" .. newName .. "' already exists.")
        else
            FleshWoundData.profiles[newName] = FleshWoundData.profiles[oldName]
            FleshWoundData.profiles[oldName] = nil
            if FleshWoundData.currentProfile == oldName then
                FleshWoundData.currentProfile = newName
            end
        end
    else
        print("Profile '" .. oldName .. "' does not exist.")
    end
end

-- Function to close all dialogs
function CloseAllDialogs()
    -- Close the main frame
    if FleshWoundFrame then
        FleshWoundFrame:Hide()
    end
    -- Close any other dialogs
    for _, frame in pairs({ "FleshWoundDialog_", "FleshWoundAddNoteDialog_", "FleshWoundEditNoteDialog_", "FleshWoundProfileManager", "FleshWoundCreateProfileDialog", "FleshWoundRenameProfileDialog" }) do
        for k, v in pairs(_G) do
            if type(k) == "string" and k:match(frame) and type(v) == "table" and v.Hide then
                v:Hide()
            end
        end
    end
end
