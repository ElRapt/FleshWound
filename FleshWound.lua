-- Create the main frame for the addon
local frame = CreateFrame("Frame", "MyHealthUIFrame", UIParent)
frame:SetSize(200, 50)  -- Width, Height
frame:SetPoint("CENTER", UIParent, "CENTER")  -- Position in the center of the screen
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Background texture
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- Border texture
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 1)  -- Black background
frame:Hide()  -- Start with the frame hidden

-- Create the title for the frame
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText("Character Health")

-- Create a StatusBar to represent health
local healthBar = CreateFrame("StatusBar", nil, frame)
healthBar:SetSize(180, 20)
healthBar:SetPoint("CENTER", frame, "CENTER", 0, -5)
healthBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
healthBar:SetStatusBarColor(0, 1, 0)  -- Green health bar
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(75)  -- Example: start with 75% health

-- Create text to display the health value
local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
healthText:SetText("75 / 100")

-- Function to update the health bar (for testing purposes)
local function UpdateHealth(newValue)
    healthBar:SetValue(newValue)
    healthText:SetText(newValue .. " / 100")
end

-- Slash command to toggle the UI
SLASH_MYADDON1 = "/healthui"  -- Define the slash command /healthui
SlashCmdList["MYADDON"] = function(msg)
    if frame:IsShown() then
        frame:Hide()  -- Hide the frame if it's currently shown
    else
        frame:Show()  -- Show the frame if it's currently hidden
    end
end

-- Test: Change health dynamically after 3 seconds
C_Timer.After(3, function()
    UpdateHealth(50)  -- Set health to 50 after 3 seconds
end)