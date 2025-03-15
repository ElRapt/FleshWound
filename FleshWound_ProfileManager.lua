-- FleshWound_ProfileManager.lua
local addonName, addonTable = ...
local GUI = addonTable.GUI
local Dialogs = addonTable.Dialogs
local ProfileManager = {}
addonTable.ProfileManager = ProfileManager
local CONSTANTS = GUI.CONSTANTS
local L = addonTable.L

StaticPopupDialogs["FW_DELETE_PROFILE_CONFIRM"] = {
    text = L.DELETE_PROFILE_CONFIRM or "Are you sure you want to delete the profile '%s'?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        addonTable.Data:DeleteProfile(data)
        addonTable.ProfileManager:OpenProfileManager()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


--- Opens the profile manager dialog.
function ProfileManager:OpenProfileManager()
    addonTable.Dialogs:CloseAllDialogs()
    local frameName = "FleshWoundProfileManager"
    local dialogTitle = L.PROFILE_MANAGER or "Profile Manager"
    local dialog = Dialogs:CreateDialog(frameName, dialogTitle, CONSTANTS.SIZES.PROFILE_MANAGER_WIDTH, CONSTANTS.SIZES.PROFILE_MANAGER_HEIGHT)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    addonTable.Utils.MakeFrameDraggable(dialog, function(f)
        GUI:SaveWindowPosition(frameName, f)
    end)
    GUI:RestoreWindowPosition(frameName, dialog)
    dialog.ScrollFrame, dialog.ScrollChild = GUI:CreateScrollFrame(dialog, 15, -60, -35, 100)
    dialog.ProfileEntries = {}
    dialog.CreateProfileButton = GUI:CreateButton(dialog, L.CREATE_PROFILE or "Create Profile", 120, 30, "BOTTOMLEFT", 15, 15)
    dialog.CreateProfileButton:SetScript("OnClick", function()
        dialog:Hide()
        ProfileManager:OpenCreateProfileDialog()
    end)
    dialog.CloseButton = GUI:CreateButton(dialog, L.CLOSE or "Close", 80, 30, "BOTTOMRIGHT", -15, 15)
    dialog.CloseButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    _G[frameName] = dialog
    ProfileManager:PopulateProfileManager(dialog)
    dialog:Show()
end

--- Populates the profile manager with available profiles.
-- @param dialog Frame The profile manager dialog.
function ProfileManager:PopulateProfileManager(dialog)
    local profiles = addonTable.FleshWoundData.profiles or {}
    local currentProfile = addonTable.FleshWoundData.currentProfile
    for _, entry in ipairs(dialog.ProfileEntries) do
        entry:Hide()
    end
    dialog.ProfileEntries = {}
    local yOffset = -10
    local sortedProfiles = {}
    for profileName in pairs(profiles) do
        table.insert(sortedProfiles, profileName)
    end
    table.sort(sortedProfiles)
    for _, profileName in ipairs(sortedProfiles) do
        local entry = ProfileManager:CreateProfileEntry(dialog.ScrollChild, profileName, currentProfile)
        entry:SetPoint("TOPLEFT", 10, yOffset)
        table.insert(dialog.ProfileEntries, entry)
        yOffset = yOffset - 50
    end
    dialog.ScrollChild:SetHeight(-yOffset)
end

--- Creates an entry for a profile in the profile manager.
-- @param parent Frame The parent frame.
-- @param profileName string The profile name.
-- @param currentProfile string The active profile.
-- @return Frame The created entry frame.
function ProfileManager:CreateProfileEntry(parent, profileName, currentProfile)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetWidth(parent:GetWidth() - 20)
    entry:SetHeight(40)
    entry:SetBackdrop(GUI.CONSTANTS.BACKDROPS.TOOLTIP_FRAME)
    if profileName == currentProfile then
        entry:SetBackdropColor(0.0, 0.5, 0.0, 0.5)
    else
        entry:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
    end
    entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", entry, "LEFT", 10, 0)
    nameText:SetText(profileName)
    local charProfiles = addonTable.FleshWoundData.charProfiles or {}
    local usageCount = 0
    for _, pName in pairs(charProfiles) do
        if pName == profileName then
            usageCount = usageCount + 1
        end
    end
    local iconSize = 16
    local iconTexture = entry:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(iconSize, iconSize)
    iconTexture:SetTexture(GUI.CONSTANTS.ICONS and GUI.CONSTANTS.ICONS.BANDAGE or "Interface\\Icons\\INV_Misc_Bandage_01")
    iconTexture:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
    local countText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("LEFT", iconTexture, "RIGHT", 2, 0)
    countText:SetText(tostring(usageCount))
    local selectButton = GUI:CreateButton(entry, L.SELECT or "Select", 80, 24, "RIGHT", -10, 0)
    selectButton:SetScript("OnClick", function()
        addonTable.Data:SwitchProfile(profileName)
        GUI:UpdateRegionColors()
        ProfileManager:OpenProfileManager()
    end)
    local deleteButton = GUI:CreateButton(entry, L.DELETE or "Delete", 80, 24, "RIGHT", selectButton, "LEFT", -5, 0)
    deleteButton:SetScript("OnClick", function()
        StaticPopup_Show("FW_DELETE_PROFILE_CONFIRM", profileName, nil, profileName)
    end)
    if profileName == currentProfile then
        deleteButton:Disable()
    end
    local renameButton = GUI:CreateButton(entry, L.RENAME or "Rename", 80, 24, "RIGHT", deleteButton, "LEFT", -5, 0)
    renameButton:SetScript("OnClick", function()
        ProfileManager:OpenRenameProfileDialog(profileName)
    end)
    return entry
end

--- Opens the dialog to create a new profile.
function ProfileManager:OpenCreateProfileDialog()
    addonTable.Dialogs:CloseAllDialogs()
    local frameName = "FleshWoundCreateProfileDialog"
    local dialogTitle = L.CREATE_PROFILE or "Create Profile"
    local dialog = Dialogs:CreateDialog(frameName, dialogTitle, CONSTANTS.SIZES.CREATE_PROFILE_WIDTH, CONSTANTS.SIZES.CREATE_PROFILE_HEIGHT)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    addonTable.Utils.MakeFrameDraggable(dialog, function(f)
        GUI:SaveWindowPosition(frameName, f)
    end)
    GUI:RestoreWindowPosition(frameName, dialog)
    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
    nameLabel:SetText(L.PROFILE_NAME or "Profile Name")
    local nameEditBox, charCountLabel = addonTable.Dialogs:CreateSingleLineEditBoxWithCounter(dialog, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH)
    nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    dialog.nameEditBox = nameEditBox
    dialog.charCountLabel = charCountLabel
    dialog.SaveButton, dialog.CancelButton = Dialogs:CreateSaveCancelButtons(dialog)
    dialog.SaveButton:SetText(L.CREATE or "Create")
    _G[frameName] = dialog
    local function UpdateCreateButtonState()
        local text = addonTable.Utils.SanitizeInput(dialog.nameEditBox:GetText())
        local profileName = text
        local length = strlenutf8(text)
        dialog.charCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", length, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH))
        if profileName == "" or (addonTable.FleshWoundData.profiles and addonTable.FleshWoundData.profiles[profileName]) then
            dialog.SaveButton:Disable()
        else
            dialog.SaveButton:Enable()
        end
    end
    dialog.nameEditBox:SetText("")
    dialog.charCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", 0, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH))
    dialog.SaveButton:Disable()
    dialog.nameEditBox:SetScript("OnTextChanged", UpdateCreateButtonState)
    dialog.SaveButton:SetScript("OnClick", function()
        local profileName = addonTable.Utils.SanitizeInput(dialog.nameEditBox:GetText())
        addonTable.Data:CreateProfile(profileName)
        dialog:Hide()
        ProfileManager:OpenProfileManager()
    end)
    dialog.CancelButton:SetScript("OnClick", function()
        dialog:Hide()
        ProfileManager:OpenProfileManager()
    end)
    dialog:Show()
end

--- Opens the dialog to rename an existing profile.
-- @param oldProfileName string The current profile name.
function ProfileManager:OpenRenameProfileDialog(oldProfileName)
    local frameName = "FleshWoundRenameProfileDialog"
    local dialogTitle = L.RENAME_PROFILE or "Rename Profile"
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        _G["FleshWoundProfileManager"]:Hide()
    end
    local dialog = _G[frameName]
    if not dialog then
        dialog = Dialogs:CreateDialog(frameName, dialogTitle, CONSTANTS.SIZES.RENAME_PROFILE_WIDTH, CONSTANTS.SIZES.RENAME_PROFILE_HEIGHT)
        addonTable.Utils.MakeFrameDraggable(dialog, function(f)
            GUI:SaveWindowPosition(frameName, f)
        end)
        local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        nameLabel:SetText(L.NEW_NAME or "New Name")
        local nameEditBox, charCountLabel = addonTable.Dialogs:CreateSingleLineEditBoxWithCounter(dialog, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH)
        nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
        dialog.nameEditBox = nameEditBox
        dialog.charCountLabel = charCountLabel
        dialog.SaveButton, dialog.CancelButton = Dialogs:CreateSaveCancelButtons(dialog)
        dialog.SaveButton:SetText(L.RENAME or "Rename")
        _G[frameName] = dialog
    end
    GUI:RestoreWindowPosition(frameName, dialog)
    local function UpdateRenameButtonState()
        local text = dialog.nameEditBox:GetText()
        local newProfileName = addonTable.Utils.SanitizeInput(text)
        local length = strlenutf8(text)
        dialog.charCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", length, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH))
        if newProfileName == "" or (addonTable.FleshWoundData.profiles and addonTable.FleshWoundData.profiles[newProfileName]) or newProfileName == oldProfileName then
            dialog.SaveButton:Disable()
        else
            dialog.SaveButton:Enable()
        end
    end
    dialog.nameEditBox:SetText(oldProfileName)
    local initialLength = strlenutf8(oldProfileName)
    dialog.charCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", initialLength, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH))
    dialog.SaveButton:Disable()
    dialog.nameEditBox:SetScript("OnTextChanged", UpdateRenameButtonState)
    dialog.SaveButton:SetScript("OnClick", function()
        local newProfileName = addonTable.Utils.SanitizeInput(dialog.nameEditBox:GetText())
        addonTable.Data:RenameProfile(oldProfileName, newProfileName)
        dialog:Hide()
        ProfileManager:OpenProfileManager()
    end)
    dialog.CancelButton:SetScript("OnClick", function()
        dialog:Hide()
        ProfileManager:OpenProfileManager()
    end)
    dialog:Show()
end

return ProfileManager
