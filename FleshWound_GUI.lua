local addonName, addonTable = ...
local L = addonTable.L
local Utils = addonTable.Utils

local CONSTANTS = {
    IMAGES = {
        DIALOG_BG = "Interface\\DialogFrame\\UI-DialogBox-Background",
        DIALOG_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border",
        TOOLTIP_BG = "Interface\\Tooltips\\UI-Tooltip-Background",
        TOOLTIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border",
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
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 24,
            insets = { left = 5, right = 5, top = 5, bottom = 5 },
        },
        DIALOG_FRAME = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        },
        TOOLTIP_FRAME = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 0,
            edgeSize = 14,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        },
        BANNER_FRAME = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
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
        { name = L.HEAD,      x = 130, y = 420, width = 50,  height = 75 },
        { name = L.TORSO,     x = 130, y = 275, width = 50,  height = 120 },
        { name = L.LEFT_ARM,  x = 75,  y = 300, width = 50,  height = 120 },
        { name = L.RIGHT_ARM, x = 185, y = 300, width = 50,  height = 120 },
        { name = L.LEFT_HAND, x = 40,  y = 180, width = 50,  height = 100 },
        { name = L.RIGHT_HAND,x = 215, y = 180, width = 50,  height = 100 },
        { name = L.LEFT_LEG,  x = 100, y = 50,  width = 50,  height = 130 },
        { name = L.RIGHT_LEG, x = 155, y = 50,  width = 50,  height = 130 },
        { name = L.LEFT_FOOT, x = 110, y = 0,   width = 50,  height = 50 },
        { name = L.RIGHT_FOOT,x = 150, y = 0,   width = 50,  height = 50 },
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

local GUI = {}
addonTable.GUI = GUI

StaticPopupDialogs["FW_DELETE_PROFILE_CONFIRM"] = {
    text = L.DELETE_PROFILE_CONFIRM,
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local profileName = self.data
        addonTable.Data:DeleteProfile(profileName)
        if addonTable.GUI and addonTable.GUI.OpenProfileManager then
            addonTable.GUI:OpenProfileManager()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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

local function SanitizeInput(text)
    text = text or ""
    text = text:match("^%s*(.-)%s*$") or ""
    text = text:gsub("[%c]", "")
    return text
end

local function GetSeverityColorByID(severityID)
    local sev = SeveritiesByID[severityID]
    if not sev then
        return 0, 0, 0, 0
    end
    local c = sev.color
    return c[1], c[2], c[3], c[4]
end

local function GetHighestSeverityID(regionName)
    local woundData = addonTable.woundData or {}
    local notes = woundData[regionName]
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

function GUI:SaveWindowPosition(frameName, frame)
    addonTable.FleshWoundData.positions = addonTable.FleshWoundData.positions or {}
    local pos = addonTable.FleshWoundData.positions
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    pos[frameName] = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs,
    }
end

function GUI:RestoreWindowPosition(frameName, frame)
    local pos = addonTable.FleshWoundData.positions and addonTable.FleshWoundData.positions[frameName]
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        frame:SetPoint("CENTER")
    end
end

local function CreateDialog(name, titleText, width, height)
    local dialog = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    dialog:SetSize(width, height)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop(CONSTANTS.BACKDROPS.GENERIC_DIALOG)
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    Utils.MakeFrameDraggable(dialog, nil)
    dialog.CloseButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    dialog.CloseButton:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
    dialog.CloseButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    if name and name ~= "" then
        table.insert(UISpecialFrames, name)
    end
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -15)
    title:SetText(titleText)
    local titleLine = dialog:CreateTexture(nil, "ARTWORK")
    titleLine:SetHeight(2)
    titleLine:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    titleLine:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -15, -40)
    titleLine:SetColorTexture(1, 1, 1, 0.2)
    return dialog
end

