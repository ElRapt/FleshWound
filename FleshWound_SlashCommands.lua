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
