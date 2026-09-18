local ADDON_NAME = ...

local DEFAULTS = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    scale = 1,
}

local MIN_SCALE = 0.75
local MAX_SCALE = 2.50
local SCALE_STEP = 0.10
local BORDER_COLOR = 0.72
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

local button

local function ApplyBlackBackdrop(frame, edgeSize)
    frame:SetBackdrop({
        bgFile = WHITE_TEXTURE,
        edgeFile = WHITE_TEXTURE,
        edgeSize = edgeSize,
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetBackdropBorderColor(BORDER_COLOR, BORDER_COLOR, BORDER_COLOR, 1)
end

local function InitializeDatabase()
    if type(DevReloadDB) ~= "table" then
        DevReloadDB = {}
    end

    for key, value in pairs(DEFAULTS) do
        if DevReloadDB[key] == nil then
            DevReloadDB[key] = value
        end
    end

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
    label:SetTextColor(1, 1, 1, 1)
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
    closeLabel:SetTextColor(1, 0.1, 0.1, 1)
    close:SetFontString(closeLabel)
    close:SetScript("OnClick", function()
        SetShown(false)
    end)
    close:SetScript("OnMouseWheel", function(_, delta)
        ResizeFromWheel(delta)
    end)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.95, 0.95, 0.95, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(BORDER_COLOR, BORDER_COLOR, BORDER_COLOR, 1)
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

local function CreateSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "DevReload"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("DevReload")

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    description:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
    description:SetJustifyH("LEFT")
    description:SetText("A convenient reload button for addon developers, saving you from repeatedly typing reload commands in chat. It is designed to be shown only when needed, not left on screen during normal play.")

    local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    help:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20)
    help:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
    help:SetJustifyH("LEFT")
    help:SetTextColor(1, 1, 1, 1)
    help:SetText("Drag with the left mouse button to move. Scroll the mouse wheel over the button to resize. Click Reload UI to reload the interface. Use /dr or /devreload to show it again after closing it.")

    local function CreatePanelButton(text, point, x, onClick)
        local settingsButton = CreateFrame("Button", nil, panel, "BackdropTemplate")
        settingsButton:SetSize(180, 26)
        settingsButton:SetPoint(point, panel, "TOP", x, -128)
        settingsButton:SetNormalFontObject("GameFontNormal")
        settingsButton:SetText(text)
        settingsButton:GetFontString():SetTextColor(1, 1, 1, 1)
        settingsButton:SetScript("OnClick", onClick)
        ApplyBlackBackdrop(settingsButton, 1)
    end

    CreatePanelButton("Show Reload Button", "TOPRIGHT", -6, function()
        SetShown(true)
    end)
    CreatePanelButton("Reset Position & Size", "TOPLEFT", 6, ResetPosition)

    if Settings and Settings.RegisterCanvasLayoutCategory then
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
    CreateSettingsPanel()
    eventFrame:UnregisterEvent("ADDON_LOADED")

    SLASH_DEVRELOAD1 = "/dr"
    SLASH_DEVRELOAD2 = "/devreload"
    SlashCmdList.DEVRELOAD = function()
        SetShown(true)
    end
end)
