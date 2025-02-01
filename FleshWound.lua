-- FleshWound.lua
-- The main addon file that initializes the addon's modules on ADDON_LOADED.

local addonName, addonTable = ...
local L = addonTable.L
local Utils = addonTable.Utils

-- Create a custom welcome frame for first-time use.
local function ShowWelcomeFrame()
    -- Basic check to avoid re-showing if already done
    if FleshWoundData and FleshWoundData.hasShownWelcome then
        return
    end

    -- Main frame
    local welcomeFrame = CreateFrame("Frame", "FleshWoundWelcomeFrame", UIParent, "BackdropTemplate")
    welcomeFrame:SetSize(400, 220)
    welcomeFrame:SetPoint("CENTER")
    welcomeFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    welcomeFrame:SetMovable(true)
    welcomeFrame:EnableMouse(true)
    welcomeFrame:RegisterForDrag("LeftButton")
    welcomeFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    welcomeFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Title
    local title = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    -- You can localize this text as needed
    title:SetText("FleshWound - v.0.1.0")

    -- Body Text
    local text = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetWidth(350)
    text:SetPoint("TOP", title, "BOTTOM", 0, -12)
    text:SetText(L.FLESHWOUND_FIRST_RELEASE_POPUP)

    -- Close Button
    local closeButton = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 22)
    closeButton:SetPoint("BOTTOM", 0, 16)
    closeButton:SetText("OK")
    closeButton:SetScript("OnClick", function()
        -- Hide and set flag so we don't show again
        welcomeFrame:Hide()
        FleshWoundData.hasShownWelcome = true
    end)

    welcomeFrame:Show()
end


--[[---------------------------------------------------------------------------
  EventHandler: A small module to handle ADDON_LOADED and set up the addon.
---------------------------------------------------------------------------]]--
local EventHandler = {}
addonTable.EventHandler = EventHandler

function EventHandler:OnAddonLoaded(loadedName)
    if loadedName == addonName then
        -- Ensure global SV is present
        if not FleshWoundData then
            FleshWoundData = {}
        end
        addonTable.FleshWoundData = FleshWoundData

        -- Initialize Data
        if addonTable.Data and addonTable.Data.Initialize then
            addonTable.Data:Initialize()
        else
            Utils.FW_Print("Data module not found or missing Initialize method.", true)
        end

        -- Initialize GUI
        if addonTable.GUI and addonTable.GUI.Initialize then
            addonTable.GUI:Initialize()
        else
            Utils.FW_Print("GUI module not found or missing Initialize method.", true)
        end

        -- Initialize Comm
        if addonTable.Comm and addonTable.Comm.Initialize then
            addonTable.Comm:Initialize()
        end

        -- Attempt to retrieve the version from the TOC
        local version = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version") or "v0.2.0"
        Utils.FW_Print(string.format(L.THANK_YOU, version), false)

        ----------------------------------------------------------------------
        -- Show the custom welcome frame if not shown yet
        ----------------------------------------------------------------------
        ShowWelcomeFrame()

        -- Unregister the event to avoid re-initialization
        self.eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end


--[[---------------------------------------------------------------------------
  Called when we receive a remote profile. Temporarily display that data until
  the user closes or reverts to their own profile.
---------------------------------------------------------------------------]]--
function addonTable:OpenReceivedProfile(profileName, profileData)
    local GUI = addonTable.GUI
    if not GUI then
        return
    end

    -- If we're already viewing a remote profile, restore our local data first
    if GUI.currentTemporaryProfile then
        GUI:RestoreOriginalProfile()
    end
    GUI:CloseAllDialogs()
    if GUI.frame then
        GUI.frame:Hide()
    end

    -- Deep copy of your original data (so we can revert later)
    local originalProfile   = addonTable.FleshWoundData.currentProfile
    local originalWoundData = CopyTable(addonTable.woundData)

    -- Deep copy the remote data (so changes don’t affect them)
    local copiedRemoteData = CopyTable(profileData.woundData)

    -- Temporarily overwrite your local data with the remote
    addonTable.woundData = copiedRemoteData

    -- Update the GUI with the new data
    if GUI.UpdateRegionColors then
        GUI:UpdateRegionColors()
    end

    -- Re-show the main frame so the user sees the remote data
    if GUI.frame then
        GUI.frame:Show()
    end

    -- Store references so we can revert easily
    GUI.originalProfile   = originalProfile
    GUI.originalWoundData = originalWoundData
    GUI.currentTemporaryProfile = profileName

    -- Update the label/banner to reflect remote mode
    if GUI.UpdateProfileBanner then
        GUI:UpdateProfileBanner()
    end

    -- Hide the normal "Profile" button while viewing a remote profile
    if GUI.frame and GUI.frame.ProfileButton then
        GUI.frame.ProfileButton:Hide()
    end
end


-- Set up an event frame to handle ADDON_LOADED
EventHandler.eventFrame = CreateFrame("Frame")
EventHandler.eventFrame:RegisterEvent("ADDON_LOADED")
EventHandler.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        EventHandler:OnAddonLoaded(...)
    end
end)


