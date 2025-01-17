-- FleshWound_GUI.lua
-- Contains all GUI-related functions and data persistence in the UI layer.

local addonName, addonTable = ...
local L = addonTable.L
local Utils = addonTable.Utils

local GUI = {}
addonTable.GUI = GUI

local MAX_NOTE_LENGTH = 125
local MAX_PROFILE_NAME_LENGTH = 50

StaticPopupDialogs["FW_DELETE_PROFILE_CONFIRM"] = {
    text = L["Delete profile confirmation"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local profileName = self.data
        addonTable.Data:DeleteProfile(profileName)
        if addonTable.GUI and addonTable.GUI.OpenProfileManager then
            addonTable.GUI:OpenProfileManager()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


-- Severity definitions
local Severities = {
    { name = L["None"],     color = {0, 0, 0, 0.0} },
    { name = L["Unknown"],  color = {0.5, 0.5, 0.5, 0.4} },
    { name = L["Benign"],   color = {0, 1, 0, 0.4} },
    { name = L["Moderate"], color = {1, 1, 0, 0.4} },
    { name = L["Severe"],   color = {1, 0.5, 0, 0.4} },
    { name = L["Critical"], color = {1, 0, 0, 0.4} },
    { name = L["Deadly"],   color = {0.6, 0, 0.6, 0.4} },
}

local SeverityLevels = {}
for index, severity in ipairs(Severities) do
    SeverityLevels[severity.name] = index - 2
end

-- Simple string sanitization
local function SanitizeInput(text)
    text = text:match("^%s*(.-)%s*$") or ""
    text = text:gsub("[%c]", "")
    return text
end

local function GetSeverityColor(severityName)
    for _, severity in ipairs(Severities) do
        if severity.name == severityName then
            return severity.color
        end
    end
    return {0, 0, 0, 0.0}
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

--------------------------------------------------------------------------------
-- ANCHOR SAVING/RESTORING FOR ANY WINDOW
--------------------------------------------------------------------------------

-- Save a frame's position in FleshWoundData.positions[frameName]
function GUI:SaveWindowPosition(frameName, frame)
    addonTable.FleshWoundData.positions = addonTable.FleshWoundData.positions or {}
    local pos = addonTable.FleshWoundData.positions

    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    pos[frameName] = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs,
    }
end

-- Restore a frame's position from FleshWoundData.positions[frameName]
function GUI:RestoreWindowPosition(frameName, frame)
    local pos = addonTable.FleshWoundData.positions and addonTable.FleshWoundData.positions[frameName]
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        frame:SetPoint("CENTER")
    end
end

--------------------------------------------------------------------------------

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
    dialog:EnableMouse(true)

    -- We'll rely on MakeFrameDraggable, then override OnDragStop
    Utils.MakeFrameDraggable(dialog, nil)

    dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    dialog.CloseButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
    dialog.CloseButton:SetScript("OnClick", function()
        dialog:Hide()
    end)

    if name and name ~= "" then
        table.insert(UISpecialFrames, name)
    end

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)
    title:SetText(titleText)

    local titleLine = dialog:CreateTexture(nil, "ARTWORK")
    titleLine:SetHeight(2)
    titleLine:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    titleLine:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -15, -40)
    titleLine:SetColorTexture(1, 1, 1, 0.2)

    return dialog
end

local function CreateSeverityDropdown(parent)
    local severityLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    severityLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -60)
    severityLabel:SetText(L["Severity:"])

    local severityDropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    severityDropdown:SetPoint("LEFT", severityLabel, "RIGHT", -10, -3)
    UIDropDownMenu_SetWidth(severityDropdown, 150)

    severityDropdown.initialize = function(self, level)
        for _, sev in ipairs(Severities) do
            local info = UIDropDownMenu_CreateInfo()
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

local function CreateEditBoxWithCounter(parent, maxChars)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent.SeverityLabel, "BOTTOMLEFT", 0, -20)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -35, 80)

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
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    editBox:SetBackdropColor(0, 0, 0, 0.5)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    scrollFrame:SetScrollChild(editBox)

    local charCountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charCountLabel:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
    charCountLabel:SetText(string.format(L["%d / %d"], 0, maxChars))

    -- Attach OnTextChanged hook for dynamic updates
    editBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        local length = strlenutf8(text)
        charCountLabel:SetText(string.format(L["%d / %d"], length, maxChars))
    end)

    return scrollFrame, editBox, charCountLabel
