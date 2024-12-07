-- FleshWound_GUI.lua
-- Contains all GUI-related functions with data persistence and localization

local addonName, addonTable = ...
local L = addonTable.L

-- Create a GUI module to encapsulate all GUI-related functionality
local GUI = {}
addonTable.GUI = GUI  -- Expose the GUI module to the addonTable

-- Constants
local MAX_NOTE_LENGTH = 125
local MAX_PROFILE_NAME_LENGTH = 50

-- Severity definitions
local Severities = {
    { name = L["None"], color = {0, 0, 0, 0.0} },
    { name = L["Unknown"], color = {0.5, 0.5, 0.5, 0.4} },
    { name = L["Benign"], color = {0, 1, 0, 0.4} },
    { name = L["Moderate"], color = {1, 1, 0, 0.4} },
    { name = L["Severe"], color = {1, 0.5, 0, 0.4} },
    { name = L["Critical"], color = {1, 0, 0, 0.4} },
    { name = L["Deadly"], color = {0.6, 0, 0.6, 0.4} },
}

local SeverityLevels = {}
for index, severity in ipairs(Severities) do
    SeverityLevels[severity.name] = index - 2  -- Start from -1 for "None"
end

-- Utility Functions
local function SanitizeInput(text)
    text = text:match("^%s*(.-)%s*$")  -- Trim whitespace
    text = text:gsub("[%c]", "")       -- Remove control characters
    return text
end

local function GetSeverityColor(severityName)
    for _, severity in ipairs(Severities) do
        if severity.name == severityName then
            return severity.color
        end
    end
    return {0, 0, 0, 0.0}  -- Default to transparent if not found
end

local function GetHighestSeverity(regionName)
    local woundData = addonTable.woundData or {}
    local notes = woundData[regionName]
    if not notes or #notes == 0 then
        return L["None"]
    end

    local highestLevel = -1
    local highestSeverity = L["None"]

    for _, note in ipairs(notes) do
        local level = SeverityLevels[note.severity] or 0
        if level > highestLevel then
            highestLevel = level
            highestSeverity = note.severity
        end
    end

    return highestSeverity
end

-- Function to create common dialog frames
local function CreateDialog(name, titleText, width, height)
    local dialog = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    dialog:SetSize(width, height)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    dialog:SetFrameStrata("DIALOG")

    -- Make the dialog draggable
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)

    -- Close Button
    dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    dialog.CloseButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
    dialog.CloseButton:SetScript("OnClick", function()
        dialog:Hide()
    end)

    -- Bind the dialog to the ESC key
    if dialog:GetName() then
        table.insert(UISpecialFrames, dialog:GetName())
    else
        local uniqueName = "FleshWoundDialog_" .. tostring(math.random(10000, 99999))
        dialog:SetName(uniqueName)
        table.insert(UISpecialFrames, uniqueName)
    end

    -- Title
    dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    dialog.Title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)
    dialog.Title:SetText(titleText)

    -- Decorative line under the title
    local titleLine = dialog:CreateTexture(nil, "ARTWORK")
    titleLine:SetHeight(2)
    titleLine:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 0, -10)
    titleLine:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -15, -40)
    titleLine:SetColorTexture(1, 1, 1, 0.2)

    return dialog
end

-- Function to create severity dropdown menus
local function CreateSeverityDropdown(parent)
    -- Severity Label
    local severityLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    severityLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -60)
    severityLabel:SetText(L["Severity:"])

    -- Severity Dropdown Menu
    local severityDropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    severityDropdown:SetPoint("LEFT", severityLabel, "RIGHT", -10, -3)
    UIDropDownMenu_SetWidth(severityDropdown, 150)

    severityDropdown.initialize = function(self, level)
        local info
        for _, sev in ipairs(Severities) do
            info = UIDropDownMenu_CreateInfo()
            info.text = sev.name
            info.arg1 = sev.name
            info.func = function(_, arg1)
                UIDropDownMenu_SetSelectedName(severityDropdown, arg1)
                parent.selectedSeverity = arg1
            end
            info.checked = (sev.name == (parent.selectedSeverity or L["Unknown"]))
            UIDropDownMenu_AddButton(info)
        end
    end

    return severityLabel, severityDropdown
