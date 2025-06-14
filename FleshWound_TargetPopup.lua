local addonName, addonTable = ...
local L = addonTable.L
local Utils = addonTable.Utils

local CONSTANTS = {
    FRAME_SIZE = { WIDTH = 220, HEIGHT = 80 },
    QUERY_RETRY_DURATION = 10,
    FRAME_POSITION = { ANCHOR = "BOTTOMRIGHT", X_OFFSET = -50, Y_OFFSET = 200 },
    BACKDROP = {
        GOLD_BG = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
        GOLD_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        EDGE_SIZE = 32,
        TILE_SIZE = 32,
        INSET = 8,
        BG_ALPHA = 0.9
    },
    ICON = {
        BANDAGE = "Interface\\Icons\\INV_Misc_Bandage_01",
        HIGHLIGHT = "Interface\\Buttons\\UI-Common-MouseHilight",
        SIZE = 32
    },
    POPUP_OFFSET_ON_CLOSE_BUTTON = { X = -5, Y = -5 },
    DEFAULT_POPUP_POS = { X = -50, Y = 200 },
}

-- Cache of recent failed lookup attempts.
-- Maps normalized player names to the timestamp (via time()) of the last
-- unsuccessful query. Entries are cleared when a HELLO from that player is
-- received, allowing new queries to be sent immediately.
local failedLookupCache = {}

local pendingTarget
local popupFrame
local targetName

--- A function to save the position of the popup frame.
local function SavePopupPosition()
    if not FleshWoundData then FleshWoundData = {} end
    FleshWoundData.popupPos = FleshWoundData.popupPos or {}
    local point, _, relativePoint, xOfs, yOfs = popupFrame:GetPoint()
    FleshWoundData.popupPos.point = point
    FleshWoundData.popupPos.relativePoint = relativePoint
    FleshWoundData.popupPos.xOfs = xOfs
    FleshWoundData.popupPos.yOfs = yOfs
end

--- A function to restore the position of the popup frame.
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
        popupFrame:SetPoint(
            CONSTANTS.FRAME_POSITION.ANCHOR,
            UIParent,
            CONSTANTS.FRAME_POSITION.ANCHOR,
            CONSTANTS.FRAME_POSITION.X_OFFSET,
            CONSTANTS.FRAME_POSITION.Y_OFFSET
        )
    end
end


--- Helper function to hide the popup frame.
local function HidePopup()
    if popupFrame then
        popupFrame:Hide()
    end
end


--- The function to show the popup frame for a target.
--- @param name string: The name of the target player.
local function ShowPopupForTarget(name)
    if not popupFrame then
        popupFrame = CreateFrame("Frame", "FleshWoundTargetPopup", UIParent, "BackdropTemplate")
        popupFrame:SetSize(CONSTANTS.FRAME_SIZE.WIDTH, CONSTANTS.FRAME_SIZE.HEIGHT)
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
            bgFile = CONSTANTS.BACKDROP.GOLD_BG,
            edgeFile = CONSTANTS.BACKDROP.GOLD_BORDER,
            tile = true,
            tileSize = CONSTANTS.BACKDROP.TILE_SIZE,
            edgeSize = CONSTANTS.BACKDROP.EDGE_SIZE,
            insets = { left = CONSTANTS.BACKDROP.INSET, right = CONSTANTS.BACKDROP.INSET, top = CONSTANTS.BACKDROP.INSET, bottom = CONSTANTS.BACKDROP.INSET },
        })
        popupFrame:SetBackdropColor(1, 1, 1, CONSTANTS.BACKDROP.BG_ALPHA)
        local iconButton = CreateFrame("Button", nil, popupFrame, "BackdropTemplate")
        iconButton:SetSize(CONSTANTS.ICON.SIZE, CONSTANTS.ICON.SIZE)
        iconButton:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", 15, -15)
        local icon = iconButton:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(CONSTANTS.ICON.BANDAGE)
        icon:SetAllPoints(iconButton)
        iconButton:SetHighlightTexture(CONSTANTS.ICON.HIGHLIGHT, "ADD")
        iconButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(iconButton, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L.REQUEST_PROFILE, 1, 1, 1)
            GameTooltip:Show()
        end)
        iconButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        iconButton:SetScript("OnClick", function()
            if targetName then
                addonTable.Comm:RequestProfile(targetName)
            end
        end)
        popupFrame.title = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        popupFrame.title:SetPoint("TOPLEFT", iconButton, "TOPRIGHT", 10, -3)
        popupFrame.title:SetText(L.REQUEST_PROFILE)
        popupFrame.text = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        popupFrame.text:SetPoint("TOPLEFT", popupFrame.title, "BOTTOMLEFT", 0, -5)
        popupFrame.text:SetWidth(popupFrame:GetWidth() - 60)
        popupFrame.text:SetJustifyH("LEFT")
        popupFrame.text:SetText(L.CLICK_BANDAGE_REQUEST)
        popupFrame.closeButton = CreateFrame("Button", nil, popupFrame, "UIPanelCloseButton")
        popupFrame.closeButton:SetPoint("TOPRIGHT", popupFrame, "TOPRIGHT", CONSTANTS.POPUP_OFFSET_ON_CLOSE_BUTTON.X, CONSTANTS.POPUP_OFFSET_ON_CLOSE_BUTTON.Y)
        popupFrame.closeButton:SetScript("OnClick", HidePopup)
        RestorePopupPosition()
    end
    targetName = name
    popupFrame:Show()
