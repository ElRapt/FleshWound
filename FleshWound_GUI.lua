-- FleshWound_GUI.lua
-- Contains all GUI-related functions with data persistence and localization

local addonName, addonTable = ...
local L = addonTable.L
local FleshWoundFrame

-- Define severities and their colors
local severities = {
    { name = L["None"], color = {0, 0, 0, 0.0} },             -- Transparent
    { name = L["Unknown"], color = {0.5, 0.5, 0.5, 0.4} },    -- Grey, 40% opacity
    { name = L["Benign"], color = {0, 1, 0, 0.4} },           -- Green, 40% opacity
    { name = L["Moderate"], color = {1, 1, 0, 0.4} },         -- Yellow, 40% opacity
    { name = L["Severe"], color = {1, 0.5, 0, 0.4} },         -- Orange, 40% opacity
    { name = L["Critical"], color = {1, 0, 0, 0.4} },         -- Red, 40% opacity
    { name = L["Deadly"], color = {0.6, 0, 0.6, 0.4} },       -- Purple, 40% opacity
}

-- Severity levels mapping for comparison
local severityLevels = {
    [L["None"]] = -1,
    [L["Unknown"]] = 0,
    [L["Benign"]] = 1,
    [L["Moderate"]] = 2,
    [L["Severe"]] = 3,
    [L["Critical"]] = 4,
    [L["Deadly"]] = 5,
}

-- Function to sanitize input text
function SanitizeInput(text)
    -- Trim leading and trailing whitespace
    text = text:match("^%s*(.-)%s*$")
    -- Remove control characters
    text = text:gsub("[%c]", "")
    return text
end

-- Function to handle the frame's OnLoad event
function FleshWound_OnLoad(self)
    -- Initialize woundData and FleshWoundFrame
    local woundData = addonTable.woundData or {}
    FleshWoundFrame = self

    -- Set the frame size slightly larger than the body image
    self:SetSize(320, 540)

    -- Set the backdrop with Blizzard default background
    self:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  -- Blizzard default background
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    self:SetFrameStrata("DIALOG")

    -- Make the frame draggable
    self:EnableMouse(true)
    self:SetMovable(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", self.StartMoving)
    self:SetScript("OnDragStop", self.StopMovingOrSizing)

    -- Close Button for the main window
    self.CloseButton = CreateFrame("Button", nil, self, "UIPanelCloseButton")
    self.CloseButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -5, -5)
    self.CloseButton:SetScript("OnClick", function()
        self:Hide()
    end)

    -- Profile Icon Button (New)
    self.ProfileButton = CreateFrame("Button", nil, self)
    self.ProfileButton:SetSize(35, 35)  -- Increased size for better visibility
    self.ProfileButton:SetPoint("TOPLEFT", self, "TOPLEFT", 15, -15)
    self.ProfileButton:SetNormalTexture("Interface\\ICONS\\INV_Misc_Book_09") 
    self.ProfileButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    self.ProfileButton:SetScript("OnClick", function()
        OpenProfileManager()
    end)
    self.ProfileButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.ProfileButton, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Profile Manager"], 1, 1, 1)
        GameTooltip:Show()
    end)
    self.ProfileButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Bind the main window to the ESC key
    table.insert(UISpecialFrames, self:GetName())

    -- Create the body image
    self.BodyImage = self:CreateTexture(nil, "BACKGROUND")
    self.BodyImage:SetSize(300, 500)
    self.BodyImage:SetPoint("CENTER", self, "CENTER", 0, 0)
    self.BodyImage:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Textures\\body_image.tga")

    -- Create clickable regions on the body
    CreateBodyRegions(self)

    -- Set up the options panel (if needed)
    FleshWound_AddonOptions()

    -- Update region colors based on the severities of their notes
    UpdateRegionColors()
end

