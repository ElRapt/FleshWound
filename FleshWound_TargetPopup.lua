-- FleshWound_TargetPopup.lua
local addonName, addonTable = ...
local L = addonTable.L -- Make sure localization is loaded and addonTable.L is defined

local popupFrame
local targetName

local knownAddonUsers = addonTable.Comm:GetKnownAddonUsers() 
local PING_TIMEOUT = 5
local pendingTarget

local function HidePopup()
    if popupFrame then
        popupFrame:Hide()
    end
end

local function ShowPopupForTarget(name)
    if not popupFrame then
        popupFrame = CreateFrame("Frame", "FleshWoundTargetPopup", UIParent, "BackdropTemplate")
        popupFrame:SetSize(220, 80)
        popupFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -50, 200)
        popupFrame:SetFrameStrata("DIALOG")
        popupFrame:SetMovable(true)
        popupFrame:EnableMouse(true)
        popupFrame:RegisterForDrag("LeftButton")
        popupFrame:SetScript("OnDragStart", popupFrame.StartMoving)
        popupFrame:SetScript("OnDragStop", popupFrame.StopMovingOrSizing)

        popupFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        popupFrame:SetBackdropColor(1, 1, 1, 0.9)

        local iconButton = CreateFrame("Button", nil, popupFrame, "BackdropTemplate")
        iconButton:SetSize(32, 32)
        iconButton:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", 15, -15)

        local icon = iconButton:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\INV_Misc_Bandage_01")
        icon:SetAllPoints(iconButton)

        -- Add hover highlight
        iconButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

        -- Add tooltip on hover
        iconButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(iconButton, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["Request Profile"], 1, 1, 1)
            GameTooltip:Show()
        end)
        iconButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        iconButton:SetScript("OnClick", function()
            if targetName then
                addonTable.Comm:RequestProfile(targetName)
                -- Do NOT hide the popup now; leave it visible
            end
        end)

        popupFrame.title = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        popupFrame.title:SetPoint("TOPLEFT", iconButton, "TOPRIGHT", 10, -3)
        popupFrame.title:SetText(L["Request Profile"])

        popupFrame.text = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        popupFrame.text:SetPoint("TOPLEFT", popupFrame.title, "BOTTOMLEFT", 0, -5)
        popupFrame.text:SetWidth(popupFrame:GetWidth() - 60)
        popupFrame.text:SetJustifyH("LEFT")
        popupFrame.text:SetText(L["Click the bandage to request."])

        popupFrame.closeButton = CreateFrame("Button", nil, popupFrame, "UIPanelCloseButton")
        popupFrame.closeButton:SetPoint("TOPRIGHT", popupFrame, "TOPRIGHT", -5, -5)
        popupFrame.closeButton:SetScript("OnClick", HidePopup)
    end

    targetName = name
    popupFrame:Show()
end

local function OnPingCompleted(player)
    if player == targetName and UnitName("target") == player then
        ShowPopupForTarget(player)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        HidePopup()
        local unit = "target"
        if UnitExists(unit) and UnitIsPlayer(unit) and UnitIsFriend("player", unit) then
            local name, realm = UnitName(unit)
            if realm and realm ~= "" then
                name = name.."-"..realm
            end

            knownAddonUsers = addonTable.Comm:GetKnownAddonUsers()
            if knownAddonUsers[name] then
                ShowPopupForTarget(name)
            else
                pendingTarget = name
                addonTable.Comm:PingPlayer(name)
                C_Timer.After(PING_TIMEOUT, function()
                    knownAddonUsers = addonTable.Comm:GetKnownAddonUsers()
                    if knownAddonUsers[name] then
                        if UnitName("target") == name then
                            ShowPopupForTarget(name)
                        end
                    end
                end)
            end
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefixMsg, msg, channel, sender = ...
        local player = Ambiguate(sender, "short")

        if prefixMsg == addonTable.Comm.prefix then
            if msg == "PONG" then
                knownAddonUsers[player] = true
                if player == pendingTarget and UnitName("target") == player then
                    ShowPopupForTarget(player)
                end
            elseif msg == "REQUEST_PROFILE" or msg:match("^PROFILE_DATA:") then
                knownAddonUsers[player] = true
            end
        end
    end
end)
