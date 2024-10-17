-- FleshWound_GUI.lua
-- Contains all GUI-related functions with data persistence and corrected region handling

local addonName, addonTable = ...
local woundData
local FleshWoundFrame

-- Define severities and their colors
local severities = {
    { name = "None", color = {0, 0, 0, 0} },      -- Transparent
    { name = "Minor", color = {0, 1, 0, 0.4} },   -- Green, 40% opacity
    { name = "Moderate", color = {1, 1, 0, 0.4} },-- Yellow, 40% opacity
    { name = "Severe", color = {1, 0.5, 0, 0.4} },-- Orange, 40% opacity
    { name = "Critical", color = {1, 0, 0, 0.4} },-- Red, 40% opacity
}

-- Function to handle the frame's OnLoad event
function FleshWound_OnLoad(self)
    -- Now that the frame is loaded, we can initialize woundData and FleshWoundFrame
    woundData = addonTable.woundData
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

    -- **Create the player head frame and model**
    self.HeadFrame = CreateFrame("Frame", nil, self, "BackdropTemplate")
    self.HeadFrame:SetSize(80, 80)
    self.HeadFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 15, -15)
    self.HeadFrame:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    self.HeadFrame:SetBackdropBorderColor(1, 1, 1, 1)
    self.HeadFrame:SetBackdropColor(0, 0, 0, 0)

    self.PlayerHeadModel = CreateFrame("PlayerModel", nil, self.HeadFrame)
    self.PlayerHeadModel:SetSize(76, 76)
    self.PlayerHeadModel:SetPoint("CENTER", self.HeadFrame, "CENTER", 0, 0)
    self.PlayerHeadModel:SetUnit("player")
    self.PlayerHeadModel:SetPortraitZoom(1)
    self.PlayerHeadModel:SetCamDistanceScale(1)
    self.PlayerHeadModel:SetPosition(0, 0.03, 0)  -- Shift the model to the right
    self.PlayerHeadModel:SetRotation(0)  -- Adjust rotation if needed

    -- Create the body image
    self.BodyImage = self:CreateTexture(nil, "BACKGROUND")
    self.BodyImage:SetSize(300, 500)
    self.BodyImage:SetPoint("CENTER", self, "CENTER", 0, 0)
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

        -- **Add the region marker (green dot)**
        local regionMarker = btn:CreateTexture(nil, "OVERLAY")
        regionMarker:SetSize(10, 10)
        regionMarker:SetPoint("CENTER", btn, "CENTER")
        regionMarker:SetColorTexture(0, 1, 0, 1) -- Green color
        btn.regionMarker = regionMarker

        -- **Add an overlay texture to color the region based on severity**
        local overlay = btn:CreateTexture(nil, "ARTWORK")
        overlay:SetAllPoints(btn)
        overlay:SetColorTexture(0, 0, 0, 0)  -- Default transparent
        btn.overlay = overlay

        self.BodyRegions[region.name] = btn
    end

    -- Update region colors based on severity
    UpdateRegionColors()
end

-- Function to update region colors based on severity
function UpdateRegionColors()
    for regionName, btn in pairs(FleshWoundFrame.BodyRegions) do
        local severity = woundData[regionName] and woundData[regionName].severity or "None"
        local color = GetSeverityColor(severity)
        btn.overlay:SetColorTexture(unpack(color))
    end
end

-- Function to get the color based on severity name
function GetSeverityColor(severityName)
    for _, sev in ipairs(severities) do
        if sev.name == severityName then
            return sev.color
        end
    end
    -- Default color if severity not found
    return {0, 0, 0, 0}
end

-- FleshWound_GUI.lua
-- Contains all GUI-related functions with data persistence and corrected region handling