-- Function to create clickable regions on the body image
function CreateBodyRegions(self)
    self.BodyRegions = {}

    -- Define regions
    local regions = {
        {name = "Head", x = 130, y = 420, width = 50, height = 75},
        {name = "Torso", x = 130, y = 275, width = 50, height = 120},
        {name = "Left Arm", x = 75, y = 300, width = 50, height = 120},
        {name = "Right Arm", x = 185, y = 300, width = 50, height = 120},
        {name = "Left Hand", x = 40, y = 180, width = 50, height = 100},
        {name = "Right Hand", x = 215, y = 180, width = 50, height = 100},
        {name = "Left Leg", x = 100, y = 50, width = 50, height = 130},
        {name = "Right Leg", x = 155, y = 50, width = 50, height = 130},
        {name = "Left Foot", x = 110, y = 0, width = 50, height = 50},
        {name = "Right Foot", x = 150, y = 0, width = 50, height = 50},
    }

    for _, region in ipairs(regions) do
        local btn = CreateFrame("Button", nil, self)
        btn:SetSize(region.width, region.height)

        -- Position the button relative to the BodyImage
        btn:SetPoint("BOTTOMLEFT", self.BodyImage, "BOTTOMLEFT", region.x, region.y)

        btn:SetScript("OnClick", function()
            OpenWoundDialog(region.name)
        end)

        -- Set a highlight texture to indicate when the region is hovered over
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

        -- Add the region marker (green dot)
        local regionMarker = btn:CreateTexture(nil, "OVERLAY")
        regionMarker:SetSize(10, 10)
        regionMarker:SetPoint("CENTER", btn, "CENTER")
        regionMarker:SetColorTexture(0, 1, 0, 1) -- Green color
        btn.regionMarker = regionMarker

        -- Add an overlay texture to color the region based on severity
        local overlay = btn:CreateTexture(nil, "ARTWORK")
        local inset = 7  -- Adjust this value to control how much smaller the overlay is compared to the button
        overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
        overlay:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
        overlay:SetColorTexture(0, 0, 0, 0)  -- Default transparent
        btn.overlay = overlay

        self.BodyRegions[region.name] = btn
    end
end

-- Function to update region colors based on the highest severity of their notes
function UpdateRegionColors()
    if not FleshWoundFrame or not FleshWoundFrame.BodyRegions then
        return
    end
    local woundData = addonTable.woundData or {}
    for regionName, btn in pairs(FleshWoundFrame.BodyRegions) do
        local highestSeverity = GetHighestSeverity(regionName)
        local color = GetSeverityColor(highestSeverity)
        btn.overlay:SetColorTexture(unpack(color))
    end
end

-- Function to get the highest severity for a region
function GetHighestSeverity(regionName)
    local woundData = addonTable.woundData or {}
    local notes = woundData[regionName]
    if not notes or #notes == 0 then
        return L["None"]
    end

    local highestLevel = -1
    local highestSeverity = L["None"]

    for _, note in ipairs(notes) do
        local level = severityLevels[note.severity] or 0
        if level > highestLevel then
            highestLevel = level
            highestSeverity = note.severity
        end
    end

    return highestSeverity
end

-- Function to get the color based on severity name
function GetSeverityColor(severityName)
    for _, sev in ipairs(severities) do
        if sev.name == severityName then
            return sev.color
        end
    end
    -- No coloring if severity is not found
    return {0, 0, 0, 0.0}
end

-- Function to create common dialog frames
function CreateDialog(name, titleText, width, height)
    -- Ensure the frame name is global and unique
    local dialog = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    dialog:SetSize(width, height)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
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
        -- If the frame does not have a name, assign one
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
function CreateSeverityDropdown(parent)
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
        for _, sev in ipairs(severities) do
            info = UIDropDownMenu_CreateInfo()
            info.text = sev.name
            info.arg1 = sev.name
            info.func = function(self, arg1)
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
function CreateEditBoxWithCounter(parent, maxChars)
    -- ScrollFrame for the EditBox
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent.SeverityLabel, "BOTTOMLEFT", 0, -20)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -35, 80)  -- Adjusted height

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
function CreateSaveCancelButtons(parent)
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