end


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

local function CreateSingleLineEditBoxWithCounter(parent, maxChars)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetAutoFocus(true)
    editBox:SetMaxLetters(maxChars)
    editBox:SetSize(160, 30)

    local charCountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charCountLabel:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -5)
    charCountLabel:SetText(string.format(L["%d / %d"], 0, maxChars))

    editBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        local length = strlenutf8(text)
        charCountLabel:SetText(string.format(L["%d / %d"], length, maxChars))
    end)

    return editBox, charCountLabel
end



--------------------------------------------------------------------------------
-- MAIN GUI INITIALIZATION
--------------------------------------------------------------------------------

function GUI:Initialize()
    self.woundData = addonTable.woundData or {}

    self:CreateMainFrame()            -- The main 320x540 frame
    self:RestoreWindowPosition("FleshWoundFrame", self.frame)
    self:CreateBodyRegions()
    self:CreateTemporaryProfileBanner()
    self:UpdateRegionColors()
    self:UpdateProfileBanner()
end

function GUI:UpdateProfileBanner()
    if not self.frame or not self.tempProfileBannerFrame or not self.tempProfileBanner then return end

    local currentProfileName = addonTable.FleshWoundData.currentProfile
    if self.currentTemporaryProfile then
        self.tempProfileBanner:SetText(string.format(L["Viewing %s's Profile"], self.currentTemporaryProfile))
    else
        -- e.g. "Profile of X" or "Viewing X's Profile"
        -- If you want a different phrasing, change below:
        self.tempProfileBanner:SetText(string.format(L["Viewing %s's Profile"], currentProfileName))
    end
    self.tempProfileBannerFrame:Show()
end

function GUI:CreateTemporaryProfileBanner()
    if not self.frame then return end

    local bannerFrame = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    bannerFrame:SetSize(self.frame:GetWidth() - 20, 30)
    bannerFrame:SetPoint("TOP", self.frame, "TOP", 0, 25)
    bannerFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    bannerFrame:SetBackdropColor(0, 0, 0, 0.7)
    bannerFrame:Hide()

    local bannerText = bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bannerText:SetPoint("CENTER", bannerFrame, "CENTER", 0, 0)
    bannerText:SetJustifyH("CENTER")
    bannerText:SetTextColor(1, 0.8, 0, 1)

    self.tempProfileBannerFrame = bannerFrame
    self.tempProfileBanner = bannerText
end

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
    self:UpdateProfileBanner()

    if self.frame and self.frame.ProfileButton then
        self.frame.ProfileButton:Show()
    end
end

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

    -- Make draggable, saving anchor on drag stop:
    Utils.MakeFrameDraggable(frame, function(f)
        self:SaveWindowPosition("FleshWoundFrame", f)
    end)

    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:SetScript("OnHide", function()
        if GUI.currentTemporaryProfile then
            GUI:RestoreOriginalProfile()
        end
    end)

    frame.ProfileButton = CreateFrame("Button", nil, frame)
    frame.ProfileButton:SetSize(35, 35)
    frame.ProfileButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
    frame.ProfileButton:SetNormalTexture("Interface\\ICONS\\INV_Misc_Book_09")
    frame.ProfileButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    frame.ProfileButton:SetScript("OnClick", function()
        -- If a note dialog is open, close it before opening the Profile Manager
        for frameName, frm in pairs(_G) do
            if type(frameName) == "string"
               and (frameName:match("^FleshWoundAddNoteDialog_") or frameName:match("^FleshWoundEditNoteDialog_"))
               and frm:IsShown()
            then
                frm:Hide()  -- Close the note dialog
            end
        end
        
        -- Now open the profile manager
        self:OpenProfileManager()
    end)
    

    table.insert(UISpecialFrames, frame:GetName())

    frame.BodyImage = frame:CreateTexture(nil, "BACKGROUND")
    frame.BodyImage:SetSize(300, 500)
    frame.BodyImage:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.BodyImage:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Textures\\body_image.tga")
