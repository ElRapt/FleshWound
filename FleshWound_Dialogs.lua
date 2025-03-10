-- FleshWound_Dialogs.lua
local addonName, addonTable = ...
local GUI = addonTable.GUI
local Dialogs = {}
addonTable.Dialogs = Dialogs
local CONSTANTS = GUI.CONSTANTS
local L = addonTable.L

local function getActiveWoundData()
    if GUI.displayingRemote and GUI.activeRemoteProfileName then
        return addonTable.remoteProfiles[GUI.activeRemoteProfileName] or {}
    end
    return addonTable.woundData or {}
end

function Dialogs:CreateDialog(name, titleText, width, height)
    if type(width) ~= "number" or type(height) ~= "number" then
        error(string.format("Invalid dialog size: width=%s, height=%s", tostring(width), tostring(height)))
        return nil
    end

    local dialog = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    dialog:SetSize(width, height)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop(CONSTANTS.BACKDROPS.GENERIC_DIALOG)
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    addonTable.Utils.MakeFrameDraggable(dialog, nil)

    dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    dialog.CloseButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
    dialog.CloseButton:SetScript("OnClick", function() dialog:Hide() end)

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

function Dialogs:CreateSeverityDropdown(parent)
    local severityLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    severityLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -60)
    severityLabel:SetText(L.SEVERITY or "Severity")

    local severityDropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    severityDropdown:SetPoint("LEFT", severityLabel, "RIGHT", -10, -3)
    UIDropDownMenu_SetWidth(severityDropdown, 150)

    severityDropdown.initialize = function(dropdown, level)
        for _, sev in ipairs(GUI.Severities) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = sev.displayName
            info.arg1 = sev.id
            info.func = function(_, chosenID)
                UIDropDownMenu_SetSelectedValue(dropdown, chosenID)
                parent.selectedSeverityID = chosenID
            end
            info.checked = (sev.id == (parent.selectedSeverityID or 1))
            UIDropDownMenu_AddButton(info)
        end
    end

    function severityDropdown:SetSeverityID(id)
        parent.selectedSeverityID = id
        UIDropDownMenu_SetSelectedValue(severityDropdown, id)
    end

    return severityLabel, severityDropdown
end

function Dialogs:CreateStatusSelection(parent)
    local frame = CreateFrame("Frame", nil, parent)
    local numStatuses = #GUI.Statuses
    local height = 30 * (numStatuses + 1)
    frame:SetSize(400, height)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -100)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT")
    label:SetText(L.STATUS or "Status")

    frame.checkboxes = {}
    frame.selectedStatusIDs = {}

    local yOffset = -20
    for _, st in ipairs(GUI.Statuses) do
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, yOffset)
        cb.text:SetText(st.displayName)
        cb:SetScript("OnClick", function(self)
            if st.id == 1 then
                if self:GetChecked() then
                    wipe(frame.selectedStatusIDs)
                    frame.selectedStatusIDs[1] = true
                    for otherID, otherCb in pairs(frame.checkboxes) do
                        if otherID ~= 1 then
                            otherCb:SetChecked(false)
                        end
                    end
                else
                    frame.selectedStatusIDs[1] = nil
                end
            else
                if self:GetChecked() then
                    frame.selectedStatusIDs[st.id] = true
                    if frame.checkboxes[1] and frame.checkboxes[1]:GetChecked() then
                        frame.checkboxes[1]:SetChecked(false)
                        frame.selectedStatusIDs[1] = nil
                    end
                else
                    frame.selectedStatusIDs[st.id] = nil
                end
            end
        end)
        frame.checkboxes[st.id] = cb
        yOffset = yOffset - 20
    end

    function frame:SetStatusIDs(idTable)
        for id, cb in pairs(frame.checkboxes) do
            cb:SetChecked(false)
        end
        wipe(frame.selectedStatusIDs)
        if idTable then
            for _, stID in ipairs(idTable) do
                if frame.checkboxes[stID] then
                    frame.checkboxes[stID]:SetChecked(true)
                    frame.selectedStatusIDs[stID] = true
                end
            end
        end
    end

    return frame
end