local function CreateSeverityDropdown(parent)
    local severityLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    severityLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -60)
    severityLabel:SetText(L.SEVERITY)
    local severityDropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    severityDropdown:SetPoint("LEFT", severityLabel, "RIGHT", -10, -3)
    UIDropDownMenu_SetWidth(severityDropdown, 150)
    severityDropdown.initialize = function(dropdown, level)
        for _, sev in ipairs(Severities) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = sev.displayName
            info.arg1 = sev.id
            info.func = function(_, chosenID)
                UIDropDownMenu_SetSelectedValue(dropdown, chosenID)
                parent.selectedSeverityID = chosenID
            end
            info.checked = (sev.id == (parent.selectedSeverityID or 1))
            UIDropDownMenu_AddButton(info)
        end
    end
    function severityDropdown:SetSeverityID(id)
        parent.selectedSeverityID = id
        UIDropDownMenu_SetSelectedValue(severityDropdown, id)
    end
    return severityLabel, severityDropdown
end

local function CreateStatusSelection(parent)
    local frame = CreateFrame("Frame", nil, parent)
    local numStatuses = #Statuses
    local height = 30 * (numStatuses + 1)
    frame:SetSize(400, height)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -100)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT")
    label:SetText(L.STATUS)
    frame.checkboxes = {}
    frame.selectedStatusIDs = {}
    local yOffset = -20
    for _, st in ipairs(Statuses) do
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, yOffset)
        cb.text:SetText(st.displayName)
        cb:SetScript("OnClick", function(self)
            if st.id == 1 then
                if self:GetChecked() then
                    wipe(frame.selectedStatusIDs)
                    frame.selectedStatusIDs[1] = true
                    for otherID, otherCb in pairs(frame.checkboxes) do
                        if otherID ~= 1 then
                            otherCb:SetChecked(false)
                        end
                    end
                else
                    frame.selectedStatusIDs[1] = nil
                end
            else
                if self:GetChecked() then
                    frame.selectedStatusIDs[st.id] = true
                    if frame.checkboxes[1] and frame.checkboxes[1]:GetChecked() then
                        frame.checkboxes[1]:SetChecked(false)
                        frame.selectedStatusIDs[1] = nil
                    end
                else
                    frame.selectedStatusIDs[st.id] = nil
                end
            end
        end)
        frame.checkboxes[st.id] = cb
        yOffset = yOffset - 20
    end
    function frame:SetStatusIDs(idTable)
        for id, cb in pairs(frame.checkboxes) do
            cb:SetChecked(false)
        end
        wipe(frame.selectedStatusIDs)
        if idTable then
            for _, stID in ipairs(idTable) do
                if frame.checkboxes[stID] then
                    frame.checkboxes[stID]:SetChecked(true)
                    frame.selectedStatusIDs[stID] = true
                end
            end
        end
    end
    return frame
end

function GUI:CreateScrollFrame(parent, left, top, right, bottom)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", left, top)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", right, bottom)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    return scrollFrame, scrollChild
end

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

local function CreateEditBoxWithCounter(parent, maxChars)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    local topAnchor = parent.StatusLabel or parent.StatusSelection
    if topAnchor then
        scrollFrame:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", 0, -20)
    else
        scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -120)
    end
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -35, 80)
    local editBox = CreateFrame("EditBox", nil, scrollFrame, "BackdropTemplate")
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetMaxLetters(maxChars)
    editBox:SetAutoFocus(true)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetTextInsets(10, 10, 10, 10)
    editBox:SetBackdrop(CONSTANTS.BACKDROPS.EDIT_BOX)
    editBox:SetBackdropColor(0, 0, 0, 0.5)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    scrollFrame:SetScrollChild(editBox)
    local charCountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charCountLabel:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, 50)
    charCountLabel:SetText(string.format(L.CHAR_COUNT, 0, maxChars))
    editBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        local length = strlenutf8(text)
        charCountLabel:SetText(string.format(L.CHAR_COUNT, length, maxChars))
    end)
    return scrollFrame, editBox, charCountLabel
end

local function CreateSaveCancelButtons(parent)
    local saveButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    saveButton:SetSize(80, 24)
    saveButton:SetPoint("BOTTOMRIGHT", parent, "BOTTOM", -10, 15)
    saveButton:SetText(L.SAVE)
    local cancelButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 24)
    cancelButton:SetPoint("BOTTOMLEFT", parent, "BOTTOM", 10, 15)
    cancelButton:SetText(L.CANCEL)
    return saveButton, cancelButton
end

