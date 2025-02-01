-- FleshWound_GameMenu.lua
-- Adds a button to the Game Menu and a minimap icon using LDB/LibDBIcon.

local addonName, addonTable = ...
local GameMenu = {}
addonTable.GameMenu = GameMenu
local L = addonTable.L

local LDB = LibStub("LibDataBroker-1.1")
local Icon = LibStub("LibDBIcon-1.0")
local Utils = addonTable.Utils

--[[---------------------------------------------------------------------------
  Initialize the minimap icon and game menu button.
---------------------------------------------------------------------------]]--
function GameMenu:Initialize()
    self:CreateMinimapIcon()
    self:AddToGameMenu()
end

--[[---------------------------------------------------------------------------
  Toggle the main frame. Called by the game menu button or minimap icon.
---------------------------------------------------------------------------]]--
function GameMenu:ToggleMainFrame()
    local GUI = addonTable.GUI
    if not GUI or not GUI.frame then
        Utils.FW_Print("FleshWound main frame is not initialized.", true)
        return
    end

    if GUI.frame:IsShown() then
        GUI.frame:Hide()
    else
        GUI.frame:Show()
    end
end

--[[---------------------------------------------------------------------------
  Create the minimap icon using LibDataBroker + LibDBIcon.
---------------------------------------------------------------------------]]--

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
            tooltip:AddLine(L.LEFT_CLICK_SHOW_HIDE)
        end,
    })

    FleshWoundDB = FleshWoundDB or {}
    Icon:Register("FleshWound", ldb, FleshWoundData)
end

--[[---------------------------------------------------------------------------
  Add "FleshWound" to the main Game Menu (ESC screen).
---------------------------------------------------------------------------]]--
function GameMenu:AddToGameMenu()
    local btn = CreateFrame("Button", "GameMenuButtonFleshWound", GameMenuFrame, "GameMenuButtonTemplate")
    btn:SetText("FleshWound")
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetHighlightFontObject("GameFontHighlight")

    btn:SetScript("OnClick", function()
        HideUIPanel(GameMenuFrame)
        self:ToggleMainFrame()
    end)

    -- Adjust existing buttons when GameMenuFrame is shown
    GameMenuFrame:HookScript("OnShow", function()
        btn:ClearAllPoints()
        if GameMenuButtonAddOns and GameMenuButtonAddOns:IsShown() then
            btn:SetPoint("TOP", GameMenuButtonAddOns, "BOTTOM", 0, -1)
        elseif GameMenuButtonMacros and GameMenuButtonMacros:IsShown() then
            btn:SetPoint("TOP", GameMenuButtonMacros, "BOTTOM", 0, -1)
        else
            btn:SetPoint("TOP", GameMenuButtonOptions, "BOTTOM", 0, -1)
        end

        local heightOffset = btn:GetHeight() + 2
        GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + heightOffset)
        self:AdjustGameMenuButtons(btn)
    end)

    local iconTexture = btn:CreateTexture(nil, "ARTWORK")
    iconTexture:SetTexture("Interface\\Icons\\INV_Misc_Bandage_01")
    iconTexture:SetSize(20, 20)
    iconTexture:SetPoint("LEFT", btn, "LEFT", 22, 0)

    local text = btn:GetFontString()
    text:ClearAllPoints()
    text:SetPoint("LEFT", iconTexture, "RIGHT", 4, 0)

    -- An extra button to request a profile from your current target
    local requestButton = CreateFrame("Button", nil, GameMenuFrame, "UIPanelButtonTemplate")
    requestButton:SetText("Request Profile")
    requestButton:SetSize(120, 24)
    requestButton:SetPoint("TOP", btn, "BOTTOM", 0, -5)
    requestButton:SetScript("OnClick", function()
        local targetName = UnitName("target")
        if not targetName or targetName == "" then
            UIErrorsFrame:AddMessage("No target selected.", 1.0, 0.0, 0.0, 5)
            return
        end
        addonTable.Comm:RequestProfile(targetName)
    end)
end

--[[---------------------------------------------------------------------------
  Adjust the positions of other menu buttons so nothing overlaps.
---------------------------------------------------------------------------]]--
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

-- Register for ADDON_LOADED to call Initialize
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        GameMenu:Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
