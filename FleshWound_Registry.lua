local addonName, addonTable = ...
local Utils = addonTable.Utils
local L = addonTable.L or {}
local Registry = {}
addonTable.Registry = Registry

Registry.PREFIX = "FleshWoundRegistry"
Registry.EVENT_HELLO = "HELLO"
Registry.EVENT_QUERY = "QUERY"
Registry.users = {}
Registry.newVersionNotified = false
Registry.fetchingUsers = false
Registry.usersFetched = false
Registry.queryTicker = nil
Registry.fetchTimer = nil
Registry.CHANNEL_NAME = "FleshWoundComm"

--- Normalizes a player's name using Ambiguate in "short" mode.
-- @param name string The player's name.
-- @return string|nil The normalized name or nil if no name provided.
local function NormalizePlayerName(name)
    return name and Ambiguate(name, "short") or nil
end

--- Converts a given name to lowercase.
-- @param name string The player's name.
-- @return string|nil The lowercase version of the name or nil if no name provided.
local function ToLower(name)
    return name and string.lower(name) or nil
end

--- Compares two version strings.
-- Returns -1 if v1 is less than v2, 1 if greater, or 0 if equal.
-- @param v1 string First version string.
-- @param v2 string Second version string.
-- @return number Comparison result: -1, 0, or 1.
local function VersionCompare(v1, v2)
    --- Splits a version string into its numeric parts.
    -- @param v string Version string.
    -- @return table Array of numbers representing the version.
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

--- Retrieves the local addon's version.
-- @return string The local version string.
function Registry:GetLocalVersion()
    return Utils.GetAddonVersion()
end

--- Sends a HELLO message containing the local version.
-- @param target string (optional) The target player to respond to.
function Registry:SendHello(target)
    local version = self:GetLocalVersion()
    local msg = self.EVENT_HELLO .. ":" .. version
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        local channel = addonTable.Comm and addonTable.Comm:GetChannel()
        if channel then
            C_ChatInfo.SendAddonMessage(self.PREFIX, msg, "CHANNEL", channel, "ALERT")
        end
    else
        C_ChatInfo.SendAddonMessage(self.PREFIX, msg, "YELL", nil, "ALERT")
    end
end

--- Sends a QUERY message to request version information.
-- @param target string (optional) The target player for the query.
function Registry:SendQuery(target)
    local msg = self.EVENT_QUERY
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        local channel = addonTable.Comm and addonTable.Comm:GetChannel()
        if channel then
            C_ChatInfo.SendAddonMessage(self.PREFIX, msg, "CHANNEL", channel, "ALERT")
        end
    else
        C_ChatInfo.SendAddonMessage(self.PREFIX, msg, "YELL", nil, "ALERT")
    end
end

--- Handles incoming addon messages.
-- Processes both QUERY and HELLO messages from other users.
-- @param prefix string The addon message prefix.
-- @param msg string The message payload.
-- @param channel string The channel over which the message was received.
-- @param sender string The sender's name.
function Registry:OnChatMsgAddon(prefix, msg, channel, sender)
    if prefix ~= self.PREFIX then return end
    local player = NormalizePlayerName(sender)
    if not player then return end
    local event, payload = strsplit(":", msg, 2)
    
    if event == self.EVENT_QUERY then
        self:SendHello(player)
    elseif event == self.EVENT_HELLO then
        local remoteVersion = payload or "0.0.0"
        self.users[ToLower(player)] = { version = remoteVersion, lastSeen = time() }
        local localVersion = self:GetLocalVersion()
        if not self.newVersionNotified and VersionCompare(localVersion, remoteVersion) < 0 then
            self.newVersionNotified = true
            Utils.FW_Print(string.format(L.NEW_VERSION_AVAILABLE, remoteVersion, localVersion), true)
        end
        self:DisplayUserCount()
    end
end

--- Displays the count of online users.
-- Calculates the number of users in the registry and prints an appropriate message.
function Registry:DisplayUserCount()
    local total = 0
    for player, data in pairs(self.users) do
        total = total + 1
    end
    local count = total - 1
    if count == 1 then
        Utils.FW_Print(string.format(L.USERS_ONLINE_ONE), false)
    elseif count > 1 then
        Utils.FW_Print(string.format(L.USERS_ONLINE_OTHER, count), false)
    else
        Utils.FW_Print(string.format(L.USERS_ONLINE_NONE), false)
    end
end 

--- Initiates fetching of the user list from the designated channel.
-- Calls ListChannelByName to trigger the CHAT_MSG_CHANNEL_LIST event.
function Registry:FetchUsers()
    if self.usersFetched and not self.fetchingUsers then return end
    self.fetchingUsers = true
    if addonTable.Comm and addonTable.Comm:GetChannel() then
        ListChannelByName(self.CHANNEL_NAME)
    end
end

--- Callback for the CHAT_MSG_CHANNEL_LIST event.
-- Processes the comma-separated list of players from the channel and updates the registry.
local channelListFrame = CreateFrame("Frame")
channelListFrame:RegisterEvent("CHAT_MSG_CHANNEL_LIST")
channelListFrame:SetScript("OnEvent", function(_, event, ...)
    local playersIndex = 1
    local channelIndex = 9
    
    local players = select(playersIndex, ...)
    local channelName = select(channelIndex, ...)
    
    if channelName ~= Registry.CHANNEL_NAME then
        return
    end
    
    if not players or players == "" then
        return
    end
    
    for player in string.gmatch(players, "([^,]+)") do
        player = player:gsub("^%s*(.-)%s*$", "%1")
        local normPlayer = NormalizePlayerName(player)
        if normPlayer then
            local key = ToLower(normPlayer)
            Registry.users[key] = Registry.users[key] or {}
            Registry.users[key].lastSeen = time()
        end
    end
    
    Registry:DisplayUserCount()
end)

--- Filters CHAT_MSG_CHANNEL_LIST events.
-- Suppresses the default chat output for the designated channel.
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LIST", function(_, event, ...)
    local channelName = select(9, ...)
    if channelName == Registry.CHANNEL_NAME then
        return true
    end
    return false
end)

--- Initializes the registry module.
-- Registers the addon message prefix, sets up event handlers, fetches users,
-- and starts a periodic ticker to send HELLO messages.
function Registry:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(self.PREFIX)
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:SetScript("OnEvent", function(_, _, ...)
        Registry:OnChatMsgAddon(...)
    end)
    self:FetchUsers()
    C_Timer.NewTicker(300, function()
        self:SendHello()
    end)
end

return Registry
