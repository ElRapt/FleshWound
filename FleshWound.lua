-- Define the addon version
local addonVersion = "1.0.0"

-- Table to store wound notes
local woundData = {}

-- Function to handle the frame's OnLoad event
function FleshWound_OnLoad(self)
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:SetScript("OnEvent", FleshWound_OnEvent)
    self:SetClampedToScreen(true)
    self:RegisterForDrag("LeftButton")

    -- Set the frame size slightly larger than the body image
    self:SetSize(320, 540)

    -- Set the backdrop
    self:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
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
end

-- Event handler function
function FleshWound_OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "FleshWound" then
        ShowWelcomeMessage()

        -- Load saved data
        if FleshWoundData then
            woundData = FleshWoundData
        else
            FleshWoundData = woundData
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Additional actions when entering the world
    end
end

-- Show welcome message
function ShowWelcomeMessage()
    local message = "|cFFFF0000<FleshWound>|r Welcome to FleshWound v" .. addonVersion .. "!"
    print(message)
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

        -- Bring back the green dot for debugging the center of the clickable region
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
        dialog:SetSize(400, 350)
        dialog:SetPoint("CENTER")
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
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
        dialog.ScrollFrame:SetSize(360, 220)

        dialog.ScrollChild = CreateFrame("Frame", nil, dialog.ScrollFrame)
        dialog.ScrollChild:SetSize(360, 220)
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
                FleshWoundDialog:Hide()
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
        dialog:SetSize(350, 200)
        dialog:SetPoint("CENTER")
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
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

        dialog.EditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        dialog.EditBox:SetSize(310, 20)
        dialog.EditBox:SetPoint("TOP", dialog.Title, "BOTTOM", 0, -20)
        dialog.EditBox:SetAutoFocus(false)
        dialog.EditBox:SetMaxLetters(200)

        dialog.SaveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.SaveButton:SetSize(80, 22)
        dialog.SaveButton:SetPoint("BOTTOM", dialog, "BOTTOM", -50, 20)
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
        dialog.CancelButton:SetSize(80, 22)
        dialog.CancelButton:SetPoint("BOTTOM", dialog, "BOTTOM", 50, 20)
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
end

-- Function to open the edit note dialog
function OpenEditNoteDialog(regionName, noteIndex)
    if not FleshWoundEditNoteDialog then
        local dialog = CreateFrame("Frame", "FleshWoundEditNoteDialog", UIParent, "BackdropTemplate")
        dialog:SetSize(350, 200)
        dialog:SetPoint("CENTER")
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
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

        dialog.EditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        dialog.EditBox:SetSize(310, 20)
        dialog.EditBox:SetPoint("TOP", dialog.Title, "BOTTOM", 0, -20)
        dialog.EditBox:SetAutoFocus(false)
        dialog.EditBox:SetMaxLetters(200)

        dialog.SaveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.SaveButton:SetSize(80, 22)
        dialog.SaveButton:SetPoint("BOTTOM", dialog, "BOTTOM", -50, 20)
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
        dialog.CancelButton:SetSize(80, 22)
        dialog.CancelButton:SetPoint("BOTTOM", dialog, "BOTTOM", 50, 20)
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
end

-- Create minimap button using LibDataBroker and LibDBIcon
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("FleshWound", {
    type = "launcher",
    text = "FleshWound",
    icon = "Interface\\Icons\\INV_Misc_Bandage_01",
    OnClick = function(_, button)
        if button == "LeftButton" then
            if FleshWoundFrame:IsShown() then
                FleshWoundFrame:Hide()
            else
                FleshWoundFrame:Show()
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("FleshWound")
        tooltip:AddLine("Left-click to show/hide the health frame.")
    end,
})

-- Use LibDBIcon to create minimap icon
local icon = LibStub("LibDBIcon-1.0")
if not FleshWoundDB then
    FleshWoundDB = {}
end
icon:Register("FleshWound", LDB, FleshWoundDB)

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

    -- Use the new Settings API to add the panel to the Interface Options
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "FleshWound")
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        -- Fallback for older clients
        InterfaceOptions_AddCategory(panel)
    else
        print("Error: Could not register options panel. Neither Settings API nor InterfaceOptions_AddCategory is available.")
    end
end

-- Call the function to set up the options panel
FleshWound_AddonOptions()

-- Create the main frame for the addon
local FleshWoundFrame = CreateFrame("Frame", "FleshWoundFrame", UIParent, "BackdropTemplate")
FleshWoundFrame:SetPoint("CENTER")
FleshWoundFrame:EnableMouse(true)
FleshWoundFrame:SetMovable(true)
FleshWoundFrame:SetScript("OnMouseDown", FleshWoundFrame_OnDragStart)
FleshWoundFrame:SetScript("OnMouseUp", FleshWoundFrame_OnDragStop)

-- Initialize the frame
FleshWound_OnLoad(FleshWoundFrame)

-- Function to add the FleshWound button to the Game Menu
local function AddFleshWoundToGameMenu()
    -- Create the button
    local btn = CreateFrame("Button", "GameMenuButtonFleshWound", GameMenuFrame, "GameMenuButtonTemplate")
    btn:SetText("FleshWound")
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetHighlightFontObject("GameFontHighlight")

    -- Position the button below the AddOns button
    btn:SetPoint("TOP", GameMenuButtonAddOns, "BOTTOM", 0, -1)

    -- Set the click handler
    btn:SetScript("OnClick", function()
        HideUIPanel(GameMenuFrame)
        if FleshWoundFrame:IsShown() then
            FleshWoundFrame:Hide()
        else
            FleshWoundFrame:Show()
        end
    end)

    -- Adjust the positions of other buttons
    GameMenuButtonLogout:ClearAllPoints()
    GameMenuButtonLogout:SetPoint("TOP", btn, "BOTTOM", 0, -16)

    -- Adjust the height of the Game Menu
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + btn:GetHeight() + 2)

    -- Add the bandage icon to the button
    local iconTexture = btn:CreateTexture(nil, "ARTWORK")
    iconTexture:SetTexture("Interface\\Icons\\INV_Misc_Bandage_01")
    iconTexture:SetSize(20, 20)
    iconTexture:SetPoint("LEFT", btn, "LEFT", 22, 0)

    -- Adjust the text position
    local text = btn:GetFontString()
    text:ClearAllPoints()
    text:SetPoint("LEFT", iconTexture, "RIGHT", 4, 0)
end

-- Event listener to add the button when the addon loads
local gameMenuFrame = CreateFrame("Frame")
gameMenuFrame:RegisterEvent("ADDON_LOADED")
gameMenuFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "FleshWound" then
        AddFleshWoundToGameMenu()
        self:UnregisterEvent("ADDON_LOADED")  -- Unregister the event after adding the button
    end
end)
