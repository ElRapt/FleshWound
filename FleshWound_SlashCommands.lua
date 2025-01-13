-- FleshWound_SlashCommands.lua
-- Adds slash commands for toggling the main FleshWound UI, pinging, requesting profiles, etc.

local addonName, addonTable = ...
local Comm = addonTable.Comm
local Utils = addonTable.Utils

--[[---------------------------------------------------------------------------
  /fw toggles the main UI.
---------------------------------------------------------------------------]]--
SlashCmdList.FW = function(msg)
    local GUI = addonTable.GUI
    if not GUI or not GUI.frame then
        Utils.FW_Print("The main FleshWound frame is not initialized yet.", true)
        return
    end

    local frame = GUI.frame
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
SLASH_FW1 = "/fw"

--[[---------------------------------------------------------------------------
  /fwping <player-realm> tries a ping to see if that player has the addon.
---------------------------------------------------------------------------]]--
SlashCmdList.FWPING = function(msg)
    local targetPlayer = strtrim(msg or "")
    if targetPlayer == "" then
        Utils.FW_Print("Usage: /fwping PlayerName-Realm", true)
        return
    end

    Utils.FW_Print("Pinging " .. targetPlayer .. "...", false)
    Comm:PingPlayer(targetPlayer)

    -- After Comm.PING_TIMEOUT+1, see if player responded
    C_Timer.After(Comm.PING_TIMEOUT + 1, function()
        local known = Comm:GetKnownAddonUsers()
        if known and known[targetPlayer] then
            Utils.FW_Print(targetPlayer.." responded (has FleshWound).", false)
        else
            Utils.FW_Print(targetPlayer.." did not respond; might not have the addon.", false)
        end
    end)
end
SLASH_FWPING1 = "/fwping"

--[[---------------------------------------------------------------------------
  /fwprofile <player-realm> requests that player's profile if they have the addon.
---------------------------------------------------------------------------]]--
SlashCmdList.FWPROFILE = function(msg)
    local targetPlayer = strtrim(msg or "")
    if targetPlayer == "" then
        Utils.FW_Print("Usage: /fwprofile PlayerName-Realm", true)
        return
    end

    local function requestProfileAfterHandshake()
        Utils.FW_Print("Requesting " .. targetPlayer .. "'s profile...", false)
        Comm:RequestProfile(targetPlayer)
    end

    local knownAddonUsers = Comm:GetKnownAddonUsers()
    if knownAddonUsers and knownAddonUsers[targetPlayer] then
        requestProfileAfterHandshake()
    else
        Utils.FW_Print("Not sure if " .. targetPlayer .. " has the addon; pinging first...", false)
        Comm:PingPlayer(targetPlayer)

        C_Timer.After(Comm.PING_TIMEOUT + 1, function()
            local known = Comm:GetKnownAddonUsers()
            if known and known[targetPlayer] then
                requestProfileAfterHandshake()
            else
                Utils.FW_Print(targetPlayer.." did not respond to ping. Cannot request profile.", true)
            end
        end)
    end
end
SLASH_FWPROFILE1 = "/fwprofile"
