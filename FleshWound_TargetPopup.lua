-- FleshWound_TargetPopup.lua

local addonName, addonTable = ...
local L = addonTable.L -- Localization
local knownAddonUsers = addonTable.Comm:GetKnownAddonUsers()
local PING_TIMEOUT = 5
local pendingTarget
local popupFrame
local targetName

---------------------------------------------------
-- Save/restore the popup's position
---------------------------------------------------
local function SavePopupPosition()
    if not FleshWoundData then FleshWoundData = {} end
    FleshWoundData.popupPos = FleshWoundData.popupPos or {}

    local point, _, relativePoint, xOfs, yOfs = popupFrame:GetPoint()
    FleshWoundData.popupPos.point = point
    FleshWoundData.popupPos.relativePoint = relativePoint
    FleshWoundData.popupPos.xOfs = xOfs
    FleshWoundData.popupPos.yOfs = yOfs
end

local function RestorePopupPosition()
    if FleshWoundData and FleshWoundData.popupPos then
        popupFrame:ClearAllPoints()
        popupFrame:SetPoint(
            FleshWoundData.popupPos.point,
            UIParent,
            FleshWoundData.popupPos.relativePoint,
            FleshWoundData.popupPos.xOfs,
            FleshWoundData.popupPos.yOfs
        )
    else
        popupFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -50, 200)
    end
end

---------------------------------------------------
-- Hide/show the popup
---------------------------------------------------
local function HidePopup()
    if popupFrame then
        popupFrame:Hide()
    end
end

local function ShowPopupForTarget(name)
    if not popupFrame then
        popupFrame = CreateFrame("Frame", "FleshWoundTargetPopup", UIParent, "BackdropTemplate")
        popupFrame:SetSize(220, 80)
        popupFrame:SetFrameStrata("DIALOG")
        popupFrame:SetMovable(true)
        popupFrame:EnableMouse(true)
        popupFrame:RegisterForDrag("LeftButton")
        popupFrame:SetScript("OnDragStart", popupFrame.StartMoving)
        popupFrame:SetScript("OnDragStop", function()
            popupFrame:StopMovingOrSizing()
            SavePopupPosition()
        end)

        popupFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        popupFrame:SetBackdropColor(1, 1, 1, 0.9)

        -- An icon button for requesting profiles
        local iconButton = CreateFrame("Button", nil, popupFrame, "BackdropTemplate")
        iconButton:SetSize(32, 32)
        iconButton:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", 15, -15)

        local icon = iconButton:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\INV_Misc_Bandage_01")
        icon:SetAllPoints(iconButton)

        iconButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
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
                -- Optionally hide the popup here if you want.
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

        -- Restore the saved position (if any) after creating the frame
        RestorePopupPosition()
    end

    targetName = name
    popupFrame:Show()
end

---------------------------------------------------
-- Event frame that checks when you change target
-- or when we receive an addon message
---------------------------------------------------
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

            -- If we already know this target has FleshWound, show popup immediately
            if knownAddonUsers[name] then
                ShowPopupForTarget(name)
            else
                -- Otherwise send a ping and wait for PONG before showing
                pendingTarget = name
                addonTable.Comm:PingPlayer(name)
            end
        end

    elseif event == "CHAT_MSG_ADDON" then
        local prefixMsg, msg, channel, sender = ...
        local player = Ambiguate(sender, "short")

        -- Make sure it's our prefix before proceeding
        if prefixMsg ~= "FleshWoundComm" then
            return
        end

        -- If we got a PONG from someone, mark them as known
        if msg == "PONG" then
            knownAddonUsers[player] = true

            -- If the player we pinged is the current target, show the popup
            if player == pendingTarget and UnitName("target") == player then
                ShowPopupForTarget(player)
            end

        -- If we see these messages, also mark them known
        elseif msg == "REQUEST_PROFILE" or msg:match("^PROFILE_DATA:") then
            knownAddonUsers[player] = true
        end
    end
end)
