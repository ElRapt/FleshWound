-- FleshWound_Utils.lua
-- Contains utility functions used across the addon

local addonName, addonTable = ...

-- Currently, we may not have utility functions, but this file can be used for future utilities

-- Example utility function to print debug messages
function addonTable.DebugPrint(message)
    if addonTable.debugMode then
        print("|cFFFF0000[Debug]|r " .. message)
    end
end
