local addonName, addonTable = ...
local Utils = addonTable.Utils
local Comm = {}
addonTable.Comm = Comm
Comm.PREFIX = "FleshWoundComm"
Comm.PING_TIMEOUT = 5
local AceSerializer = LibStub("AceSerializer-3.0")
local knownAddonUsers = {}
local pendingPings = {}
local channelJoinedOnce = false

function Comm:RequestProfile(targetPlayer)
    if not targetPlayer or targetPlayer == "" then return end
    if knownAddonUsers[targetPlayer] then
        C_ChatInfo.SendAddonMessage(self.PREFIX, "REQUEST_PROFILE", "WHISPER", targetPlayer)
    else
        self:PingPlayer(targetPlayer)
        C_Timer.After(self.PING_TIMEOUT + 1, function()
            if knownAddonUsers[targetPlayer] then
                C_ChatInfo.SendAddonMessage(self.PREFIX, "REQUEST_PROFILE", "WHISPER", targetPlayer)
            end
        end)
    end
end

function Comm:SendProfileData(targetPlayer, profileName)
    if not targetPlayer or not profileName then return end
    local data = addonTable.FleshWoundData.profiles[profileName]
    if not data then return end
    local serialized = self:SerializeProfile(data)
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PROFILE_DATA:" .. profileName .. ":" .. serialized, "WHISPER", targetPlayer)
end

function Comm:SerializeProfile(profileData)
    local woundData = profileData.woundData or {}
    local serialized = AceSerializer:Serialize(woundData)
    return serialized
end

function Comm:DeserializeProfile(serialized)
    local profileData = { woundData = {} }
    if serialized == "" then return profileData end
    local success, woundData = AceSerializer:Deserialize(serialized)
    if success and type(woundData) == "table" then
        profileData.woundData = woundData
    end
    return profileData
end

function Comm:PingPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == "" then return end
    pendingPings[targetPlayer] = time()
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PING", "WHISPER", targetPlayer)
    C_Timer.After(self.PING_TIMEOUT, function()
        if pendingPings[targetPlayer] and (time() - pendingPings[targetPlayer]) >= self.PING_TIMEOUT then
            pendingPings[targetPlayer] = nil
            knownAddonUsers[targetPlayer] = nil
        end
    end)
end

function Comm:SendPong(targetPlayer)
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PONG", "WHISPER", targetPlayer)
end

function Comm:HandlePong(sender)
    pendingPings[sender] = nil
    knownAddonUsers[sender] = true
end

function Comm:GetKnownAddonUsers()
    return knownAddonUsers
end

function Comm:OnChatMsgAddon(prefixMsg, msg, channel, sender)
    if prefixMsg ~= self.PREFIX then return end
    local player = Ambiguate(sender, "short")
    if msg == "PING" then
        self:SendPong(player)
    elseif msg == "PONG" then
        self:HandlePong(player)
    elseif msg == "REQUEST_PROFILE" then
        knownAddonUsers[player] = true
        local currentProfile = addonTable.FleshWoundData.currentProfile
        self:SendProfileData(player, currentProfile)
    else
        local cmd, profileName, data = strsplit(":", msg, 3)
        if cmd == "PROFILE_DATA" then
            knownAddonUsers[player] = true
            local profileData = self:DeserializeProfile(data)
            addonTable:OpenReceivedProfile(profileName, profileData)
        end
    end
end

function Comm:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(self.PREFIX)
    self:JoinChannel()
end

function Comm:GetChannel()
    local channelId = GetChannelName("FleshWoundComm")
    if channelId ~= 0 then
        return channelId
    else
        return nil
    end
end

Comm.channelJoiner = nil
local CHANNEL_NAME = "FleshWoundComm"

function Comm:OnChannelJoined()
    if not channelJoinedOnce then
        channelJoinedOnce = true
        if addonTable.Registry and addonTable.Registry.Initialize then
            addonTable.Registry:Initialize()
        end
    end
end

function Comm:OnChannelFailed(reason)
    C_Timer.After(10, function() self:JoinChannel() end)
end

function Comm:OnChannelLeft()
    C_Timer.After(1, function() self:JoinChannel() end)
end

local channelNoticeFrame = CreateFrame("Frame")
channelNoticeFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
channelNoticeFrame:SetScript("OnEvent", function(self, event, ...)
    local text, _, _, _, _, _, _, _, channelName = ...
    if channelName == CHANNEL_NAME then
        if text == "YOU_JOINED" or text == "YOU_CHANGED" then
            Comm:OnChannelJoined()
        elseif text == "WRONG_PASSWORD" or text == "BANNED" then
            Comm:OnChannelFailed(text)
        elseif text == "YOU_LEFT" then
            Comm:OnChannelLeft()
        end
    end
end)

function Comm:JoinChannel()
    if self.channelJoiner then return end
    if self:GetChannel() then
        self:OnChannelJoined()
        return
    end
    self.channelJoiner = C_Timer.NewTicker(1, function()
        if self:GetChannel() then
            if self.channelJoiner then
                self.channelJoiner:Cancel()
                self.channelJoiner = nil
            end
            self:OnChannelJoined()
        else
            JoinTemporaryChannel(CHANNEL_NAME, nil)
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Comm:OnChatMsgAddon(...)
    end
end)

return Comm
