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

local function NormalizePlayerName(name)
	return name and Ambiguate(name, "short") or nil
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
		local channel = addonTable.Comm and addonTable.Comm:GetChannel() and addonTable.Comm:GetChannel()
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
		local channel = addonTable.Comm and addonTable.Comm.GetChannel and addonTable.Comm:GetChannel()
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
		self.users[player] = { version = remoteVersion, lastSeen = time() }
		local localVersion = self:GetLocalVersion()
		if not self.newVersionNotified and VersionCompare(localVersion, remoteVersion) < 0 then
			self.newVersionNotified = true
			Utils.FW_Print(string.format(L.NEW_VERSION_AVAILABLE, remoteVersion, localVersion), true)
		end
		if self.fetchingUsers then
			if self.fetchTimer then
				self.fetchTimer:Cancel()
				self.fetchTimer = nil
			end
			self.fetchTimer = C_Timer.NewTimer(FETCH_USERS_END_TIMEOUT, function()
				self.usersFetched = true
				self.fetchingUsers = false
				if self.queryTicker then
					self.queryTicker:Cancel()
					self.queryTicker = nil
				end
				self:DisplayUserCount()
				if self.onRegistryReady then
					self.onRegistryReady()
				end
			end)
		else
			self:DisplayUserCount()
		end
	end
end

function Registry:DisplayUserCount()
	local count = 0
	local localPlayer = NormalizePlayerName(UnitName("player"))
	for player, _ in pairs(self.users) do
		if player ~= localPlayer then count = count + 1 end
	end
	if count > 0 then
		Utils.FW_Print(string.format(L.USERS_ONLINE_OTHER, count), false)
	else
		Utils.FW_Print(L.USERS_ONLINE_NONE, false)
	end
end

function Registry:FetchUsers()
	if self.usersFetched and not self.fetchingUsers then return end
	self.fetchingUsers = true
	self:SendQuery()
	self.queryTicker = C_Timer.NewTicker(FETCH_USERS_RETRY_RATE, function()
		self:SendQuery()
	end)
end

function Registry:Initialize()
	C_ChatInfo.RegisterAddonMessagePrefix(self.PREFIX)
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("CHAT_MSG_ADDON")
	eventFrame:SetScript("OnEvent", function(_, event, ...)
		Registry:OnChatMsgAddon(...)
	end)
	C_Timer.After(2, function() Registry:SendQuery() end)
	C_Timer.NewTicker(300, function() Registry:SendHello() end)
	self:FetchUsers()
end

return Registry