-- Function to open the Add/Edit Note dialog
function OpenNoteDialog(regionName, noteIndex)
    local isEdit = noteIndex ~= nil
    local dialogBaseName = isEdit and "FleshWoundEditNoteDialog" or "FleshWoundAddNoteDialog"
    local displayRegionName = L[regionName] or regionName
    local dialogTitle = format(isEdit and L["Edit Note - %s"] or L["Add Note - %s"], displayRegionName)

    -- Use a unique global name for the dialog
    local frameName = dialogBaseName .. "_" .. regionName

    local dialog = _G[frameName]
    if not dialog then
        dialog = CreateDialog(frameName, dialogTitle, 400, 370)
        dialog.regionName = regionName

        -- Severity Dropdown
        dialog.SeverityLabel, dialog.SeverityDropdown = CreateSeverityDropdown(dialog)

        -- EditBox with Character Counter
        dialog.ScrollFrame, dialog.EditBox, dialog.CharCountLabel = CreateEditBoxWithCounter(dialog, 125)

        -- Save and Cancel Buttons
        dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)

        -- Store the dialog globally
        _G[frameName] = dialog
    else
        dialog.Title:SetText(dialogTitle)
        dialog.regionName = regionName
    end

    local woundData = addonTable.woundData or {}
    dialog.noteIndex = noteIndex
    dialog.selectedSeverity = L["Unknown"]
    UIDropDownMenu_SetSelectedName(dialog.SeverityDropdown, dialog.selectedSeverity)
    UIDropDownMenu_Initialize(dialog.SeverityDropdown, dialog.SeverityDropdown.initialize)

    if isEdit then
        local note = woundData[regionName][noteIndex]
        dialog.EditBox:SetText(note.text or "")
        dialog.selectedSeverity = note.severity or L["Unknown"]
        UIDropDownMenu_SetSelectedName(dialog.SeverityDropdown, dialog.selectedSeverity)
        -- Update character count label
        local initialText = note.text or ""
        local initialLength = strlenutf8(initialText)
        dialog.CharCountLabel:SetText(format(L["%d / %d"], initialLength, 125))
    else
        dialog.EditBox:SetText("")
        dialog.CharCountLabel:SetText(format(L["%d / %d"], 0, 125))
    end

    -- Function to check for duplicate notes and sanitize input
    local function UpdateSaveButtonState()
        local text = dialog.EditBox:GetText()
        text = SanitizeInput(text)
        local length = strlenutf8(text)
        dialog.CharCountLabel:SetText(format(L["%d / %d"], length, 125))

        if text == "" then
            dialog.SaveButton:Disable()
            return
        end

        -- Check for duplicate content
        woundData[regionName] = woundData[regionName] or {}
        local isDuplicate = false
        for idx, note in ipairs(woundData[regionName]) do
            if (not isEdit or idx ~= noteIndex) and note.text == text then
                isDuplicate = true
                break
            end
        end

        if isDuplicate then
            dialog.SaveButton:Disable()
            -- Optionally, display a message or change the appearance
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

    -- Set the OnTextChanged handler
    dialog.EditBox:SetScript("OnTextChanged", function(self)
        UpdateSaveButtonState()
    end)

    -- Initial call to set the correct state
    UpdateSaveButtonState()

    dialog:Show()
    dialog.EditBox:SetFocus()

    -- Save Button Handler
    dialog.SaveButton:SetScript("OnClick", function()
        local text = dialog.EditBox:GetText()
        text = SanitizeInput(text)
        local severity = dialog.selectedSeverity or L["Unknown"]
        if text and text ~= "" then
            -- Check for duplicate content
            woundData[regionName] = woundData[regionName] or {}
            local isDuplicate = false
            for idx, note in ipairs(woundData[regionName]) do
                if (not isEdit or idx ~= noteIndex) and note.text == text then
                    isDuplicate = true
                    break
                end
            end

            if isDuplicate then
                -- Display error message
                UIErrorsFrame:AddMessage(format(L["Error: %s"], L["A note with this content already exists."]), 1.0, 0.0, 0.0, 53, 5)
            else
                if isEdit then
                    woundData[regionName][noteIndex].text = text
                    woundData[regionName][noteIndex].severity = severity
                else
                    table.insert(woundData[regionName], { text = text, severity = severity })
                end
                UpdateRegionColors() -- Update the region color
                dialog.EditBox:SetText("")
                dialog:Hide()
                OpenWoundDialog(regionName)  -- Reopen the wound dialog to show updated notes
            end
        else
            -- Display error message if text is empty
            UIErrorsFrame:AddMessage(format(L["Error: %s"], L["Note content cannot be empty."]), 1.0, 0.0, 0.0, 53, 5)
        end
    end)

    -- Cancel Button Handler
    dialog.CancelButton:SetScript("OnClick", function()
        dialog.EditBox:SetText("")
        dialog:Hide()
        OpenWoundDialog(regionName)  -- Reopen the wound dialog
    end)