end

-- Function to create the edit box with character count
local function CreateEditBoxWithCounter(parent, maxChars)
    -- ScrollFrame for the EditBox
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent.SeverityLabel, "BOTTOMLEFT", 0, -20)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -35, 80)

    -- EditBox
    local editBox = CreateFrame("EditBox", nil, scrollFrame, "BackdropTemplate")
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetMaxLetters(maxChars)
    editBox:SetAutoFocus(true)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetTextInsets(10, 10, 10, 10)
    editBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = nil,
        tile = false,
        tileSize = 0,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.5)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    scrollFrame:SetScrollChild(editBox)

    -- Character Count Label
    local charCountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charCountLabel:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
    charCountLabel:SetText(format(L["%d / %d"], 0, maxChars))

    return scrollFrame, editBox, charCountLabel
end

-- Function to create Save and Cancel buttons
local function CreateSaveCancelButtons(parent)
    local saveButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    saveButton:SetSize(80, 24)
    saveButton:SetPoint("BOTTOMRIGHT", parent, "BOTTOM", -10, 15)
    saveButton:SetText(L["Save"])

    local cancelButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 24)
    cancelButton:SetPoint("BOTTOMLEFT", parent, "BOTTOM", 10, 15)
    cancelButton:SetText(L["Cancel"])

    return saveButton, cancelButton
end

-- Function to create a single-line edit box with character counter
local function CreateSingleLineEditBoxWithCounter(parent, maxChars)
    -- EditBox
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetAutoFocus(true)
    editBox:SetMaxLetters(maxChars)
    editBox:SetSize(160, 30)

    -- Character Count Label
    local charCountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charCountLabel:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -5)
    charCountLabel:SetText(format(L["%d / %d"], 0, maxChars))

    -- Update character count on text change
    editBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        local length = strlenutf8(text)
        charCountLabel:SetText(format(L["%d / %d"], length, maxChars))
    end)

    return editBox, charCountLabel
end

-- GUI Initialization
function GUI:Initialize()
    self.woundData = addonTable.woundData or {}
    self:CreateMainFrame()
    self:CreateBodyRegions()
    self:UpdateRegionColors()
    self:CreateTemporaryProfileBanner()
end

function GUI:CreateTemporaryProfileBanner()
    if not self.frame then return end

    -- Create a small frame to hold the banner text
    self.tempProfileBannerFrame = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.tempProfileBannerFrame:SetSize(self.frame:GetWidth() - 20, 30)
    self.tempProfileBannerFrame:SetPoint("TOP", self.frame, "TOP", 0, 25) -- More margin from the top
    self.tempProfileBannerFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 0,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    self.tempProfileBannerFrame:SetBackdropColor(0, 0, 0, 0.7)
    self.tempProfileBannerFrame:Hide()

    self.tempProfileBanner = self.tempProfileBannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.tempProfileBanner:SetPoint("CENTER", self.tempProfileBannerFrame, "CENTER", 0, 0)
    self.tempProfileBanner:SetJustifyH("CENTER")
    self.tempProfileBanner:SetTextColor(1, 0.8, 0, 1)
end

