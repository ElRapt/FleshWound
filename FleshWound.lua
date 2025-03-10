-- FleshWound.lua
-- The main addon file that initializes the addon's modules on ADDON_LOADED.

local addonName, addonTable = ...
addonTable.remoteProfiles = addonTable.remoteProfiles or {}
local L = addonTable.L
local Utils = addonTable.Utils

local version = Utils.GetAddonVersion()

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

local EventHandler = {}
addonTable.EventHandler = EventHandler

function EventHandler:OnAddonLoaded(loadedName)
    if loadedName == addonName then
        if not FleshWoundData then
            FleshWoundData = {}
        end
        addonTable.FleshWoundData = FleshWoundData

        if addonTable.Data and addonTable.Data.Initialize then
            addonTable.Data:Initialize()
        else
            Utils.FW_Print("Data module not found or missing Initialize method.", true)
        end

        if addonTable.GUI and addonTable.GUI.Initialize then
            addonTable.GUI:Initialize()
        else
            Utils.FW_Print("GUI module not found or missing Initialize method.", true)
        end

        if addonTable.Comm and addonTable.Comm.Initialize then
            addonTable.Comm:Initialize()
        end

        Utils.FW_Print(string.format(L.THANK_YOU, version), false)
        ShowWelcomeFrame()
        self.eventFrame:UnregisterEvent(CONSTANTS.RELOAD_EVENT_NAME)
    end
end

--- Opens a received remote profile for display in read-only mode.
--- @param profileName string The remote profile name
--- @param profileData table The remote profile data
function addonTable:OpenReceivedProfile(profileName, profileData)
    if not addonTable.GUI then return end
    addonTable.remoteProfiles[profileName] = profileData.woundData or {}
    addonTable.GUI:DisplayRemoteProfile(profileName)
end

EventHandler.eventFrame = CreateFrame("Frame")
EventHandler.eventFrame:RegisterEvent(CONSTANTS.RELOAD_EVENT_NAME)
EventHandler.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == CONSTANTS.RELOAD_EVENT_NAME then
        EventHandler:OnAddonLoaded(...)
    end
end)