end

-- Function to open the wound dialog
function OpenWoundDialog(regionName)
    local dialogName = "FleshWoundDialog_" .. regionName
    local displayRegionName = L[regionName] or regionName
    local dialogTitle = format(L["Wound Details - %s"], displayRegionName)

    local dialog = _G[dialogName]
    if not dialog then
        dialog = CreateDialog(dialogName, dialogTitle, 550, 500)
        dialog.regionName = regionName

        -- ScrollFrame to display notes
        dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        dialog.ScrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        dialog.ScrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -35, 60)

        dialog.ScrollChild = CreateFrame("Frame", nil, dialog.ScrollFrame)
        dialog.ScrollChild:SetSize(dialog.ScrollFrame:GetWidth(), 1)
        dialog.ScrollFrame:SetScrollChild(dialog.ScrollChild)

        -- Placeholder for note entries
        dialog.NoteEntries = {}

        dialog.AddNoteButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.AddNoteButton:SetSize(120, 30)
        dialog.AddNoteButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 15, 15)
        dialog.AddNoteButton:SetText(L["Add Note"])
        dialog.AddNoteButton:SetScript("OnClick", function()
            dialog:Hide()
            OpenNoteDialog(dialog.regionName)
        end)

        _G[dialogName] = dialog
    else
        dialog.Title:SetText(dialogTitle)
        dialog.regionName = regionName
    end

    local woundData = addonTable.woundData or {}
    local notes = woundData[regionName]

    -- Clear previous entries
    for _, entry in ipairs(dialog.NoteEntries) do
        entry:Hide()
    end
    dialog.NoteEntries = {}

    if notes and #notes > 0 then
        local yOffset = -10
        for i, note in ipairs(notes) do
            local entry = CreateFrame("Frame", nil, dialog.ScrollChild, "BackdropTemplate")
            entry:SetWidth(dialog.ScrollChild:GetWidth() - 20)
            entry:SetPoint("TOPLEFT", 10, yOffset)
            entry:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false,
                tileSize = 0,
                edgeSize = 14,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            -- Get the color based on severity
            local color = GetSeverityColor(note.severity or L["None"])
            entry:SetBackdropColor(color[1], color[2], color[3], 0.4)
            entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

            -- Display the note text
            local noteText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noteText:SetPoint("TOPLEFT", entry, "TOPLEFT", 10, -10)
            noteText:SetPoint("BOTTOMRIGHT", entry, "BOTTOMRIGHT", -110, 10)
            noteText:SetJustifyH("LEFT")
            noteText:SetJustifyV("TOP")
            noteText:SetText(note.text)

            -- Adjust the height based on the text content
            local textHeight = noteText:GetStringHeight()
            local entryHeight = textHeight + 20
            entry:SetHeight(entryHeight)

            -- Edit Button
            local editButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
            editButton:SetSize(70, 22)
            editButton:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -80, -5)
            editButton:SetText(L["Edit"])
            editButton:SetScript("OnClick", function()
                dialog:Hide()
                OpenNoteDialog(dialog.regionName, i)
            end)

            -- Delete Button
            local deleteButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
            deleteButton:SetSize(70, 22)
            deleteButton:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -10, -5)
            deleteButton:SetText(L["Delete"])
            deleteButton:SetScript("OnClick", function()
                table.remove(woundData[dialog.regionName], i)
                OpenWoundDialog(dialog.regionName) -- Refresh the dialog
                UpdateRegionColors() -- Update the region color
            end)

            table.insert(dialog.NoteEntries, entry)
            yOffset = yOffset - (entryHeight + 10)
        end
        -- Adjust the ScrollChild height
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

    dialog:Show()
