-- FleshWound_SlashCommands.lua
-- This file adds slash commands to toggle the main FleshWound UI

local addonName, addonTable = ...

-- FleshWound_SlashCommands.lua

local addonName, addonTable = ...
local Comm = addonTable.Comm


-- Handler for the slash command
function SlashCmdList.FLESHPING(msg)
    local targetPlayer = strtrim(msg)
    if targetPlayer == "" then
        print("Usage: /fleshping PlayerName-Realm")
        return
    end

    print("Pinging "..targetPlayer.."...")
    Comm:PingPlayer(targetPlayer)

    -- After PING_TIMEOUT + 1 sec, check if player responded
    -- Assume same PING_TIMEOUT as defined in Comm
    local PING_TIMEOUT = 5
    C_Timer.After(PING_TIMEOUT + 1, function()
        local knownAddonUsers = Comm.GetKnownAddonUsers and Comm:GetKnownAddonUsers() or nil
        if knownAddonUsers and knownAddonUsers[targetPlayer] then
            print(targetPlayer.." is running FleshWound!")
        else
            print(targetPlayer.." did not respond. They might not have the addon.")
        end
    end)
end




-- Slash command handler
local function FleshWound_SlashHandler(msg)
    local GUI = addonTable.GUI
    if not GUI or not GUI.frame then
        print("FleshWound: The main frame is not initialized yet.")
        return
    end

    local frame = GUI.frame
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end


function SlashCmdList.FLESHPROFILE(msg)
    local targetPlayer = strtrim(msg)
    if targetPlayer == "" then
        print("Usage: /fleshprofile PlayerName-Realm")
        return
    end

    local function requestProfileAfterHandshake()
        print("Requesting "..targetPlayer.."'s profile...")
        Comm:RequestProfile(targetPlayer)
        -- The response (PROFILE_DATA) will trigger Comm:ShowIncomingProfilePopup and then addonTable:OpenReceivedProfile.
    end

    -- Check if we know the player has the addon
    local known = false
    if Comm.GetKnownAddonUsers then
        local knownAddonUsers = Comm:GetKnownAddonUsers()
        if knownAddonUsers and knownAddonUsers[targetPlayer] then
            known = true
        end
    end

    if known then
        requestProfileAfterHandshake()
    else
        print("Not sure if "..targetPlayer.." has the addon, pinging first...")
        Comm:PingPlayer(targetPlayer)

        -- After PING_TIMEOUT + 1 sec, check again
        local PING_TIMEOUT = 5
        C_Timer.After(PING_TIMEOUT + 1, function()
            local knownAddonUsers = Comm:GetKnownAddonUsers()
            if knownAddonUsers and knownAddonUsers[targetPlayer] then
                requestProfileAfterHandshake()
            else
                print(targetPlayer.." did not respond to PING. Cannot request profile.")
            end
        end)
    end
end


SLASH_FLESHPROFILE1 = "/fleshprofile"
SLASH_FLESHWOUND1 = "/fw"
SLASH_FLESHPING1 = "/fleshping"
SlashCmdList["FLESHWOUND"] = FleshWound_SlashHandler
