-- FleshWound_Comm.lua
-- Handles addon message-based communication (pings, profile requests, profile data).
-- Centralizes the prefix & ping timeout so all references are consistent.

local addonName, addonTable = ...
local Utils = addonTable.Utils  -- for Utils.FW_Print

local Comm = {}
addonTable.Comm = Comm

-- Centralize constants here:
Comm.PREFIX = "FleshWoundComm"
Comm.PING_TIMEOUT = 5

-- Load AceSerializer
local AceSerializer = LibStub("AceSerializer-3.0")

-- Table tracking known users who responded with PONG
local knownAddonUsers = {}
-- Tracks pings that haven’t been answered
local pendingPings = {}



--- Requests a profile from the specified target player.
--- If the player is already known (has responded to a previous ping), the request is sent immediately.
--- Otherwise, the player is pinged and, after a timeout, the profile request is resent if a response is received.
--- @param targetPlayer string: The name (or name-realm) of the target player.
function Comm:RequestProfile(targetPlayer)
    if not targetPlayer or targetPlayer == "" then
        return
    end

    if knownAddonUsers[targetPlayer] then
        C_ChatInfo.SendAddonMessage(self.PREFIX, "REQUEST_PROFILE", "WHISPER", targetPlayer)
    else
        -- Ping first, wait, then try again
        self:PingPlayer(targetPlayer)
        C_Timer.After(self.PING_TIMEOUT + 1, function()
            if knownAddonUsers[targetPlayer] then
                C_ChatInfo.SendAddonMessage(self.PREFIX, "REQUEST_PROFILE", "WHISPER", targetPlayer)
            end
        end)
    end
end

--- Sends the serialized profile data associated with profileName to the target player via an addon message.
--- @param targetPlayer string: The recipient player.
--- @param profileName string: The name of the profile whose data is to be sent.
function Comm:SendProfileData(targetPlayer, profileName)
    if not targetPlayer or not profileName then return end

    local data = addonTable.FleshWoundData.profiles[profileName]
    if not data then return end

    local serialized = self:SerializeProfile(data)
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PROFILE_DATA:"..profileName..":"..serialized, "WHISPER", targetPlayer)
end

--- Serializes the woundData sub-table from the provided profileData using AceSerializer.
--- @param profileData table: The profile data containing woundData.
--- @return string: The serialized woundData string.
function Comm:SerializeProfile(profileData)
    local woundData = profileData.woundData or {}
    local serialized = AceSerializer:Serialize(woundData)
    return serialized
end

--- Deserializes the provided serialized woundData string using AceSerializer and returns a table with the woundData.
--- @param serialized string: The serialized data string.
--- @return table: A table containing the deserialized woundData.
function Comm:DeserializeProfile(serialized)
    local profileData = { woundData = {} }
    if serialized == "" then
        return profileData
    end

    local success, woundData = AceSerializer:Deserialize(serialized)
    if success and type(woundData) == "table" then
        profileData.woundData = woundData

    end

    return profileData
end

--- Sends a ping message to the specified target player to check if they have the addon installed.
--- Sets a timeout after which the pending ping is cleared if no pong is received.
--- @param targetPlayer string: The name (or name-realm) of the target player.
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

--- Sends a pong response to the specified target player to indicate that this player has the addon.
--- @param targetPlayer string: The recipient player.
function Comm:SendPong(targetPlayer)
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PONG", "WHISPER", targetPlayer)
end

--- Processes a pong response by clearing any pending ping for the sender and marking the sender as a known addon user.
--- @param sender string: The name of the player who sent the pong.
function Comm:HandlePong(sender)
    pendingPings[sender] = nil
    knownAddonUsers[sender] = true
end

--- Returns the table of players who are known to have the addon (i.e. who have responded to a ping).
--- @return table: A table where keys are player names and values indicate addon presence.
function Comm:GetKnownAddonUsers()
    return knownAddonUsers
end

--- Handles incoming addon messages that match the registered prefix.
--- Dispatches actions based on the message content (e.g., PING, PONG, REQUEST_PROFILE, PROFILE_DATA).
--- @param prefixMsg string: The prefix of the incoming message.
--- @param msg string: The message content.
--- @param channel string: The channel the message was received on.
--- @param sender string: The player who sent the message.
function Comm:OnChatMsgAddon(prefixMsg, msg, channel, sender)
    if prefixMsg ~= self.PREFIX then return end
    local player = Ambiguate(sender, "short")

    if msg == "PING" then
        self:SendPong(player)
    elseif msg == "PONG" then
        self:HandlePong(player)
    elseif msg == "REQUEST_PROFILE" then
        knownAddonUsers[player] = true  -- Mark them known
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

--- Registers the addon message prefix with C_ChatInfo.RegisterAddonMessagePrefix so that all subsequent addon messages use a consistent prefix.
function Comm:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(self.PREFIX)
end

-- Event frame to catch CHAT_MSG_ADDON
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Comm:OnChatMsgAddon(...)
    end
end)