end

-- Function to open the Profile Manager
function OpenProfileManager()
    local frameName = "FleshWoundProfileManager"
    local dialogTitle = L["Profile Manager"]

    local dialog = _G[frameName]
    if not dialog then
        dialog = CreateDialog(frameName, dialogTitle, 500, 500)

        -- ScrollFrame to display profiles
        dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        dialog.ScrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        dialog.ScrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -35, 100)

        dialog.ScrollChild = CreateFrame("Frame", nil, dialog.ScrollFrame)
        dialog.ScrollChild:SetSize(dialog.ScrollFrame:GetWidth(), 1)
        dialog.ScrollFrame:SetScrollChild(dialog.ScrollChild)

        -- Placeholder for profile entries
        dialog.ProfileEntries = {}

        -- Create Profile Button
        dialog.CreateProfileButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.CreateProfileButton:SetSize(120, 30)
        dialog.CreateProfileButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 15, 15)
        dialog.CreateProfileButton:SetText(L["Create Profile"])
        dialog.CreateProfileButton:SetScript("OnClick", function()
            OpenCreateProfileDialog()
        end)

        -- Close Button
        dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.CloseButton:SetSize(80, 30)
        dialog.CloseButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -15, 15)
        dialog.CloseButton:SetText(L["Close"])
        dialog.CloseButton:SetScript("OnClick", function()
            dialog:Hide()
        end)

        _G[frameName] = dialog
    end

    -- Populate the profiles list
    local profiles = addonTable.FleshWoundData.profiles
    local currentProfile = addonTable.FleshWoundData.currentProfile

    -- Clear previous entries
    for _, entry in ipairs(dialog.ProfileEntries) do
        entry:Hide()
    end
    dialog.ProfileEntries = {}

    local yOffset = -10
    local index = 1
    local sortedProfiles = {}
    for profileName in pairs(profiles) do
        table.insert(sortedProfiles, profileName)
    end
    table.sort(sortedProfiles)

    for _, profileName in ipairs(sortedProfiles) do
        local entry = CreateFrame("Frame", nil, dialog.ScrollChild, "BackdropTemplate")
        entry:SetWidth(dialog.ScrollChild:GetWidth() - 20)
        entry:SetHeight(40)
        entry:SetPoint("TOPLEFT", 10, yOffset)
        entry:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 0,
            edgeSize = 14,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        if profileName == currentProfile then
            entry:SetBackdropColor(0.0, 0.5, 0.0, 0.5)  -- Highlight current profile
        else
            entry:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
        end
        entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

        -- Profile Name
        local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", entry, "LEFT", 10, 0)
        nameText:SetText(profileName)

        -- Select Button
        local selectButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        selectButton:SetSize(80, 24)
        selectButton:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
        selectButton:SetText(L["Select"])
        selectButton:SetScript("OnClick", function()
            FleshWound_SwitchProfile(profileName)
            UpdateRegionColors()  -- Update the region colors immediately
            OpenProfileManager()  -- Refresh the profile manager
        end)

        -- Delete Button
        local deleteButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        deleteButton:SetSize(80, 24)
        deleteButton:SetPoint("RIGHT", selectButton, "LEFT", -5, 0)
        deleteButton:SetText(L["Delete"])
        deleteButton:SetScript("OnClick", function()
            FleshWound_DeleteProfile(profileName)
            OpenProfileManager()  -- Refresh the profile manager
        end)
        if profileName == currentProfile then
            deleteButton:Disable()
        end

        -- Rename Button
        local renameButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
        renameButton:SetSize(80, 24)
        renameButton:SetPoint("RIGHT", deleteButton, "LEFT", -5, 0)
        renameButton:SetText(L["Rename"])
        renameButton:SetScript("OnClick", function()
            OpenRenameProfileDialog(profileName)
        end)

        table.insert(dialog.ProfileEntries, entry)
        yOffset = yOffset - 50
        index = index + 1
    end

    -- Adjust the ScrollChild height
    dialog.ScrollChild:SetHeight(-yOffset)

    dialog:Show()
