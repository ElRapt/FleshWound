-- FleshWound.lua
-- The main addon file that initializes the addon's modules on ADDON_LOADED.

local addonName, addonTable = ...
local L = addonTable.L
local Utils = addonTable.Utils

local version = Utils.GetAddonVersion()

-- Centralized constants
local CONSTANTS = {
    WELCOME_FRAME = {
        WIDTH = 400,
        HEIGHT = 220,
        BACKDROP = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        },
        TITLE = "FleshWound - v.0.2.2",
        CLOSE_BUTTON_WIDTH = 80,
        CLOSE_BUTTON_HEIGHT = 22,
        DEFAULT_POINT = "CENTER",
        TEXT_WIDTH = 350,
        TEXT_OFFSET_Y = -12
    },
    WELCOME_ALREADY_SHOWN_KEY = "hasShownWelcome",
    RELOAD_EVENT_NAME = "ADDON_LOADED"
}

--- Create a custom backdrop frame to display the welcome message.
local function ShowWelcomeFrame()
    if FleshWoundData and FleshWoundData[CONSTANTS.WELCOME_ALREADY_SHOWN_KEY] then
        return
    end

    local welcomeFrame = CreateFrame("Frame", "FleshWoundWelcomeFrame", UIParent, "BackdropTemplate")
    welcomeFrame:SetSize(CONSTANTS.WELCOME_FRAME.WIDTH, CONSTANTS.WELCOME_FRAME.HEIGHT)
    welcomeFrame:SetPoint(CONSTANTS.WELCOME_FRAME.DEFAULT_POINT)
    welcomeFrame:SetBackdrop(CONSTANTS.WELCOME_FRAME.BACKDROP)
    welcomeFrame:SetMovable(true)
    welcomeFrame:EnableMouse(true)
    welcomeFrame:RegisterForDrag("LeftButton")
    welcomeFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    welcomeFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    local title = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(CONSTANTS.WELCOME_FRAME.TITLE)

    local text = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetWidth(CONSTANTS.WELCOME_FRAME.TEXT_WIDTH)
    text:SetPoint("TOP", title, "BOTTOM", 0, CONSTANTS.WELCOME_FRAME.TEXT_OFFSET_Y)
    text:SetText(L.FLESHWOUND_FIRST_RELEASE_POPUP)

    local closeButton = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(CONSTANTS.WELCOME_FRAME.CLOSE_BUTTON_WIDTH, CONSTANTS.WELCOME_FRAME.CLOSE_BUTTON_HEIGHT)
    closeButton:SetPoint("BOTTOM", 0, 16)
    closeButton:SetText("OK")
    closeButton:SetScript("OnClick", function()
        welcomeFrame:Hide()
        FleshWoundData[CONSTANTS.WELCOME_ALREADY_SHOWN_KEY] = true
    end)

    welcomeFrame:Show()
end

--- Event handler for the ADDON_LOADED event.
local EventHandler = {}
addonTable.EventHandler = EventHandler

--- A callback for the ADDON_LOADED event.
--- @param loadedName string: The name of the addon that was loaded.
function EventHandler:OnAddonLoaded(loadedName)
    if loadedName == addonName then
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

        -- Initialize Registry
        if addonTable.Registry and addonTable.Registry.Initialize then
            addonTable.Registry:Initialize()
        else
            Utils.FW_Print("Registry module not found or missing Initialize method.", true)
        end

        Utils.FW_Print(string.format(L.THANK_YOU, version), false)

        ShowWelcomeFrame()

        self.eventFrame:UnregisterEvent(CONSTANTS.RELOAD_EVENT_NAME)
    end
end

--- A function to handle the display of distant profile data.
--- @param profileName string: The name of the profile.
--- @param profileData table: The profile data to display.
function addonTable:OpenReceivedProfile(profileName, profileData)
    local GUI = addonTable.GUI
    if not GUI then
        return
    end

    if GUI.currentTemporaryProfile then
        GUI:RestoreOriginalProfile()
    end
    GUI:CloseAllDialogs()
    if GUI.frame then
        GUI.frame:Hide()
    end

    local originalProfile   = FleshWoundData.currentProfile
    local originalWoundData = CopyTable(addonTable.woundData)
    local copiedRemoteData  = CopyTable(profileData.woundData)

    addonTable.woundData = copiedRemoteData

    if GUI.UpdateRegionColors then
        GUI:UpdateRegionColors()
    end

    if GUI.frame then
        GUI.frame:Show()
    end

    GUI.originalProfile   = originalProfile
    GUI.originalWoundData = originalWoundData
    GUI.currentTemporaryProfile = profileName

    if GUI.UpdateProfileBanner then
        GUI:UpdateProfileBanner()
    end

    if GUI.frame and GUI.frame.ProfileButton then
        GUI.frame.ProfileButton:Hide()
    end
end


--- The event frame to catch the ADDON_LOADED event.
EventHandler.eventFrame = CreateFrame("Frame")
EventHandler.eventFrame:RegisterEvent(CONSTANTS.RELOAD_EVENT_NAME)
EventHandler.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == CONSTANTS.RELOAD_EVENT_NAME then
        EventHandler:OnAddonLoaded(...)
    end
end)