-- Main Frame Creation
function GUI:CreateMainFrame()
    local frame = CreateFrame("Frame", "FleshWoundFrame", UIParent, "BackdropTemplate")
    self.frame = frame

    frame:SetSize(320, 540)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Close Button
    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
        if GUI.currentTemporaryProfile then
            GUI:RestoreOriginalProfile()
            frame:Hide()
        end
    end)

    -- Profile Icon Button
    frame.ProfileButton = CreateFrame("Button", nil, frame)
    frame.ProfileButton:SetSize(35, 35)
    frame.ProfileButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
    frame.ProfileButton:SetNormalTexture("Interface\\ICONS\\INV_Misc_Book_09")
    frame.ProfileButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    frame.ProfileButton:SetScript("OnClick", function()
        -- Check if any note dialogs are open
        local noteDialogOpen = false
        for frameName, frame in pairs(_G) do
            if type(frameName) == "string" and (frameName:match("^FleshWoundAddNoteDialog_") or frameName:match("^FleshWoundEditNoteDialog_")) and frame:IsShown() then
                noteDialogOpen = true
                break
            end
        end

        if noteDialogOpen then
            UIErrorsFrame:AddMessage(L["Cannot open Profile Manager while note dialog is open."], 1.0, 0.0, 0.0, 53, 5)
            return
        end

        self:OpenProfileManager()
    end)

    frame.ProfileButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.ProfileButton, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Profile Manager"], 1, 1, 1)
        GameTooltip:Show()
    end)
    frame.ProfileButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    table.insert(UISpecialFrames, frame:GetName())

    -- Body Image
    frame.BodyImage = frame:CreateTexture(nil, "BACKGROUND")
    frame.BodyImage:SetSize(300, 500)
    frame.BodyImage:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.BodyImage:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Textures\\body_image.tga")
end

-- Body Regions Creation
function GUI:CreateBodyRegions()
    local frame = self.frame
    frame.BodyRegions = {}

    local regions = {
        { name = "Head", x = 130, y = 420, width = 50, height = 75 },
        { name = "Torso", x = 130, y = 275, width = 50, height = 120 },
        { name = "Left Arm", x = 75, y = 300, width = 50, height = 120 },
        { name = "Right Arm", x = 185, y = 300, width = 50, height = 120 },
        { name = "Left Hand", x = 40, y = 180, width = 50, height = 100 },
        { name = "Right Hand", x = 215, y = 180, width = 50, height = 100 },
        { name = "Left Leg", x = 100, y = 50, width = 50, height = 130 },
        { name = "Right Leg", x = 155, y = 50, width = 50, height = 130 },
        { name = "Left Foot", x = 110, y = 0, width = 50, height = 50 },
        { name = "Right Foot", x = 150, y = 0, width = 50, height = 50 },
    }

    for _, region in ipairs(regions) do
        self:CreateBodyRegion(frame, region)
    end
end

function GUI:CreateBodyRegion(frame, region)
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(region.width, region.height)
    btn:SetPoint("BOTTOMLEFT", frame.BodyImage, "BOTTOMLEFT", region.x, region.y)
    btn:SetScript("OnClick", function()
        self:OpenWoundDialog(region.name)
    end)
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

    -- Region Marker
    local regionMarker = btn:CreateTexture(nil, "OVERLAY")
    regionMarker:SetSize(10, 10)
    regionMarker:SetPoint("CENTER", btn, "CENTER")
    regionMarker:SetColorTexture(0, 1, 0, 1)
    btn.regionMarker = regionMarker

    -- Severity Overlay
    local overlay = btn:CreateTexture(nil, "ARTWORK")
    local inset = 7
    overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
    overlay:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
    overlay:SetColorTexture(0, 0, 0, 0)
    btn.overlay = overlay

    frame.BodyRegions[region.name] = btn
end

-- Update Region Colors Based on Severity
function GUI:UpdateRegionColors()
    local frame = self.frame
    if not frame or not frame.BodyRegions then return end
    for regionName, btn in pairs(frame.BodyRegions) do
        local highestSeverity = GetHighestSeverity(regionName)
        local color = GetSeverityColor(highestSeverity)
        btn.overlay:SetColorTexture(unpack(color))
    end
end

-- Dialog Creation Helpers
function GUI:CreateDialog(name, titleText, width, height)
    local dialog = CreateDialog(name, titleText, width, height)
    return dialog
end

function GUI:CreateSeverityDropdown(parent)
    return CreateSeverityDropdown(parent)
end

function GUI:CreateEditBoxWithCounter(parent, maxChars)
    return CreateEditBoxWithCounter(parent, maxChars)
end

function GUI:CreateSingleLineEditBoxWithCounter(parent, maxChars)
    return CreateSingleLineEditBoxWithCounter(parent, maxChars)
end

function GUI:CreateSaveCancelButtons(parent)
    return CreateSaveCancelButtons(parent)