end

-- Function to open the Create Profile dialog
function OpenCreateProfileDialog()
    local frameName = "FleshWoundCreateProfileDialog"
    local dialogTitle = L["Create Profile"]

    local dialog = _G[frameName]
    if not dialog then
        dialog = CreateDialog(frameName, dialogTitle, 300, 150)

        -- Profile Name Label
        local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        nameLabel:SetText(L["Profile Name:"])

        -- Profile Name EditBox
        local nameEditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        nameEditBox:SetSize(160, 30)
        nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
        nameEditBox:SetAutoFocus(true)

        -- Create and Cancel Buttons
        local createButton, cancelButton = CreateSaveCancelButtons(dialog)
        createButton:SetText(L["Create"])
        cancelButton:SetText(L["Cancel"])

        -- Function to update the Create button state
        local function UpdateCreateButtonState()
            local profileName = SanitizeInput(nameEditBox:GetText())
            if profileName == "" or addonTable.FleshWoundData.profiles[profileName] then
                createButton:Disable()
            else
                createButton:Enable()
            end
        end

        -- Set the OnTextChanged handler
        nameEditBox:SetScript("OnTextChanged", UpdateCreateButtonState)

        createButton:SetScript("OnClick", function()
            local profileName = SanitizeInput(nameEditBox:GetText())
            FleshWound_CreateProfile(profileName)
            dialog:Hide()
            OpenProfileManager()
        end)

        cancelButton:SetScript("OnClick", function()
            dialog:Hide()
            OpenProfileManager()
        end)

        _G[frameName] = dialog
        dialog.nameEditBox = nameEditBox
        dialog.createButton = createButton  -- Store reference
    end

    dialog.nameEditBox:SetText("")
    dialog:Show()
    dialog.nameEditBox:SetFocus()
    dialog.createButton:Disable()  -- Disable the Create button initially
end

-- Function to open the Rename Profile dialog
function OpenRenameProfileDialog(oldProfileName)
    local frameName = "FleshWoundRenameProfileDialog"
    local dialogTitle = L["Rename Profile"]

    local dialog = _G[frameName]
    if not dialog then
        dialog = CreateDialog(frameName, dialogTitle, 300, 150)

        -- Profile Name Label
        local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        nameLabel:SetText(L["New Name:"])

        -- Profile Name EditBox
        local nameEditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        nameEditBox:SetSize(200, 30)
        nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
        nameEditBox:SetAutoFocus(true)

        -- Rename and Cancel Buttons
        local renameButton, cancelButton = CreateSaveCancelButtons(dialog)
        renameButton:SetText(L["Rename"])
        cancelButton:SetText(L["Cancel"])

        -- Function to update the Rename button state
        local function UpdateRenameButtonState()
            local newProfileName = SanitizeInput(nameEditBox:GetText())
            if newProfileName == "" or addonTable.FleshWoundData.profiles[newProfileName] or newProfileName == oldProfileName then
                renameButton:Disable()
            else
                renameButton:Enable()
            end
        end

        -- Set the OnTextChanged handler
        nameEditBox:SetScript("OnTextChanged", UpdateRenameButtonState)

        renameButton:SetScript("OnClick", function()
            local newProfileName = SanitizeInput(nameEditBox:GetText())
            FleshWound_RenameProfile(oldProfileName, newProfileName)
            dialog:Hide()
            OpenProfileManager()
        end)

        cancelButton:SetScript("OnClick", function()
            dialog:Hide()
            OpenProfileManager()
        end)

        _G[frameName] = dialog
        dialog.nameEditBox = nameEditBox
        dialog.renameButton = renameButton  -- Store reference
    end

    dialog.nameEditBox:SetText(oldProfileName)
    dialog:Show()
    dialog.nameEditBox:SetFocus()
    dialog.renameButton:Disable()  -- Disable the Rename button initially
end

-- Function to create the addon options panel (Placeholder for future implementation)
function FleshWound_AddonOptions()
    -- Implement options panel as needed
end

-- Close all open dialogs (used when switching profiles)
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