local function CreateSingleLineEditBoxWithCounter(parent, maxChars)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetAutoFocus(true)
    editBox:SetMaxLetters(maxChars)
    editBox:SetSize(160, 30)
    local charCountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charCountLabel:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -5)
    charCountLabel:SetText(string.format(L.CHAR_COUNT, 0, maxChars))
    editBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        local length = strlenutf8(text)
        charCountLabel:SetText(string.format(L.CHAR_COUNT, length, maxChars))
    end)
    return editBox, charCountLabel
end

function GUI:Initialize()
    self.woundData = addonTable.woundData or {}
    self:CreateMainFrame()
    self:RestoreWindowPosition("FleshWoundFrame", self.frame)
    self:CreateBodyRegions()
    self:CreateTemporaryProfileBanner()
    self:UpdateRegionColors()
    self:UpdateProfileBanner()
end

function GUI:UpdateProfileBanner()
    if not (self.frame and self.tempProfileBannerFrame and self.tempProfileBanner) then
        return
    end
    local currentProfileName = addonTable.FleshWoundData.currentProfile or "Unknown"
    if self.currentTemporaryProfile then
        self.tempProfileBanner:SetText(string.format(L.VIEWING_PROFILE, self.currentTemporaryProfile))
    else
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

function GUI:RestoreOriginalProfile()
    if not self.originalWoundData then
        return
    end
    addonTable.FleshWoundData.currentProfile = self.originalProfile
    addonTable.woundData = self.originalWoundData
    self.originalProfile   = nil
    self.originalWoundData = nil
    self.currentTemporaryProfile = nil
    if self.frame and self.frame.ProfileButton then
        self.frame.ProfileButton:Show()
    end
    self:UpdateRegionColors()
    if self.UpdateProfileBanner then
        self:UpdateProfileBanner()
    end
end

