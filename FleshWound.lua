-- Define the addon version
local addonVersion = "1.0.0"

-- Table to store wound notes and colors
local woundData = {}

-- Function to handle the frame's OnLoad event
function FleshWound_OnLoad(self)
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:SetScript("OnEvent", FleshWound_OnEvent)
    self:SetClampedToScreen(true)
    self:RegisterForDrag("LeftButton")

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

    -- Define regions (example: head, torso, left arm, right arm, left leg, right leg, left hand, right hand, left foot, right foot)
    local regions = {
        {name = "Head", x = 127, y = 420, width = 50, height = 75},
        {name = "Torso", x = 130, y = 275, width = 50, height = 120},
        {name = "LeftArm", x = 70, y = 300, width = 50, height = 120},
        {name = "RightArm", x = 185, y = 300, width = 50, height = 120},
        {name = "LeftHand", x = 40, y = 180, width = 50, height = 100},
        {name = "RightHand", x = 215, y = 180, width = 50, height = 100},
        {name = "LeftLeg", x = 100, y = 50, width = 50, height = 130},
        {name = "RightLeg", x = 155, y = 50, width = 50, height = 130},
        {name = "LeftFoot", x = 105, y = 0, width = 50, height = 50},
        {name = "RightFoot", x = 150, y = 0, width = 50, height = 50},
    }

    for _, region in ipairs(regions) do
        local btn = CreateFrame("Button", nil, self)
        btn:SetSize(region.width, region.height)
        btn:SetPoint("BOTTOMLEFT", self.BodyImage, "BOTTOMLEFT", region.x, region.y)
        btn:SetScript("OnClick", function()
            OpenWoundDialog(region.name, btn)
        end)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        local texture = btn:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints()
        local colors = {
            {1, 0, 0, 0.3},  -- Red
            {0, 1, 0, 0.3},  -- Green
            {0, 0, 1, 0.3},  -- Blue
            {1, 1, 0, 0.3},  -- Yellow
            {1, 0, 1, 0.3},  -- Magenta
            {0, 1, 1, 0.3},  -- Cyan
            {1, 0.5, 0, 0.3},  -- Orange
            {0.5, 0, 0.5, 0.3},  -- Purple
            {0.5, 0.5, 0.5, 0.3},  -- Gray
            {0, 0, 0, 0.3}  -- Black
        }
        local color = colors[_ % #colors + 1]
        texture:SetColorTexture(unpack(color))
        btn:SetAlpha(1)
        self.BodyRegions[region.name] = btn

        -- Create a green dot for debugging the center of the clickable region
        local debugDot = self:CreateTexture(nil, "OVERLAY")
        debugDot:SetSize(10, 10)
        debugDot:SetPoint("CENTER", btn, "CENTER")
        debugDot:SetColorTexture(0, 1, 0, 1)  -- Green color
    end
end

-- Function to open the wound dialog
function OpenWoundDialog(regionName, button)
    if not FleshWoundDialog then
        local dialog = CreateFrame("Frame", "FleshWoundDialog", UIParent, "BackdropTemplate")
        dialog:SetSize(300, 300)
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

        dialog.EditBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        dialog.EditBox:SetSize(260, 20)
        dialog.EditBox:SetPoint("TOP", dialog.Title, "BOTTOM", 0, -20)
        dialog.EditBox:SetAutoFocus(false)
        dialog.EditBox:SetMaxLetters(200)

        dialog.SaveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.SaveButton:SetSize(80, 22)
        dialog.SaveButton:SetPoint("BOTTOM", dialog, "BOTTOM", -50, 20)
        dialog.SaveButton:SetText("Save")
        dialog.SaveButton:SetScript("OnClick", function()
            local text = dialog.EditBox:GetText()
            -- Save the note
            woundData[regionName] = woundData[regionName] or {}
            woundData[regionName].note = text
            dialog:Hide()
        end)

        dialog.CancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.CancelButton:SetSize(80, 22)
        dialog.CancelButton:SetPoint("BOTTOM", dialog, "BOTTOM", 50, 20)
        dialog.CancelButton:SetText("Cancel")
        dialog.CancelButton:SetScript("OnClick", function()
            dialog:Hide()
        end)

        FleshWoundDialog = dialog
    end

    FleshWoundDialog.Title:SetText("Wound Details - " .. regionName)
    FleshWoundDialog.EditBox:SetText(woundData[regionName] and woundData[regionName].note or "")
    FleshWoundDialog:Show()
end

-- Create minimap button using LibDataBroker and LibDBIcon
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("FleshWound", {
    type = "launcher",
    text = "FleshWound",
    icon = "Interface\\Icons\\INV_Misc_Bandage_01",  -- Updated icon
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