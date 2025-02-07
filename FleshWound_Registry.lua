-- FleshWound_Registry.lua
-- This module handles version exchange and tracking of other users of FleshWound.
-- It detects when a remote user’s version is higher than your local version
-- and notifies you. It also maintains a registry of users with their version info,
-- allowing you to display the count of online users with the addon.

local addonName, addonTable = ...
local Utils = addonTable.Utils  
local L = addonTable.L or {}

local Registry = {}
addonTable.Registry = Registry

-- Define our addon message prefix and event strings
Registry.PREFIX = "FleshWoundRegistry"
Registry.EVENT_HELLO = "HELLO"   -- sent to announce our version
Registry.EVENT_QUERY = "QUERY"   -- request version info

-- Table to hold info on users (key: normalized player name; value: {version, lastSeen})
Registry.users = {}

-- Flag to prevent multiple notifications for a new version
Registry.newVersionNotified = false

---------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------

-- Normalizes player names using Ambiguate so that "Player-Realm" format is consistent
local function NormalizePlayerName(name)
    return name and Ambiguate(name, "short") or nil
end

-- Simple version comparison function.
-- Splits version strings (e.g. "0.2.2") into numeric parts and compares them.
local function VersionCompare(v1, v2)
    local function splitVersion(v)
        local parts = {}
        for num in string.gmatch(v, "%d+") do
            table.insert(parts, tonumber(num))
        end
        return parts
    end

    local t1 = splitVersion(v1)
    local t2 = splitVersion(v2)
    local maxLen = math.max(#t1, #t2)
    for i = 1, maxLen do
        local n1 = t1[i] or 0
        local n2 = t2[i] or 0
        if n1 < n2 then
            return -1
        elseif n1 > n2 then
            return 1
        end
    end
    return 0
end

--- Retrieves the local addon version from metadata or a default version.
--- @return string: The local version of the addon.
function Registry:GetLocalVersion()
    return Utils.GetAddonVersion()
end
---------------------------------------------------------------
-- Messaging Functions
---------------------------------------------------------------

--- Sends a HELLO message containing the local version to announce the addon's presence.
--- If a target is provided, the message is sent as a whisper.
--- @param target string|nil: Optional target player to receive the hello message.
function Registry:SendHello(target)
    local version = self:GetLocalVersion()
    local msg = self.EVENT_HELLO .. ":" .. version
    local distribution = target and "WHISPER" or "GUILD"  -- adjust as needed for your use-case
    C_ChatInfo.SendAddonMessage(self.PREFIX, msg, distribution, target)
end

--- Processes incoming addon messages for the registry.
--- Handles QUERY messages by replying with a HELLO and processes HELLO messages to update version info and notify of newer versions.
--- @param prefix string: The message prefix.
--- @param msg string: The incoming message content.
--- @param channel string: The channel the message was received on.
--- @param sender string: The sender's name.
function Registry:SendQuery(target)
    local msg = self.EVENT_QUERY
    local distribution = target and "WHISPER" or "GUILD"
    C_ChatInfo.SendAddonMessage(self.PREFIX, msg, distribution, target)
end

---------------------------------------------------------------
-- Message Handling
---------------------------------------------------------------

--- Processes incoming addon messages for the registry.
--- Handles QUERY messages by replying with a HELLO and processes HELLO messages to update version info and notify of newer versions.
--- @param prefix string: The message prefix.
--- @param msg string: The incoming message content.
--- @param channel string: The channel the message was received on.
--- @param sender string: The sender's name.
function Registry:OnChatMsgAddon(prefix, msg, channel, sender)
    if prefix ~= self.PREFIX then
        return
    end

    local player = NormalizePlayerName(sender)
    if not player then return end

    -- Split the message into an event and optional payload
    local event, payload = strsplit(":", msg, 2)
    if event == self.EVENT_QUERY then
        -- When a QUERY is received, immediately reply with our HELLO.
        self:SendHello(player)
    elseif event == self.EVENT_HELLO then
        -- A HELLO message was received; payload should be the version.
        local remoteVersion = payload or "0.0.0"
        -- Record or update this player's info
        self.users[player] = { version = remoteVersion, lastSeen = time() }

        -- Compare remote version with our local version
        local localVersion = self:GetLocalVersion()
        if not self.newVersionNotified and VersionCompare(localVersion, remoteVersion) < 0 then
            self.newVersionNotified = true
            Utils.FW_Print(string.format(L.NEW_VERSION_AVAILABLE, remoteVersion, localVersion), true)
            -- Optionally, you could play a sound or display a popup here.
        end

        -- After processing, update the displayed user count.
        self:DisplayUserCount()
    end
end

--- Calculates and displays the number of online users (excluding the local player) who have the addon installed.
function Registry:DisplayUserCount()
    local count = 0
    local localPlayer = NormalizePlayerName(UnitName("player"))
    for player, info in pairs(self.users) do
        if player ~= localPlayer then
            count = count + 1
        end
    end
    if count > 0 then
        Utils.FW_Print(string.format(L.USERS_ONLINE_OTHER, count), false)
    else
        Utils.FW_Print(L.USERS_ONLINE_NONE, false)
    end
end

--- Initializes the registry module.
--- Registers the addon message prefix, sets up the event listener for CHAT_MSG_ADDON,
--- sends an initial version query, and schedules periodic version announcements.
function Registry:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(self.PREFIX)

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:SetScript("OnEvent", function(selfFrame, event, ...)
        Registry:OnChatMsgAddon(...)
    end)

    C_Timer.After(2, function() Registry:SendQuery() end)

    C_Timer.NewTicker(300, function() Registry:SendHello() end)

    Registry:DisplayUserCount()
end

---------------------------------------------------------------
-- Return the module
---------------------------------------------------------------

return Registry