function GUI:CreateMainFrame()
    local frame = CreateFrame("Frame", "FleshWoundFrame", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetSize(CONSTANTS.SIZES.MAIN_FRAME_WIDTH, CONSTANTS.SIZES.MAIN_FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetBackdrop(CONSTANTS.BACKDROPS.DIALOG_FRAME)
    frame:SetFrameStrata("DIALOG")
    Utils.MakeFrameDraggable(frame, function(f)
        self:SaveWindowPosition("FleshWoundFrame", f)
    end)
    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame:SetScript("OnHide", function()
        if GUI.currentTemporaryProfile then
            GUI:RestoreOriginalProfile()
        end
    end)
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
        self:OpenProfileManager()
    end)
    table.insert(UISpecialFrames, frame:GetName())
    frame.BodyImage = frame:CreateTexture(nil, "BACKGROUND")
    frame.BodyImage:SetSize(CONSTANTS.SIZES.BODY_IMAGE_WIDTH, CONSTANTS.SIZES.BODY_IMAGE_HEIGHT)
    frame.BodyImage:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.BodyImage:SetTexture(CONSTANTS.IMAGES.BODY_IMAGE)
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
    btn:SetSize(region.width, region.height)
    btn:SetPoint("BOTTOMLEFT", frame.BodyImage, "BOTTOMLEFT", region.x, region.y)
    btn:SetHighlightTexture(CONSTANTS.IMAGES.ICON_MOUSE_HIGHLIGHT)
    btn:SetScript("OnClick", function()
        self:OpenWoundDialog(region.name)
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
    frame.BodyRegions[region.name] = btn
end

function GUI:UpdateRegionColors()
    local frame = self.frame
    if not (frame and frame.BodyRegions) then return end
    local statusPriority = CONSTANTS.STATUS_PRIORITY
    for regionName, btn in pairs(frame.BodyRegions) do
        local highestID = GetHighestSeverityID(regionName)
        local r, g, b, a = GetSeverityColorByID(highestID)
        btn.overlay:SetColorTexture(r, g, b, a)
        local woundData = addonTable.woundData or {}
        local notes = woundData[regionName]
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

function GUI:OpenWoundDialog(regionName, skipCloseDialogs)
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        _G["FleshWoundProfileManager"]:Hide()
    end
    if not skipCloseDialogs then
        self:CloseAllDialogs("BodyPartDialogs")
    end
    local dialogName = "FleshWoundDialog_" .. regionName
    local displayName = L[regionName] or regionName
    local dialogTitle = string.format(L.WOUND_DETAILS, displayName)
    local dialog = CreateDialog(dialogName, dialogTitle, CONSTANTS.SIZES.GENERIC_DIALOG_WIDTH, CONSTANTS.SIZES.GENERIC_DIALOG_HEIGHT)
    dialog.regionName = regionName
    dialog:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        self:SaveWindowPosition(dialogName, f)
    end)
    self:RestoreWindowPosition(dialogName, dialog)
    dialog.ScrollFrame, dialog.ScrollChild = self:CreateScrollFrame(dialog, 15, -60, -35, 60)
    dialog.NoteEntries = {}
    if not self.currentTemporaryProfile then
        dialog.AddNoteButton = self:CreateButton(dialog, L.ADD_NOTE, 120, 30, "BOTTOMLEFT", 15, 15)
        dialog.AddNoteButton:SetScript("OnClick", function()
            dialog:Hide()
            self:OpenNoteDialog(regionName)
        end)
    end
    _G[dialogName] = dialog
    self:PopulateWoundDialog(dialog)
    dialog:Show()
end

function GUI:PopulateWoundDialog(dialog)
    local woundData = addonTable.woundData or {}
    local notes = woundData[dialog.regionName]
    if dialog.NoteEntries then
        for _, entry in ipairs(dialog.NoteEntries) do
            entry:SetParent(nil)
            entry:Hide()
        end
    end
    dialog.NoteEntries = {}
    if notes and #notes > 0 then
        local yOffset = -10
        for i, note in ipairs(notes) do
            local entry = self:CreateNoteEntry(dialog.ScrollChild, note, i, dialog.regionName)
            entry:SetPoint("TOPLEFT", 10, yOffset)
            table.insert(dialog.NoteEntries, entry)
            yOffset = yOffset - (entry:GetHeight() + 10)
        end
        dialog.ScrollChild:SetHeight(-yOffset)
    else
        local noNotesText = dialog.ScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noNotesText:SetPoint("TOPLEFT", 10, -10)
        noNotesText:SetWidth(dialog.ScrollChild:GetWidth() - 20)
        noNotesText:SetJustifyH("CENTER")
        noNotesText:SetText(L.NO_NOTES)
        table.insert(dialog.NoteEntries, noNotesText)
        dialog.ScrollChild:SetHeight(30)
    end
end

function GUI:CreateNoteEntry(parent, note, index, regionName)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetWidth(parent:GetWidth() - 20)
    entry:SetBackdrop(CONSTANTS.BACKDROPS.TOOLTIP_FRAME)
    local severityID = note.severityID or 1
    local r, g, b, a = GetSeverityColorByID(severityID)
    entry:SetBackdropColor(r, g, b, a)
    entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    entry:EnableMouse(true)
    entry:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(note.text, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    entry:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    local iconSpacing = 4
    local iconSize = 16
    local xOffset = 10
    if type(note.statusIDs) == "table" then
        for _, stID in ipairs(note.statusIDs) do
            local st = StatusesByID[stID]
            if st and st.icon then
                local iconButton = CreateFrame("Button", nil, entry, "BackdropTemplate")
                iconButton:SetSize(iconSize, iconSize)
                iconButton:SetPoint("TOPLEFT", entry, "TOPLEFT", xOffset, -10)
                local statusIcon = iconButton:CreateTexture(nil, "ARTWORK")
                statusIcon:SetAllPoints(iconButton)
                statusIcon:SetTexture(st.icon)
                iconButton:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(st.displayName, 1, 1, 1)
                    GameTooltip:Show()
                end)
                iconButton:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
                xOffset = xOffset + iconSize + iconSpacing
            end
        end
    end
    local reservedForButtons = 160
    local availableWidth = entry:GetWidth() - xOffset - reservedForButtons
    if availableWidth < 40 then
        availableWidth = 40
    end
    local noteText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    noteText:SetPoint("TOPLEFT", entry, "TOPLEFT", xOffset, -10)
    noteText:SetWidth(availableWidth)
    noteText:SetWordWrap(true)
    noteText:SetJustifyH("LEFT")
    noteText:SetJustifyV("TOP")
    noteText:SetText(note.text or "")
    local textHeight = noteText:GetStringHeight() + 20
    entry:SetHeight(textHeight)
    entry.regionName = regionName
    if not self.currentTemporaryProfile then
        local editButton = self:CreateButton(entry, L.EDIT, 70, 22, "TOPRIGHT", -80, -5)
        editButton:SetScript("OnClick", function()
            entry:GetParent():GetParent():Hide()
            self:OpenNoteDialog(entry.regionName, index)
        end)
        local deleteButton = self:CreateButton(entry, L.DELETE, 70, 22, "TOPRIGHT", -10, -5)
        deleteButton:SetScript("OnClick", function()
            if addonTable.woundData[entry.regionName] then
                table.remove(addonTable.woundData[entry.regionName], index)
                self:OpenWoundDialog(entry.regionName)
                self:UpdateRegionColors()
            end
        end)
    end
    return entry
end

function GUI:OpenNoteDialog(regionName, noteIndex)
    if not regionName then
        Utils.FW_Print("Error: regionName is nil in OpenNoteDialog", true)
        return
    end
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        UIErrorsFrame:AddMessage(L.CANNOT_OPEN_PM_WHILE_NOTE, 1.0, 0.0, 0.0, 5)
        return
    end
    self:CloseAllDialogs("BodyPartDialogs")
    local isEdit = (noteIndex ~= nil)
    local baseName = isEdit and "FleshWoundEditNoteDialog" or "FleshWoundAddNoteDialog"
    local displayRegionName = L[regionName] or regionName
    local dialogTitle = isEdit and string.format(L.EDIT_NOTE, displayRegionName)
                                 or string.format(L.ADD_NOTE, displayRegionName)
    local frameName = baseName .. "_" .. regionName
    local dialog = CreateDialog(frameName, dialogTitle, CONSTANTS.SIZES.NOTE_DIALOG_WIDTH, CONSTANTS.SIZES.NOTE_DIALOG_HEIGHT)
    dialog.regionName = regionName
    Utils.MakeFrameDraggable(dialog, function(f)
        self:SaveWindowPosition(frameName, f)
    end)
    self:RestoreWindowPosition(frameName, dialog)
    dialog.SeverityLabel, dialog.SeverityDropdown = CreateSeverityDropdown(dialog)
    dialog.StatusSelection = CreateStatusSelection(dialog)
    dialog.ScrollFrame, dialog.EditBox, dialog.CharCountLabel = CreateEditBoxWithCounter(dialog, CONSTANTS.LIMITS.MAX_NOTE_LENGTH)
    dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)
    _G[frameName] = dialog
    self:PopulateNoteDialog(dialog, noteIndex)
    dialog:Show()
    dialog.EditBox:SetFocus()