end

function GUI:OpenWoundDialog(regionName, skipCloseDialogs)
    local profileManager = _G["FleshWoundProfileManager"]
    if profileManager and profileManager:IsShown() then
        -- Close the Profile Manager before opening the wound details
        profileManager:Hide()
    end

    if not skipCloseDialogs then
        -- Close any open body part dialogs to ensure only one is open
        self:CloseAllDialogs("BodyPartDialogs")
    end

    local dialogName = "FleshWoundDialog_" .. regionName
    local displayRegionName = L[regionName] or regionName
    local dialogTitle = format(L["Wound Details - %s"], displayRegionName)

    -- Always create a new dialog to ensure a fresh UI
    local dialog = self:CreateDialog(dialogName, dialogTitle, 550, 500)
    dialog.regionName = regionName

    -- Ensure clicks do not pass through the dialog
    dialog:EnableMouse(true)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)

    -- Notes Scroll Frame
    dialog.ScrollFrame, dialog.ScrollChild = self:CreateScrollFrame(dialog, 15, -60, -35, 60)

    -- Notes Entries
    dialog.NoteEntries = {}

    -- Only show the Add Note button if we’re not viewing a temporary profile
    if not self.currentTemporaryProfile then
        dialog.AddNoteButton = self:CreateButton(dialog, L["Add Note"], 120, 30, "BOTTOMLEFT", 15, 15)
        dialog.AddNoteButton:SetScript("OnClick", function()
            dialog:Hide()
            self:OpenNoteDialog(regionName)
        end)
    end

    -- Store the dialog in _G for reference
    _G[dialogName] = dialog

    self:PopulateWoundDialog(dialog)
    dialog:Show()
end


function GUI:CreateNoteEntry(parent, note, index, regionName)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetWidth(parent:GetWidth() - 20)
    entry:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 0,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local color = GetSeverityColor(note.severity or L["None"])
    entry:SetBackdropColor(color[1], color[2], color[3], 0.4)
    entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    entry.regionName = regionName

    local noteText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    noteText:SetPoint("TOPLEFT", entry, "TOPLEFT", 10, -10)
    noteText:SetPoint("BOTTOMRIGHT", entry, "BOTTOMRIGHT", -110, 10)
    noteText:SetJustifyH("LEFT")
    noteText:SetJustifyV("TOP")
    noteText:SetText(note.text)

    local textHeight = noteText:GetStringHeight()
    entry:SetHeight(textHeight + 20)

    -- Only show edit/delete buttons if we're viewing our own profile (i.e., not a temporary profile)
    if not self.currentTemporaryProfile then
        local editButton = self:CreateButton(entry, L["Edit"], 70, 22, "TOPRIGHT", -80, -5)
        editButton:SetScript("OnClick", function()
            entry:GetParent():GetParent():Hide()
            self:OpenNoteDialog(entry.regionName, index)
        end)

        local deleteButton = self:CreateButton(entry, L["Delete"], 70, 22, "TOPRIGHT", -10, -5)
        deleteButton:SetScript("OnClick", function()
            if addonTable.woundData[entry.regionName] then
                table.remove(addonTable.woundData[entry.regionName], index)
                self:OpenWoundDialog(entry.regionName)
                self:UpdateRegionColors()
            end
        end)
    end

    return entry
end

