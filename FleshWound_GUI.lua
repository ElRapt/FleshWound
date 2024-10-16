-- FleshWound_GUI.lua
-- Contains all GUI-related functions with redesigned note window

local addonName, addonTable = ...
local woundData = addonTable.woundData
local FleshWoundFrame = addonTable.FleshWoundFrame

-- Function to handle the frame's OnLoad event
function FleshWound_OnLoad(self)
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

    -- Create the body image
    self.BodyImage = self:CreateTexture(nil, "BACKGROUND")
    self.BodyImage:SetSize(300, 500)
    self.BodyImage:SetPoint("CENTER")
    self.BodyImage:SetTexture("Interface\\AddOns\\FleshWound\\Textures\\body_image.tga")

    -- Create clickable regions on the body
    CreateBodyRegions(self)

    -- Set up the options panel
    FleshWound_AddonOptions()
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
            OpenWoundDialog(region.name, btn)
        end)

        -- Set a highlight texture to indicate when the region is hovered over
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

        -- Keep the green dot for debugging the center of the clickable region
        local debugDot = btn:CreateTexture(nil, "OVERLAY")
        debugDot:SetSize(10, 10)
        debugDot:SetPoint("CENTER", btn, "CENTER")
        debugDot:SetColorTexture(0, 1, 0, 1)

        self.BodyRegions[region.name] = btn
    end
end

-- Redesigned function to open the wound dialog
function OpenWoundDialog(regionName, button)
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

        dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        dialog.Title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)
        dialog.Title:SetText("Wound Details - " .. regionName)

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
            OpenAddNoteDialog(regionName)
        end)

        FleshWoundDialog = dialog
    end

    -- Update the dialog content
    FleshWoundDialog.Title:SetText("Wound Details - " .. regionName)
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
            entry:SetBackdropColor(0, 0, 0, 0.5)
            entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

            local noteText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noteText:SetPoint("TOPLEFT", entry, "TOPLEFT", 10, -10)
            noteText:SetPoint("BOTTOMRIGHT", entry, "BOTTOMRIGHT", -110, 10)
            noteText:SetJustifyH("LEFT")
            noteText:SetJustifyV("TOP")
            noteText:SetText(note.text)

            -- Adjust the height based on the text content
            local textHeight = noteText:GetStringHeight()
            local entryHeight = textHeight + 30
            entry:SetHeight(entryHeight)

            local editButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
            editButton:SetSize(50, 22)
            editButton:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -55, -10)
            editButton:SetText("Edit")
            editButton:SetScript("OnClick", function()
                FleshWoundDialog:Hide()
                OpenEditNoteDialog(regionName, i)
            end)

            local deleteButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
            deleteButton:SetSize(60, 22)
            deleteButton:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -5, -10)
            deleteButton:SetText("Delete")
            deleteButton:SetScript("OnClick", function()
                table.remove(woundData[regionName], i)
                FleshWoundData = woundData  -- Save data
                OpenWoundDialog(regionName) -- Refresh the dialog
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
        dialog:SetSize(500, 400)
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
            OpenWoundDialog(regionName)
        end)

        dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        dialog.Title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)
        dialog.Title:SetText("Add Note - " .. regionName)

        -- Create a decorative line under the title
        local titleLine = dialog:CreateTexture(nil, "ARTWORK")
        titleLine:SetHeight(2)
        titleLine:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 0, -10)
        titleLine:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -15, -40)
        titleLine:SetColorTexture(1, 1, 1, 0.2)

        -- Create the multi-line EditBox within a ScrollFrame
        dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        dialog.ScrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        dialog.ScrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -35, 80)

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
        dialog.SaveButton:SetSize(100, 30)
        dialog.SaveButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -10, 15)
        dialog.SaveButton:SetText("Save")
        dialog.SaveButton:SetScript("OnClick", function()
            local text = dialog.EditBox:GetText()
            if text and text ~= "" then
                woundData[regionName] = woundData[regionName] or {}
                table.insert(woundData[regionName], { text = text })
                FleshWoundData = woundData  -- Save data
            end
            dialog.EditBox:SetText("")
            dialog:Hide()
            OpenWoundDialog(regionName)  -- Reopen the wound dialog to show updated notes
        end)

        dialog.CancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.CancelButton:SetSize(100, 30)
        dialog.CancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 10, 15)
        dialog.CancelButton:SetText("Cancel")
        dialog.CancelButton:SetScript("OnClick", function()
            dialog.EditBox:SetText("")
            dialog:Hide()
            OpenWoundDialog(regionName)  -- Reopen the wound dialog
        end)

        FleshWoundAddNoteDialog = dialog
    end

    FleshWoundAddNoteDialog.Title:SetText("Add Note - " .. regionName)
    FleshWoundAddNoteDialog.EditBox:SetText("")
    FleshWoundAddNoteDialog:Show()
    FleshWoundAddNoteDialog.EditBox:SetFocus()
