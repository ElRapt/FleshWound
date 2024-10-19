-- FleshWound_GUI.lua
-- Contains all GUI-related functions with data persistence and corrected region handling

local addonName, addonTable = ...
local woundData
local FleshWoundFrame

-- Define severities and their colors
local severities = {
    { name = "None", color = {0, 0, 0, 0.0} },               -- Transparent
    { name = "Unknown", color = {0.5, 0.5, 0.5, 0.4} },   -- Grey, 40% opacity
    { name = "Benign", color = {0, 1, 0, 0.4} },          -- Green, 40% opacity
    { name = "Moderate", color = {1, 1, 0, 0.4} },        -- Yellow, 40% opacity
    { name = "Severe", color = {1, 0.5, 0, 0.4} },        -- Orange, 40% opacity
    { name = "Critical", color = {1, 0, 0, 0.4} },        -- Red, 40% opacity
    { name = "Deadly", color = {0.6, 0, 0.6, 0.4} }    -- Purple, 40% opacity

}

-- Function to handle the frame's OnLoad event
function FleshWound_OnLoad(self)
    -- Now that the frame is loaded, we can initialize woundData and FleshWoundFrame
    woundData = addonTable.woundData or {}
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

    -- Make the frame draggable
    self:EnableMouse(true)
    self:SetMovable(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", FleshWoundFrame_OnDragStart)
    self:SetScript("OnDragStop", FleshWoundFrame_OnDragStop)

    -- Close Button for the main window
    self.CloseButton = CreateFrame("Button", nil, self, "UIPanelCloseButton")
    self.CloseButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -5, -5)
    self.CloseButton:SetScript("OnClick", function()
        self:Hide()
    end)

    -- Bind the main window to the ESC key
    table.insert(UISpecialFrames, self:GetName())

    -- Create the player head frame and model
    -- (Your existing code for the head frame remains the same)

    -- Create the body image
    self.BodyImage = self:CreateTexture(nil, "BACKGROUND")
    self.BodyImage:SetSize(300, 500)
    self.BodyImage:SetPoint("CENTER", self, "CENTER", 0, 0)
    self.BodyImage:SetTexture("Interface\\AddOns\\FleshWound\\Textures\\body_image.tga")

    -- Create clickable regions on the body
    CreateBodyRegions(self)

    -- Set up the options panel
    FleshWound_AddonOptions()

    -- Update region colors based on the severities of their notes
    UpdateRegionColors()
end

-- Frame drag functions
function FleshWoundFrame_OnDragStart(self)
    self:StartMoving()
end

function FleshWoundFrame_OnDragStop(self)
    self:StopMovingOrSizing()
end

-- Function to create clickable regions on the body image
function CreateBodyRegions(self)
    self.BodyRegions = {}

    -- Define regions (positions reset to original)
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
        overlay:SetAllPoints(btn)
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
    for regionName, btn in pairs(FleshWoundFrame.BodyRegions) do
        local highestSeverity = GetHighestSeverity(regionName)
        local color = GetSeverityColor(highestSeverity)
        btn.overlay:SetColorTexture(unpack(color))
    end
end

-- Function to get the highest severity for a region
function GetHighestSeverity(regionName)
    local notes = woundData[regionName]
    if not notes or #notes == 0 then
        return "None"
    end

    -- Map severities to numerical values for comparison
    local severityLevels = {
        ["None"] = -1,
        ["Unknown"] = 0,
        ["Benign"] = 1,
        ["Moderate"] = 2,
        ["Severe"] = 3,
        ["Critical"] = 4,
        ["Deadly"] = 5,

    }

    local highestLevel = -1
    local highestSeverity = "None"

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