end

function GUI:PopulateNoteDialog(dialog, noteIndex)
    local isEdit = (noteIndex ~= nil)
    local woundData = addonTable.woundData or {}
    local notes = woundData[dialog.regionName]
    dialog.noteIndex = noteIndex
    dialog.selectedSeverityID = 2
    if isEdit and notes and notes[noteIndex] then
        local note = notes[noteIndex]
        local severityID = note.severityID or 2
        dialog.SeverityDropdown:SetSeverityID(severityID)
        if type(note.statusIDs) == "table" then
            dialog.StatusSelection:SetStatusIDs(note.statusIDs)
        else
            dialog.StatusSelection:SetStatusIDs({})
        end
        dialog.EditBox:SetText(note.text or "")
        local initialLen = strlenutf8(note.text or "")
        dialog.CharCountLabel:SetText(string.format(L.CHAR_COUNT, initialLen, CONSTANTS.LIMITS.MAX_NOTE_LENGTH))
    else
        dialog.SeverityDropdown:SetSeverityID(2)
        dialog.StatusSelection:SetStatusIDs({})
        dialog.EditBox:SetText("")
        dialog.CharCountLabel:SetText(string.format(L.CHAR_COUNT, 0, CONSTANTS.LIMITS.MAX_NOTE_LENGTH))
    end
    local function UpdateSaveButtonState()
        local text = SanitizeInput(dialog.EditBox:GetText() or "")
        local length = strlenutf8(text)
        dialog.CharCountLabel:SetText(string.format(L.CHAR_COUNT, length, CONSTANTS.LIMITS.MAX_NOTE_LENGTH))
        if text == "" then
            dialog.SaveButton:Disable()
            if dialog.DuplicateWarning then
                dialog.DuplicateWarning:Hide()
            end
            return
        end
        local isDuplicate = false
        for idx, existingNote in ipairs(woundData[dialog.regionName] or {}) do
            local sameNoteIndex = (isEdit and (idx == noteIndex))
            if (not sameNoteIndex) and (existingNote.text == text) then
                isDuplicate = true
                break
            end
        end
        if isDuplicate then
            dialog.SaveButton:Disable()
            if not dialog.DuplicateWarning then
                dialog.DuplicateWarning = dialog:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
                dialog.DuplicateWarning:SetPoint("TOPLEFT", dialog.EditBox, "BOTTOMLEFT", 0, -5)
                dialog.DuplicateWarning:SetText(L.NOTE_DUPLICATE)
            end
            dialog.DuplicateWarning:Show()
        else
            dialog.SaveButton:Enable()
            if dialog.DuplicateWarning then
                dialog.DuplicateWarning:Hide()
            end
        end
    end
    dialog.EditBox:SetScript("OnTextChanged", UpdateSaveButtonState)
    local function ConfirmAndSaveNote()
        local text = SanitizeInput(dialog.EditBox:GetText() or "")
        if text == "" then
            UIErrorsFrame:AddMessage(string.format(L.ERROR, L.EMPTY), 1.0, 0.0, 0.0, 5)
            return
        end
        local severityID = dialog.selectedSeverityID or 2
        local chosenStatuses = {}
        for stID in pairs(dialog.StatusSelection.selectedStatusIDs) do
            table.insert(chosenStatuses, stID)
        end
        woundData[dialog.regionName] = woundData[dialog.regionName] or {}
        if isEdit and notes and notes[noteIndex] then
            notes[noteIndex].text = text
            notes[noteIndex].severityID = severityID
            notes[noteIndex].statusIDs = chosenStatuses
        else
            table.insert(woundData[dialog.regionName], {
                text = text,
                severityID = severityID,
                statusIDs = chosenStatuses,
            })
        end
        self:UpdateRegionColors()
        dialog.EditBox:SetText("")
        dialog:Hide()
        self:OpenWoundDialog(dialog.regionName, true)
    end
    dialog.EditBox:SetScript("OnEnterPressed", function(editBoxSelf)
        if IsShiftKeyDown() then
            editBoxSelf:Insert("\n")
        else
            if dialog.SaveButton:IsEnabled() then
                ConfirmAndSaveNote()
            end
        end
    end)
    dialog.SaveButton:SetScript("OnClick", ConfirmAndSaveNote)
    dialog.CancelButton:SetScript("OnClick", function()
        dialog.EditBox:SetText("")
        dialog:Hide()
        self:OpenWoundDialog(dialog.regionName, true)
    end)
    UpdateSaveButtonState()
    dialog.EditBox:SetFocus()
