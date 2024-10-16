-- FleshWound_Data.lua
-- Handles data persistence and wound data structures

local addonName, addonTable = ...
local woundData = {}
addonTable.woundData = woundData

-- Event handler function
function FleshWound_OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ShowWelcomeMessage()

        -- Load saved data
        if FleshWoundData then
            woundData = FleshWoundData
            addonTable.woundData = woundData
        else
            FleshWoundData = woundData
        end
    end
end

-- Show welcome message
function ShowWelcomeMessage()
    local message = "|cFFFF0000<FleshWound>|r Welcome to FleshWound v" .. addonTable.addonVersion .. "!"
    print(message)
end