function Dialogs:CreateEditBoxWithCounter(parent, maxChars)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    local topAnchor = parent.StatusLabel or parent.StatusSelection
    if topAnchor then
        scrollFrame:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", 0, -20)
    else
        scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -120)
    end
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -35, 80)

    local editBox = CreateFrame("EditBox", nil, scrollFrame, "BackdropTemplate")
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetMaxLetters(maxChars)
    editBox:SetAutoFocus(true)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetTextInsets(10, 10, 10, 10)
    editBox:SetBackdrop(CONSTANTS.BACKDROPS.EDIT_BOX)
    editBox:SetBackdropColor(0, 0, 0, 0.5)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    scrollFrame:SetScrollChild(editBox)

    local charCountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charCountLabel:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, 50)
    charCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", 0, maxChars))

    editBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        local length = strlenutf8(text)
        charCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", length, maxChars))
    end)

    return scrollFrame, editBox, charCountLabel
end

function Dialogs:CreateSaveCancelButtons(parent)
    local saveButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    saveButton:SetSize(80, 24)
    saveButton:SetPoint("BOTTOMRIGHT", parent, "BOTTOM", -10, 15)
    saveButton:SetText(L.SAVE or "Save")

    local cancelButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 24)
    cancelButton:SetPoint("BOTTOMLEFT", parent, "BOTTOM", 10, 15)
    cancelButton:SetText(L.CANCEL or "Cancel")

    return saveButton, cancelButton
end

function Dialogs:CreateSingleLineEditBoxWithCounter(parent, maxChars)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetAutoFocus(true)
    editBox:SetMaxLetters(maxChars)
    editBox:SetSize(160, 30)

    local charCountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charCountLabel:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -5)
    charCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", 0, maxChars))

    editBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        local length = strlenutf8(text)
        charCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", length, maxChars))
    end)

    return editBox, charCountLabel
end

function Dialogs:OpenWoundDialog(regionID, skipCloseDialogs)
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        _G["FleshWoundProfileManager"]:Hide()
    end
    if not skipCloseDialogs then
        self:CloseAllDialogs("BodyPartDialogs")
    end

    local regionData
    for _, rData in ipairs(CONSTANTS.REGIONS) do
        if rData.id == regionID then
            regionData = rData
            break
        end
    end
    local displayName = regionData and regionData.localName or ("Unknown Region " .. tostring(regionID))
    local dialogName = "FleshWoundDialog_" .. regionID
    local dialogTitle = string.format(L.WOUND_DETAILS or "Wound Details: %s", displayName)

    local dialog = self:CreateDialog(dialogName, dialogTitle, CONSTANTS.SIZES.GENERIC_DIALOG_WIDTH, CONSTANTS.SIZES.GENERIC_DIALOG_HEIGHT)
    dialog.regionID = regionID
    dialog:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        GUI:SaveWindowPosition(dialogName, f)
    end)

    GUI:RestoreWindowPosition(dialogName, dialog)

    dialog.ScrollFrame, dialog.ScrollChild = GUI:CreateScrollFrame(dialog, 15, -60, -35, 60)
    dialog.NoteEntries = {}

    -- Hide the "Add Note" button if we're displaying remote data
    if not GUI.displayingRemote then
        dialog.AddNoteButton = GUI:CreateButton(dialog, L.ADD_NOTE or "Add Note", 120, 30, "BOTTOMLEFT", 15, 15)
        dialog.AddNoteButton:SetScript("OnClick", function()
            dialog:Hide()
            self:OpenNoteDialog(regionID)
        end)
    end

    _G[dialogName] = dialog
    self:PopulateWoundDialog(dialog)
    dialog:Show()
end

function Dialogs:PopulateWoundDialog(dialog)
    local data = getActiveWoundData()
    local notes = data[dialog.regionID]

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
            local entry = self:CreateNoteEntry(dialog.ScrollChild, note, i, dialog.regionID)
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
        noNotesText:SetText(L.NO_NOTES or "No Notes")
        table.insert(dialog.NoteEntries, noNotesText)
        dialog.ScrollChild:SetHeight(30)
    end
end