end

function GUI:CreateBodyRegions()
    local frame = self.frame
    frame.BodyRegions = {}

    local regions = {
        { name = "Head",      x = 130, y = 420, width = 50,  height = 75 },
        { name = "Torso",     x = 130, y = 275, width = 50,  height = 120 },
        { name = "Left Arm",  x = 75,  y = 300, width = 50,  height = 120 },
        { name = "Right Arm", x = 185, y = 300, width = 50,  height = 120 },
        { name = "Left Hand", x = 40,  y = 180, width = 50,  height = 100 },
        { name = "Right Hand",x = 215, y = 180, width = 50,  height = 100 },
        { name = "Left Leg",  x = 100, y = 50,  width = 50,  height = 130 },
        { name = "Right Leg", x = 155, y = 50,  width = 50,  height = 130 },
        { name = "Left Foot", x = 110, y = 0,   width = 50,  height = 50 },
        { name = "Right Foot",x = 150, y = 0,   width = 50,  height = 50 },
    }

    for _, region in ipairs(regions) do
        self:CreateBodyRegion(frame, region)
    end
end

function GUI:CreateBodyRegion(frame, region)
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(region.width, region.height)
    btn:SetPoint("BOTTOMLEFT", frame.BodyImage, "BOTTOMLEFT", region.x, region.y)
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    btn:SetScript("OnClick", function()
        self:OpenWoundDialog(region.name)
    end)

    local regionMarker = btn:CreateTexture(nil, "OVERLAY")
    regionMarker:SetSize(10, 10)
    regionMarker:SetPoint("CENTER", btn, "CENTER")
    regionMarker:SetColorTexture(0, 1, 0, 1)
    btn.regionMarker = regionMarker

    local overlay = btn:CreateTexture(nil, "ARTWORK")
    local inset = 7
    overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
    overlay:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
    overlay:SetColorTexture(0, 0, 0, 0)
    btn.overlay = overlay

    frame.BodyRegions[region.name] = btn
end

function GUI:UpdateRegionColors()
    local frame = self.frame
    if not frame or not frame.BodyRegions then return end

    for regionName, btn in pairs(frame.BodyRegions) do
        local highestSeverity = GetHighestSeverity(regionName)
        local color = GetSeverityColor(highestSeverity)
        btn.overlay:SetColorTexture(unpack(color))
    end
end

--------------------------------------------------------------------------------
--  WINDOW CREATION HELPERS
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--  WOUND DIALOGS
--------------------------------------------------------------------------------

function GUI:OpenWoundDialog(regionName, skipCloseDialogs)
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        _G["FleshWoundProfileManager"]:Hide()
    end

    if not skipCloseDialogs then
        self:CloseAllDialogs("BodyPartDialogs")
    end

    local dialogName = "FleshWoundDialog_" .. regionName
    local displayName = L[regionName] or regionName
    local dialogTitle = string.format(L["Wound Details - %s"], displayName)

    local dialog = CreateDialog(dialogName, dialogTitle, 550, 500)
    dialog.regionName = regionName

    -- Override drag stop to save position
    dialog:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        self:SaveWindowPosition(dialogName, f)
    end)
    -- Restore last position
    self:RestoreWindowPosition(dialogName, dialog)

    dialog.ScrollFrame, dialog.ScrollChild = self:CreateScrollFrame(dialog, 15, -60, -35, 60)
    dialog.NoteEntries = {}

    if not self.currentTemporaryProfile then
        dialog.AddNoteButton = self:CreateButton(dialog, L["Add Note"], 120, 30, "BOTTOMLEFT", 15, 15)
        dialog.AddNoteButton:SetScript("OnClick", function()
            dialog:Hide()
            self:OpenNoteDialog(regionName)
        end)
    end

    _G[dialogName] = dialog

    self:PopulateWoundDialog(dialog)
    dialog:Show()
end

function GUI:PopulateWoundDialog(dialog)
    local woundData = addonTable.woundData or {}
    local notes = woundData[dialog.regionName]

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

