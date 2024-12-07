-- FleshWound_GameMenu.lua
-- Handles adding the addon button to the Game Menu and minimap icon

local addonName, addonTable = ...
local GameMenu = {}
addonTable.GameMenu = GameMenu  -- Expose the GameMenu module to addonTable

-- Dependencies
local LDB = LibStub("LibDataBroker-1.1")
local Icon = LibStub("LibDBIcon-1.0")

-- Initialize GameMenu
function GameMenu:Initialize()
    self:CreateMinimapIcon()
    self:AddToGameMenu()
end

-- Toggle the main frame
function GameMenu:ToggleMainFrame()
    local GUI = addonTable.GUI
    if not GUI or not GUI.frame then
        print("FleshWoundFrame is not yet initialized.")
        return
    end

    if GUI.frame:IsShown() then
        GUI.frame:Hide()
    else
        GUI.frame:Show()
    end
end

-- Create minimap button using LibDataBroker and LibDBIcon
function GameMenu:CreateMinimapIcon()
    local ldb = LDB:NewDataObject("FleshWound", {
        type = "launcher",
        text = "FleshWound",
        icon = "Interface\\Icons\\INV_Misc_Bandage_01",
        OnClick = function(_, button)
            if button == "LeftButton" then
                self:ToggleMainFrame()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("FleshWound")
            tooltip:AddLine("Left-click to show/hide the health frame.")
        end,
    })

    -- Use LibDBIcon to create minimap icon
    FleshWoundDB = FleshWoundDB or {}
    Icon:Register("FleshWound", ldb, FleshWoundDB)
end

-- Add the FleshWound button to the Game Menu
function GameMenu:AddToGameMenu()
    local btn = CreateFrame("Button", "GameMenuButtonFleshWound", GameMenuFrame, "GameMenuButtonTemplate")
    btn:SetText("FleshWound")
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetHighlightFontObject("GameFontHighlight")

    -- Set the click handler
    btn:SetScript("OnClick", function()
        HideUIPanel(GameMenuFrame)
        self:ToggleMainFrame()
    end)

    -- Adjust the positions of other buttons when GameMenuFrame is shown
    GameMenuFrame:HookScript("OnShow", function()
        btn:ClearAllPoints()
        if GameMenuButtonAddOns and GameMenuButtonAddOns:IsShown() then
            btn:SetPoint("TOP", GameMenuButtonAddOns, "BOTTOM", 0, -1)
        elseif GameMenuButtonMacros and GameMenuButtonMacros:IsShown() then
            btn:SetPoint("TOP", GameMenuButtonMacros, "BOTTOM", 0, -1)
        else
            btn:SetPoint("TOP", GameMenuButtonOptions, "BOTTOM", 0, -1)
        end

        -- Adjust the positions of the Logout button and others
        local heightOffset = btn:GetHeight() + 2
        GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + heightOffset)
        self:AdjustGameMenuButtons(btn)
    end)

    -- Add the bandage icon to the button
    local iconTexture = btn:CreateTexture(nil, "ARTWORK")
    iconTexture:SetTexture("Interface\\Icons\\INV_Misc_Bandage_01")
    iconTexture:SetSize(20, 20)
    iconTexture:SetPoint("LEFT", btn, "LEFT", 22, 0)

    -- Adjust the text position to fit with the icon
    local text = btn:GetFontString()
    text:ClearAllPoints()
    text:SetPoint("LEFT", iconTexture, "RIGHT", 4, 0)
end

-- Adjust positions of other Game Menu buttons
function GameMenu:AdjustGameMenuButtons(btn)
    local prevButton = btn
    local buttons = {
        GameMenuButtonLogout,
        GameMenuButtonQuit,
        GameMenuButtonContinue,
        GameMenuButtonMacOptions,
        GameMenuButtonOptions,
        GameMenuButtonUIOptions,
        GameMenuButtonKeybindings,
        GameMenuButtonMacros,
        GameMenuButtonAddOns,
    }

    for _, button in ipairs(buttons) do
        if button and button:IsShown() and button ~= btn then
            button:ClearAllPoints()
            button:SetPoint("TOP", prevButton, "BOTTOM", 0, -1)
            prevButton = button
        end
    end
end

local requestButton = CreateFrame("Button", nil, GameMenuFrame, "UIPanelButtonTemplate")
requestButton:SetText("Request Profile")
requestButton:SetSize(120, 24)
requestButton:SetPoint("TOP", GameMenuButtonFleshWound, "BOTTOM", 0, -5)
requestButton:SetScript("OnClick", function()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        print("No target selected.")
        return
    end
    addonTable.Comm:RequestProfile(targetName)
end)


-- Initialize when the addon loads
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        GameMenu:Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