end



--- Helper function to attempt to show the popup frame for a target.
--- @param targetName string: The name of the target player.
--- @param totalTimeout number: The total time to wait for the target to respond.
--- @return void
local function AttemptToShowPopup(targetName, totalTimeout)
    local elapsed = 0
    local interval = 1  -- check every second
    local ticker
    ticker = C_Timer.NewTicker(interval, function()
        elapsed = elapsed + interval
        addonTable.Registry:SendQuery(targetName)

        if addonTable.Registry:IsUserOnline(targetName) then
            ShowPopupForTarget(targetName)
            pendingTarget = nil
            if ticker then
                ticker:Cancel()
            end
        elseif elapsed >= totalTimeout then
            if ticker then
                ticker:Cancel()
            end
            failedLookupCache[Utils.ToLower(targetName)] = time()
        end
    end)
end

--- Event frame to catch PLAYER_TARGET_CHANGED and CHAT_MSG_ADDON events.
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
                name = name .. "-" .. realm
            end
            local normalized = Utils.NormalizePlayerName(name)
            local key = Utils.ToLower(normalized)
            if addonTable.Registry:IsUserOnline(normalized) then
                ShowPopupForTarget(normalized)
            else
                -- Skip querying if we recently failed to locate this player
                local lastFail = failedLookupCache[key]
                if not (lastFail and (time() - lastFail) < CONSTANTS.QUERY_RETRY_DURATION) then
                    pendingTarget = normalized
                    AttemptToShowPopup(normalized, CONSTANTS.QUERY_RETRY_DURATION)
                end
            end
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, _, sender = ...
        if prefix == addonTable.Registry.PREFIX then
            local eventType = strsplit(":", msg)
            if eventType == addonTable.Registry.EVENT_HELLO then
                local normalized = Utils.NormalizePlayerName(sender)
                local key = normalized and Utils.ToLower(normalized)
                -- Remove any cached failure entry when the player finally responds
                if key and failedLookupCache[key] then
                    failedLookupCache[key] = nil
                end
            end
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...
        if pendingTarget and prefix == addonTable.Registry.PREFIX then
            local evt = strsplit(":", msg)
            if evt == addonTable.Registry.EVENT_HELLO then
                local normSender = Utils.NormalizePlayerName(sender)
                local normPending = Utils.NormalizePlayerName(pendingTarget)
                if normSender and normPending and Utils.ToLower(normSender) == Utils.ToLower(normPending) then
                    ShowPopupForTarget(pendingTarget)
                    pendingTarget = nil
                end
            end
        end
    end
end)
