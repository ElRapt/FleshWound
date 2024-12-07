-- FleshWound_TargetPopup.lua
local addonName, addonTable = ...

local popupFrame
local targetName

local function HidePopup()
    if popupFrame then
        popupFrame:Hide()
    end
end

local function ShowPopupForTarget(name)
    if not popupFrame then
        popupFrame = CreateFrame("Frame", "FleshWoundTargetPopup", UIParent, "BackdropTemplate")
        popupFrame:SetSize(50, 50)
        popupFrame:SetPoint("CENTER", 0, 200)
        popupFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 12,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        popupFrame:EnableMouse(true)

        popupFrame.icon = popupFrame:CreateTexture(nil, "ARTWORK")
        popupFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_Bandage_01")
        popupFrame.icon:SetAllPoints(popupFrame)

        popupFrame:SetScript("OnMouseDown", function()
            if targetName then
                addonTable.Comm:RequestProfile(targetName)
                HidePopup()
            end
        end)

        popupFrame.closeButton = CreateFrame("Button", nil, popupFrame, "UIPanelCloseButton")
        popupFrame.closeButton:SetPoint("TOPRIGHT", popupFrame, "TOPRIGHT", -2, -2)
        popupFrame.closeButton:SetScript("OnClick", HidePopup)
    end

    targetName = name
    popupFrame:Show()
end

-- Event Handling: When target changes, show popup if conditions are met
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function()
    HidePopup() -- Hide popup by default

    local unit = "target"
    if UnitExists(unit) and UnitIsPlayer(unit) and UnitIsFriend("player", unit) then
        local name, realm = UnitName(unit)
        if realm and realm ~= "" then
            name = name.."-"..realm
        end

        -- You can implement a more complex check to know if the target has the addon,
        -- such as sending a "PING" message and waiting for a "PONG", or using a cached list of players known to have the addon.
        -- For simplicity, let's assume we always show the popup for players.
        
        ShowPopupForTarget(name)
    end
end)
