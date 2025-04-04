-- FleshWound_SlashCommands.lua
-- Slash commands for the FleshWound addon.

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

-- Simple test command for treating a wound and printing the history log.
SLASH_FWADDHISTORY1 = "/fwaddhistory"
SlashCmdList["FWADDHISTORY"] = function(msg)
    -- Use a region ID from the command (or default to 1 if none provided)
    local regionID = tonumber(msg) or 1

    -- Create dummy treatment details.
    local treatmentDetails = {
        treatment   = "Applied magical bandages",
        appearance  = "Clean and mended",
        healer      = "TestHealer",
        severityID  = 3,
        statusIDs   = {2, 3},
        originalText= "Deep cut on region " .. tostring(regionID)
    }

    -- Add the history entry.
    addonTable.Data:AddHistoryEntry(regionID, treatmentDetails)
    print("Added test history entry for region " .. regionID)
end

SLASH_FWHISTORY1 = "/fwhistory"
SlashCmdList["FWHISTORY"] = function(msg)
    local regionID = tonumber(msg) or 3
    local history = addonTable.historyData and addonTable.historyData[regionID]
    if history and #history > 0 then
        print("History for region " .. regionID .. ":")
        for i, entry in ipairs(history) do
            local sinceHealed = time() - entry.timestamp
            print(string.format("Entry %d: Treatment: %s | Healed since: %d sec | Appearance: %s | Healer: %s",
                i, entry.treatment, sinceHealed, entry.appearance, entry.healer or "None"))
        end
    else
        print("No history for region " .. regionID)
    end
end