function GUI:OpenNoteDialog(regionName, noteIndex)
    if not regionName then
        print("Error: regionName is nil in OpenNoteDialog")
        return
    end

    -- Check if Profile Manager is open
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        -- Option 1: Prevent opening and show an error message
        UIErrorsFrame:AddMessage(L["Cannot open note dialog while Profile Manager is open."], 1.0, 0.0, 0.0, 53, 5)
        return

        -- Option 2: Close the Profile Manager before opening the note dialog
        -- self:CloseAllDialogs()
    end

    -- Close the wound dialog when opening the note dialog
    self:CloseAllDialogs("BodyPartDialogs")

    local isEdit = noteIndex ~= nil
    local dialogBaseName = isEdit and "FleshWoundEditNoteDialog" or "FleshWoundAddNoteDialog"
    local displayRegionName = L[regionName] or regionName
    local dialogTitle = format(isEdit and L["Edit Note - %s"] or L["Add Note - %s"], displayRegionName)
    local frameName = dialogBaseName .. "_" .. regionName

    -- Always create a new dialog
    local dialog = self:CreateDialog(frameName, dialogTitle, 400, 370)
    dialog.regionName = regionName

    -- Ensure clicks do not pass through the dialog
    dialog:EnableMouse(true)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)

    -- Severity Dropdown
    dialog.SeverityLabel, dialog.SeverityDropdown = CreateSeverityDropdown(dialog)

    -- EditBox with Character Counter
    dialog.ScrollFrame, dialog.EditBox, dialog.CharCountLabel = CreateEditBoxWithCounter(dialog, MAX_NOTE_LENGTH)

    -- Save and Cancel Buttons
    dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)

    -- Store the dialog in _G for reference
    _G[frameName] = dialog

    self:PopulateNoteDialog(dialog, noteIndex)
    dialog:Show()
    dialog.EditBox:SetFocus()
end





function GUI:PopulateNoteDialog(dialog, noteIndex)
    local isEdit = noteIndex ~= nil
    local woundData = addonTable.woundData or {}
    local notes = woundData[dialog.regionName]
    dialog.noteIndex = noteIndex
    dialog.selectedSeverity = L["Unknown"]

    UIDropDownMenu_SetSelectedName(dialog.SeverityDropdown, dialog.selectedSeverity)
    UIDropDownMenu_Initialize(dialog.SeverityDropdown, dialog.SeverityDropdown.initialize)

    if isEdit then
        local note = notes[noteIndex]
        dialog.EditBox:SetText(note.text or "")
        dialog.selectedSeverity = note.severity or L["Unknown"]
        UIDropDownMenu_SetSelectedName(dialog.SeverityDropdown, dialog.selectedSeverity)
        local initialLength = strlenutf8(note.text or "")
        dialog.CharCountLabel:SetText(format(L["%d / %d"], initialLength, MAX_NOTE_LENGTH))
    else
        dialog.EditBox:SetText("")
        dialog.CharCountLabel:SetText(format(L["%d / %d"], 0, MAX_NOTE_LENGTH))
    end

    -- Update Save Button State
    local function UpdateSaveButtonState()
        local text = SanitizeInput(dialog.EditBox:GetText())
        local length = strlenutf8(text)
        dialog.CharCountLabel:SetText(format(L["%d / %d"], length, MAX_NOTE_LENGTH))

        if text == "" then
            dialog.SaveButton:Disable()
            return
        end

        -- Check for duplicate content
        woundData[dialog.regionName] = woundData[dialog.regionName] or {}
        local isDuplicate = false
        for idx, note in ipairs(woundData[dialog.regionName]) do
            if (not isEdit or idx ~= noteIndex) and note.text == text then
                isDuplicate = true
                break
            end
        end

        if isDuplicate then
            dialog.SaveButton:Disable()
            if not dialog.DuplicateWarning then
                dialog.DuplicateWarning = dialog:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
                dialog.DuplicateWarning:SetPoint("TOPLEFT", dialog.EditBox, "BOTTOMLEFT", 0, -5)
                dialog.DuplicateWarning:SetText(L["A note with this content already exists."])
            end
            dialog.DuplicateWarning:Show()
        else
            dialog.SaveButton:Enable()
            if dialog.DuplicateWarning then
                dialog.DuplicateWarning:Hide()
            end
        end
    end

    dialog.EditBox:SetScript("OnTextChanged", UpdateSaveButtonState)
    UpdateSaveButtonState()
    -- Save Button Handler
    dialog.SaveButton:SetScript("OnClick", function()
        local text = SanitizeInput(dialog.EditBox:GetText())
        local severity = dialog.selectedSeverity or L["Unknown"]
        if text and text ~= "" then
            woundData[dialog.regionName] = woundData[dialog.regionName] or {}
            if isEdit then
                woundData[dialog.regionName][noteIndex].text = text
                woundData[dialog.regionName][noteIndex].severity = severity
            else
                table.insert(woundData[dialog.regionName], { text = text, severity = severity })
            end
            self:UpdateRegionColors()
            dialog.EditBox:SetText("")
            dialog:Hide()
            self:OpenWoundDialog(dialog.regionName, true)  -- Pass true to skip closing dialogs
        else
            UIErrorsFrame:AddMessage(format(L["Error: %s"], L["Note content cannot be empty."]), 1.0, 0.0, 0.0, 53, 5)
        end
    end)

    -- Cancel Button Handler
    dialog.CancelButton:SetScript("OnClick", function()
        dialog.EditBox:SetText("")
        dialog:Hide()
        self:OpenWoundDialog(dialog.regionName, true)  -- Pass true to skip closing dialogs
    end)