-- Redesigned function to open the wound dialog
function OpenWoundDialog(regionName)
    if not FleshWoundDialog then
        local dialog = CreateFrame("Frame", "FleshWoundDialog", UIParent, "BackdropTemplate")
        dialog:SetPoint("CENTER")
        dialog:SetSize(550, 500)
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
        dialog:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        dialog:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
        end)

        -- Close Button
        dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
        dialog.CloseButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
        dialog.CloseButton:SetScript("OnClick", function()
            dialog:Hide()
        end)

        -- Bind the dialog to the ESC key
        table.insert(UISpecialFrames, dialog:GetName())

        dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        dialog.Title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)

        -- Create a decorative line under the title
        local titleLine = dialog:CreateTexture(nil, "ARTWORK")
        titleLine:SetHeight(2)
        titleLine:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 0, -10)
        titleLine:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -15, -40)
        titleLine:SetColorTexture(1, 1, 1, 0.2)

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
        dialog.AddNoteButton:SetText("Add Note")
        dialog.AddNoteButton:SetScript("OnClick", function()
            dialog:Hide()
            OpenAddNoteDialog(dialog.regionName)
        end)

        FleshWoundDialog = dialog
    end

    -- Update the dialog content
    FleshWoundDialog.Title:SetText("Wound Details - " .. regionName)
    FleshWoundDialog.regionName = regionName  -- Store the current region name

    local notes = woundData[regionName]

    -- Clear previous entries
    for _, entry in ipairs(FleshWoundDialog.NoteEntries) do
        entry:Hide()
    end
    FleshWoundDialog.NoteEntries = {}

    if notes and #notes > 0 then
        local yOffset = -10
        for i, note in ipairs(notes) do
            local entry = CreateFrame("Frame", nil, FleshWoundDialog.ScrollChild, "BackdropTemplate")
            entry:SetWidth(FleshWoundDialog.ScrollChild:GetWidth() - 20)
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
            local color = GetSeverityColor(note.severity or "None")
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

            local editButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
            editButton:SetSize(50, 22)
            editButton:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -55, -10)
            editButton:SetText("Edit")
            editButton:SetScript("OnClick", function()
                FleshWoundDialog:Hide()
                OpenEditNoteDialog(FleshWoundDialog.regionName, i)
            end)

            local deleteButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
            deleteButton:SetSize(60, 22)
            deleteButton:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -5, -10)
            deleteButton:SetText("Delete")
            deleteButton:SetScript("OnClick", function()
                table.remove(woundData[FleshWoundDialog.regionName], i)
                OpenWoundDialog(FleshWoundDialog.regionName) -- Refresh the dialog
                UpdateRegionColors() -- Update the region color
            end)

            table.insert(FleshWoundDialog.NoteEntries, entry)
            yOffset = yOffset - (entryHeight + 10)
        end
        -- Adjust the ScrollChild height
        FleshWoundDialog.ScrollChild:SetHeight(-yOffset)
    else
        local noNotesText = FleshWoundDialog.ScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noNotesText:SetPoint("TOPLEFT", 10, -10)
        noNotesText:SetWidth(FleshWoundDialog.ScrollChild:GetWidth() - 20)
        noNotesText:SetJustifyH("CENTER")
        noNotesText:SetText("No notes have been added for this region.")

        table.insert(FleshWoundDialog.NoteEntries, noNotesText)
        FleshWoundDialog.ScrollChild:SetHeight(30)
    end

    FleshWoundDialog:Show()
