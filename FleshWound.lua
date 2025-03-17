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
        HEIGHT = 235,
        BACKDROP = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true,
            tileSize = 64,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        },
        TITLE = "FleshWound - v" .. version,
        CLOSE_BUTTON_WIDTH = 80,
        CLOSE_BUTTON_HEIGHT = 22,
        DEFAULT_POINT = "CENTER",
        TEXT_WIDTH = 350,
        TEXT_OFFSET_Y = -20
    },
    DISCLAIMER_FRAME = {
        WIDTH = 500,
        HEIGHT = 325,
        TITLE = "FleshWound - Disclaimer",
        BUTTON_WIDTH = 120,
        BUTTON_HEIGHT = 26,
        ICON_SIZE = 64,
    },
    WELCOME_ALREADY_SHOWN_KEY = "hasShownWelcome",
    DISCLAIMER_ALREADY_SHOWN_KEY = "hasShownDisclaimer",
    RELOAD_EVENT_NAME = "ADDON_LOADED"
}

local EventHandler = {}
addonTable.EventHandler = EventHandler


local function ShowWelcomeFrame()
    if FleshWoundData and FleshWoundData[CONSTANTS.WELCOME_ALREADY_SHOWN_KEY] then
        return
    end

    local welcomeFrame = CreateFrame("Frame", "FleshWoundWelcomeFrame", UIParent, "BackdropTemplate")
    welcomeFrame:SetSize(CONSTANTS.WELCOME_FRAME.WIDTH, CONSTANTS.WELCOME_FRAME.HEIGHT)
    welcomeFrame:SetPoint("CENTER")
    welcomeFrame:SetBackdrop(CONSTANTS.WELCOME_FRAME.BACKDROP)
    welcomeFrame:SetMovable(true)
    welcomeFrame:EnableMouse(true)
    welcomeFrame:RegisterForDrag("LeftButton")
    welcomeFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    welcomeFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local title = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText(CONSTANTS.WELCOME_FRAME.TITLE)

    local text = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetWidth(CONSTANTS.WELCOME_FRAME.TEXT_WIDTH)
    text:SetPoint("TOP", title, "BOTTOM", 0, CONSTANTS.WELCOME_FRAME.TEXT_OFFSET_Y)
    text:SetText(L.FLESHWOUND_FIRST_RELEASE_POPUP)

    local closeButton = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(CONSTANTS.WELCOME_FRAME.CLOSE_BUTTON_WIDTH, CONSTANTS.WELCOME_FRAME.CLOSE_BUTTON_HEIGHT)
    closeButton:SetPoint("TOP", welcomeFrame, "BOTTOM", 0, -10)
    closeButton:SetText("OK")
    closeButton:SetScript("OnClick", function()
        welcomeFrame:Hide()
        closeButton:Hide()
        FleshWoundData[CONSTANTS.WELCOME_ALREADY_SHOWN_KEY] = true
    end)

    welcomeFrame:Show()
end


local function ShowDisclaimerFrame()
    if FleshWoundData and FleshWoundData[CONSTANTS.DISCLAIMER_ALREADY_SHOWN_KEY] then
        return
    end

    local disclaimerFrame = CreateFrame("Frame", "FleshWoundDisclaimerFrame", UIParent, "BackdropTemplate")
    disclaimerFrame:SetSize(CONSTANTS.DISCLAIMER_FRAME.WIDTH, CONSTANTS.DISCLAIMER_FRAME.HEIGHT)
    disclaimerFrame:SetPoint("CENTER")
    disclaimerFrame:SetBackdrop(CONSTANTS.WELCOME_FRAME.BACKDROP)
    disclaimerFrame:SetMovable(true)
    disclaimerFrame:EnableMouse(true)
    disclaimerFrame:RegisterForDrag("LeftButton")
    disclaimerFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    disclaimerFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local icon = disclaimerFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(CONSTANTS.DISCLAIMER_FRAME.ICON_SIZE, CONSTANTS.DISCLAIMER_FRAME.ICON_SIZE)
    icon:SetPoint("TOP", 0, -20)
    icon:SetTexture("Interface\\ICONS\\INV_Misc_Bandage_03")

    local title = disclaimerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -10)
    title:SetText(CONSTANTS.DISCLAIMER_FRAME.TITLE)

    local text = disclaimerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetWidth(CONSTANTS.DISCLAIMER_FRAME.WIDTH - 40)
    text:SetPoint("TOP", title, "BOTTOM", 0, -10)
    text:SetJustifyH("CENTER")
    text:SetText(L.DISCLAIMER)

    local agreeButton = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
    agreeButton:SetSize(CONSTANTS.DISCLAIMER_FRAME.BUTTON_WIDTH, CONSTANTS.DISCLAIMER_FRAME.BUTTON_HEIGHT)
    agreeButton:SetPoint("TOP", disclaimerFrame, "BOTTOM", 0, -10)
    agreeButton:SetText(L.I_AGREE)
    agreeButton:SetScript("OnClick", function()
        disclaimerFrame:Hide()
        agreeButton:Hide()
        FleshWoundData[CONSTANTS.DISCLAIMER_ALREADY_SHOWN_KEY] = true
        ShowWelcomeFrame()
    end)

    local warningIcon = disclaimerFrame:CreateTexture(nil, "ARTWORK")
    warningIcon:SetSize(24, 24)
    warningIcon:SetPoint("BOTTOMLEFT", disclaimerFrame, "BOTTOMLEFT", 10, 10)
    warningIcon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")

    disclaimerFrame:Show()
end


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
        ShowDisclaimerFrame()
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


