-- FleshWound_GUI.lua
-- Contains all GUI-related functions

local addonName, addonTable = ...
local woundData = addonTable.woundData
local FleshWoundFrame = addonTable.FleshWoundFrame

-- Function to handle the frame's OnLoad event
function FleshWound_OnLoad(self)
    self:RegisterEvent("ADDON_LOADED")
    self:SetScript("OnEvent", FleshWound_OnEvent)
    self:SetClampedToScreen(true)
    self:RegisterForDrag("LeftButton")

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

-- Function to open the wound dialog
function OpenWoundDialog(regionName, button)
    if not FleshWoundDialog then
        local dialog = CreateFrame("Frame", "FleshWoundDialog", UIParent, "BackdropTemplate")
        dialog:SetPoint("CENTER")
        dialog:SetSize(400, 300)  -- Set default size
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  -- Blizzard default background
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        dialog:SetFrameStrata("DIALOG")
        dialog:Hide()

        dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        dialog.Title:SetPoint("TOP", 0, -16)
        dialog.Title:SetText("Wound Details")

        -- ScrollFrame to display notes
        dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        dialog.ScrollFrame:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 0, -10)
        dialog.ScrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -30, 60)

        dialog.ScrollChild = CreateFrame("Frame", nil, dialog.ScrollFrame)
        dialog.ScrollChild:SetSize(1, 1)
        dialog.ScrollFrame:SetScrollChild(dialog.ScrollChild)

        -- Placeholder for note entries
        dialog.NoteEntries = {}

        dialog.AddNoteButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.AddNoteButton:SetSize(100, 22)
        dialog.AddNoteButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, 20)
        dialog.AddNoteButton:SetText("Add a Note")
        dialog.AddNoteButton:SetScript("OnClick", function()
            dialog:Hide()
            OpenAddNoteDialog(regionName)
        end)

        dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.CloseButton:SetSize(80, 22)
        dialog.CloseButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, 20)
        dialog.CloseButton:SetText("Close")
        dialog.CloseButton:SetScript("OnClick", function()
            dialog:Hide()
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
            local entry = CreateFrame("Frame", nil, FleshWoundDialog.ScrollChild)
            entry:SetSize(340, 30)
            entry:SetPoint("TOPLEFT", 0, yOffset)

            local noteText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noteText:SetPoint("LEFT")
            noteText:SetWidth(220)
            noteText:SetJustifyH("LEFT")
            noteText:SetText(i .. ". " .. note.text)

            local editButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
            editButton:SetSize(50, 22)
            editButton:SetPoint("LEFT", noteText, "RIGHT", 5, 0)
            editButton:SetText("Edit")
            editButton:SetScript("OnClick", function()
                FleshWoundDialog:Hide()
                OpenEditNoteDialog(regionName, i)
            end)

            local deleteButton = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
            deleteButton:SetSize(60, 22)
            deleteButton:SetPoint("LEFT", editButton, "RIGHT", 5, 0)
            deleteButton:SetText("Delete")
            deleteButton:SetScript("OnClick", function()
                table.remove(woundData[regionName], i)
                FleshWoundData = woundData  -- Save data
                OpenWoundDialog(regionName) -- Refresh the dialog
            end)

            table.insert(FleshWoundDialog.NoteEntries, entry)
            yOffset = yOffset - 35
        end
        -- Adjust the ScrollChild height
        FleshWoundDialog.ScrollChild:SetHeight(-yOffset)
    else
        local noNotesText = FleshWoundDialog.ScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noNotesText:SetPoint("TOPLEFT", 0, -10)
        noNotesText:SetWidth(340)
        noNotesText:SetJustifyH("LEFT")
        noNotesText:SetText("Nothing noteworthy.")

        table.insert(FleshWoundDialog.NoteEntries, noNotesText)
        FleshWoundDialog.ScrollChild:SetHeight(30)
    end

    FleshWoundDialog:Show()
end

-- Function to open the add note dialog
function OpenAddNoteDialog(regionName)
    if not FleshWoundAddNoteDialog then
        local dialog = CreateFrame("Frame", "FleshWoundAddNoteDialog", UIParent, "BackdropTemplate")
        dialog:SetSize(400, 300)
        dialog:SetPoint("CENTER")
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  -- Blizzard default background
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        dialog:SetFrameStrata("DIALOG")
        dialog:Hide()

        dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        dialog.Title:SetPoint("TOP", 0, -16)
        dialog.Title:SetText("Add Note")

        -- Multi-line EditBox
        dialog.EditBox = CreateFrame("ScrollFrame", nil, dialog, "InputScrollFrameTemplate")
        dialog.EditBox:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 10, -20)
        dialog.EditBox:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -30, 60)
        dialog.EditBox.EditBox:SetMaxLetters(1000)
        dialog.EditBox.EditBox:SetAutoFocus(true)
        dialog.EditBox.CharCount:Hide()  -- Hide character count if not needed

        dialog.SaveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.SaveButton:SetSize(80, 22)
        dialog.SaveButton:SetPoint("BOTTOM", dialog, "BOTTOM", -50, 20)
        dialog.SaveButton:SetText("Save")
        dialog.SaveButton:SetScript("OnClick", function()
            local text = dialog.EditBox.EditBox:GetText()
            if text and text ~= "" then
                woundData[regionName] = woundData[regionName] or {}
                table.insert(woundData[regionName], { text = text })
                FleshWoundData = woundData  -- Save data
            end
            dialog.EditBox.EditBox:SetText("")
            dialog:Hide()
            OpenWoundDialog(regionName)  -- Reopen the wound dialog to show updated notes
        end)

        dialog.CancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.CancelButton:SetSize(80, 22)
        dialog.CancelButton:SetPoint("BOTTOM", dialog, "BOTTOM", 50, 20)
        dialog.CancelButton:SetText("Cancel")
        dialog.CancelButton:SetScript("OnClick", function()
            dialog.EditBox.EditBox:SetText("")
            dialog:Hide()
            OpenWoundDialog(regionName)  -- Reopen the wound dialog
        end)

        FleshWoundAddNoteDialog = dialog
    end

    FleshWoundAddNoteDialog.Title:SetText("Add Note - " .. regionName)
    FleshWoundAddNoteDialog.EditBox.EditBox:SetText("")
    FleshWoundAddNoteDialog:Show()
    FleshWoundAddNoteDialog.EditBox.EditBox:SetFocus()