end

function GUI:OpenProfileManager()
    self:CloseAllDialogs()
    local frameName = "FleshWoundProfileManager"
    local dialogTitle = L.PROFILE_MANAGER
    local dialog = CreateDialog(frameName, dialogTitle, CONSTANTS.SIZES.PROFILE_MANAGER_WIDTH, CONSTANTS.SIZES.PROFILE_MANAGER_HEIGHT)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    Utils.MakeFrameDraggable(dialog, function(f)
        self:SaveWindowPosition(frameName, f)
    end)
    self:RestoreWindowPosition(frameName, dialog)
    dialog.ScrollFrame, dialog.ScrollChild = self:CreateScrollFrame(dialog, 15, -60, -35, 100)
    dialog.ProfileEntries = {}
    dialog.CreateProfileButton = self:CreateButton(dialog, L.CREATE_PROFILE, 120, 30, "BOTTOMLEFT", 15, 15)
    dialog.CreateProfileButton:SetScript("OnClick", function()
        dialog:Hide()
        self:OpenCreateProfileDialog()
    end)
    dialog.CloseButton = self:CreateButton(dialog, L.CLOSE, 80, 30, "BOTTOMRIGHT", -15, 15)
    dialog.CloseButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    _G[frameName] = dialog
    self:PopulateProfileManager(dialog)
    dialog:Show()
end