end

-- Redesigned function to open the edit note dialog
function OpenEditNoteDialog(regionName, noteIndex)
    if not FleshWoundEditNoteDialog then
        local dialog = CreateFrame("Frame", "FleshWoundEditNoteDialog", UIParent, "BackdropTemplate")
        dialog:SetSize(500, 400)
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
            OpenWoundDialog(regionName)
        end)

        dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        dialog.Title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)
        dialog.Title:SetText("Edit Note - " .. regionName)

        -- Create a decorative line under the title
        local titleLine = dialog:CreateTexture(nil, "ARTWORK")
        titleLine:SetHeight(2)
        titleLine:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 0, -10)
        titleLine:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -15, -40)
        titleLine:SetColorTexture(1, 1, 1, 0.2)

        -- Create the multi-line EditBox within a ScrollFrame
        dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        dialog.ScrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        dialog.ScrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -35, 80)

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
        dialog.SaveButton:SetSize(100, 30)
        dialog.SaveButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -10, 15)
        dialog.SaveButton:SetText("Save")
        dialog.SaveButton:SetScript("OnClick", function()
            local text = dialog.EditBox:GetText()
            if text and text ~= "" then
                woundData[regionName][noteIndex].text = text
                FleshWoundData = woundData  -- Save data
            end
            dialog.EditBox:SetText("")
            dialog:Hide()
            OpenWoundDialog(regionName)  -- Reopen the wound dialog to show updated notes
        end)

        dialog.CancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.CancelButton:SetSize(100, 30)
        dialog.CancelButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 10, 15)
        dialog.CancelButton:SetText("Cancel")
        dialog.CancelButton:SetScript("OnClick", function()
            dialog.EditBox:SetText("")
            dialog:Hide()
            OpenWoundDialog(regionName)  -- Reopen the wound dialog
        end)

        FleshWoundEditNoteDialog = dialog
    end

    FleshWoundEditNoteDialog.Title:SetText("Edit Note - " .. regionName)
    FleshWoundEditNoteDialog.EditBox:SetText(woundData[regionName][noteIndex].text or "")
    FleshWoundEditNoteDialog:Show()
    FleshWoundEditNoteDialog.EditBox:SetFocus()
end

-- Function to create the addon options panel
function FleshWound_AddonOptions()
    local panel = CreateFrame("Frame", "FleshWoundOptionsPanel", UIParent)
    panel.name = "FleshWound"
    panel:Hide()

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("FleshWound Settings")

    -- Option to hide/show minimap icon
    local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    checkbox.Text:SetText("Show Minimap Icon")
    checkbox:SetChecked(not FleshWoundDB.hide)
    checkbox:SetScript("OnClick", function(self)
        FleshWoundDB.hide = not self:GetChecked()
        if FleshWoundDB.hide then
            icon:Hide("FleshWound")
        else
            icon:Show("FleshWound")
        end
    end)

    -- Register the options panel
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "FleshWound")
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    else
        print("Error: Could not register options panel.")
    end
end