-- (Rest of your code remains the same up to the OpenWoundDialog function)

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
    
            -- Severity Dropdown Menu
            dialog.SeverityLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dialog.SeverityLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
            dialog.SeverityLabel:SetText("Severity:")
    
            dialog.SeverityDropdown = CreateFrame("Frame", "FleshWoundSeverityDropdown", dialog, "UIDropDownMenuTemplate")
            dialog.SeverityDropdown:SetPoint("TOPLEFT", dialog.SeverityLabel, "TOPRIGHT", -10, -5)
            UIDropDownMenu_SetWidth(dialog.SeverityDropdown, 150)
    
            -- Initialize the dropdown menu
            dialog.SeverityDropdown.initialize = function(self, level)
                local info
                local currentSeverity = woundData[dialog.regionName] and woundData[dialog.regionName].severity or "None"
                for _, sev in ipairs(severities) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = sev.name
                    info.arg1 = sev.name
                    info.func = function(self, arg1)
                        UIDropDownMenu_SetSelectedName(dialog.SeverityDropdown, arg1)
                        -- Update the woundData with selected severity
                        woundData[dialog.regionName] = woundData[dialog.regionName] or {}
                        woundData[dialog.regionName].severity = arg1
                        UpdateRegionColors() -- Update region colors
                    end
                    info.checked = (sev.name == currentSeverity)
                    UIDropDownMenu_AddButton(info)
                end
            end
    
            FleshWoundDialog = dialog
        end
    
        -- Update the dialog content
        FleshWoundDialog.Title:SetText("Wound Details - " .. regionName)
        FleshWoundDialog.regionName = regionName  -- Store the current region name
    
        -- Set the severity dropdown to current severity
        local severity = woundData[regionName] and woundData[regionName].severity or "None"
        UIDropDownMenu_SetSelectedName(FleshWoundDialog.SeverityDropdown, severity)
        UIDropDownMenu_SetSelectedValue(FleshWoundDialog.SeverityDropdown, severity)
    
        -- Force refresh of the dropdown menu
        UIDropDownMenu_Initialize(FleshWoundDialog.SeverityDropdown, FleshWoundDialog.SeverityDropdown.initialize)
        UIDropDownMenu_SetSelectedName(FleshWoundDialog.SeverityDropdown, severity)
    
        -- (Rest of your OpenWoundDialog function remains the same)
    end
    
-- Redesigned function to open the add note dialog
function OpenAddNoteDialog(regionName)
    if not FleshWoundAddNoteDialog then
        local dialog = CreateFrame("Frame", "FleshWoundAddNoteDialog", UIParent, "BackdropTemplate")
        dialog:SetSize(400, 300)
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

        -- Create the multi-line EditBox within a ScrollFrame
        dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        dialog.ScrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
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
    FleshWoundAddNoteDialog:Show()
    FleshWoundAddNoteDialog.EditBox:SetFocus()

    -- Reassign the OnClick handlers to capture the current regionName
    FleshWoundAddNoteDialog.SaveButton:SetScript("OnClick", function()
        local text = FleshWoundAddNoteDialog.EditBox:GetText()
        if text and text ~= "" then
            woundData[FleshWoundAddNoteDialog.regionName] = woundData[FleshWoundAddNoteDialog.regionName] or {}
            woundData[FleshWoundAddNoteDialog.regionName].notes = woundData[FleshWoundAddNoteDialog.regionName].notes or {}
            table.insert(woundData[FleshWoundAddNoteDialog.regionName].notes, { text = text })
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
        dialog:SetSize(400, 300)
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

        -- Create the multi-line EditBox within a ScrollFrame
        dialog.ScrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        dialog.ScrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
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
    FleshWoundEditNoteDialog.EditBox:SetText(woundData[regionName].notes[noteIndex].text or "")
    FleshWoundEditNoteDialog:Show()
    FleshWoundEditNoteDialog.EditBox:SetFocus()

    -- Reassign the OnClick handlers to capture the current regionName and noteIndex
    FleshWoundEditNoteDialog.SaveButton:SetScript("OnClick", function()
        local text = FleshWoundEditNoteDialog.EditBox:GetText()
        if text and text ~= "" then
            woundData[FleshWoundEditNoteDialog.regionName].notes[FleshWoundEditNoteDialog.noteIndex].text = text
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
