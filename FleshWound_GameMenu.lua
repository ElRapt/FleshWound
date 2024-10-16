-- FleshWound_GameMenu.lua
-- Handles adding the addon button to the Game Menu

local addonName, addonTable = ...

-- Function to toggle the FleshWoundFrame
local function ToggleFleshWoundFrame()
    local FleshWoundFrame = addonTable.FleshWoundFrame
    if not FleshWoundFrame then
        print("FleshWoundFrame is not yet initialized.")
        return
    end

    if FleshWoundFrame:IsShown() then
        FleshWoundFrame:Hide()
    else
        FleshWoundFrame:Show()
    end
end

-- Create minimap button using LibDataBroker and LibDBIcon
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("FleshWound", {
    type = "launcher",
    text = "FleshWound",
    icon = "Interface\\Icons\\INV_Misc_Bandage_01",
    OnClick = function(_, button)
        if button == "LeftButton" then
            ToggleFleshWoundFrame()
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

-- Function to add the FleshWound button to the Game Menu
local function AddFleshWoundToGameMenu()
    -- Create the button
    local btn = CreateFrame("Button", "GameMenuButtonFleshWound", GameMenuFrame, "GameMenuButtonTemplate")
    btn:SetText("FleshWound")
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetHighlightFontObject("GameFontHighlight")

    -- Set the click handler
    btn:SetScript("OnClick", function()
        HideUIPanel(GameMenuFrame)
        ToggleFleshWoundFrame()
    end)

    -- Adjust the positions of other buttons when GameMenuFrame is shown
    GameMenuFrame:HookScript("OnShow", function()
        -- Position the FleshWound button below the AddOns button if it exists, else below Macros
        if GameMenuButtonAddOns and GameMenuButtonAddOns:IsShown() then
            btn:SetPoint("TOP", GameMenuButtonAddOns, "BOTTOM", 0, -1)
        elseif GameMenuButtonMacros and GameMenuButtonMacros:IsShown() then
            btn:SetPoint("TOP", GameMenuButtonMacros, "BOTTOM", 0, -1)
        else
            btn:SetPoint("TOP", GameMenuButtonOptions, "BOTTOM", 0, -1)
        end

        -- Adjust the positions of the Logout button and other buttons
        if GameMenuButtonLogout then
            GameMenuButtonLogout:ClearAllPoints()
            GameMenuButtonLogout:SetPoint("TOP", btn, "BOTTOM", 0, -16)
        end

        -- Adjust the height of the Game Menu to fit the new button
        GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + btn:GetHeight() + 2)
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

-- Event listener to add the button when the addon loads
local gameMenuFrame = CreateFrame("Frame")
gameMenuFrame:RegisterEvent("ADDON_LOADED")
gameMenuFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        AddFleshWoundToGameMenu()
        self:UnregisterEvent("ADDON_LOADED")  -- Unregister the event after adding the button
    end
end)