function GUI:CreateNoteEntry(parent, note, index, regionName)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetWidth(parent:GetWidth() - 20)
    entry:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 14,
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
        Utils.FW_Print("Error: regionName is nil in OpenNoteDialog", true)
        return
    end

    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        UIErrorsFrame:AddMessage(L["Cannot open note dialog while Profile Manager is open."], 1.0, 0.0, 0.0, 5)
        return
    end

    self:CloseAllDialogs("BodyPartDialogs")

    local isEdit = (noteIndex ~= nil)
    local baseName = isEdit and "FleshWoundEditNoteDialog" or "FleshWoundAddNoteDialog"
    local displayRegionName = L[regionName] or regionName
    local dialogTitle = isEdit and string.format(L["Edit Note - %s"], displayRegionName)
                                 or string.format(L["Add Note - %s"], displayRegionName)
    local frameName = baseName .. "_" .. regionName

    local dialog = CreateDialog(frameName, dialogTitle, 400, 370)
    dialog.regionName = regionName

    -- Make it draggable individually
    Utils.MakeFrameDraggable(dialog, function(f)
        self:SaveWindowPosition(frameName, f)
    end)
    self:RestoreWindowPosition(frameName, dialog)

    dialog.SeverityLabel, dialog.SeverityDropdown = CreateSeverityDropdown(dialog)
    dialog.ScrollFrame, dialog.EditBox, dialog.CharCountLabel = CreateEditBoxWithCounter(dialog, MAX_NOTE_LENGTH)
    dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)

    _G[frameName] = dialog
    self:PopulateNoteDialog(dialog, noteIndex)
    dialog:Show()
    dialog.EditBox:SetFocus()
end

function GUI:PopulateNoteDialog(dialog, noteIndex)
    local isEdit = (noteIndex ~= nil)
    local woundData = addonTable.woundData or {}
    local notes = woundData[dialog.regionName]
    dialog.noteIndex = noteIndex
    dialog.selectedSeverity = L["Unknown"]

    UIDropDownMenu_SetSelectedName(dialog.SeverityDropdown, dialog.selectedSeverity)
    UIDropDownMenu_Initialize(dialog.SeverityDropdown, dialog.SeverityDropdown.initialize)

    if isEdit and notes and notes[noteIndex] then
        local note = notes[noteIndex]
        dialog.EditBox:SetText(note.text or "")
        dialog.selectedSeverity = note.severity or L["Unknown"]
        UIDropDownMenu_SetSelectedName(dialog.SeverityDropdown, dialog.selectedSeverity)

        local initialLen = strlenutf8(note.text or "")
        dialog.CharCountLabel:SetText(string.format(L["%d / %d"], initialLen, MAX_NOTE_LENGTH))
    else
        dialog.EditBox:SetText("")
        dialog.CharCountLabel:SetText(string.format(L["%d / %d"], 0, MAX_NOTE_LENGTH))
    end

    local function UpdateSaveButtonState()
        local text = SanitizeInput(dialog.EditBox:GetText())
        local length = strlenutf8(text)
        dialog.CharCountLabel:SetText(string.format(L["%d / %d"], length, MAX_NOTE_LENGTH))

        if text == "" then
            dialog.SaveButton:Disable()
            return
        end

        local isDuplicate = false
        for idx, n in ipairs(woundData[dialog.regionName] or {}) do
            if (not isEdit or idx ~= noteIndex) and n.text == text then
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

    dialog.SaveButton:SetScript("OnClick", function()
        local text = SanitizeInput(dialog.EditBox:GetText())
        local severity = dialog.selectedSeverity or L["Unknown"]
        if text and text ~= "" then
            woundData[dialog.regionName] = woundData[dialog.regionName] or {}
            if isEdit and notes and notes[noteIndex] then
                notes[noteIndex].text = text
                notes[noteIndex].severity = severity
            else
                table.insert(woundData[dialog.regionName], { text = text, severity = severity })
            end
            self:UpdateRegionColors()
            dialog.EditBox:SetText("")
            dialog:Hide()
            self:OpenWoundDialog(dialog.regionName, true)
        else
            UIErrorsFrame:AddMessage(string.format(L["Error: %s"], L["Note content cannot be empty."]), 1.0, 0.0, 0.0, 5)
        end
    end)

    dialog.CancelButton:SetScript("OnClick", function()
        dialog.EditBox:SetText("")
        dialog:Hide()
        self:OpenWoundDialog(dialog.regionName, true)
    end)
