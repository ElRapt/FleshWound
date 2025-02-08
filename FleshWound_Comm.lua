local addonName, addonTable = ...
local Comm = {}
addonTable.Comm = Comm

-- Constants
Comm.PREFIX = "FleshWoundComm"
Comm.PING_TIMEOUT = 5
local AceSerializer = LibStub("AceSerializer-3.0")
local CHANNEL_NAME = "FleshWoundComm"

-- Internal state tables
local knownAddonUsers = {}   -- Tracks players known to have the addon
local pendingPings = {}      -- Records ping start times for players
local channelJoinedOnce = false

--------------------------------------------------------------------------------
-- Profile Request and Handling
--------------------------------------------------------------------------------

--- Requests a profile from the specified target player.
-- If the player is known to have the addon, immediately sends a profile request.
-- Otherwise, pings the player and retries after the ping timeout.
-- @param targetPlayer string The name of the target player.
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

--- Sends the profile data for a given profile name to a target player.
-- Retrieves the profile from FleshWoundData, serializes it, and sends it.
-- @param targetPlayer string The name of the target player.
-- @param profileName string The name of the profile to send.
function Comm:SendProfileData(targetPlayer, profileName)
    if not targetPlayer or not profileName then return end
    local data = addonTable.FleshWoundData.profiles[profileName]
    if not data then return end
    local serialized = self:SerializeProfile(data)
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PROFILE_DATA:" .. profileName .. ":" .. serialized, "WHISPER", targetPlayer)
end

--- Serializes a profile's wound data.
-- @param profileData table The profile data table.
-- @return string The serialized wound data.
function Comm:SerializeProfile(profileData)
    local woundData = profileData.woundData or {}
    return AceSerializer:Serialize(woundData)
end

--- Deserializes profile data from a serialized string.
-- @param serialized string The serialized wound data.
-- @return table A table containing a field 'woundData' with the deserialized data.
function Comm:DeserializeProfile(serialized)
    local profileData = { woundData = {} }
    if serialized == "" then return profileData end
    local success, woundData = AceSerializer:Deserialize(serialized)
    if success and type(woundData) == "table" then
        profileData.woundData = woundData
    end
    return profileData
end

--------------------------------------------------------------------------------
-- Ping/Pong Functions
--------------------------------------------------------------------------------

--- Pings a target player to determine if they have the addon.
-- Records the ping time and sends a "PING" message.
-- @param targetPlayer string The name of the target player.
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

--- Sends a "PONG" message in response to a ping.
-- @param targetPlayer string The name of the target player.
function Comm:SendPong(targetPlayer)
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PONG", "WHISPER", targetPlayer)
end

--- Handles receipt of a "PONG" message.
-- Clears any pending ping for the sender and marks them as a known addon user.
-- @param sender string The name of the sender.
function Comm:HandlePong(sender)
    pendingPings[sender] = nil
    knownAddonUsers[sender] = true
end

--- Retrieves the table of known addon users.
-- @return table A table mapping player names to true.
function Comm:GetKnownAddonUsers()
    return knownAddonUsers
end

--------------------------------------------------------------------------------
-- Addon Message Handling
--------------------------------------------------------------------------------

--- Processes incoming addon messages.
-- Handles "PING", "PONG", "REQUEST_PROFILE", and "PROFILE_DATA" commands.
-- @param prefixMsg string The message prefix.
-- @param msg string The content of the message.
-- @param channel string The channel over which the message was received.
-- @param sender string The name of the sender.
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

--------------------------------------------------------------------------------
-- Channel Management
--------------------------------------------------------------------------------

--- Initializes the Comm module.
-- Registers the addon message prefix and begins the process of joining the channel.
function Comm:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(self.PREFIX)
    self:JoinChannel()
end

--- Retrieves the channel ID for the communication channel.
-- @return number|nil The channel ID, or nil if the channel is not found.
function Comm:GetChannel()
    local channelId = GetChannelName(CHANNEL_NAME)
    if channelId ~= 0 then
        return channelId
    else
        return nil
    end
end

--- Called when the channel is successfully joined.
-- Initializes the Registry module on the first successful join.
function Comm:OnChannelJoined()
    if not channelJoinedOnce then
        channelJoinedOnce = true
        if addonTable.Registry and addonTable.Registry.Initialize then
            addonTable.Registry:Initialize()
        end
    end
end

--- Called when joining the channel fails.
-- Retries joining the channel after a 10-second delay.
-- @param reason string The reason for the failure.
function Comm:OnChannelFailed(reason)
    C_Timer.After(10, function() self:JoinChannel() end)
end

--- Called when the channel is left.
-- Attempts to rejoin the channel after a 1-second delay.
function Comm:OnChannelLeft()
    C_Timer.After(1, function() self:JoinChannel() end)
end

--- Attempts to join the communication channel.
-- If already joined, triggers OnChannelJoined; otherwise, periodically attempts to join.
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

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

-- Create a frame to handle CHAT_MSG_CHANNEL_NOTICE events.
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

-- Create a frame to handle CHAT_MSG_ADDON events.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Comm:OnChatMsgAddon(...)
    end
end)

return Comm
