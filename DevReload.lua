local ADDON_NAME = ...

local TITLE = "DevReload"
local VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "1.1.0"
local ICON = "Interface\\AddOns\\DevReload\\DevReloadDRIcon.png"
local LDB_NAME = "DevReload"
local PINK_HEX = "FFFF8DA1"
local PINK_R, PINK_G, PINK_B = 1, 0.553, 0.631

local DEFAULTS = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    scale = 1,
    showMinimapButton = true,
    minimap = { minimapPos = 225 },
}

local MIN_SCALE = 0.75
local MAX_SCALE = 2.50
local SCALE_STEP = 0.10
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

local button
local ldbIcon

local function ApplyBlackBackdrop(frame, edgeSize)
    frame:SetBackdrop({
        bgFile = WHITE_TEXTURE,
        edgeFile = WHITE_TEXTURE,
        edgeSize = edgeSize,
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetBackdropBorderColor(PINK_R, PINK_G, PINK_B, 1)
end

local function InitializeDatabase()
    if type(DevReloadDB) ~= "table" then
        DevReloadDB = {}
    end

    for key, value in pairs(DEFAULTS) do
        if key ~= "minimap" and DevReloadDB[key] == nil then
            DevReloadDB[key] = value
        end
    end
    DevReloadDB.showMinimapButton = DevReloadDB.showMinimapButton ~= false
    DevReloadDB.minimap = type(DevReloadDB.minimap) == "table" and DevReloadDB.minimap or {
        minimapPos = DEFAULTS.minimap.minimapPos,
    }
    DevReloadDB.minimap.minimapPos = tonumber(DevReloadDB.minimap.minimapPos) or DEFAULTS.minimap.minimapPos

    if type(DevReloadCharDB) ~= "table" then
        DevReloadCharDB = {}
    end
    if type(DevReloadCharDB.shown) ~= "boolean" then
        DevReloadCharDB.shown = false
    end
end

local function SavePosition()
    local point, _, relativePoint, x, y = button:GetPoint(1)
    DevReloadDB.point = point
    DevReloadDB.relativePoint = relativePoint
    DevReloadDB.x = x
    DevReloadDB.y = y
end

local function SetShown(shown)
    shown = shown and true or false
    DevReloadCharDB.shown = shown
    button:SetShown(shown)
end

local function ResetPosition()
    DevReloadDB.point = DEFAULTS.point
    DevReloadDB.relativePoint = DEFAULTS.relativePoint
    DevReloadDB.x = DEFAULTS.x
    DevReloadDB.y = DEFAULTS.y
    DevReloadDB.scale = DEFAULTS.scale

    button:ClearAllPoints()
    button:SetPoint(DEFAULTS.point, UIParent, DEFAULTS.relativePoint, DEFAULTS.x, DEFAULTS.y)
    button:SetScale(DEFAULTS.scale)
    SetShown(true)
end

local function ResizeFromWheel(delta)
    local newScale = DevReloadDB.scale + (delta > 0 and SCALE_STEP or -SCALE_STEP)
    newScale = math.max(MIN_SCALE, math.min(MAX_SCALE, newScale))
    DevReloadDB.scale = math.floor((newScale * 100) + 0.5) / 100

    -- Preserve the button's visual center. Changing a frame's scale also scales
    -- its anchor offsets, which otherwise makes a freely positioned frame move.
    local centerX, centerY = button:GetCenter()
    local oldEffectiveScale = button:GetEffectiveScale()
    local screenX = centerX * oldEffectiveScale
    local screenY = centerY * oldEffectiveScale

    button:SetScale(DevReloadDB.scale)

    local newEffectiveScale = button:GetEffectiveScale()
    button:ClearAllPoints()
    button:SetPoint(
        "CENTER",
        UIParent,
        "BOTTOMLEFT",
        screenX / newEffectiveScale,
        screenY / newEffectiveScale
    )
    SavePosition()
end

local function CreateButton()
    button = CreateFrame("Button", "DevReloadButton", UIParent, "BackdropTemplate")
    button:SetSize(150, 52)
    button:SetFrameStrata("DIALOG")
    button:SetClampedToScreen(true)
    button:SetMovable(true)
    button:EnableMouseWheel(true)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    ApplyBlackBackdrop(button, 2)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER", -5, 0)
    label:SetText("Reload UI")
    label:SetTextColor(PINK_R, PINK_G, PINK_B, 1)
    button:SetFontString(label)

    local close = CreateFrame("Button", nil, button, "BackdropTemplate")
    close:SetSize(25, 25)
    close:SetPoint("TOPRIGHT", -3, -3)
    close:SetFrameLevel(button:GetFrameLevel() + 5)
    close:EnableMouseWheel(true)
    ApplyBlackBackdrop(close, 1)

    local closeLabel = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeLabel:SetPoint("CENTER", 0, 1)
    closeLabel:SetText("X")
    closeLabel:SetTextColor(PINK_R, PINK_G, PINK_B, 1)
    close:SetFontString(closeLabel)
    close:SetScript("OnClick", function()
        SetShown(false)
    end)
    close:SetScript("OnMouseWheel", function(_, delta)
        ResizeFromWheel(delta)
    end)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(PINK_R, PINK_G, PINK_B, 0.12)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, 1)
    end)
    button:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:StartMoving()
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.isDragging = false
        self.justDragged = true
        SavePosition()
        C_Timer.After(0, function()
            self.justDragged = false
        end)
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" and not self.isDragging and not self.justDragged then
            ReloadUI()
        end
    end)
    button:SetScript("OnMouseWheel", function(_, delta)
        ResizeFromWheel(delta)
    end)

    button:SetPoint(DevReloadDB.point, UIParent, DevReloadDB.relativePoint, DevReloadDB.x, DevReloadDB.y)
    button:SetScale(DevReloadDB.scale)
    button:SetShown(DevReloadCharDB.shown)