function Dialogs:CreateNoteEntry(parent, note, index, regionID)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetWidth(parent:GetWidth() - 20)
    entry:SetBackdrop(CONSTANTS.BACKDROPS.TOOLTIP_FRAME)

    local sevID = note.severityID or 1
    local sev = GUI.SeveritiesByID[sevID] or { color = {0,0,0,0} }
    local r, g, b, a = sev.color[1], sev.color[2], sev.color[3], sev.color[4]
    entry:SetBackdropColor(r, g, b, a)
    entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    entry:EnableMouse(true)
    entry:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(note.text or "", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    entry:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local iconSpacing = 4
    local iconSize = 16
    local xOffset = 10

    if type(note.statusIDs) == "table" then
        for _, stID in ipairs(note.statusIDs) do
            local st = GUI.StatusesByID[stID]
            if st and st.icon then
                local iconButton = CreateFrame("Button", nil, entry, "BackdropTemplate")
                iconButton:SetSize(iconSize, iconSize)
                iconButton:SetPoint("TOPLEFT", entry, "TOPLEFT", xOffset, -10)

                local statusIcon = iconButton:CreateTexture(nil, "ARTWORK")
                statusIcon:SetAllPoints(iconButton)
                statusIcon:SetTexture(st.icon)

                iconButton:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(st.displayName, 1, 1, 1)
                    GameTooltip:Show()
                end)
                iconButton:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                xOffset = xOffset + iconSize + iconSpacing
            end
        end
    end

    local reservedForButtons = 160
    local availableWidth = entry:GetWidth() - xOffset - reservedForButtons
    if availableWidth < 40 then
        availableWidth = 40
    end

    local noteText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    noteText:SetPoint("TOPLEFT", entry, "TOPLEFT", xOffset, -10)
    noteText:SetWidth(availableWidth)
    noteText:SetWordWrap(true)
    noteText:SetJustifyH("LEFT")
    noteText:SetJustifyV("TOP")
    noteText:SetText(note.text or "")

    local textHeight = noteText:GetStringHeight() + 20
    entry:SetHeight(textHeight)
    entry.regionID = regionID

    -- Hide Edit/Delete if remote
    if not GUI.displayingRemote then
        local editButton = GUI:CreateButton(entry, L.EDIT or "Edit", 70, 22, "TOPRIGHT", -80, -5)
        editButton:SetScript("OnClick", function()
            entry:GetParent():GetParent():Hide()
            self:OpenNoteDialog(entry.regionID, index)
        end)

        local deleteButton = GUI:CreateButton(entry, L.DELETE or "Delete", 70, 22, "TOPRIGHT", -10, -5)
        deleteButton:SetScript("OnClick", function()
            local data = getActiveWoundData()
            if data[entry.regionID] then
                table.remove(data[entry.regionID], index)
                self:OpenWoundDialog(entry.regionID)
                GUI:UpdateRegionColors()
            end
        end)
    end

    return entry
end

function Dialogs:OpenNoteDialog(regionID, noteIndex)
    if not regionID then
        addonTable.Utils.FW_Print("Error: regionID is nil in OpenNoteDialog", true)
        return
    end
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        UIErrorsFrame:AddMessage(L.CANNOT_OPEN_PM_WHILE_NOTE or "Cannot open Profile Manager while note dialog is open.", 1.0, 0.0, 0.0, 5)
        return
    end
    self:CloseAllDialogs("BodyPartDialogs")

    local isEdit = (noteIndex ~= nil)
    local baseName = isEdit and "FleshWoundEditNoteDialog" or "FleshWoundAddNoteDialog"
    local regionData
    for _, rData in ipairs(CONSTANTS.REGIONS) do
        if rData.id == regionID then
            regionData = rData
            break
        end
    end
    local displayRegionName = regionData and regionData.localName or ("Unknown Region " .. tostring(regionID))
    local dialogTitle = isEdit
        and string.format(L.EDIT_NOTE or "Edit Note: %s", displayRegionName)
        or string.format(L.ADD_NOTE or "Add Note: %s", displayRegionName)

    local frameName = baseName .. "_" .. tostring(regionID)
    local dialog = self:CreateDialog(frameName, dialogTitle, CONSTANTS.SIZES.NOTE_DIALOG_WIDTH, CONSTANTS.SIZES.NOTE_DIALOG_HEIGHT)
    dialog.regionID = regionID
    addonTable.Utils.MakeFrameDraggable(dialog, function(f)
        GUI:SaveWindowPosition(frameName, f)
    end)
    GUI:RestoreWindowPosition(frameName, dialog)

    dialog.SeverityLabel, dialog.SeverityDropdown = self:CreateSeverityDropdown(dialog)
    dialog.StatusSelection = self:CreateStatusSelection(dialog)
    dialog.ScrollFrame, dialog.EditBox, dialog.CharCountLabel = self:CreateEditBoxWithCounter(dialog, CONSTANTS.LIMITS.MAX_NOTE_LENGTH)
    dialog.SaveButton, dialog.CancelButton = self:CreateSaveCancelButtons(dialog)
    _G[frameName] = dialog

    self:PopulateNoteDialog(dialog, noteIndex)
    dialog:Show()
    dialog.EditBox:SetFocus()
