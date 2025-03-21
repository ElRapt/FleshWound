-- FleshWound_GUI.lua
local addonName, addonTable = ...
local GUI = {}
addonTable.GUI = GUI
local L = addonTable.L

local CONSTANTS = {
    SIZES = {
        MAIN_FRAME_WIDTH = 320,
        MAIN_FRAME_HEIGHT = 540,
        BODY_IMAGE_WIDTH = 300,
        BODY_IMAGE_HEIGHT = 500,
        GENERIC_DIALOG_WIDTH = 550,
        GENERIC_DIALOG_HEIGHT = 500,
        NOTE_DIALOG_WIDTH = 400,
        NOTE_DIALOG_HEIGHT = 370,
        PROFILE_MANAGER_WIDTH = 500,
        PROFILE_MANAGER_HEIGHT = 500,
        CREATE_PROFILE_WIDTH = 300,
        CREATE_PROFILE_HEIGHT = 200,
        RENAME_PROFILE_WIDTH = 300,
        RENAME_PROFILE_HEIGHT = 200,
    },
    LIMITS = {
        MAX_NOTE_LENGTH = 125,
        MAX_PROFILE_NAME_LENGTH = 50,
    },
    BACKDROPS = {
        GENERIC_DIALOG = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 24,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        },
        DIALOG_FRAME = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        },
        TOOLTIP_FRAME = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = false,
            tileSize = 0,
            edgeSize = 14,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        },
        BANNER_FRAME = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = false,
            tileSize = 0,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        },
        EDIT_BOX = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = nil,
            tile = false,
            tileSize = 0,
            edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        },
    },
    IMAGES = {
        DIALOG_BG = "Interface\\DialogFrame\\UI-DialogBox-Background",
        DIALOG_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border",
        TOOLTIP_BG = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        BODY_IMAGE = "Interface\\AddOns\\" .. addonName .. "\\Textures\\body_image.tga",
        ICON_BOOK = "Interface\\ICONS\\INV_Misc_Book_09",
        ICON_HIGHLIGHT_SQUARE = "Interface\\Buttons\\ButtonHilight-Square",
        ICON_MOUSE_HIGHLIGHT = "Interface\\Buttons\\UI-Common-MouseHilight",
    },
    ICONS = {
        BANDAGE = "Interface\\Icons\\INV_Misc_Bandage_01",
        BLOOD = "Interface\\Icons\\Spell_Druid_Bloodythrash",
        BONE = "Interface\\Icons\\INV_Misc_Bone_01",
        FIRE = "Interface\\Icons\\Spell_Fire_Immolation",
        SCAR = "Interface\\Icons\\Spell_Misc_Petheal",
        POISON = "Interface\\Icons\\Ability_Rogue_Deviouspoisons",
        INFECTED = "Interface\\Icons\\Ability_Druid_Infectedwound",
    },
    SEVERITIES = {
        { id = 1, displayName = L.SEVERITY_NONE,     color = {0, 0, 0, 0.0} },
        { id = 2, displayName = L.SEVERITY_UNKNOWN,  color = {0.5, 0.5, 0.5, 0.4} },
        { id = 3, displayName = L.SEVERITY_BENIGN,   color = {0, 1, 0, 0.4} },
        { id = 4, displayName = L.SEVERITY_MODERATE, color = {1, 1, 0, 0.4} },
        { id = 5, displayName = L.SEVERITY_SEVERE,   color = {1, 0.5, 0, 0.4} },
        { id = 6, displayName = L.SEVERITY_CRITICAL, color = {1, 0, 0, 0.4} },
        { id = 7, displayName = L.SEVERITY_DEADLY,   color = {0.6, 0, 0.6, 0.4} },
    },
    STATUSES = {
        { id = 1, displayName = L.STATUS_NONE,       icon = nil },
        { id = 2, displayName = L.STATUS_BANDAGED,   icon = "Interface\\Icons\\INV_Misc_Bandage_01" },
        { id = 3, displayName = L.STATUS_BLEEDING,   icon = "Interface\\Icons\\Spell_Druid_Bloodythrash" },
        { id = 4, displayName = L.STATUS_BROKEN_BONE,icon = "Interface\\Icons\\INV_Misc_Bone_01" },
        { id = 5, displayName = L.STATUS_BURN,       icon = "Interface\\Icons\\Spell_Fire_Immolation" },
        { id = 6, displayName = L.STATUS_SCARRED,    icon = "Interface\\Icons\\Spell_Misc_Petheal" },
        { id = 7, displayName = L.STATUS_POISONED,   icon = "Interface\\Icons\\Ability_Rogue_Deviouspoisons" },
        { id = 8, displayName = L.STATUS_INFECTED,   icon = "Interface\\Icons\\Ability_Druid_Infectedwound" },
    },
    REGIONS = {
        { id = 1,  nameKey = "Head",      localName = L.HEAD,      x = 130, y = 420, width = 50,  height = 75 },
        { id = 2,  nameKey = "Torso",     localName = L.TORSO,     x = 130, y = 275, width = 50,  height = 120 },
        { id = 3,  nameKey = "LeftArm",   localName = L.LEFT_ARM,  x = 75,  y = 300, width = 50,  height = 120 },
        { id = 4,  nameKey = "RightArm",  localName = L.RIGHT_ARM, x = 185, y = 300, width = 50,  height = 120 },
        { id = 5,  nameKey = "LeftHand",  localName = L.LEFT_HAND, x = 40,  y = 180, width = 50,  height = 100 },
        { id = 6,  nameKey = "RightHand", localName = L.RIGHT_HAND,x = 215, y = 180, width = 50,  height = 100 },
        { id = 7,  nameKey = "LeftLeg",   localName = L.LEFT_LEG,  x = 100, y = 50,  width = 50,  height = 130 },
        { id = 8,  nameKey = "RightLeg",  localName = L.RIGHT_LEG, x = 155, y = 50,  width = 50,  height = 130 },
        { id = 9,  nameKey = "LeftFoot",  localName = L.LEFT_FOOT, x = 110, y = 0,   width = 50,  height = 50 },
        { id = 10, nameKey = "RightFoot", localName = L.RIGHT_FOOT,x = 150, y = 0,   width = 50,  height = 50 },
    },
    STATUS_PRIORITY = {
        [4] = 1,
        [5] = 2,
        [8] = 3,
        [3] = 4,
        [7] = 5,
        [6] = 6,
        [2] = 7,
    },
}
GUI.CONSTANTS = CONSTANTS