end
-- Redesigned function to open the add note dialog
    function OpenAddNoteDialog(regionName)
        if not FleshWoundAddNoteDialog then
            local dialog = CreateFrame("Frame", "FleshWoundAddNoteDialog", UIParent, "BackdropTemplate")
            dialog:SetSize(400, 350)
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
            dialog:SetScript("OnDragStart", function(self)
                self:StartMoving()
            end)
            dialog:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
            end)
    
            -- Close Button
            dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
            dialog.CloseButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
            dialog.CloseButton:SetScript("OnClick", function()
                dialog:Hide()
                OpenWoundDialog(dialog.regionName)
            end)
    
            -- Bind the dialog to the ESC key
            table.insert(UISpecialFrames, dialog:GetName())
    
            dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            dialog.Title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)
    
            -- Create a decorative line under the title
            local titleLine = dialog:CreateTexture(nil, "ARTWORK")
            titleLine:SetHeight(2)
            titleLine:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 0, -10)
            titleLine:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -15, -40)
            titleLine:SetColorTexture(1, 1, 1, 0.2)
    
            -- Severity Label
            dialog.SeverityLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dialog.SeverityLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
            dialog.SeverityLabel:SetText("Severity:")
    
            -- Severity Dropdown Menu
            dialog.SeverityDropdown = CreateFrame("Frame", "FleshWoundAddNoteSeverityDropdown", dialog, "UIDropDownMenuTemplate")
            dialog.SeverityDropdown:SetPoint("LEFT", dialog.SeverityLabel, "RIGHT", -10, -3)
            UIDropDownMenu_SetWidth(dialog.SeverityDropdown, 150)
    
            dialog.SeverityDropdown.initialize = function(self, level)
                local info
                for _, sev in ipairs(severities) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = sev.name
                    info.arg1 = sev.name
                    info.func = function(self, arg1)
                        UIDropDownMenu_SetSelectedName(dialog.SeverityDropdown, arg1)
                        dialog.selectedSeverity = arg1
                    end
                    info.checked = (sev.name == (dialog.selectedSeverity or "None"))
                    UIDropDownMenu_AddButton(info)
                end
            end
    
            -- Adjusted the position of the ScrollFrame to move the EditBox downwards
            dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
            dialog.ScrollFrame:SetPoint("TOPLEFT", dialog.SeverityLabel, "BOTTOMLEFT", 0, -20)  -- Increased the Y offset to -20
            dialog.ScrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -35, 60)
    
            -- Include "BackdropTemplate" for the EditBox
            dialog.EditBox = CreateFrame("EditBox", nil, dialog.ScrollFrame, "BackdropTemplate")
            dialog.EditBox:SetMultiLine(true)
            dialog.EditBox:SetFontObject("ChatFontNormal")
            dialog.EditBox:SetMaxLetters(2000)
            dialog.EditBox:SetAutoFocus(true)
            dialog.EditBox:SetWidth(dialog.ScrollFrame:GetWidth())
            dialog.EditBox:SetTextInsets(10, 10, 10, 10)
            dialog.EditBox:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = nil,
                tile = false,
                tileSize = 0,
                edgeSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            dialog.EditBox:SetBackdropColor(0, 0, 0, 0.5)
            dialog.EditBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            dialog.ScrollFrame:SetScrollChild(dialog.EditBox)
    
            dialog.SaveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
            dialog.SaveButton:SetSize(80, 24)
            dialog.SaveButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -10, 15)
            dialog.SaveButton:SetText("Save")
    
            dialog.CancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
            dialog.CancelButton:SetSize(80, 24)
            dialog.CancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 10, 15)
            dialog.CancelButton:SetText("Cancel")
    
            FleshWoundAddNoteDialog = dialog
        end
    
        FleshWoundAddNoteDialog.Title:SetText("Add Note - " .. regionName)
        FleshWoundAddNoteDialog.regionName = regionName  -- Store the current region name
        FleshWoundAddNoteDialog.EditBox:SetText("")
        FleshWoundAddNoteDialog.selectedSeverity = "None"
        UIDropDownMenu_SetSelectedName(FleshWoundAddNoteDialog.SeverityDropdown, "None")
        UIDropDownMenu_Initialize(FleshWoundAddNoteDialog.SeverityDropdown, FleshWoundAddNoteDialog.SeverityDropdown.initialize)
    
        FleshWoundAddNoteDialog:Show()
        FleshWoundAddNoteDialog.EditBox:SetFocus()
    
        -- Reassign the OnClick handlers to capture the current regionName
        FleshWoundAddNoteDialog.SaveButton:SetScript("OnClick", function()
            local text = FleshWoundAddNoteDialog.EditBox:GetText()
            local severity = FleshWoundAddNoteDialog.selectedSeverity or "None"
            if text and text ~= "" then
                woundData[FleshWoundAddNoteDialog.regionName] = woundData[FleshWoundAddNoteDialog.regionName] or {}
                table.insert(woundData[FleshWoundAddNoteDialog.regionName], { text = text, severity = severity })
                UpdateRegionColors() -- Update the region color
            end
            FleshWoundAddNoteDialog.EditBox:SetText("")
            FleshWoundAddNoteDialog:Hide()
            OpenWoundDialog(FleshWoundAddNoteDialog.regionName)  -- Reopen the wound dialog to show updated notes
        end)
    
        FleshWoundAddNoteDialog.CancelButton:SetScript("OnClick", function()
            FleshWoundAddNoteDialog.EditBox:SetText("")
            FleshWoundAddNoteDialog:Hide()
            OpenWoundDialog(FleshWoundAddNoteDialog.regionName)  -- Reopen the wound dialog
        end)
    end
    