function GUI:PopulateProfileManager(dialog)
    local profiles = addonTable.FleshWoundData.profiles
    local currentProfile = addonTable.FleshWoundData.currentProfile
    for _, entry in ipairs(dialog.ProfileEntries) do
        entry:Hide()
    end
    dialog.ProfileEntries = {}
    local yOffset = -10
    local sortedProfiles = {}
    for profileName in pairs(profiles or {}) do
        table.insert(sortedProfiles, profileName)
    end
    table.sort(sortedProfiles)
    for _, profileName in ipairs(sortedProfiles) do
        local entry = self:CreateProfileEntry(dialog.ScrollChild, profileName, currentProfile)
        entry:SetPoint("TOPLEFT", 10, yOffset)
        table.insert(dialog.ProfileEntries, entry)
        yOffset = yOffset - 50
    end
    dialog.ScrollChild:SetHeight(-yOffset)
end

function GUI:CreateProfileEntry(parent, profileName, currentProfile)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetWidth(parent:GetWidth() - 20)
    entry:SetHeight(40)
    entry:SetBackdrop(CONSTANTS.BACKDROPS.TOOLTIP_FRAME)
    if profileName == currentProfile then
        entry:SetBackdropColor(0.0, 0.5, 0.0, 0.5)
    else
        entry:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
    end
    entry:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", entry, "LEFT", 10, 0)
    nameText:SetText(profileName)
    local charProfiles = addonTable.FleshWoundData.charProfiles or {}
    local usageCount = 0
    for _, pName in pairs(charProfiles) do
        if pName == profileName then
            usageCount = usageCount + 1
        end
    end
    local iconSize = 16
    local iconTexture = entry:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(iconSize, iconSize)
    iconTexture:SetTexture(CONSTANTS.ICONS.BANDAGE)
    iconTexture:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
    local countText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("LEFT", iconTexture, "RIGHT", 2, 0)
    countText:SetText(tostring(usageCount))
    local selectButton = self:CreateButton(entry, L.SELECT, 80, 24, "RIGHT", -10, 0)
    selectButton:SetScript("OnClick", function()
        addonTable.Data:SwitchProfile(profileName)
        self:UpdateRegionColors()
        self:OpenProfileManager()
    end)
    local deleteButton = self:CreateButton(entry, L.DELETE, 80, 24, "RIGHT", selectButton, "LEFT", -5, 0)
    deleteButton:SetScript("OnClick", function()
        StaticPopup_Show("FW_DELETE_PROFILE_CONFIRM", profileName, nil, profileName)
    end)
    if profileName == currentProfile then
        deleteButton:Disable()
    end
    local renameButton = self:CreateButton(entry, L.RENAME, 80, 24, "RIGHT", deleteButton, "LEFT", -5, 0)
    renameButton:SetScript("OnClick", function()
        self:OpenRenameProfileDialog(profileName)
    end)
    return entry
end

function GUI:OpenCreateProfileDialog()
    self:CloseAllDialogs()
    local frameName = "FleshWoundCreateProfileDialog"
    local dialogTitle = L.CREATE_PROFILE
    local dialog = CreateDialog(frameName, dialogTitle, CONSTANTS.SIZES.CREATE_PROFILE_WIDTH, CONSTANTS.SIZES.CREATE_PROFILE_HEIGHT)
    dialog:EnableMouseWheel(true)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    Utils.MakeFrameDraggable(dialog, function(f)
        self:SaveWindowPosition(frameName, f)
    end)
    self:RestoreWindowPosition(frameName, dialog)
    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
    nameLabel:SetText(L.PROFILE_NAME)
    local nameEditBox, charCountLabel = CreateSingleLineEditBoxWithCounter(dialog, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH)
    nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    dialog.nameEditBox = nameEditBox
    dialog.charCountLabel = charCountLabel
    dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)
    dialog.SaveButton:SetText(L.CREATE)
    _G[frameName] = dialog
    local function UpdateCreateButtonState()
        local text = dialog.nameEditBox:GetText()
        local profileName = SanitizeInput(text)
        local length = strlenutf8(text)
        dialog.charCountLabel:SetText(string.format(L.CHAR_COUNT, length, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH))
        if profileName == "" or (addonTable.FleshWoundData.profiles and addonTable.FleshWoundData.profiles[profileName]) then
            dialog.SaveButton:Disable()
        else
            dialog.SaveButton:Enable()
        end
    end
    dialog.nameEditBox:SetText("")
    dialog.charCountLabel:SetText(string.format(L.CHAR_COUNT, 0, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH))
    dialog.SaveButton:Disable()
    dialog.nameEditBox:SetScript("OnTextChanged", UpdateCreateButtonState)
    dialog.SaveButton:SetScript("OnClick", function()
        local profileName = SanitizeInput(dialog.nameEditBox:GetText())
        addonTable.Data:CreateProfile(profileName)
        dialog:Hide()
        self:OpenProfileManager()
    end)
    dialog.CancelButton:SetScript("OnClick", function()
        dialog:Hide()
        self:OpenProfileManager()
    end)
    dialog:Show()