end

function GUI:PopulateWoundDialog(dialog)
    local woundData = addonTable.woundData or {}
    local notes = woundData[dialog.regionName]

    -- Remove previous entries from the parent frame and hide them
    if dialog.NoteEntries then
        for _, entry in ipairs(dialog.NoteEntries) do
            entry:SetParent(nil)
            entry:Hide()
        end
    end
    dialog.NoteEntries = {}

    if notes and #notes > 0 then
        local yOffset = -10
        for i, note in ipairs(notes) do
            local entry = self:CreateNoteEntry(dialog.ScrollChild, note, i, dialog.regionName)
            entry:SetPoint("TOPLEFT", 10, yOffset)
            table.insert(dialog.NoteEntries, entry)
            yOffset = yOffset - (entry:GetHeight() + 10)
        end
        dialog.ScrollChild:SetHeight(-yOffset)
    else
        local noNotesText = dialog.ScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noNotesText:SetPoint("TOPLEFT", 10, -10)
        noNotesText:SetWidth(dialog.ScrollChild:GetWidth() - 20)
        noNotesText:SetJustifyH("CENTER")
        noNotesText:SetText(L["No notes have been added for this region."])
        table.insert(dialog.NoteEntries, noNotesText)
        dialog.ScrollChild:SetHeight(30)
    end
end



function GUI:OpenProfileManager()
    -- Close all other dialogs
    self:CloseAllDialogs()

    local frameName = "FleshWoundProfileManager"
    local dialogTitle = L["Profile Manager"]

    -- Always create a new dialog to ensure a fresh UI
    local dialog = self:CreateDialog(frameName, dialogTitle, 500, 500)

    -- Ensure clicks do not pass through the dialog
    dialog:EnableMouse(true)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)

    -- Profiles Scroll Frame
    dialog.ScrollFrame, dialog.ScrollChild = self:CreateScrollFrame(dialog, 15, -60, -35, 100)

    -- Profile Entries
    dialog.ProfileEntries = {}

    -- Create Profile Button
    dialog.CreateProfileButton = self:CreateButton(dialog, L["Create Profile"], 120, 30, "BOTTOMLEFT", 15, 15)
    dialog.CreateProfileButton:SetScript("OnClick", function()
        dialog:Hide()
        self:OpenCreateProfileDialog()
    end)

    -- Close Button
    dialog.CloseButton = self:CreateButton(dialog, L["Close"], 80, 30, "BOTTOMRIGHT", -15, 15)
    dialog.CloseButton:SetScript("OnClick", function()
        dialog:Hide()
    end)

    -- Store the dialog in _G for reference
    _G[frameName] = dialog

    self:PopulateProfileManager(dialog)
    dialog:Show()
end

-- FleshWound_GUI.lua (RestoreOriginalProfile)
function GUI:RestoreOriginalProfile()
    if self.originalWoundData then
        addonTable.woundData = self.originalWoundData
        self.originalWoundData = nil
    end

    if self.originalProfile then
        addonTable.FleshWoundData.currentProfile = self.originalProfile
        self.originalProfile = nil
    end

    self.currentTemporaryProfile = nil
    self:UpdateRegionColors()

    if self.frame then
        self.frame:Show()
    end

    -- Hide the banner since we're back to our own profile
    if self.tempProfileBannerFrame then
        self.tempProfileBannerFrame:Hide()
    end

    -- Show the profile button again now that we're back to our own profile
    if self.frame and self.frame.ProfileButton then
        self.frame.ProfileButton:Show()
    end