local Severities = CONSTANTS.SEVERITIES
local SeveritiesByID = {}
for _, sev in ipairs(Severities) do
    SeveritiesByID[sev.id] = sev
end

local Statuses = CONSTANTS.STATUSES
local StatusesByID = {}
for _, st in ipairs(Statuses) do
    StatusesByID[st.id] = st
end

GUI.Severities = Severities
GUI.SeveritiesByID = SeveritiesByID
GUI.Statuses = Statuses
GUI.StatusesByID = StatusesByID

--- Saves the position of a given frame.
-- @param frameName string The unique name of the frame.
-- @param frame Frame The frame whose position is to be saved.
function GUI:SaveWindowPosition(frameName, frame)
    addonTable.FleshWoundData.positions = addonTable.FleshWoundData.positions or {}
    local pos = addonTable.FleshWoundData.positions
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    pos[frameName] = { point = point, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
end

--- Restores the position of a given frame.
-- @param frameName string The unique name of the frame.
-- @param frame Frame The frame to be positioned.
function GUI:RestoreWindowPosition(frameName, frame)
    local pos = addonTable.FleshWoundData.positions and addonTable.FleshWoundData.positions[frameName]
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        frame:SetPoint("CENTER")
    end
end

--- Creates a scroll frame with an attached child frame.
-- @param parent Frame The parent frame.
-- @param left number Left offset.
-- @param top number Top offset.
-- @param right number Right offset.
-- @param bottom number Bottom offset.
-- @return Frame, Frame The scroll frame and its child.
function GUI:CreateScrollFrame(parent, left, top, right, bottom)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", right, bottom)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    return scrollFrame, scrollChild
end

--- Creates a standardized button.
-- @param parent Frame The parent frame.
-- @param text string The button text.
-- @param width number Button width.
-- @param height number Button height.
-- @param point string Anchor point.
-- @param relativeTo Frame|string Relative frame or string.
-- @param offsetX number Horizontal offset.
-- @param offsetY number Vertical offset.
-- @return Button The created button.
function GUI:CreateButton(parent, text, width, height, point, relativeTo, offsetX, offsetY)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    if type(relativeTo) == "string" then
        button:SetPoint(point, parent, relativeTo, offsetX, offsetY)
    else
        button:SetPoint(point, relativeTo, offsetX, offsetY)
    end
    button:SetText(text)
    return button
end

--- Initializes the main FleshWound UI.

function GUI:Initialize()
    self.displayingRemote = false
    self.activeRemoteProfileName = nil
    self:CreateMainFrame()
    self:RestoreWindowPosition("FleshWoundFrame", self.frame)
    self:CreateBodyRegions()
    self:CreateTemporaryProfileBanner()
    self:UpdateRegionColors()
    self:UpdateProfileBanner()
end

--- Explicitly display a remote profile
function GUI:DisplayRemoteProfile(profileName)
    self.displayingRemote = true
    self.activeRemoteProfileName = profileName
    self:CloseAllDialogs()
    if self.frame then
        self.frame:Show()
    end
    self:UpdateProfileBanner()
    self:UpdateRegionColors()
    if self.frame and self.frame.ProfileButton then
        self.frame.ProfileButton:Hide()
    end
end

--- Explicitly display local data (the user's own profile)
function GUI:DisplayLocalProfile()
    self.displayingRemote = false
    self.activeRemoteProfileName = nil
    self:CloseAllDialogs()
    if self.frame then
        self.frame:Show()
    end
    self:UpdateProfileBanner()
    self:UpdateRegionColors()
    if self.frame and self.frame.ProfileButton then
        self.frame.ProfileButton:Show()
    end
end

function GUI:GetActiveWoundData()
    if self.displayingRemote and self.activeRemoteProfileName then
        local remoteData = addonTable.remoteProfiles[self.activeRemoteProfileName]
        if not remoteData then return {} end
        return remoteData
    end
    return addonTable.woundData or {}
end

function GUI:UpdateProfileBanner()
    if not (self.frame and self.tempProfileBannerFrame and self.tempProfileBanner) then
        return
    end
    if self.displayingRemote and self.activeRemoteProfileName then
        self.tempProfileBanner:SetText(string.format(L.VIEWING_PROFILE, self.activeRemoteProfileName))
    else
        local currentProfileName = addonTable.FleshWoundData.currentProfile or "Unknown"
        self.tempProfileBanner:SetText(string.format(L.VIEWING_PROFILE, currentProfileName))
    end
    self.tempProfileBannerFrame:Show()
end

function GUI:CreateTemporaryProfileBanner()
    if not self.frame then return end
    local bannerFrame = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    bannerFrame:SetSize(self.frame:GetWidth() - 20, 30)
    bannerFrame:SetPoint("TOP", self.frame, "TOP", 0, 25)
    bannerFrame:SetBackdrop(CONSTANTS.BACKDROPS.BANNER_FRAME)
    bannerFrame:SetBackdropColor(0, 0, 0, 0.7)
    bannerFrame:Hide()
    local bannerText = bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bannerText:SetPoint("CENTER", bannerFrame, "CENTER", 0, 0)
    bannerText:SetJustifyH("CENTER")
    bannerText:SetTextColor(1, 0.8, 0, 1)
    self.tempProfileBannerFrame = bannerFrame
    self.tempProfileBanner = bannerText
end

--- Closes all relevant dialogs when switching modes
function GUI:CloseAllDialogs()
    if addonTable.Dialogs then
        addonTable.Dialogs:CloseAllDialogs()
    end
    if self.frame then
        self.frame:Hide()
    end
end

function GUI:CreateMainFrame()
    local frame = CreateFrame("Frame", "FleshWoundFrame", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(CONSTANTS.SIZES.MAIN_FRAME_WIDTH, CONSTANTS.SIZES.MAIN_FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetBackdrop(CONSTANTS.BACKDROPS.DIALOG_FRAME)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        GUI:SaveWindowPosition("FleshWoundFrame", f)
    end)
    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    table.insert(UISpecialFrames, frame:GetName())

    frame.BodyImage = frame:CreateTexture(nil, "BACKGROUND")
    frame.BodyImage:SetSize(CONSTANTS.SIZES.BODY_IMAGE_WIDTH, CONSTANTS.SIZES.BODY_IMAGE_HEIGHT)
    frame.BodyImage:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.BodyImage:SetTexture(CONSTANTS.IMAGES.BODY_IMAGE)

    frame.ProfileButton = CreateFrame("Button", nil, frame)
    frame.ProfileButton:SetSize(35, 35)
    frame.ProfileButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
    frame.ProfileButton:SetNormalTexture(CONSTANTS.IMAGES.ICON_BOOK)
    frame.ProfileButton:SetHighlightTexture(CONSTANTS.IMAGES.ICON_HIGHLIGHT_SQUARE)
    frame.ProfileButton:SetScript("OnClick", function()
        for frameName, frm in pairs(_G) do
            if type(frameName) == "string" and
               (frameName:match("^FleshWoundAddNoteDialog_") or frameName:match("^FleshWoundEditNoteDialog_"))
               and frm.IsShown and frm:IsShown() then
                frm:Hide()
            end
        end
        if addonTable.ProfileManager then
            addonTable.ProfileManager:OpenProfileManager()
        end
    end)
end

function GUI:CreateBodyRegions()
    local frame = self.frame
    frame.BodyRegions = {}
    for _, region in ipairs(CONSTANTS.REGIONS) do
        self:CreateBodyRegion(frame, region)
    end
end

function GUI:CreateBodyRegion(frame, region)
    local btn = CreateFrame("Button", nil, frame)
    local Dialogs = addonTable.Dialogs
    btn:SetSize(region.width, region.height)
    btn:SetPoint("BOTTOMLEFT", frame.BodyImage, "BOTTOMLEFT", region.x, region.y)
    btn:SetHighlightTexture(CONSTANTS.IMAGES.ICON_MOUSE_HIGHLIGHT)
    btn.regionID = region.id
    btn:SetScript("OnClick", function()
        Dialogs:OpenRegionDialog(btn.regionID)
    end)
    local regionMarker = btn:CreateTexture(nil, "OVERLAY")
    regionMarker:SetSize(10, 10)
    regionMarker:SetPoint("CENTER", btn, "CENTER")
    regionMarker:SetColorTexture(0, 1, 0, 1)
    btn.regionMarker = regionMarker
    local overlay = btn:CreateTexture(nil, "ARTWORK")
    local inset = 7
    overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
    overlay:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
    overlay:SetColorTexture(0, 0, 0, 0)
    btn.overlay = overlay
    local countText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countText:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, -30)
    countText:SetJustifyH("RIGHT")
    countText:Hide()
    btn.countText = countText
    btn.statusIcons = {}
    local iconSize = 14
    local iconSpacing = 2
    for i = 1, 3 do
        local icon = btn:CreateTexture(nil, "OVERLAY")
        icon:SetSize(iconSize, iconSize)
        if i == 1 then
            icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        else
            icon:SetPoint("LEFT", btn.statusIcons[i - 1], "RIGHT", iconSpacing, 0)
        end
        icon:Hide()
        btn.statusIcons[i] = icon
    end
    frame.BodyRegions[region.id] = btn
end

function GUI:UpdateRegionColors()
    local frame = self.frame
    if not (frame and frame.BodyRegions) then return end
    local data = self:GetActiveWoundData()
    local statusPriority = CONSTANTS.STATUS_PRIORITY
    for regionID, btn in pairs(frame.BodyRegions) do
        local highestID = addonTable.Utils.GetHighestSeverityID(regionID, data)
        local sev = SeveritiesByID[highestID] or { color = {0, 0, 0, 0} }
        local r, g, b, a = sev.color[1], sev.color[2], sev.color[3], sev.color[4]
        btn.overlay:SetColorTexture(r, g, b, a)

        local notes = data[regionID]
        local count = notes and #notes or 0
        if count > 0 then
            btn.countText:SetText(count)
            btn.countText:Show()
        else
            btn.countText:Hide()
        end

        local foundStatuses = {}
        if notes then
            for _, note in ipairs(notes) do
                if note.statusIDs then
                    for _, stID in ipairs(note.statusIDs) do
                        foundStatuses[stID] = true
                    end
                end
            end
        end

        local sortedStatuses = {}
        for stID in pairs(foundStatuses) do
            table.insert(sortedStatuses, stID)
        end
        table.sort(sortedStatuses, function(a, b)
            return (statusPriority[a] or 999) < (statusPriority[b] or 999)
        end)

        for i = 1, 3 do
            local iconTexture = btn.statusIcons[i]
            local stID = sortedStatuses[i]
            if stID then
                local stData = StatusesByID[stID]
                if stData and stData.icon then
                    iconTexture:SetTexture(stData.icon)
                    iconTexture:Show()
                else
                    iconTexture:Hide()
                end
            else
                iconTexture:Hide()
            end
        end
    end
end

return GUI