end

function GUI:OpenRenameProfileDialog(oldProfileName)
    local frameName = "FleshWoundRenameProfileDialog"
    local dialogTitle = L.RENAME_PROFILE
    if _G["FleshWoundProfileManager"] and _G["FleshWoundProfileManager"]:IsShown() then
        _G["FleshWoundProfileManager"]:Hide()
    end
    local dialog = _G[frameName]
    if not dialog then
        dialog = CreateDialog(frameName, dialogTitle, CONSTANTS.SIZES.RENAME_PROFILE_WIDTH, CONSTANTS.SIZES.RENAME_PROFILE_HEIGHT)
        Utils.MakeFrameDraggable(dialog, function(f)
            self:SaveWindowPosition(frameName, f)
        end)
        local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, -60)
        nameLabel:SetText(L.NEW_NAME)
        local nameEditBox, charCountLabel = CreateSingleLineEditBoxWithCounter(dialog, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH)
        nameEditBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
        dialog.nameEditBox = nameEditBox
        dialog.charCountLabel = charCountLabel
        dialog.SaveButton, dialog.CancelButton = CreateSaveCancelButtons(dialog)
        dialog.SaveButton:SetText(L.RENAME)
        _G[frameName] = dialog
    end
    self:RestoreWindowPosition(frameName, dialog)
    local function UpdateRenameButtonState()
        local text = dialog.nameEditBox:GetText()
        local newProfileName = SanitizeInput(text)
        local length = strlenutf8(text)
        dialog.charCountLabel:SetText(string.format(L.CHAR_COUNT, length, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH))
        if newProfileName == "" or (addonTable.FleshWoundData.profiles and addonTable.FleshWoundData.profiles[newProfileName]) or newProfileName == oldProfileName then
            dialog.SaveButton:Disable()
        else
            dialog.SaveButton:Enable()
        end
    end
    dialog.nameEditBox:SetText(oldProfileName)
    local initialLength = strlenutf8(oldProfileName)
    dialog.charCountLabel:SetText(string.format(L.CHAR_COUNT, initialLength, CONSTANTS.LIMITS.MAX_PROFILE_NAME_LENGTH))
    dialog.SaveButton:Disable()
    dialog.nameEditBox:SetScript("OnTextChanged", UpdateRenameButtonState)
    dialog.SaveButton:SetScript("OnClick", function()
        local newProfileName = SanitizeInput(dialog.nameEditBox:GetText())
        addonTable.Data:RenameProfile(oldProfileName, newProfileName)
        dialog:Hide()
        self:OpenProfileManager()
    end)
    dialog.CancelButton:SetScript("OnClick", function()
        dialog:Hide()
        self:OpenProfileManager()
    end)
    dialog:Show()
end

function GUI:CloseAllDialogs(dialogType)
    local dialogsToClose = {}
    if dialogType == "BodyPartDialogs" then
        dialogsToClose = { "FleshWoundDialog_" }
    else
        dialogsToClose = {
            "FleshWoundDialog_",
            "FleshWoundAddNoteDialog_",
            "FleshWoundEditNoteDialog_",
            "FleshWoundProfileManager",
            "FleshWoundCreateProfileDialog",
            "FleshWoundRenameProfileDialog",
        }
    end
    for _, framePrefix in ipairs(dialogsToClose) do
        for frameName, frameObj in pairs(_G) do
            if type(frameName) == "string" and frameName:match("^" .. framePrefix)
               and type(frameObj) == "table" and frameObj.Hide then
                frameObj:Hide()
            end
        end
    end
end

return GUI