end


function GUI:PopulateProfileManager(dialog)
    local profiles = addonTable.FleshWoundData.profiles
    local currentProfile = addonTable.FleshWoundData.currentProfile

    -- Clear previous entries
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
        local entry = self:CreateProfileEntry(dialog.ScrollChild, profileName, currentProfile)
        entry:SetPoint("TOPLEFT", 10, yOffset)
        table.insert(dialog.ProfileEntries, entry)
        yOffset = yOffset - 50
    end

    dialog.ScrollChild:SetHeight(-yOffset)
end

function GUI:CreateProfileEntry(parent, profileName, currentProfile)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetWidth(parent:GetWidth() - 20)
    entry:SetHeight(40)
    entry:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 0,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if profileName == currentProfile then
        entry:SetBackdropColor(0.0, 0.5, 0.0, 0.5)
    else
        entry:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
    end
    entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    -- Profile Name
    local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", entry, "LEFT", 10, 0)
    nameText:SetText(profileName)

    -- Buttons
    local selectButton = self:CreateButton(entry, L["Select"], 80, 24, "RIGHT", -10, 0)
    selectButton:SetScript("OnClick", function()
        addonTable.Data:SwitchProfile(profileName)
        self:UpdateRegionColors()
        self:OpenProfileManager()
    end)

    local deleteButton = self:CreateButton(entry, L["Delete"], 80, 24, "RIGHT", selectButton, "LEFT", -5, 0)
    deleteButton:SetScript("OnClick", function()
        addonTable.Data:DeleteProfile(profileName)
        self:OpenProfileManager()
    end)
    if profileName == currentProfile then
        deleteButton:Disable()
    end

    local renameButton = self:CreateButton(entry, L["Rename"], 80, 24, "RIGHT", deleteButton, "LEFT", -5, 0)
    renameButton:SetScript("OnClick", function()
        self:OpenRenameProfileDialog(profileName)
    end)

    return entry
end
function GUI:OpenCreateProfileDialog()
    -- Close all other dialogs
    self:CloseAllDialogs()

    local frameName = "FleshWoundCreateProfileDialog"
    local dialogTitle = L["Create Profile"]

    -- Always create a new dialog to ensure a fresh UI
    local dialog = self:CreateDialog(frameName, dialogTitle, 300, 200)

    -- Ensure clicks do not pass through the dialog
    dialog:EnableMouse(true)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)

    -- Profile Name Label
    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
    nameLabel:SetText(L["Profile Name:"])

    -- Profile Name EditBox with Character Counter
    local nameEditBox, charCountLabel = CreateSingleLineEditBoxWithCounter(dialog, MAX_PROFILE_NAME_LENGTH)
    nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    dialog.nameEditBox = nameEditBox
    dialog.charCountLabel = charCountLabel

    -- Create and Cancel Buttons
    dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)
    dialog.SaveButton:SetText(L["Create"])

    -- Store the dialog in _G for reference
    _G[frameName] = dialog

    self:PopulateCreateProfileDialog(dialog)
    dialog:Show()
    dialog.nameEditBox:SetFocus()
end


function GUI:PopulateCreateProfileDialog(dialog)
    local function UpdateCreateButtonState()
        local profileName = SanitizeInput(dialog.nameEditBox:GetText())
        if profileName == "" or addonTable.FleshWoundData.profiles[profileName] then
            dialog.SaveButton:Disable()
        else
            dialog.SaveButton:Enable()
        end
    end

    dialog.nameEditBox:SetText("")
    dialog.charCountLabel:SetText(format(L["%d / %d"], 0, MAX_PROFILE_NAME_LENGTH))
    dialog.SaveButton:Disable()

    dialog.nameEditBox:SetScript("OnTextChanged", UpdateCreateButtonState)

    dialog.SaveButton:SetScript("OnClick", function()
        local profileName = SanitizeInput(dialog.nameEditBox:GetText())
        addonTable.Data:CreateProfile(profileName)
        dialog:Hide()
        self:OpenProfileManager()
    end)

    dialog.CancelButton:SetScript("OnClick", function()
        dialog:Hide()
        self:OpenProfileManager()
    end)