end

--------------------------------------------------------------------------------
--  PROFILE MANAGER WINDOW
--------------------------------------------------------------------------------

function GUI:OpenProfileManager()
    self:CloseAllDialogs()

    local frameName = "FleshWoundProfileManager"
    local dialogTitle = L["Profile Manager"]

    local dialog = CreateDialog(frameName, dialogTitle, 500, 500)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)

    -- Make draggable, save/restore anchor
    Utils.MakeFrameDraggable(dialog, function(f)
        self:SaveWindowPosition(frameName, f)
    end)
    self:RestoreWindowPosition(frameName, dialog)

    dialog.ScrollFrame, dialog.ScrollChild = self:CreateScrollFrame(dialog, 15, -60, -35, 100)
    dialog.ProfileEntries = {}

    dialog.CreateProfileButton = self:CreateButton(dialog, L["Create Profile"], 120, 30, "BOTTOMLEFT", 15, 15)
    dialog.CreateProfileButton:SetScript("OnClick", function()
        dialog:Hide()
        self:OpenCreateProfileDialog()
    end)

    dialog.CloseButton = self:CreateButton(dialog, L["Close"], 80, 30, "BOTTOMRIGHT", -15, 15)
    dialog.CloseButton:SetScript("OnClick", function()
        dialog:Hide()
    end)

    _G[frameName] = dialog

    self:PopulateProfileManager(dialog)
    dialog:Show()
end

function GUI:PopulateProfileManager(dialog)
    local profiles = addonTable.FleshWoundData.profiles
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
        tile = false, tileSize = 0, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    if profileName == currentProfile then
        entry:SetBackdropColor(0.0, 0.5, 0.0, 0.5)
    else
        entry:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
    end
    entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", entry, "LEFT", 10, 0)
    nameText:SetText(profileName)

    -- Calculate number of characters using this profile
    local charProfiles = addonTable.FleshWoundData.charProfiles or {}
    local usageCount = 0
    for _, pName in pairs(charProfiles) do
        if pName == profileName then
            usageCount = usageCount + 1
        end
    end

    -- Create an icon for character count
    local iconSize = 16
    local iconTexture = entry:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(iconSize, iconSize)
    iconTexture:SetTexture("Interface\\Icons\\INV_Misc_Bandage_01")  -- Choose an appropriate icon
    iconTexture:SetPoint("LEFT", nameText, "RIGHT", 10, 0)

    -- Create a label next to the icon showing the usage count
    local countText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("LEFT", iconTexture, "RIGHT", 2, 0)
    countText:SetText(tostring(usageCount))

    local selectButton = self:CreateButton(entry, L["Select"], 80, 24, "RIGHT", -10, 0)
    selectButton:SetScript("OnClick", function()
        addonTable.Data:SwitchProfile(profileName)
        self:UpdateRegionColors()
        self:OpenProfileManager()
    end)

    local deleteButton = self:CreateButton(entry, L["Delete"], 80, 24, "RIGHT", selectButton, "LEFT", -5, 0)
    deleteButton:SetScript("OnClick", function()
        StaticPopup_Show("FW_DELETE_PROFILE_CONFIRM", profileName, nil, profileName)
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



--------------------------------------------------------------------------------
--  CREATE PROFILE DIALOG
--------------------------------------------------------------------------------

function GUI:OpenCreateProfileDialog()
    self:CloseAllDialogs()

    local frameName = "FleshWoundCreateProfileDialog"
    local dialogTitle = L["Create Profile"]

    local dialog = CreateDialog(frameName, dialogTitle, 300, 200)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)

    -- Make draggable, save/restore anchor
    Utils.MakeFrameDraggable(dialog, function(f)
        self:SaveWindowPosition(frameName, f)
    end)
    self:RestoreWindowPosition(frameName, dialog)

    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
    nameLabel:SetText(L["Profile Name:"])

    local nameEditBox, charCountLabel = CreateSingleLineEditBoxWithCounter(dialog, MAX_PROFILE_NAME_LENGTH)
    nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    dialog.nameEditBox = nameEditBox
    dialog.charCountLabel = charCountLabel

    dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)
    dialog.SaveButton:SetText(L["Create"])

    _G[frameName] = dialog

    self:PopulateCreateProfileDialog(dialog)
    dialog:Show()
    dialog.nameEditBox:SetFocus()