-- Redesigned function to open the edit note dialog
    function OpenEditNoteDialog(regionName, noteIndex)
        if not FleshWoundEditNoteDialog then
            local dialog = CreateFrame("Frame", "FleshWoundEditNoteDialog", UIParent, "BackdropTemplate")
            dialog:SetSize(400, 350)
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
            dialog:SetScript("OnDragStart", function(self)
                self:StartMoving()
            end)
            dialog:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
            end)
    
            -- Close Button
            dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
            dialog.CloseButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
            dialog.CloseButton:SetScript("OnClick", function()
                dialog:Hide()
                OpenWoundDialog(dialog.regionName)
            end)
    
            -- Bind the dialog to the ESC key
            table.insert(UISpecialFrames, dialog:GetName())
    
            dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            dialog.Title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)
    
            -- Create a decorative line under the title
            local titleLine = dialog:CreateTexture(nil, "ARTWORK")
            titleLine:SetHeight(2)
            titleLine:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 0, -10)
            titleLine:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -15, -40)
            titleLine:SetColorTexture(1, 1, 1, 0.2)
    
            -- Severity Label
            dialog.SeverityLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dialog.SeverityLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
            dialog.SeverityLabel:SetText("Severity:")
    
            -- Severity Dropdown Menu
            dialog.SeverityDropdown = CreateFrame("Frame", "FleshWoundEditNoteSeverityDropdown", dialog, "UIDropDownMenuTemplate")
            dialog.SeverityDropdown:SetPoint("LEFT", dialog.SeverityLabel, "RIGHT", -10, -3)
            UIDropDownMenu_SetWidth(dialog.SeverityDropdown, 150)
    
            -- Adjusted the position of the ScrollFrame to move the EditBox downwards
            dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
            dialog.ScrollFrame:SetPoint("TOPLEFT", dialog.SeverityLabel, "BOTTOMLEFT", 0, -20)  -- Increased the Y offset to -20
            dialog.ScrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -35, 60)
    
            -- Include "BackdropTemplate" for the EditBox
            dialog.EditBox = CreateFrame("EditBox", nil, dialog.ScrollFrame, "BackdropTemplate")
            dialog.EditBox:SetMultiLine(true)
            dialog.EditBox:SetFontObject("ChatFontNormal")
            dialog.EditBox:SetMaxLetters(2000)
            dialog.EditBox:SetAutoFocus(true)
            dialog.EditBox:SetWidth(dialog.ScrollFrame:GetWidth())
            dialog.EditBox:SetTextInsets(10, 10, 10, 10)
            dialog.EditBox:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = nil,
                tile = false,
                tileSize = 0,
                edgeSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            dialog.EditBox:SetBackdropColor(0, 0, 0, 0.5)
            dialog.EditBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            dialog.ScrollFrame:SetScrollChild(dialog.EditBox)
    
            dialog.SaveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
            dialog.SaveButton:SetSize(80, 24)
            dialog.SaveButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -10, 15)
            dialog.SaveButton:SetText("Save")
    
            dialog.CancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
            dialog.CancelButton:SetSize(80, 24)
            dialog.CancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 10, 15)
            dialog.CancelButton:SetText("Cancel")
    
            FleshWoundEditNoteDialog = dialog
        end
    
        FleshWoundEditNoteDialog.Title:SetText("Edit Note - " .. regionName)
        FleshWoundEditNoteDialog.regionName = regionName  -- Store the current region name
        FleshWoundEditNoteDialog.noteIndex = noteIndex    -- Store the current note index
    
        local note = woundData[regionName][noteIndex]
    
        FleshWoundEditNoteDialog.EditBox:SetText(note.text or "")
        FleshWoundEditNoteDialog.selectedSeverity = note.severity or "None"
    
        -- Initialize the severity dropdown
        FleshWoundEditNoteDialog.SeverityDropdown.initialize = function(self, level)
            local info
            for _, sev in ipairs(severities) do
                info = UIDropDownMenu_CreateInfo()
                info.text = sev.name
                info.arg1 = sev.name
                info.func = function(self, arg1)
                    UIDropDownMenu_SetSelectedName(FleshWoundEditNoteDialog.SeverityDropdown, arg1)
                    FleshWoundEditNoteDialog.selectedSeverity = arg1
                end
                info.checked = (sev.name == (FleshWoundEditNoteDialog.selectedSeverity or "None"))
                UIDropDownMenu_AddButton(info)
            end
        end
    
        UIDropDownMenu_SetSelectedName(FleshWoundEditNoteDialog.SeverityDropdown, FleshWoundEditNoteDialog.selectedSeverity)
        UIDropDownMenu_Initialize(FleshWoundEditNoteDialog.SeverityDropdown, FleshWoundEditNoteDialog.SeverityDropdown.initialize)
    
        FleshWoundEditNoteDialog:Show()
        FleshWoundEditNoteDialog.EditBox:SetFocus()
    
        -- Reassign the OnClick handlers to capture the current regionName and noteIndex
        FleshWoundEditNoteDialog.SaveButton:SetScript("OnClick", function()
            local text = FleshWoundEditNoteDialog.EditBox:GetText()
            local severity = FleshWoundEditNoteDialog.selectedSeverity or "None"
            if text and text ~= "" then
                woundData[FleshWoundEditNoteDialog.regionName][FleshWoundEditNoteDialog.noteIndex].text = text
                woundData[FleshWoundEditNoteDialog.regionName][FleshWoundEditNoteDialog.noteIndex].severity = severity
                UpdateRegionColors() -- Update the region color
            end
            FleshWoundEditNoteDialog.EditBox:SetText("")
            FleshWoundEditNoteDialog:Hide()
            OpenWoundDialog(FleshWoundEditNoteDialog.regionName)  -- Reopen the wound dialog to show updated notes
        end)
    
        FleshWoundEditNoteDialog.CancelButton:SetScript("OnClick", function()
            FleshWoundEditNoteDialog.EditBox:SetText("")
            FleshWoundEditNoteDialog:Hide()
            OpenWoundDialog(FleshWoundEditNoteDialog.regionName)  -- Reopen the wound dialog
        end)
    end
    
    
    
-- Function to create the addon options panel
function FleshWound_AddonOptions()
    -- (Implement options panel as needed)
end