end

-- Open Rename Profile Dialog
function GUI:OpenRenameProfileDialog(oldProfileName)
    local frameName = "FleshWoundRenameProfileDialog"
    local dialogTitle = L["Rename Profile"]

    local dialog = _G[frameName]
    if not dialog then
        dialog = self:CreateDialog(frameName, dialogTitle, 300, 200)

        -- Profile Name Label
        local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        nameLabel:SetText(L["New Name:"])

        -- Profile Name EditBox with Character Counter
        local nameEditBox, charCountLabel = CreateSingleLineEditBoxWithCounter(dialog, MAX_PROFILE_NAME_LENGTH)
        nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
        dialog.nameEditBox = nameEditBox
        dialog.charCountLabel = charCountLabel

        -- Rename and Cancel Buttons
        dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)
        dialog.SaveButton:SetText(L["Rename"])

        _G[frameName] = dialog
    end

    self:PopulateRenameProfileDialog(dialog, oldProfileName)
    dialog:Show()
    dialog.nameEditBox:SetFocus()
end

function GUI:PopulateRenameProfileDialog(dialog, oldProfileName)
    local function UpdateRenameButtonState()
        local newProfileName = SanitizeInput(dialog.nameEditBox:GetText())
        if newProfileName == "" or addonTable.FleshWoundData.profiles[newProfileName] or newProfileName == oldProfileName then
            dialog.SaveButton:Disable()
        else
            dialog.SaveButton:Enable()
        end
    end

    dialog.nameEditBox:SetText(oldProfileName)
    local initialLength = strlenutf8(oldProfileName)
    dialog.charCountLabel:SetText(format(L["%d / %d"], initialLength, MAX_PROFILE_NAME_LENGTH))
    dialog.SaveButton:Disable()

    dialog.nameEditBox:SetScript("OnTextChanged", UpdateRenameButtonState)

    dialog.SaveButton:SetScript("OnClick", function()
        local newProfileName = SanitizeInput(dialog.nameEditBox:GetText())
        addonTable.Data:RenameProfile(oldProfileName, newProfileName)
        dialog:Hide()
        self:OpenProfileManager()
    end)

    dialog.CancelButton:SetScript("OnClick", function()
        dialog:Hide()
        self:OpenProfileManager()
    end)
end

-- Utility Methods
function GUI:CreateScrollFrame(parent, left, top, right, bottom)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", right, bottom)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)

    return scrollFrame, scrollChild
end

function GUI:CreateButton(parent, text, width, height, point, relativeTo, offsetX, offsetY)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    if type(relativeTo) == "string" then
        button:SetPoint(point, parent, relativeTo, offsetX, offsetY)
    else
        button:SetPoint(point, relativeTo, offsetX, offsetY)
    end
    button:SetText(text)
    return button
end

function GUI:CloseAllDialogs(dialogType)
    local dialogsToClose = {}

    if dialogType == "BodyPartDialogs" then
        -- Only close body part dialogs
        dialogsToClose = {
            "FleshWoundDialog_",
        }
    else
        -- Close all dialogs
        dialogsToClose = {
            "FleshWoundDialog_",
            "FleshWoundAddNoteDialog_",
            "FleshWoundEditNoteDialog_",
            "FleshWoundProfileManager",
            "FleshWoundCreateProfileDialog",
            "FleshWoundRenameProfileDialog",
        }
    end

    for _, framePrefix in ipairs(dialogsToClose) do
        for frameName, frame in pairs(_G) do
            if type(frameName) == "string" and frameName:match("^" .. framePrefix) and type(frame) == "table" and frame.Hide then
                frame:Hide()
            end
        end
    end
end


-- Initialize the GUI when the addon loads
-- GUI:Initialize()  -- Do not call Initialize here; it should be called after the Data module is initialized

