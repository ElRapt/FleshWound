local addonName, addonTable = ...
local Comm = {}
addonTable.Comm = Comm
Comm.PREFIX = "FW"
Comm.REQUEST_TIMEOUT = 5
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate", true)
local CHANNEL_NAME = "FleshWoundComm"
local channelJoinedOnce = false

--------------------------------------------------------------------------------
-- Profile Request and Handling
--------------------------------------------------------------------------------

--- Requests a profile from the specified target player.
-- If the target player is online, sends a "REQUEST_PROFILE" message.
-- If the target player is not detected as online, sends a query and retries after a timeout.
-- @param targetPlayer string The name of the target player.
function Comm:RequestProfile(targetPlayer)
    if not targetPlayer or targetPlayer == "" then return end
    local registry = addonTable.Registry
    if registry and registry:IsUserOnline(targetPlayer) then
        ChatThrottleLib:SendAddonMessage("NORMAL", self.PREFIX, "REQUEST_PROFILE", "WHISPER", targetPlayer)
    else
        if registry then
            registry:SendQuery()
        end
        C_Timer.After(self.REQUEST_TIMEOUT, function()
            if registry and registry:IsUserOnline(targetPlayer) then
                ChatThrottleLib:SendAddonMessage("NORMAL", self.PREFIX, "REQUEST_PROFILE", "WHISPER", targetPlayer)
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
    local encoded = serialized
    local compressed = false

    if #serialized > 255 and LibDeflate then
        encoded = LibDeflate:CompressDeflate(serialized)
        encoded = LibDeflate:EncodeForWoWAddonChannel(encoded)
        compressed = true
    end

    local cmd = compressed and "PROFILE_DATA_COMPRESSED" or "PROFILE_DATA"
    local message = string.format("%s:%s:%s", cmd, profileName, encoded)

    if #message <= 255 then
        ChatThrottleLib:SendAddonMessage("NORMAL", self.PREFIX, message, "WHISPER", targetPlayer)
        return
    end

    local partCmd = cmd .. "_PART"
    local chunkSize = 200
    local totalParts = math.ceil(#encoded / chunkSize)
    for i = 1, totalParts do
        local chunk = encoded:sub((i - 1) * chunkSize + 1, i * chunkSize)
        local partMsg = string.format("%s:%s:%d:%d:%s", partCmd, profileName, totalParts, i, chunk)
        ChatThrottleLib:SendAddonMessage("NORMAL", self.PREFIX, partMsg, "WHISPER", targetPlayer)
    end
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
function Comm:DeserializeProfile(cmd, profileName, payload, sender)
    self.partialMessages = self.partialMessages or {}
    local profileData = { woundData = {} }
    local libdeflate = LibStub("LibDeflate", true)

    if cmd == "PROFILE_DATA" or cmd == "PROFILE_DATA_COMPRESSED" then
        local data = payload or ""
        if cmd == "PROFILE_DATA_COMPRESSED" and libdeflate then
            data = libdeflate:DecodeForWoWAddonChannel(data)
            data = data and libdeflate:DecompressDeflate(data)
            if not data then
                addonTable.Utils.FW_Print("Failed to decompress profile from " .. (sender or "unknown"), true)
                return profileData
            end
        end
        if data ~= "" then
            local success, woundData = AceSerializer:Deserialize(data)
            if success and type(woundData) == "table" then
                profileData.woundData = woundData
            end
        end
        return profileData
    elseif cmd == "PROFILE_DATA_PART" or cmd == "PROFILE_DATA_COMPRESSED_PART" then
        local totalParts, index, part = payload.total, payload.index, payload.data
        if not (totalParts and index and part) then return nil end
        local key = (sender or "?") .. ":" .. profileName
        local entry = self.partialMessages[key]
        if not entry then
            entry = {total = totalParts, parts = {}, isCompressed = (cmd == "PROFILE_DATA_COMPRESSED_PART"), start = GetTime()}
            self.partialMessages[key] = entry
        end
        if totalParts ~= entry.total then
            addonTable.Utils.FW_Print("Profile transfer mismatch from " .. (sender or "unknown"), true)
            self.partialMessages[key] = nil
            return nil
        end
        entry.parts[index] = part

        if GetTime() - entry.start > 30 then
            addonTable.Utils.FW_Print("Profile transfer from " .. (sender or "unknown") .. " timed out", true)
            self.partialMessages[key] = nil
            return nil
        end

        local received = 0
        for i = 1, entry.total do
            if entry.parts[i] then
                received = received + 1
            end
        end

        if received == entry.total then
            local combined = table.concat(entry.parts)
            self.partialMessages[key] = nil
            return self:DeserializeProfile(entry.isCompressed and "PROFILE_DATA_COMPRESSED" or "PROFILE_DATA", profileName, combined, sender)
        end
        return nil
    end

    return profileData
end


--------------------------------------------------------------------------------
-- Addon Message Handling
--------------------------------------------------------------------------------

--- Processes incoming addon messages for "REQUEST_PROFILE" and "PROFILE_DATA" commands.
-- @param prefixMsg string The message prefix.
-- @param msg string The content of the message.
-- @param channel string The channel over which the message was received.
-- @param sender string The name of the sender.
function Comm:OnChatMsgAddon(prefixMsg, msg, channel, sender)
    if prefixMsg ~= self.PREFIX then return end
    if msg == "REQUEST_PROFILE" then
        local currentProfile = addonTable.FleshWoundData.currentProfile
        self:SendProfileData(sender, currentProfile)
    else
        local cmd, profileName, rest = strsplit(":", msg, 3)
        if cmd == "PROFILE_DATA" or cmd == "PROFILE_DATA_COMPRESSED" then
            local profileData = self:DeserializeProfile(cmd, profileName, rest, sender)
            addonTable:OpenReceivedProfile(profileName, profileData)
        elseif cmd == "PROFILE_DATA_PART" or cmd == "PROFILE_DATA_COMPRESSED_PART" then
            local total, index, part = strsplit(":", rest, 3)
            local profileData = self:DeserializeProfile(cmd, profileName, {total = tonumber(total), index = tonumber(index), data = part}, sender)
            if profileData then
                addonTable:OpenReceivedProfile(profileName, profileData)
            end
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
