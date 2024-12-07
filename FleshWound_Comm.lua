-- FleshWound_Comm.lua

local addonName, addonTable = ...
local Comm = {}
addonTable.Comm = Comm

local prefix = "FleshWoundComm"
local knownAddonUsers = {}
local pendingPings = {}
local PING_TIMEOUT = 2

-- Load AceSerializer
local AceSerializer = LibStub("AceSerializer-3.0")

function Comm:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(prefix)
end

function Comm:RequestProfile(targetPlayer)
    if not targetPlayer then return end
    if not knownAddonUsers[targetPlayer] then
        self:PingPlayer(targetPlayer)
    else
        C_ChatInfo.SendAddonMessage(prefix, "REQUEST_PROFILE", "WHISPER", targetPlayer)
    end
end

function Comm:SendProfileData(targetPlayer, profileName)
    local data = addonTable.FleshWoundData.profiles[profileName]
    if not data then return end
    local serialized = self:SerializeProfile(data)
    C_ChatInfo.SendAddonMessage(prefix, "PROFILE_DATA:"..profileName..":"..serialized, "WHISPER", targetPlayer)
end

function Comm:SerializeProfile(profileData)
    -- Just serialize the woundData table
    -- AceSerializer will handle all fields and special characters
    local woundData = profileData.woundData or {}
    local serialized = AceSerializer:Serialize(woundData)
    return serialized
end

function Comm:DeserializeProfile(serialized)
    local profileData = { woundData = {} }
    if serialized == "" then
        print("DeserializeProfile: Empty data, returning empty profileData.")
        return profileData
    end

    local success, woundData = AceSerializer:Deserialize(serialized)
    if success and type(woundData) == "table" then
        profileData.woundData = woundData
    else
        print("DeserializeProfile: Failed to deserialize data or invalid data type.")
    end

    -- Debug logging
    print("DeserializeProfile: Finished deserialization.")
    for region, notes in pairs(profileData.woundData) do
        print("Region:", region, "Notes Count:", #notes)
        for idx, note in ipairs(notes) do
            print("  Note #"..idx..": Severity:", note.severity, "Text:", note.text)
        end
    end

    return profileData
end

function Comm:ShowIncomingProfilePopup(sender, profileName, profileData)
    if not knownAddonUsers[sender] then
        return
    end

    if not Comm.popupFrame then
        Comm.popupFrame = CreateFrame("Frame", "FleshWoundIncomingProfilePopup", UIParent, "BackdropTemplate")
        Comm.popupFrame:SetSize(200, 100)
        Comm.popupFrame:SetPoint("CENTER")
        Comm.popupFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 24,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        })
        Comm.popupFrame:SetFrameStrata("DIALOG")
        Comm.popupFrame:EnableMouse(true)
        Comm.popupFrame:SetMovable(true)
        Comm.popupFrame:RegisterForDrag("LeftButton")
        Comm.popupFrame:SetScript("OnDragStart", Comm.popupFrame.StartMoving)
        Comm.popupFrame:SetScript("OnDragStop", Comm.popupFrame.StopMovingOrSizing)

        Comm.popupFrame.text = Comm.popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        Comm.popupFrame.text:SetPoint("TOP", 0, -20)

        Comm.popupFrame.button = CreateFrame("Button", nil, Comm.popupFrame, "UIPanelButtonTemplate")
        Comm.popupFrame.button:SetSize(80, 24)
        Comm.popupFrame.button:SetPoint("BOTTOM", 0, 15)

        Comm.popupFrame.closeButton = CreateFrame("Button", nil, Comm.popupFrame, "UIPanelCloseButton")
        Comm.popupFrame.closeButton:SetPoint("TOPRIGHT", Comm.popupFrame, "TOPRIGHT", -5, -5)
        Comm.popupFrame.closeButton:SetScript("OnClick", function() Comm.popupFrame:Hide() end)
    end
    Comm.popupFrame.text:SetText(sender.." sent a profile")
    Comm.popupFrame.button:SetText("Open")
    Comm.popupFrame.button:SetScript("OnClick", function()
        addonTable:OpenReceivedProfile(profileName, profileData)
        Comm.popupFrame:Hide()
    end)
    Comm.popupFrame:Show()
end

function Comm:PingPlayer(targetPlayer)
    if not targetPlayer then return end
    pendingPings[targetPlayer] = time()
    C_ChatInfo.SendAddonMessage(prefix, "PING", "WHISPER", targetPlayer)
    C_Timer.After(PING_TIMEOUT, function()
        if pendingPings[targetPlayer] and (time() - pendingPings[targetPlayer]) >= PING_TIMEOUT then
            pendingPings[targetPlayer] = nil
            knownAddonUsers[targetPlayer] = nil
        end
    end)
end

function Comm:SendPong(targetPlayer)
    C_ChatInfo.SendAddonMessage(prefix, "PONG", "WHISPER", targetPlayer)
end

function Comm:HandlePong(sender)
    pendingPings[sender] = nil
    knownAddonUsers[sender] = true
end

function Comm:GetKnownAddonUsers()
    return knownAddonUsers
end

function Comm:OnChatMsgAddon(prefixMsg, msg, channel, sender)
    if prefixMsg ~= prefix then return end
    local player = Ambiguate(sender, "short")

    if msg == "PING" then
        -- Sender definitely has the addon since they sent PING
        knownAddonUsers[player] = true
        Comm:SendPong(player)
        
    elseif msg == "PONG" then
        knownAddonUsers[player] = true
        Comm:HandlePong(player)
        
    elseif msg == "REQUEST_PROFILE" then
        -- If they request a profile, they have the addon
        knownAddonUsers[player] = true

        local currentProfile = addonTable.FleshWoundData.currentProfile
        Comm:SendProfileData(player, currentProfile)
        
    else
        local cmd, profileName, data = strsplit(":", msg, 3)
        if cmd == "PROFILE_DATA" then
            -- Receiving profile data means the sender has the addon
            knownAddonUsers[player] = true

            local profileData = Comm:DeserializeProfile(data)
            Comm:ShowIncomingProfilePopup(player, profileName, profileData)
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Comm:OnChatMsgAddon(...)
    end
end)
