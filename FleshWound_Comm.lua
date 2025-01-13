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

-- Register the prefix
function Comm:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(self.PREFIX)
end

--[[---------------------------------------------------------------------------
  Request another player's profile.
---------------------------------------------------------------------------]]--
function Comm:RequestProfile(targetPlayer)
    if not targetPlayer or targetPlayer == "" then
        Utils.FW_Print("Cannot request profile: no target specified.", true)
        return
    end

    if knownAddonUsers[targetPlayer] then
        C_ChatInfo.SendAddonMessage(self.PREFIX, "REQUEST_PROFILE", "WHISPER", targetPlayer)
        Utils.FW_Print("Sending profile request to " .. targetPlayer .. ".", false)
    else
        -- Ping first, wait, then try again
        self:PingPlayer(targetPlayer)
        C_Timer.After(self.PING_TIMEOUT + 1, function()
            if knownAddonUsers[targetPlayer] then
                C_ChatInfo.SendAddonMessage(self.PREFIX, "REQUEST_PROFILE", "WHISPER", targetPlayer)
                Utils.FW_Print("Sending profile request to " .. targetPlayer .. " after ping.", false)
            else
                Utils.FW_Print("No ping response from " .. targetPlayer .. "; cannot request profile.", true)
            end
        end)
    end
end

--[[---------------------------------------------------------------------------
  Send our profile data to a remote target.
---------------------------------------------------------------------------]]--
function Comm:SendProfileData(targetPlayer, profileName)
    if not targetPlayer or not profileName then return end

    local data = addonTable.FleshWoundData.profiles[profileName]
    if not data then return end

    local serialized = self:SerializeProfile(data)
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PROFILE_DATA:"..profileName..":"..serialized, "WHISPER", targetPlayer)
    Utils.FW_Print("Sending profile data '"..profileName.."' to " .. targetPlayer .. ".", false)
end

--[[---------------------------------------------------------------------------
  Serialize the woundData sub-table of a profile using AceSerializer.
---------------------------------------------------------------------------]]--
function Comm:SerializeProfile(profileData)
    local woundData = profileData.woundData or {}
    local serialized = AceSerializer:Serialize(woundData)
    return serialized
end

--[[---------------------------------------------------------------------------
  Deserialize a profile's woundData.
---------------------------------------------------------------------------]]--
function Comm:DeserializeProfile(serialized)
    local profileData = { woundData = {} }
    if serialized == "" then
        Utils.FW_Print("DeserializeProfile: Empty data, returning empty profile.", true)
        return profileData
    end

    local success, woundData = AceSerializer:Deserialize(serialized)
    if success and type(woundData) == "table" then
        profileData.woundData = woundData
    else
        Utils.FW_Print("Failed to deserialize or invalid data type.", true)
    end

    return profileData
end

--[[---------------------------------------------------------------------------
  Ping a player to see if they have the addon. If no reply in PING_TIMEOUT,
  we assume they don’t.
---------------------------------------------------------------------------]]--
function Comm:PingPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == "" then return end

    pendingPings[targetPlayer] = time()
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PING", "WHISPER", targetPlayer)

    C_Timer.After(self.PING_TIMEOUT, function()
        if pendingPings[targetPlayer] and (time() - pendingPings[targetPlayer]) >= self.PING_TIMEOUT then
            pendingPings[targetPlayer] = nil
            knownAddonUsers[targetPlayer] = nil
            Utils.FW_Print("Ping to " .. targetPlayer .. " timed out.", false)
        end
    end)
end

--[[---------------------------------------------------------------------------
  Send a PONG response back.
---------------------------------------------------------------------------]]--
function Comm:SendPong(targetPlayer)
    C_ChatInfo.SendAddonMessage(self.PREFIX, "PONG", "WHISPER", targetPlayer)
end

--[[---------------------------------------------------------------------------
  Handle a PONG. Mark them as known.
---------------------------------------------------------------------------]]--
function Comm:HandlePong(sender)
    pendingPings[sender] = nil
    knownAddonUsers[sender] = true
    Utils.FW_Print("Received PONG from " .. sender .. ".", false)
end

--[[---------------------------------------------------------------------------
  Return known users. 
---------------------------------------------------------------------------]]--
function Comm:GetKnownAddonUsers()
    return knownAddonUsers
end

--[[---------------------------------------------------------------------------
  Handle all incoming CHAT_MSG_ADDON events with our prefix.
---------------------------------------------------------------------------]]--
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

-- Event frame to catch CHAT_MSG_ADDON
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Comm:OnChatMsgAddon(...)
    end
end)
