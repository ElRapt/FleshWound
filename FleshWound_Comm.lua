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
    if knownAddonUsers[targetPlayer] then
        C_ChatInfo.SendAddonMessage(prefix, "REQUEST_PROFILE", "WHISPER", targetPlayer)
    else
        -- Ping and wait for response, then request profile after handshake
        self:PingPlayer(targetPlayer)
        C_Timer.After(PING_TIMEOUT + 1, function()
            if knownAddonUsers[targetPlayer] then
                C_ChatInfo.SendAddonMessage(prefix, "REQUEST_PROFILE", "WHISPER", targetPlayer)
            else
                print(targetPlayer.." did not respond. Cannot request profile.")
            end
        end)
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

    return profileData
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
        self:SendPong(player)
    elseif msg == "PONG" then
        self:HandlePong(player)
    elseif msg == "REQUEST_PROFILE" then
        if knownAddonUsers[player] then
            local currentProfile = addonTable.FleshWoundData.currentProfile
            self:SendProfileData(player, currentProfile)
        else
            -- If not known yet, we can't send. But normally we set knownAddonUsers on receiving addon messages.
            knownAddonUsers[player] = true
            local currentProfile = addonTable.FleshWoundData.currentProfile
            self:SendProfileData(player, currentProfile)
        end
    else
        local cmd, profileName, data = strsplit(":", msg, 3)
        if cmd == "PROFILE_DATA" then
            -- Mark them as known addon user
            knownAddonUsers[player] = true
            
            local profileData = Comm:DeserializeProfile(data)
            -- Directly open the received profile, no popup with a button
            addonTable:OpenReceivedProfile(profileName, profileData)
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