end

function Dialogs:PopulateNoteDialog(dialog, noteIndex)
    local data = getActiveWoundData()
    local notes = data[dialog.regionID]
    local isEdit = (noteIndex ~= nil)
    dialog.noteIndex = noteIndex
    dialog.selectedSeverityID = 2

    if isEdit and notes and notes[noteIndex] then
        local note = notes[noteIndex]
        local severityID = note.severityID or 2
        dialog.SeverityDropdown:SetSeverityID(severityID)
        if type(note.statusIDs) == "table" then
            dialog.StatusSelection:SetStatusIDs(note.statusIDs)
        else
            dialog.StatusSelection:SetStatusIDs({})
        end
        dialog.EditBox:SetText(note.text or "")
        local initialLen = strlenutf8(note.text or "")
        dialog.CharCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", initialLen, CONSTANTS.LIMITS.MAX_NOTE_LENGTH))
    else
        dialog.SeverityDropdown:SetSeverityID(2)
        dialog.StatusSelection:SetStatusIDs({})
        dialog.EditBox:SetText("")
        dialog.CharCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", 0, CONSTANTS.LIMITS.MAX_NOTE_LENGTH))
    end

    local function UpdateSaveButtonState()
        local text = addonTable.Utils.SanitizeInput(dialog.EditBox:GetText() or "")
        local length = strlenutf8(text)
        dialog.CharCountLabel:SetText(string.format(L.CHAR_COUNT or "Character Count: %d/%d", length, CONSTANTS.LIMITS.MAX_NOTE_LENGTH))

        if text == "" then
            dialog.SaveButton:Disable()
            if dialog.DuplicateWarning then
                dialog.DuplicateWarning:Hide()
            end
            return
        end

        local isDuplicate = false
        for idx, existingNote in ipairs(data[dialog.regionID] or {}) do
            local sameNoteIndex = (isEdit and (idx == noteIndex))
            if (not sameNoteIndex) and (existingNote.text == text) then
                isDuplicate = true
                break
            end
        end

        if isDuplicate then
            dialog.SaveButton:Disable()
            if not dialog.DuplicateWarning then
                dialog.DuplicateWarning = dialog:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
                dialog.DuplicateWarning:SetPoint("TOPLEFT", dialog.EditBox, "BOTTOMLEFT", 0, -5)
                dialog.DuplicateWarning:SetText(L.NOTE_DUPLICATE or "Duplicate note.")
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

    local function ConfirmAndSaveNote()
        local text = addonTable.Utils.SanitizeInput(dialog.EditBox:GetText() or "")
        if text == "" then
            UIErrorsFrame:AddMessage(string.format(L.ERROR or "Error: %s", L.EMPTY or "Empty"), 1.0, 0.0, 0.0, 5)
            return
        end
        local severityID = dialog.selectedSeverityID or 2
        local chosenStatuses = {}
        for stID in pairs(dialog.StatusSelection.selectedStatusIDs) do
            table.insert(chosenStatuses, stID)
        end

        data[dialog.regionID] = data[dialog.regionID] or {}
        if isEdit and notes and notes[noteIndex] then
            notes[noteIndex].text = text
            notes[noteIndex].severityID = severityID
            notes[noteIndex].statusIDs = chosenStatuses
        else
            table.insert(data[dialog.regionID], { text = text, severityID = severityID, statusIDs = chosenStatuses })
        end

        GUI:UpdateRegionColors()
        dialog.EditBox:SetText("")
        dialog:Hide()
        self:OpenWoundDialog(dialog.regionID, true)
    end

    dialog.EditBox:SetScript("OnEnterPressed", function(editBoxSelf)
        if IsShiftKeyDown() then
            editBoxSelf:Insert("\n")
        else
            if dialog.SaveButton:IsEnabled() then
                ConfirmAndSaveNote()
            end
        end
    end)

    dialog.SaveButton:SetScript("OnClick", ConfirmAndSaveNote)
    dialog.CancelButton:SetScript("OnClick", function()
        dialog.EditBox:SetText("")
        dialog:Hide()
        self:OpenWoundDialog(dialog.regionID, true)
    end)

    UpdateSaveButtonState()
    dialog.EditBox:SetFocus()
end

function Dialogs:CloseAllDialogs(dialogType)
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
            if type(frameName) == "string" and frameName:match("^" .. framePrefix)
               and type(frameObj) == "table" and frameObj.Hide then
                frameObj:Hide()
            end
        end
    end
end

return Dialogs
