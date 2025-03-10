-- FleshWound_Utils.lua
-- Utility/helper functions for the FleshWound addon.
-- (Incorporates a standardized print function and a draggable-frame helper.)

    local addonName, addonTable = ...
    local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    
    local Utils = {}
    addonTable.Utils = Utils
    
    local prefixColor = "|cFF00FF00FleshWound:|r "

    --- Returns the version of the addon as a string.
--- @return string: The version of the addon.
    function Utils.GetAddonVersion()
        local version = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
        return version or "0.0.0"
    end
    --- Prints a message to the chat frame.
--- @param msg string: The message to print.
--- @param isError boolean: If true, the message is printed in red to the UIErrorsFrame.
    function Utils.FW_Print(msg, isError)
        if isError then
            UIErrorsFrame:AddMessage(prefixColor .. msg, 1.0, 0.0, 0.0, 5)
        else
            print(prefixColor .. msg)
        end
    end

    --- Helper function to make a frame draggable.
--- @param frame table: The frame to make draggable.
--- @param onStopCallback function: An optional callback function to call when dragging stops.
    function Utils.MakeFrameDraggable(frame, onStopCallback)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(f)
            f:StartMoving()
        end)
        frame:SetScript("OnDragStop", function(f)
            f:StopMovingOrSizing()
            if onStopCallback then
                onStopCallback(f)
            end
        end)
    end
    -- Trims whitespace and removes control characters from a string.
-- @param text (string) The input string.
-- @return (string) The sanitized string.
    function Utils.SanitizeInput(text)
        text = text or ""
        text = text:match("^%s*(.-)%s*$") or ""
        text = text:gsub("[%c]", "")
        return text
    end

    -- Retrieves the RGBA color values for a given severity ID.
-- @param severityID (number) The severity identifier.
-- @param SeveritiesByID (table) The table of severity data.
-- @return (number, number, number, number) The red, green, blue, and alpha values.
    function Utils.GetSeverityColorByID(severityID, SeveritiesByID)
        local sev = SeveritiesByID[severityID]
        if not sev then
            return 0, 0, 0, 0
        end
        local c = sev.color
        return c[1], c[2], c[3], c[4]
    end
    

    -- Determines the highest severity ID within a region.
-- @param regionID (number) The ID of the body region.
-- @return (number) The highest severity ID found (default is 1 for "None").
    function Utils.GetHighestSeverityID(regionID, data)
        local woundData = data or addonTable.woundData or {}
        local notes = woundData[regionID]
        if not (notes and #notes > 0) then
            return 1
        end
        local highestID = 1
        for _, note in ipairs(notes) do
            local sevID = note.severityID or 1
            if sevID > highestID then
                highestID = sevID
            end
        end
        return highestID
    end
    
    --- Normalizes a player's name using Ambiguate in "short" mode.
-- @param name string The player's name.
-- @return string|nil The normalized name or nil if no name provided.
    function Utils.NormalizePlayerName(name)
        return name and Ambiguate(name, "short") or nil
    end
    
    --- Converts a given name to lowercase.
-- @param name string The player's name.
-- @return string|nil The lowercase version of the name or nil if no name provided.
    function Utils.ToLower(name)
        return name and string.lower(name) or nil
    end
    
    --- Compares two version strings.
-- Returns -1 if v1 is less than v2, 1 if greater, or 0 if equal.
-- @param v1 string First version string.
-- @param v2 string Second version string.
-- @return number Comparison result: -1, 0, or 1.
    function Utils.VersionCompare(v1, v2)
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
    