end

-- Function to open the edit note dialog
function OpenEditNoteDialog(regionName, noteIndex)
    if not FleshWoundEditNoteDialog then
        local dialog = CreateFrame("Frame", "FleshWoundEditNoteDialog", UIParent, "BackdropTemplate")
        dialog:SetSize(400, 300)
        dialog:SetPoint("CENTER")
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  -- Blizzard default background
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        dialog:SetFrameStrata("DIALOG")
        dialog:Hide()

        dialog.Title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        dialog.Title:SetPoint("TOP", 0, -16)
        dialog.Title:SetText("Edit Note")

        -- Multi-line EditBox
        dialog.EditBox = CreateFrame("ScrollFrame", nil, dialog, "InputScrollFrameTemplate")
        dialog.EditBox:SetPoint("TOPLEFT", dialog.Title, "BOTTOMLEFT", 10, -20)
        dialog.EditBox:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -30, 60)
        dialog.EditBox.EditBox:SetMaxLetters(1000)
        dialog.EditBox.EditBox:SetAutoFocus(true)
        dialog.EditBox.CharCount:Hide()  -- Hide character count if not needed

        dialog.SaveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.SaveButton:SetSize(80, 22)
        dialog.SaveButton:SetPoint("BOTTOM", dialog, "BOTTOM", -50, 20)
        dialog.SaveButton:SetText("Save")
        dialog.SaveButton:SetScript("OnClick", function()
            local text = dialog.EditBox.EditBox:GetText()
            if text and text ~= "" then
                woundData[regionName][noteIndex].text = text
                FleshWoundData = woundData  -- Save data
            end
            dialog.EditBox.EditBox:SetText("")
            dialog:Hide()
            OpenWoundDialog(regionName)  -- Reopen the wound dialog to show updated notes
        end)

        dialog.CancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.CancelButton:SetSize(80, 22)
        dialog.CancelButton:SetPoint("BOTTOM", dialog, "BOTTOM", 50, 20)
        dialog.CancelButton:SetText("Cancel")
        dialog.CancelButton:SetScript("OnClick", function()
            dialog.EditBox.EditBox:SetText("")
            dialog:Hide()
            OpenWoundDialog(regionName)  -- Reopen the wound dialog
        end)

        FleshWoundEditNoteDialog = dialog
    end

    FleshWoundEditNoteDialog.Title:SetText("Edit Note - " .. regionName)
    FleshWoundEditNoteDialog.EditBox.EditBox:SetText(woundData[regionName][noteIndex].text or "")
    FleshWoundEditNoteDialog:Show()
    FleshWoundEditNoteDialog.EditBox.EditBox:SetFocus()
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