end

local function UpdateMinimapButtonVisibility()
    if not ldbIcon then
        return
    end

    DevReloadDB.minimap.hide = not DevReloadDB.showMinimapButton
    if DevReloadDB.showMinimapButton then
        ldbIcon:Show(LDB_NAME)
    else
        ldbIcon:Hide(LDB_NAME)
    end
end

local function CreateMinimapButton()
    ldbIcon = LibStub("LibDBIcon-1.0")
    local launcher = LibStub("LibDataBroker-1.1"):NewDataObject(LDB_NAME, {
        type = "launcher",
        label = TITLE,
        text = TITLE,
        icon = ICON,
        OnClick = function()
            SetShown(not button:IsShown())
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(TITLE, PINK_R, PINK_G, PINK_B)
            tooltip:AddLine("Click to show or hide the reload button.", 1, 1, 1)
        end,
    })

    DevReloadDB.minimap.hide = not DevReloadDB.showMinimapButton
    ldbIcon:Register(LDB_NAME, launcher, DevReloadDB.minimap)
end

local function CreatePanelButton(parent, text, width, onClick)
    local settingsButton = CreateFrame("Button", nil, parent, "BackdropTemplate")
    settingsButton:SetSize(width, 28)
    settingsButton:SetNormalFontObject("GameFontHighlight")
    settingsButton:SetText(text)
    settingsButton:SetScript("OnClick", onClick)
    settingsButton:SetHighlightTexture(WHITE_TEXTURE)
    settingsButton:GetHighlightTexture():SetVertexColor(PINK_R, PINK_G, PINK_B, 0.22)
    settingsButton:SetPushedTexture(WHITE_TEXTURE)
    settingsButton:GetPushedTexture():SetVertexColor(PINK_R, PINK_G, PINK_B, 0.35)
    ApplyBlackBackdrop(settingsButton, 1)
    return settingsButton
end

local function CreateSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = TITLE

    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(128, 128)
    icon:SetPoint("TOP", 0, -28)
    icon:SetTexture(ICON)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -12)
    title:SetText("|c" .. PINK_HEX .. TITLE .. "|r  |cffaaaaaav" .. VERSION .. "|r")

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOP", title, "BOTTOM", 0, -10)
    description:SetWidth(520)
    description:SetJustifyH("CENTER")
    description:SetText("A convenient reload button for addon developers.")

    local minimapCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    minimapCheck:SetPoint("TOP", description, "BOTTOM", -92, -18)
    minimapCheck:SetChecked(DevReloadDB.showMinimapButton)
    minimapCheck:SetScript("OnClick", function(self)
        DevReloadDB.showMinimapButton = self:GetChecked() and true or false
        UpdateMinimapButtonVisibility()
    end)

    local minimapLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    minimapLabel:SetPoint("LEFT", minimapCheck, "RIGHT", 3, 0)
    minimapLabel:SetText("Show minimap button")

    local showButton = CreatePanelButton(panel, "Show Reload Button", 180, function()
        SetShown(true)
    end)
    showButton:SetPoint("TOPRIGHT", panel, "TOP", -8, -280)

    local resetButton = CreatePanelButton(panel, "Reset Position & Size", 180, ResetPosition)
    resetButton:SetPoint("TOPLEFT", panel, "TOP", 8, -280)

    local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    help:SetPoint("TOP", panel, "TOP", 0, -326)
    help:SetWidth(520)
    help:SetJustifyH("CENTER")
    help:SetText("Drag the reload button to move it. Scroll over it to resize. Use /dr or /devreload to show it again after closing it.")

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, loadedAddon)
    if loadedAddon ~= ADDON_NAME then
        return
    end

    InitializeDatabase()
    CreateButton()
    CreateMinimapButton()
    CreateSettingsPanel()
    eventFrame:UnregisterEvent("ADDON_LOADED")

    SLASH_DEVRELOAD1 = "/dr"
    SLASH_DEVRELOAD2 = "/devreload"
    SlashCmdList.DEVRELOAD = function()
        SetShown(true)
    end
end)
