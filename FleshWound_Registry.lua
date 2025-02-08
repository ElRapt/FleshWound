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
local FETCH_USERS_RETRY_RATE = 1
local FETCH_USERS_END_TIMEOUT = 2
Registry.fetchingUsers = false
Registry.usersFetched = false
Registry.queryTicker = nil
Registry.fetchTimer = nil
Registry.CHANNEL_NAME = "FleshWoundComm"

local function NormalizePlayerName(name)
    return name and Ambiguate(name, "short") or nil
end

local function ToLower(name)
    return name and string.lower(name) or nil
end

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

function Registry:GetLocalVersion()
    return Utils.GetAddonVersion()
end

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

function Registry:DisplayUserCount()
    local total = 0
    for player, data in pairs(self.users) do
        total = total + 1
    end
    count = total - 1
    if count == 1 then
        Utils.FW_Print(string.format(L.USERS_ONLINE_ONE), false)
    elseif count > 1 then
        Utils.FW_Print(string.format(L.USERS_ONLINE_OTHER, count), false)
    else
        Utils.FW_Print(string.format(L.USERS_ONLINE_NONE), false)
    end
end 

function Registry:FetchUsers()
    if self.usersFetched and not self.fetchingUsers then return end
    self.fetchingUsers = true
    if addonTable.Comm and addonTable.Comm:GetChannel() then
        ListChannelByName(self.CHANNEL_NAME)
    end
end

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