end

function GUI:PopulateCreateProfileDialog(dialog)
    local function UpdateCreateButtonState()
        local text = dialog.nameEditBox:GetText()
        local profileName = SanitizeInput(text)
        local length = strlenutf8(text)

        -- Update character count dynamically
        dialog.charCountLabel:SetText(string.format(L["%d / %d"], length, MAX_PROFILE_NAME_LENGTH))

        if profileName == "" or addonTable.FleshWoundData.profiles[profileName] then
            dialog.SaveButton:Disable()
        else
            dialog.SaveButton:Enable()
        end
    end

    dialog.nameEditBox:SetText("")
    dialog.charCountLabel:SetText(string.format(L["%d / %d"], 0, MAX_PROFILE_NAME_LENGTH))
    dialog.SaveButton:Disable()

    -- Attach combined update function to OnTextChanged
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

--------------------------------------------------------------------------------
--  RENAME PROFILE DIALOG
--------------------------------------------------------------------------------

function GUI:OpenRenameProfileDialog(oldProfileName)
    local frameName = "FleshWoundRenameProfileDialog"
    local dialogTitle = L["Rename Profile"]

    -- Hide the Profile Manager if it's open, so the rename dialog appears on top
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        _G["FleshWoundProfileManager"]:Hide()
    end

    local dialog = _G[frameName]
    if not dialog then
        dialog = CreateDialog(frameName, dialogTitle, 300, 200)

        -- Make draggable, but do it after creation:
        Utils.MakeFrameDraggable(dialog, function(f)
            self:SaveWindowPosition(frameName, f)
        end)

        local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        nameLabel:SetText(L["New Name:"])

        local nameEditBox, charCountLabel = CreateSingleLineEditBoxWithCounter(dialog, MAX_PROFILE_NAME_LENGTH)
        nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
        dialog.nameEditBox = nameEditBox
        dialog.charCountLabel = charCountLabel

        dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)
        dialog.SaveButton:SetText(L["Rename"])

        _G[frameName] = dialog
    end

    -- Restore position each time we open it
    self:RestoreWindowPosition(frameName, dialog)

    self:PopulateRenameProfileDialog(dialog, oldProfileName)
    dialog:Show()
    dialog.nameEditBox:SetFocus()
end


function GUI:PopulateRenameProfileDialog(dialog, oldProfileName)
    local function UpdateRenameButtonState()
        local text = dialog.nameEditBox:GetText()
        local newProfileName = SanitizeInput(text)
        local length = strlenutf8(text)
        
        -- Update character count dynamically
        dialog.charCountLabel:SetText(string.format(L["%d / %d"], length, MAX_PROFILE_NAME_LENGTH))
        
        if newProfileName == "" or addonTable.FleshWoundData.profiles[newProfileName] or newProfileName == oldProfileName then
            dialog.SaveButton:Disable()
        else
            dialog.SaveButton:Enable()
        end
    end

    dialog.nameEditBox:SetText(oldProfileName)
    local initialLength = strlenutf8(oldProfileName)
    dialog.charCountLabel:SetText(string.format(L["%d / %d"], initialLength, MAX_PROFILE_NAME_LENGTH))
    dialog.SaveButton:Disable()

    -- Attach our combined update function to OnTextChanged
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


--------------------------------------------------------------------------------
--  CLOSE ALL DIALOGS
--------------------------------------------------------------------------------

function GUI:CloseAllDialogs(dialogType)
    local dialogsToClose = {}

    if dialogType == "BodyPartDialogs" then
        dialogsToClose = { "FleshWoundDialog_" }
    else
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
        for frameName, frameObj in pairs(_G) do
            if type(frameName) == "string"
               and frameName:match("^" .. framePrefix)
               and type(frameObj) == "table"
               and frameObj.Hide
            then
                frameObj:Hide()
            end
        end
    end
end

--------------------------------------------------------------------------------

return GUI
