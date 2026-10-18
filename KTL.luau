local Isotopia = {}
local cloneref = cloneref or function(o) return o end
local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local GuiService = cloneref(game:GetService("GuiService"))
local Debris = cloneref(game:GetService('Debris'))
local Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))()

Isotopia.Theme = {
    background = Color3.fromRGB(24, 30, 46),
inset = Color3.fromRGB(30, 38, 58),
    LinesAIR = Color3.fromRGB(52, 66, 89),
    surface = Color3.fromRGB(28, 20, 24),
    stroke = Color3.fromRGB(170, 45, 55),

    accent = Color3.fromRGB(255, 40, 40),
    accentAlt = Color3.fromRGB(255, 95, 95),

    text = Color3.fromRGB(225, 225, 225),
    textMuted = Color3.fromRGB(190, 165, 170),

    mainColor = Color3.fromRGB(255, 40, 40)
}

local function getSafeParent()
    local success, parent = pcall(function()
        if gethui then
            return gethui()
        end
        return CoreGui
    end)
    return success and parent or CoreGui
end

local function cleanupOldUI(uiName)
    local locations = {}
    
    if gethui then
        local success, gethuiParent = pcall(gethui)
        if success and gethuiParent then
            table.insert(locations, gethuiParent)
        end
    end
    table.insert(locations, CoreGui)
    
    local player = Players.LocalPlayer
    if player and player:FindFirstChild("PlayerGui") then
        table.insert(locations, player.PlayerGui)
    end
    if game:FindFirstChild("StarterGui") then
        table.insert(locations, game.StarterGui)
    end
    for _, parent in ipairs(locations) do
        local oldUI = parent:FindFirstChild(uiName)
        if oldUI then
            pcall(function()
                oldUI:Destroy()
            end)
        end
    end
end

cleanupOldUI('Isotopia')
if not isfolder("Isotopia") then
    makefolder("Isotopia")
end

local Config = {
    save = function(self, file_name, config)
        if not config then return end
        
        local success_save, result = pcall(function()
            if not isfolder("Isotopia") then
                makefolder("Isotopia")
            end
            
            config._flags = config._flags or {}
            config._keybinds = config._keybinds or {}
            config._library = config._library or {}
            
            local flags = HttpService:JSONEncode(config)
            writefile('Isotopia/'..file_name..'.json', flags)
        end)
    
        if not success_save then
            warn('[Config] Failed to save config:', result)
        end
    end,
    
    load = function(self, file_name)
        local success_load, result = pcall(function()
            if not isfile('Isotopia/'..file_name..'.json') then
                return {
                    _flags = {},
                    _keybinds = {},
                    _library = {}
                }
            end
            
            local flags = readfile('Isotopia/'..file_name..'.json')
            
            if not flags or flags == "" then
                return {
                    _flags = {},
                    _keybinds = {},
                    _library = {}
                }
            end

            return HttpService:JSONDecode(flags)
        end)
    
        if not success_load then
            warn('[Config] Failed to load config:', result)
            return {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end
    
        if not result then
            return {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end
    
        result._flags = result._flags or {}
        result._keybinds = result._keybinds or {}
        result._library = result._library or {}
    
        return result
    end
}

local Util = {
    map = function(self, value, in_minimum, in_maximum, out_minimum, out_maximum)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    
    viewport_point_to_world = function(self, location, distance)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    
    get_offset = function(self)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y
        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}

local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
    
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end
    
            value:Disconnect()
        end
    end
}, Connections)

local function getIcon(iconName)
    if type(iconName) == "string" then
        if iconName:match("^rbxassetid://%d+$") then
            return iconName
        end
        if Lucide and Lucide[iconName] then
            return Lucide[iconName]
        end
    end
    return "rbxassetid://107819132007001"
end

local sizePresets = {
    { w = 500, h = 350, moduleWidth = 155, innerWidth = 121, radius = 8, offset = 138 },
    { w = 550, h = 400, moduleWidth = 175, innerWidth = 141, radius = 8 , offset = 148 },
    { w = 600, h = 420, moduleWidth = 195, innerWidth = 161, radius = 9, offset = 158},
    { w = 648, h = 429, moduleWidth = 221, innerWidth = 187, radius = 9, offset = 168 },
    { w = 650, h = 450, moduleWidth = 218, innerWidth = 184, radius = 9, offset = 178 },
    { w = 698, h = 479, moduleWidth = 241, innerWidth = 207, radius = 10, offset = 178 },
    { w = 750, h = 500, moduleWidth = 261, innerWidth = 227, radius = 10, offset = 188 },
    { w = 800, h = 530, moduleWidth = 281, innerWidth = 247, radius = 11, offset = 198},
    { w = 850, h = 560, moduleWidth = 301, innerWidth = 267, radius = 11, offset = 208},
    { w = 900, h = 600, moduleWidth = 321, innerWidth = 287, radius = 12, offset = 218 },
    { w = 950, h = 630, moduleWidth = 341, innerWidth = 307, radius = 12, offset = 228 },
    { w = 1000, h = 660, moduleWidth = 361, innerWidth = 327, radius = 13, offset = 238},
}

local function getPreset(w, h)
    local tolerance = 10
    for _, preset in ipairs(sizePresets) do
        if math.abs(w - preset.w) <= tolerance and math.abs(h - preset.h) <= tolerance then
            return preset
        end
    end
    local mw = math.floor((w - 196) / 2)
    return {
        moduleWidth = mw,
        innerWidth = mw - 34,
        radius = 10,
        offset = 168
    }
end

function Isotopia:Window(settings)
    local Window = {
        _originalTitle = settings.Title or 'Isotopia',
        _minimizedTitle = nil,
        _config = Config:load(tostring(game.GameId)),
        _choosing_keybind = false,
        _device = nil,
        _ui_open = true,
        _ui_scale = 1,
        _ui_loaded = false,
        _ui = nil,
        _dragging = false,
        _drag_start = nil,
        _container_position = nil,
        _loaded = false,
        _tab = 0,
        _tabs = {},
        _notifications = {},
        _mainColor = settings.MainColor or Isotopia.Theme.mainColor,
        _transparent = settings.Transparent or false,
        _size = settings.Size or UDim2.fromOffset(698, 479),
        _spinning = settings.Spinning or false,
        _animationSettings = settings.AnimatedTitle or {
            AnimationColor = settings.MainColor,
            AnimationSide = "Right",
            AnimationSpeed = 5
        }
    }
    Window._config._flags = Window._config._flags or {}
    Window._config._keybinds = Window._config._keybinds or {}
    Window._config._library = Window._config._library or {}
    
    Isotopia._current_window = Window
    
    if settings.MainColor then
        Isotopia.Theme.mainColor = settings.MainColor
        Isotopia.Theme.accent = settings.MainColor
    end
    
    if settings.AnimatedTitle and settings.AnimatedTitle.AnimationColor then
        Isotopia.Theme.accentAlt = settings.AnimatedTitle.AnimationColor
    end
    
    Window._themeElements = {
        frames = {},
        labels = {},
        images = {},
        strokes = {},
        gradients = {},
        toggles = {}
    }
    table.insert(Window._themeElements.frames, Pin)
    table.insert(Window._themeElements.images, Icon)
    table.insert(Window._themeElements.gradients, UIGradient)
    
    Window.__index = Window

    local old_Isotopia = CoreGui:FindFirstChild('Isotopia')
    if old_Isotopia then
        Debris:AddItem(old_Isotopia, 0)
    end

    local IsotopiaUI = Instance.new('ScreenGui')
    IsotopiaUI.ResetOnSpawn = false
    IsotopiaUI.Name = 'Isotopia'
    IsotopiaUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    IsotopiaUI.Parent = getSafeParent()
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0
    Container.BackgroundColor3 = settings.BackgroundColor or Isotopia.Theme.inset
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = settings.Size or UDim2.fromOffset(698, 479)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = IsotopiaUI
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, settings.Corner or 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Thickness = 1.25
    UIStroke.Transparency = settings.Transparent and 0.5 or 0.2
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    local ContainerGradient = Instance.new('UIGradient')
    ContainerGradient.Rotation = 270
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, (settings.BackgroundColor or Isotopia.Theme.inset)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(
            math.min(255, (settings.BackgroundColor or Isotopia.Theme.inset).R * 255 + 50),
            math.min(255, (settings.BackgroundColor or Isotopia.Theme.inset).G * 255 + 50),
            math.min(255, (settings.BackgroundColor or Isotopia.Theme.inset).B * 255 + 50)
        )),
        ColorSequenceKeypoint.new(1, (settings.BackgroundColor or Isotopia.Theme.inset))
    }
    ContainerGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0)
    }
    ContainerGradient.Parent = Container

    local Shine = Instance.new('Frame')
    Shine.Name = 'Shine'
    Shine.AnchorPoint = Vector2.new(0.5, 0.5)
    Shine.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shine.Size = UDim2.new(2, 0, 2, 0)
    Shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Shine.BorderSizePixel = 0
    Shine.ZIndex = 50
    Shine.Parent = Container

    local ShineGradient = Instance.new('UIGradient')
    ShineGradient.Rotation = 35
    ShineGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    ShineGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.45, 1),
        NumberSequenceKeypoint.new(0.5, 0.88),
        NumberSequenceKeypoint.new(0.55, 1),
        NumberSequenceKeypoint.new(1, 1)
    }
    ShineGradient.Offset = Vector2.new(-1, 0)
    ShineGradient.Parent = Shine

    task.spawn(function()
        while Shine.Parent do
            ShineGradient.Offset = Vector2.new(-1, 0)
            TweenService:Create(ShineGradient, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Offset = Vector2.new(1, 0)
            }):Play()
            task.wait(4.5)
        end
    end)
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = Window._size
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container
    
    local TabsFrame = Instance.new('ScrollingFrame')
    TabsFrame.ScrollBarImageTransparency = 1
    TabsFrame.ScrollBarThickness = 0
    TabsFrame.Name = 'Tabs'
     local tabsHeight = Window._searchBarVisible and (Window._size.Y.Offset - 60 - 10) or (Window._size.Y.Offset - 78)
    TabsFrame.Size = UDim2.new(0, 129, 0, tabsHeight)
    TabsFrame.Selectable = false
    TabsFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
    TabsFrame.BackgroundTransparency = 1
    TabsFrame.Position = Window._searchBarVisible and UDim2.new(0.026097271591424942, 0, 0, 55) or UDim2.new(0.026097271591424942, 0, 0.141, 0)
    TabsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TabsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TabsFrame.BorderSizePixel = 0
    TabsFrame.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    TabsFrame.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = TabsFrame
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Window._mainColor
    ClientName.TextTransparency = 0
    ClientName.Text = settings.Title or 'Isotopia'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 100, 0, 13)  
    ClientName.TextTruncate = Enum.TextTruncate.AtEnd
    ClientName.ClipsDescendants = true
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.0560000017285347, 0, 0.054999999701976776, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 13
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler
    
    local UIGradient = Instance.new('UIGradient')
UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Window._animationSettings.AnimationColor or Window._mainColor),
        ColorSequenceKeypoint.new(0.45, Isotopia.Theme.accentAlt),
        ColorSequenceKeypoint.new(1, Window._animationSettings.AnimationColor or Window._mainColor)
    }
    UIGradient.Offset = Vector2.new(-1, 0)
    UIGradient.Parent = ClientName

    local startOffset = Window._animationSettings.AnimationSide == "Left" and Vector2.new(-1, 0) or Vector2.new(1, 0)
    local targetOffset = Window._animationSettings.AnimationSide == "Left" and Vector2.new(1, 0) or Vector2.new(-1, 0)
    UIGradient.Offset = startOffset
    TweenService:Create(UIGradient, TweenInfo.new(Window._animationSettings.AnimationSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {
        Offset = targetOffset
    }):Play()
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026000000536441803, 0, 0.141, 0)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundTransparency = 1
    Pin.BackgroundColor3 = Window._mainColor
    Pin.Parent = Handler
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = getIcon(settings.Icon)
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.02500000037252903, 0, 0.054999999701976776, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon.Parent = Handler

    if Window._spinning then
        TweenService:Create(Icon, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
            Rotation = 360
        }):Play()
    end
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.23499999940395355, 0, 0, 0)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, Window._size.Y.Offset)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Isotopia.Theme.stroke
    Divider.Parent = Handler

    local HorizontalDivider = Instance.new('Frame')
    HorizontalDivider.Name = 'HorizontalDivider'
    HorizontalDivider.BorderSizePixel = 0
    HorizontalDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HorizontalDivider.BackgroundTransparency = 1
    HorizontalDivider.Size = UDim2.new(0, Window._size.X.Offset, 0, 1)
    HorizontalDivider.Position = UDim2.new(0, 0, 0.099, 0)
    HorizontalDivider.Parent = Handler

    local HorizontalGradient = Instance.new('UIGradient')
    HorizontalGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,    Window._mainColor),
        ColorSequenceKeypoint.new(0.25, Window._animationSettings.AnimationColor or Isotopia.Theme.accentAlt),
        ColorSequenceKeypoint.new(0.5,  Window._mainColor),
        ColorSequenceKeypoint.new(0.75, Window._animationSettings.AnimationColor or Isotopia.Theme.accentAlt),
        ColorSequenceKeypoint.new(1,    Window._mainColor),
    }
    HorizontalGradient.Transparency =      NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0.3),
    }
    HorizontalGradient.Offset = Vector2.new(-1, 0)
    HorizontalGradient.Parent = HorizontalDivider

    local startOffsetHD = Window._animationSettings.AnimationSide == "Left" and Vector2.new(-1, 0) or Vector2.new(1, 0)
    local targetOffsetHD = Window._animationSettings.AnimationSide == "Left" and Vector2.new(1, 0) or Vector2.new(-1, 0)
    HorizontalGradient.Offset = startOffsetHD
    TweenService:Create(HorizontalGradient, TweenInfo.new(Window._animationSettings.AnimationSpeed * 3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {
        Offset = targetOffsetHD
    }):Play()
    
    if settings.HideSearchBar == false then
    Divider.Visible = false
    HorizontalDivider.BackgroundTransparency = 0

    local SideDivider = Instance.new('Frame')
    SideDivider.Name = 'SideDivider'
    SideDivider.Size = UDim2.new(0, 2, 0, 300)
    SideDivider.Position = UDim2.new(0.235, 0, 0.5, 0)
    SideDivider.AnchorPoint = Vector2.new(0.5, 0.5)
    SideDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SideDivider.BorderSizePixel = 0
    SideDivider.Parent = Handler
    
    local SideDividerCorner = Instance.new('UICorner')
    SideDividerCorner.CornerRadius = UDim.new(0, 2)
    SideDividerCorner.Parent = SideDivider

    local SideDividerGradient = Instance.new('UIGradient')
    SideDividerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, (settings.BackgroundColor or Isotopia.Theme.inset)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(
            math.min(255, (settings.BackgroundColor or Isotopia.Theme.inset).R * 255 + 50),
            math.min(255, (settings.BackgroundColor or Isotopia.Theme.inset).G * 255 + 50),
            math.min(255, (settings.BackgroundColor or Isotopia.Theme.inset).B * 255 + 50)
        )),
        ColorSequenceKeypoint.new(1, (settings.BackgroundColor or Isotopia.Theme.inset))
    }
    SideDividerGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0)
    }
    SideDividerGradient.Rotation = 90
    SideDividerGradient.Offset = Vector2.new(-1, 0)
    SideDividerGradient.Parent = SideDivider

    local startOffsetSD = Window._animationSettings.AnimationSide == "Left" and Vector2.new(-1, 0) or Vector2.new(1, 0)
    local targetOffsetSD = Window._animationSettings.AnimationSide == "Left" and Vector2.new(1, 0) or Vector2.new(-1, 0)
    SideDividerGradient.Offset = startOffsetSD
    TweenService:Create(SideDividerGradient, TweenInfo.new(Window._animationSettings.AnimationSpeed * 3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {
        Offset = targetOffsetSD
    }):Play()
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler

    local PlayerAvatar = Instance.new('ImageLabel')
    PlayerAvatar.Name = 'PlayerAvatar'
    PlayerAvatar.Size = UDim2.fromOffset(36, 36)
    PlayerAvatar.Position = UDim2.new(0.026, 0, 0, 0)
    PlayerAvatar.AnchorPoint = Vector2.new(0, 1)
    PlayerAvatar.Position = UDim2.new(0.026, 0, 1, -12)
    PlayerAvatar.BackgroundColor3 = Isotopia.Theme.surface
    PlayerAvatar.BackgroundTransparency = 0
    PlayerAvatar.BorderSizePixel = 0
    PlayerAvatar.ScaleType = Enum.ScaleType.Fit
    PlayerAvatar.Image = ''
    PlayerAvatar.ZIndex = 5
    PlayerAvatar.Parent = Handler

    local PlayerAvatarCorner = Instance.new('UICorner')
    PlayerAvatarCorner.CornerRadius = UDim.new(0, 6)
    PlayerAvatarCorner.Parent = PlayerAvatar

    local PlayerUsername = Instance.new('TextLabel')
    PlayerUsername.Name = 'PlayerUsername'
    PlayerUsername.Size = UDim2.fromOffset(110, 14)
    PlayerUsername.Position = UDim2.new(0.026, 50, 1, -30)
    PlayerUsername.AnchorPoint = Vector2.new(0, 1)
    PlayerUsername.BackgroundTransparency = 1
    PlayerUsername.BorderSizePixel = 0
    PlayerUsername.TextColor3 = Isotopia.Theme.text
    PlayerUsername.TextTransparency = 0.2
    PlayerUsername.Text = '@' .. Players.LocalPlayer.Name
    PlayerUsername.TextSize = 12
    PlayerUsername.TextXAlignment = Enum.TextXAlignment.Left
    PlayerUsername.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    PlayerUsername.ZIndex = 5
    PlayerUsername.Parent = Handler

    local PlayerSubtext = Instance.new('TextLabel')
    PlayerSubtext.Name = 'PlayerSubtext'
    PlayerSubtext.Size = UDim2.fromOffset(110, 12)
    PlayerSubtext.Position = UDim2.new(0.026, 50, 1, -16)
    PlayerSubtext.AnchorPoint = Vector2.new(0, 1)
    PlayerSubtext.BackgroundTransparency = 1
    PlayerSubtext.BorderSizePixel = 0
    PlayerSubtext.TextColor3 = Isotopia.Theme.textMuted
    PlayerSubtext.TextTransparency = 0.3
    PlayerSubtext.Text = 'Argon Hub X | Private'
    PlayerSubtext.TextSize = 10
    PlayerSubtext.TextXAlignment = Enum.TextXAlignment.Left
    PlayerSubtext.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    PlayerSubtext.ZIndex = 5
    PlayerSubtext.Parent = Handler

    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(
                Players.LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size48x48
            )
        end)
        if ok and img and typeof(img) == "string" then
            PlayerAvatar.Image = img
        elseif ok and img then
            PlayerAvatar.Image = tostring(img)
        end
    end)

    local SearchButton = Instance.new('TextButton')
    SearchButton.Name = 'SearchButton'
    SearchButton.BackgroundTransparency = 1
    SearchButton.Size = UDim2.new(0, 26, 0, 26)
    SearchButton.Position = UDim2.new(1, -45, 0, 9)
    SearchButton.Text = ''
    SearchButton.AutoButtonColor = false
    SearchButton.Parent = Handler

    local SearchCircle = Instance.new('Frame')
    SearchCircle.Name = 'SearchCircle'
    SearchCircle.Size = UDim2.new(1, 0, 1, 0)
    SearchCircle.BackgroundColor3 = Isotopia.Theme.surface
    SearchCircle.BackgroundTransparency = 0.3
    SearchCircle.BorderSizePixel = 0
    SearchCircle.Parent = SearchButton

    local SearchCircleCorner = Instance.new('UICorner')
    SearchCircleCorner.CornerRadius = UDim.new(1, 0)
    SearchCircleCorner.Parent = SearchCircle

    local SearchCircleStroke = Instance.new('UIStroke')
    SearchCircleStroke.Color = Isotopia.Theme.stroke
    SearchCircleStroke.Thickness = 1
    SearchCircleStroke.Transparency = 0.4
    SearchCircleStroke.Parent = SearchCircle

    local SearchIcon = Instance.new('ImageLabel')
    SearchIcon.Image = getIcon('search')
    SearchIcon.ImageColor3 = Window._mainColor
    SearchIcon.Size = UDim2.new(0, 14, 0, 14)
    SearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    SearchIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.ScaleType = Enum.ScaleType.Fit
    SearchIcon.Parent = SearchCircle
    
    local SearchBox = Instance.new('TextBox')
    SearchBox.Name = 'SearchBox'
    SearchBox.PlaceholderText = 'Search...'
    SearchBox.Text = ''
    SearchBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    SearchBox.TextSize = 11
    SearchBox.TextColor3 = Isotopia.Theme.text
    SearchBox.PlaceholderColor3 = Isotopia.Theme.textMuted
    SearchBox.BackgroundColor3 = Isotopia.Theme.surface
    SearchBox.BackgroundTransparency = 0.3
    SearchBox.BorderSizePixel = 0
    SearchBox.ClearTextOnFocus = false
    SearchBox.Size = UDim2.new(0, 0, 0, 26)
    SearchBox.Position = UDim2.new(1, -45, 0, 9)
    SearchBox.AnchorPoint = Vector2.new(1, 0)
    SearchBox.Visible = false
    SearchBox.ClipsDescendants = true
    SearchBox.Parent = Handler

    local SearchBoxCorner = Instance.new('UICorner')
    SearchBoxCorner.CornerRadius = UDim.new(0, 6)
    SearchBoxCorner.Parent = SearchBox

    local SearchBoxStroke = Instance.new('UIStroke')
    SearchBoxStroke.Color = Window._mainColor
    SearchBoxStroke.Thickness = 1
    SearchBoxStroke.Transparency = 0.5
    SearchBoxStroke.Parent = SearchBox

    local SearchPadding = Instance.new('UIPadding')
    SearchPadding.PaddingLeft = UDim.new(0, 8)
    SearchPadding.PaddingRight = UDim.new(0, 8)
    SearchPadding.Parent = SearchBox

    local searchOpen = false

    local function openSearch()
        searchOpen = true
        SearchBox.Visible = true
        TweenService:Create(SearchBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 160, 0, 26)
        }):Play()
        task.wait(0.05)
        SearchBox:CaptureFocus()
    end

    local function closeSearch()
        searchOpen = false
        SearchBox.Text = ''
        TweenService:Create(SearchBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 0, 0, 26)
        }):Play()
        task.wait(0.3)
        SearchBox.Visible = false
        for _, section in pairs(Window._sections:GetChildren()) do
            if section:IsA('ScrollingFrame') then
                for _, module in pairs(section:GetChildren()) do
                    if module:IsA('Frame') and module.Name == 'Module' then
                        module.Visible = true
                    end
                end
            end
        end
    end

    local function doSearch(query)
        query = query:lower()
        for _, section in pairs(Window._sections:GetChildren()) do
            if section:IsA('ScrollingFrame') and section.Visible then
                for _, module in pairs(section:GetChildren()) do
                    if module:IsA('Frame') and module.Name == 'Module' then
                        local header = module:FindFirstChild('Header')
                        local matched = false
                        if header then
                            local nameLabel = header:FindFirstChild('ModuleName')
                            local descLabel = header:FindFirstChild('Description')
                            local nameText = nameLabel and nameLabel.Text:lower() or ''
                            local descText = descLabel and descLabel.Text:lower() or ''
                            matched = nameText:find(query, 1, true) ~= nil
                                   or descText:find(query, 1, true) ~= nil
                        end
                        module.Visible = matched or query == ''
                    end
                end
            end
        end
    end

    SearchButton.MouseButton1Click:Connect(function()
        if searchOpen then
            closeSearch()
        else
            openSearch()
        end
    end)

        SearchBox:GetPropertyChangedSignal('Text'):Connect(function()
            doSearch(SearchBox.Text)
        end)

        SearchBox.FocusLost:Connect(function(enterPressed)
            if SearchBox.Text == '' then
                closeSearch()
            end
        end)
    end
    Window._searchBarVisible = (settings.HideSearchBar == false)
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 32, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    do
        local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
        if isMobile then
            local function computeScale()
                local vp = workspace.CurrentCamera.ViewportSize
                return math.min(1, math.min(vp.X, vp.Y) / 700)
            end
            UIScale.Scale = computeScale()
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                UIScale.Scale = computeScale()
            end)
        end
    end

    Window._ui = IsotopiaUI
    Window._tabs_frame = TabsFrame
    Window._sections = Sections
    Window._pin = Pin
    Window._handler = Handler
    Window._container = Container

    local function applyMainColor()
    local color = Window._mainColor
    Pin.BackgroundColor3 = color
    ClientName.TextColor3 = color
    
    local gradient = ClientName:FindFirstChild("UIGradient")
    if gradient then
        local animationColor = Window._mainColor
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, animationColor),
            ColorSequenceKeypoint.new(0.45, Isotopia.Theme.accentAlt),
            ColorSequenceKeypoint.new(1, animationColor)
        }
    end
end
    applyMainColor()

    local function on_drag(input, process)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Window._dragging = true
            Window._drag_start = input.Position
            Window._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                Window._dragging = false
            end)
        end
    end

    local function update_drag(input)
        if not Window._dragging then return end
        
        local delta = input.Position - Window._drag_start
        local position = UDim2.new(
            Window._container_position.X.Scale, 
            Window._container_position.X.Offset + delta.X, 
            Window._container_position.Y.Scale, 
            Window._container_position.Y.Offset + delta.Y
        )

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
        for _, gui in pairs(getSafeParent():GetChildren()) do
            if gui.Name == "DropdownOptionsList" then
                gui.Enabled = false
            end
        end
    end

    local function drag(input, process)
        if not Window._dragging then return end
        
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)
    
    function Window:loadAllSavedFlags()
    for _, section in pairs(self._sections:GetChildren()) do
        if section:IsA("ScrollingFrame") then
            for _, moduleFrame in pairs(section:GetChildren()) do
                if moduleFrame:IsA("Frame") and moduleFrame.Name == "Module" then
                    local header = moduleFrame:FindFirstChild("Header")
                    if header then
                        local moduleName = header:FindFirstChild("ModuleName")
                        if moduleName then
                            local flag = nil
                        end
                    end
                end
            end
        end
    end
end

    function Window:load()
        local content = {}
    
        for _, object in IsotopiaUI:GetDescendants() do
            if not object:IsA('ImageLabel') then
                continue
            end
    
            table.insert(content, object)
        end
    
        ContentProvider:PreloadAsync(content)

        local device = 'Unknown'
        if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
            device = 'PC'
        elseif UserInputService.TouchEnabled then
            device = 'Mobile'
        elseif UserInputService.GamepadEnabled then
            device = 'Console'
        end
        
        Window._device = device


    
        self:change_visiblity(true)
        
        self:loadAllSavedFlags()
        Window._ui_loaded = true
        Window._loaded = true
    end
    
    function Window:saveCurrentConfig()
        Config:save(tostring(game.GameId), Window._config)
    end
    
    function Window:Toggle()
    Window._ui_open = not Window._ui_open
    self:change_visiblity(Window._ui_open)

    if self._minimizedTitle and self._handler and self._handler:FindFirstChild("ClientName") then
        local ClientName = self._handler.ClientName
        
        if Window._ui_open then
            ClientName.Text = self._originalTitle or "Isotopia"
        else
            ClientName.Text = self._minimizedTitle
        end
    end
end

function Window:change_visiblity(state)
    if state then
        TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = self._size
        }):Play()

        if self._minimizedTitle and self._handler and self._handler:FindFirstChild("ClientName") then
            self._handler.ClientName.Text = self._originalTitle or "Isotopia"
        end

        local hd = self._handler and self._handler:FindFirstChild("HorizontalDivider")
        if hd then
            TweenService:Create(hd, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
        end
    else
        TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(self._size.X.Offset * 0.25, 52)
        }):Play()

        if self._minimizedTitle and self._handler and self._handler:FindFirstChild("ClientName") then
            self._handler.ClientName.Text = self._minimizedTitle
        end

        local hd = self._handler and self._handler:FindFirstChild("HorizontalDivider")
        if hd then
            TweenService:Create(hd, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        end
    end
end
    
   function Window:EditOpenButton(settings)
    if not self._handler then return end
    
    local MinimizeButton = self._handler:FindFirstChild("Minimize")
    if not MinimizeButton then return end
    
    if settings.Title then
        self._minimizedTitle = settings.Title
    end
    
    if settings.CornerRadius then
        local containerCorner = self._container:FindFirstChild("UICorner")
        if containerCorner then
            containerCorner.CornerRadius = settings.CornerRadius
        end
    end
    
    if settings.StrokeThickness then
        local containerStroke = self._container:FindFirstChild("UIStroke")
        if containerStroke then
            containerStroke.Thickness = settings.StrokeThickness
        end
    end
    
    if settings.Enabled ~= nil then
        MinimizeButton.Visible = settings.Enabled
    end
    
    if settings.OnlyMobile ~= nil then
        if settings.OnlyMobile then
            local currentDevice = self._device or "Unknown"
            MinimizeButton.Visible = (currentDevice == "Mobile" or currentDevice == "Unknown") 
                and (settings.Enabled ~= false)
        else
            if settings.Enabled == nil then
                MinimizeButton.Visible = true
            end
        end
    end
    
    if settings.Draggable ~= nil then
        if not settings.Draggable then
            if Connections['container_input_began'] then
                Connections:disconnect('container_input_began')
            end
            if Connections['input_changed'] then
                Connections:disconnect('input_changed')
            end
        else
            if not Connections['container_input_began'] then
                local function on_drag(input, process)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                        self._dragging = true
                        self._drag_start = input.Position
                        self._container_position = self._container.Position

                        Connections['container_input_ended'] = input.Changed:Connect(function()
                            if input.UserInputState ~= Enum.UserInputState.End then
                                return
                            end

                            Connections:disconnect('container_input_ended')
                            self._dragging = false
                        end)
                    end
                end

                local function drag(input, process)
                    if not self._dragging then return end
                    
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        local delta = input.Position - self._drag_start
                        local position = UDim2.new(
                            self._container_position.X.Scale, 
                            self._container_position.X.Offset + delta.X, 
                            self._container_position.Y.Scale, 
                            self._container_position.Y.Offset + delta.Y
                        )

                        TweenService:Create(self._container, TweenInfo.new(0.2), {
                            Position = position
                        }):Play()
                    end
                end
                
                Connections['container_input_began'] = self._container.InputBegan:Connect(on_drag)
                Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)
            end
        end
    end
    
    return MinimizeButton
end
   
    
    function Window:flag_type(flag, flag_type)
        if not Window._config._flags[flag] then
            return false
        end
        return typeof(Window._config._flags[flag]) == flag_type
    end
    
    function Window:SetMainColor(color)
    if typeof(color) ~= "Color3" then
        warn("[Isotopia] MainColor must be a Color3 value")
        return
    end
    
    self._mainColor = color
    Isotopia.Theme.accent = color
    Isotopia.Theme.mainColor = color
    
    if self._handler and self._handler:FindFirstChild("ClientName") then
        self._handler.ClientName.TextColor3 = color
    end
    
    self:_updateAllThemeElements(color)
    self:_updateUIHierarchy(self._ui, color)
end

function Window:_updateUIHierarchy(parent, color)
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("Frame") then
            if child.Name == "Pin" then
                child.BackgroundColor3 = color
            elseif child.Name == "Toggle" and child:FindFirstChild("Circle") then
                local circle = child:FindFirstChild("Circle")
                if circle.Position.X.Scale > 0 then
                    child.BackgroundColor3 = color
                    circle.BackgroundColor3 = color
                end
            elseif child.Name == "Drag" or child.Name == "Fill" then
                child.BackgroundColor3 = color
            elseif child.Name == "CheckboxFrame" then
                local checkmark = child:FindFirstChild("Checkmark")
                if checkmark and checkmark.ImageTransparency < 1 then
                    child.BackgroundColor3 = color
                end
            end
        elseif child:IsA("TextLabel") then
            if child.Name == "ModuleName" and child.TextColor3 == self._mainColor then
                child.TextColor3 = color
            end
        elseif child:IsA("ImageLabel") then
            if child.Name == "Icon" and child.ImageColor3 == self._mainColor then
                child.ImageColor3 = color
            elseif child.Name == "Arrow" then
                child.ImageColor3 = color
            end
        elseif child:IsA("UIGradient") then
            if child.Parent and child.Parent.Name == "ClientName" then
                child.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, color),
                    ColorSequenceKeypoint.new(0.45, Isotopia.Theme.accentAlt),
                    ColorSequenceKeypoint.new(1, color)
                }
            end
        elseif child:IsA("TextButton") and child.Name == "Button" then
            if child.BackgroundColor3 == self._mainColor then
                child.BackgroundColor3 = color
            end
        end
    end
end

function Window:_updateAllThemeElements(color)
    for _, frame in ipairs(self._themeElements.frames) do
        if frame and frame.Parent then
            frame.BackgroundColor3 = color
        end
    end
    
    for _, image in ipairs(self._themeElements.images) do
        if image and image.Parent then
            image.ImageColor3 = color
        end
    end
    
    for _, label in ipairs(self._themeElements.labels) do
        if label and label.Parent and label.Name == "ModuleName" then
            label.TextColor3 = color
        end
    end
    
    for _, gradient in ipairs(self._themeElements.gradients) do
        if gradient and gradient.Parent then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, color),
                ColorSequenceKeypoint.new(0.45, Isotopia.Theme.accentAlt),
                ColorSequenceKeypoint.new(1, color)
            }
        end
    end
    
    for _, toggleData in ipairs(self._themeElements.toggles) do
        if toggleData and toggleData.toggle and toggleData.toggle.Parent then
            if toggleData.state then
                toggleData.toggle.BackgroundColor3 = color
                if toggleData.circle then
                    toggleData.circle.BackgroundColor3 = color
                end
            end
        end
    end
end
    
    function Window:SetSize(newSize)
        if typeof(newSize) ~= "UDim2" then
            warn("[Isotopia] Size must be a UDim2 value. Use: UDim2.fromOffset(width, height)")
            return
        end
        
        if newSize.X.Offset < 400 or newSize.Y.Offset < 300 then
            warn("Minimum window size is 400x300 pixels")
            newSize = UDim2.fromOffset(math.max(400, newSize.X.Offset), math.max(300, newSize.Y.Offset))
        end
        
        self._size = newSize
        
        if self._handler then
            TweenService:Create(self._handler, TweenInfo.new(0.3), {
                Size = newSize
            }):Play()
        end
        
        if self._tabs_frame then
            TweenService:Create(self._tabs_frame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 129, 0, newSize.Y.Offset - 78)
            }):Play()
        end
        self:_updateSectionsSize(newSize)
        
        if self._ui_open and self._container then
            TweenService:Create(self._container, TweenInfo.new(0.3), {
                Size = newSize
            }):Play()
        end
        
        return self._size
    end
    
    function Window:GetSize()
        return self._size
    end
    
    function Window:_updateSectionsSize(newSize)
        if not self._sections then return end
        
        local sectionHeight = newSize.Y.Offset - 34
        
        for _, section in ipairs(self._sections:GetChildren()) do
            if section:IsA("ScrollingFrame") and (section.Name == "LeftSection" or section.Name == "RightSection") then
                TweenService:Create(section, TweenInfo.new(0.3), {
                    Size = UDim2.new(0, 243, 0, sectionHeight - 40)
                }):Play()
            end
        end
    end

    function Window:SetTransparent(state)
        if state == nil then
            state = not self._transparent
        end
        
        self._transparent = state
        
        if self._container then
            TweenService:Create(self._container, TweenInfo.new(0.3), {
                BackgroundTransparency = state and 0.5 or 0.07
            }):Play()
            
            local stroke = self._container:FindFirstChild("UIStroke")
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(0.3), {
                    Transparency = state and 0.5 or 0.2
                }):Play()
            end
        end
        self:_updateModulesTransparency(state)
        
        return self._transparent
    end
    
    function Window:GetTransparent()
        return self._transparent
    end
    
    function Window:_updateModulesTransparency(state)
        if not self._sections then return end
        
        for _, section in ipairs(self._sections:GetChildren()) do
            if section:IsA("ScrollingFrame") then
                for _, module in ipairs(section:GetChildren()) do
                    if module:IsA("Frame") and module.Name == "Module" then
                        TweenService:Create(module, TweenInfo.new(0.3), {
                            BackgroundTransparency = state and 0.7 or 0.5
                        }):Play()
                        
                        local stroke = module:FindFirstChild("UIStroke")
                        if stroke then
                            TweenService:Create(stroke, TweenInfo.new(0.3), {
                                Transparency = state and 0.5 or 0.25
                            }):Play()
                        end
                    end
                end
            end
        end
    end
    
    function Window:_refreshThemeColors()
        if Window._pin then
            Window._pin.BackgroundColor3 = Window._mainColor
        end
        
        if Window._handler and Window._handler:FindFirstChild("Icon") then
            Window._handler.Icon.ImageColor3 = Window._mainColor
        end
       
        if Window._handler and Window._handler:FindFirstChild("ClientName") then
            local gradient = Window._handler.ClientName:FindFirstChild("UIGradient")
            if gradient then
                gradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Window._mainColor),
                    ColorSequenceKeypoint.new(0.45, Isotopia.Theme.accentAlt),
                    ColorSequenceKeypoint.new(1, Window._mainColor)
                }
            end
        end
    end
    
    function Window:SetAnimationSettings(settings)
    if not settings then return end
    
    if settings.AnimationColor then
        Window._animationSettings.AnimationColor = settings.AnimationColor
    end
    if settings.AnimationSide then
        Window._animationSettings.AnimationSide = settings.AnimationSide
    end
    if settings.AnimationSpeed then
        Window._animationSettings.AnimationSpeed = settings.AnimationSpeed
    end
    
    local gradient = ClientName:FindFirstChild("UIGradient")
    if gradient then
        local animationColor = Window._animationSettings.AnimationColor or Window._mainColor
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, animationColor),
            ColorSequenceKeypoint.new(0.45, Isotopia.Theme.accentAlt),
            ColorSequenceKeypoint.new(1, animationColor)
        }
        
        for _, tween in pairs(gradient:GetChildren()) do
            if tween:IsA("Tween") then
                tween:Cancel()
            end
        end
        
        TweenService:GetTweeningObjects(gradient):forEach(function(tween)
            tween:Cancel()
        end)
        
        local animationInfo = TweenInfo.new(
            Window._animationSettings.AnimationSpeed,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut,
            -1,
            true
        )
        
        local startOffset, targetOffset
        if Window._animationSettings.AnimationSide == "Right" then
            startOffset = Vector2.new(-1, 0)
            targetOffset = Vector2.new(1, 0)
        else
            startOffset = Vector2.new(1, 0)
            targetOffset = Vector2.new(-1, 0)
        end
        
        gradient.Offset = startOffset
        TweenService:Create(gradient, animationInfo, {
            Offset = targetOffset
        }):Play()
    end
end
    
    function Window:GetAnimationSettings()
        return Window._animationSettings
    end
    
    function Window:SetToggleKey(keyCode)
    if not keyCode then return end

    if Connections['window_toggle_key'] then
        Connections:disconnect('window_toggle_key')
    end
    Window._toggle_key = keyCode

    Connections['window_toggle_key'] = UserInputService.InputBegan:Connect(function(input, process)
        if input.KeyCode == keyCode and not process then
            Window:Toggle()
        end
    end)
end

    function Window:GetToggleKey()
    return Window._toggle_key or Enum.KeyCode.LeftControl
end

function Window:ClearToggleKey()
    if Connections['window_toggle_key'] then
        Connections:disconnect('window_toggle_key')
    end
    Window._toggle_key = nil
end

    function Window:update_tabs(tab)
        for _, object in TabsFrame:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (42 / Window._size.Y.Offset)

                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.165 + offset)
                    }):Play()    

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.2,
                        TextColor3 = Window._mainColor
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Window._mainColor
                    }):Play()
                end
                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Isotopia.Theme.textMuted
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Isotopia.Theme.textMuted
                }):Play()
            end
        end
    end
    
    function Window:update_sections(left_section, right_section)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
                continue
            end
            object.Visible = false
        end
    end
    function Window:Destroy()
    if self._ui then
        self._ui:Destroy()
    end
    Connections:disconnect_all()
    local parent = getSafeParent()
    for _, gui in ipairs(parent:GetChildren()) do
        if gui.Name == "IsotopiaNotification" 
        or gui.Name == "IsotopiaPopup" 
        or gui.Name == "IsotopiaBlur"
        or gui.Name == "DropdownOptionsList" then
            gui:Destroy()
        end
    end
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") then
            effect:Destroy()
        end
    end
end

function Window:DestroyAll()
    if self._ui then
        self._ui:Destroy()
    end
    
    Connections:disconnect_all()
    
    local parent = getSafeParent()
    for _, gui in ipairs(parent:GetChildren()) do
        if gui.Name == "IsotopiaNotification" 
        or gui.Name == "IsotopiaPopup" 
        or gui.Name == "IsotopiaBlur"
        or gui.Name == "DropdownOptionsList" then
            gui:Destroy()
        end
    end

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") then
            effect:Destroy()
        end
    end
    
    Isotopia._current_window = nil
    
    self._ui = nil
    self._handler = nil
    self._container = nil
    self._sections = nil
    self._tabs_frame = nil
end

    local _preset = getPreset(Window._size.X.Offset, Window._size.Y.Offset)
    local sectionWidth = _preset.moduleWidth + 2
    function Window:Tab(settings)
        local TabManager = {}
        local LayoutOrder = 0

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = settings.Title or "Tab"
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not TabsFrame:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Isotopia.Theme.surface
        Tab.Parent = TabsFrame
        Tab.LayoutOrder = Window._tab
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 10)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Isotopia.Theme.text
        TextLabel.TextTransparency = 0.55
        TextLabel.Text = settings.Title or "Tab"
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.2400001734495163, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab
        
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.6
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.ImageColor3 = Isotopia.Theme.textMuted
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = getIcon(settings.Icon)
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        local sectionHeight, sectionYScale, sectionYOffset
        if Window._searchBarVisible then
    sectionYOffset = 60
    sectionHeight = Window._size.Y.Offset - sectionYOffset - 50
    sectionYScale = 0
else
    sectionHeight = Window._size.Y.Offset - 80
    sectionYScale = 0.5
    sectionYOffset = 0
end
        LeftSection.Size = UDim2.new(0, sectionWidth, 0, sectionHeight)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        local sectionOffset = _preset.offset + math.floor((Window._size.X.Offset - 698) * 0.05)
        LeftSection.Position = UDim2.new(0, sectionOffset, sectionYScale, sectionYOffset)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, sectionWidth, 0, sectionHeight)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0, sectionOffset + sectionWidth + 16, sectionYScale, sectionYOffset)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections
        
        local UIListLayout2 = Instance.new('UIListLayout')
        UIListLayout2.Padding = UDim.new(0, 11)
        UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout2.Parent = RightSection
        
        local UIPadding2 = Instance.new('UIPadding')
        UIPadding2.PaddingTop = UDim.new(0, 1)
        UIPadding2.Parent = RightSection

        if Window._searchBarVisible then
             LeftSection.AnchorPoint = Vector2.new(0, 0)
             RightSection.AnchorPoint = Vector2.new(0, 0)
        else
             LeftSection.AnchorPoint = Vector2.new(0, 0.5)
             RightSection.AnchorPoint = Vector2.new(0, 0.5)
         end 

        Window._tab += 1

        if first_tab then
            Window:update_tabs(Tab)
            Window:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            Window:update_tabs(Tab)
            Window:update_sections(LeftSection, RightSection)
        end)
        
        function TabManager:Section(settings)
    local section = settings.Side == 'right' and RightSection or LeftSection
    return {
        _frame = section,
        Module = function(self, settings)
            return create_module(section, settings)
        end,

        Toggle = function(self, settings)
            return create_module(section, settings)
        end,
        
        Button = function(self, settings)
            local ModuleManager = create_module(section, {
                Title = settings.Title or "Button",
                Description = settings.Desc or settings.Description or "",
                Default = true
            })
            
            ModuleManager:Button(settings)

            ModuleManager:Toggle(true)
            
            return ModuleManager
        end,
        
        Slider = function(self, settings)
    local ModuleManager = create_module(section, {
        Title = settings.Title or "Slider",
        Description = settings.Desc or settings.Description or "",
        Default = true
    })
    
    local slider = ModuleManager:Slider(settings)
    
    ModuleManager:Toggle(true)
    
    return slider
end,
        
        Dropdown = function(self, settings)
            local ModuleManager = create_module(section, {
                Title = settings.Title or "Dropdown",
                Description = settings.Desc or settings.Description or "",
                Default = true
            })
            
            local dropdown = ModuleManager:Dropdown(settings)

            ModuleManager:Toggle(true)
            
            return dropdown
        end,
        
        Label = function(self, settings)
            local ModuleManager = create_module(section, {
                Title = settings.Title or "Label",
                Description = settings.Desc or settings.Description or "",
                Default = true
            })
            
            ModuleManager:Label(settings)

            ModuleManager:Toggle(true)
            
            return ModuleManager
        end,

Checkbox = function(self, settings)
    local ModuleManager = create_module(section, {
        Title = settings.Title or "Checkbox",
        Description = settings.Desc or settings.Description or "",
        Default = true
    })
    
    local checkbox = ModuleManager:Checkbox(settings)
    
    ModuleManager:Toggle(true)
    
    return checkbox
end,
      Input = function(self, settings)
    local ModuleManager = create_module(section, {
        Title = settings.Title or "Input",
        Description = settings.Desc or settings.Description or "",
        Default = true
    })
    
    local input = ModuleManager:Input(settings)
    
    ModuleManager:Toggle(true)
    
    return input
end,

Divider = function(self, settings)
    local ModuleManager = create_module(section, {
        Title = "",
        Description = "",
        Default = true
    })
    
    ModuleManager:Divider(settings)
    
    ModuleManager:Toggle(true)
    
    return true
end
    }
end

        table.insert(Window._tabs, TabManager)
        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input, process)
        if input.KeyCode ~= Enum.KeyCode.LeftControl and input.KeyCode ~= Enum.KeyCode.RightControl then
            return
        end
        Window:Toggle()
    end)

    Minimize.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)
    
    return Window
end

function create_module(section, settings)
    local ModuleManager = {
        _state = false,
        _size = 0,
        _multiplier = 0,
        _section = section
    }
    
    local Window = Isotopia._current_window
    local LayoutOrderModule = 0
    local _preset = getPreset(Window._size.X.Offset, Window._size.Y.Offset)
    local moduleWidth = _preset.moduleWidth
    local innerWidth = _preset.innerWidth
    
    local function updateSectionCanvas()
    task.defer(function()
        local totalHeight = 0
        for _, child in pairs(section:GetChildren()) do
            if child:IsA("Frame") and child.Name == "Module" then
                totalHeight = totalHeight + child.Size.Y.Offset + 11
            end
        end
        
        section.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
    end)
end
    
    local Module = Instance.new('Frame')
    Module.ClipsDescendants = true
    Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Module.BackgroundTransparency = Window._transparent and 0.7 or 0.5
    Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
    Module.Name = 'Module'
    Module.Size = UDim2.new(0, moduleWidth, 0, 93)
    Module.BorderSizePixel = 0
    Module.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Module.Parent = section
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Module
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Module
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(
        math.min(255, (Isotopia.Theme.inset.R * 255 + 50)),
        math.min(255, (Isotopia.Theme.inset.G * 255 + 50)),
        math.min(255, (Isotopia.Theme.inset.B * 255 + 50))
    )
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Module
    ModuleManager._uiStroke = UIStroke
    
    local Header = Instance.new('TextButton')
    Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Header.TextColor3 = Color3.fromRGB(0, 0, 0)
    Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Header.Text = ''
    Header.AutoButtonColor = false
    Header.BackgroundTransparency = 1
    Header.Name = 'Header'
    Header.Size = UDim2.new(0, moduleWidth, 0, 93)
    Header.BorderSizePixel = 0
    Header.TextSize = 14
    Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Header.Parent = Module
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Isotopia.Theme.text
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.ImageTransparency = 0.4
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://79095934438045'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 15, 0, 15)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon.Parent = Header
    
    local ModuleName = Instance.new('TextLabel')
    ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ModuleName.TextColor3 = Isotopia.Theme.text
    ModuleName.TextTransparency = 0.2
    if not settings.Rich then
        ModuleName.Text = settings.Title or "Module"
    else
        ModuleName.RichText = true
        ModuleName.Text = settings.RichText or "<font color='rgb(255,0,0)'>Module</font>"
    end
    ModuleName.Name = 'ModuleName'
    ModuleName.Size = UDim2.new(0, innerWidth, 0, 13)
    ModuleName.AnchorPoint = Vector2.new(0, 0.5)
    ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
    ModuleName.BackgroundTransparency = 1
    ModuleName.TextXAlignment = Enum.TextXAlignment.Left
    ModuleName.BorderSizePixel = 0
    ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ModuleName.TextSize = 13
    ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ModuleName.Parent = Header
    
    local Description = Instance.new('TextLabel')
    Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Description.TextColor3 = Isotopia.Theme.textMuted
    Description.TextTransparency = 0.5
    Description.Text = settings.Desc or settings.Description or ""
    Description.Name = 'Description'
    Description.Size = UDim2.new(0, innerWidth, 0, 13)
    Description.AnchorPoint = Vector2.new(0, 0.5)
    Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
    Description.BackgroundTransparency = 1
    Description.TextXAlignment = Enum.TextXAlignment.Left
    Description.BorderSizePixel = 0
    Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Description.TextSize = 10
    Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Description.Parent = Header
    
local Toggle = Instance.new('Frame')
Toggle.Name = 'Toggle'
Toggle.BackgroundTransparency = 0.55
Toggle.Position = UDim2.new(.81999999284744, 5, .75700002908707, 0)
Toggle.AnchorPoint = Vector2.new(1, 0)
Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
Toggle.Size = UDim2.new(0, 25, 0, 12)
Toggle.BorderSizePixel = 0
Toggle.BackgroundColor3 = Isotopia.Theme.surface
Toggle.Parent = Header

local UICorner = Instance.new('UICorner')
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = Toggle

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Isotopia.Theme.stroke
UIStroke.Thickness = 1
UIStroke.Transparency = 0.2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = Toggle

local Circle = Instance.new('Frame')
Circle.BorderColor3 = Color3.fromRGB(255, 255, 255)
Circle.AnchorPoint = Vector2.new(0, 0.5)
Circle.BackgroundTransparency = 0.1
Circle.Position = UDim2.new(0, 1, .5, 0)
Circle.Name = 'Circle'
Circle.Size = UDim2.new(0, 10, 0, 10)
Circle.BorderSizePixel = 0
Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Circle.Parent = Toggle

local UICorner2 = Instance.new('UICorner')
UICorner2.CornerRadius = UDim.new(1, 0)
UICorner2.Parent = Circle

    local i = Instance.new("Frame")
	i.Name = "Keybind"
	i.BackgroundTransparency = .69999998807907
	i.Position = UDim2.new(.15000000596046, 0, .73500001430511, 0)
	i.BorderColor3 = Color3.fromRGB(0, 0, 0)
	i.Size = UDim2.new(0, 33, 0, 15)
	i.BorderSizePixel = 0
	i.BackgroundColor3 = Isotopia.Theme.stroke
	i.Parent = Header

	local o = Instance.new("UICorner")
	o.CornerRadius = UDim.new(1, 5)
	o.Parent = i

	local d = Instance.new("TextLabel")
	d.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	d.TextColor3 = Color3.fromRGB(209, 222, 255)
	d.BorderColor3 = Color3.fromRGB(0, 0, 0)
	d.Text = "None"
	d.AnchorPoint = Vector2.new(.5, .5)
	d.Size = UDim2.new(0, 25, 0, 13)
	d.BackgroundTransparency = 1
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.Position = UDim2.new(.5, 0, .5, 0)
	d.BorderSizePixel = 0
	d.TextSize = 10
	d.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	d.Parent = i
    
    local Divider = Instance.new('Frame')
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.AnchorPoint = Vector2.new(0.5, 0)
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
    Divider.Name = 'Divider'
    Divider.Size = UDim2.new(0, moduleWidth, 0, 1)
    Divider.Visible = not Window._hideSearchBar
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Isotopia.Theme.LinesAIR
    Divider.Parent = Header

    local Divider2 = Instance.new('Frame')
    Divider2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider2.AnchorPoint = Vector2.new(0.5, 0)
    Divider2.BackgroundTransparency = 0.5
    Divider2.Position = UDim2.new(.5, 0, 1, 0)
    Divider2.Name = 'Divider2'
    Divider2.Size = UDim2.new(0, moduleWidth, 0, 1)
    Divider2.Visible = not Window._hideSearchBar
    Divider2.BorderSizePixel = 0
    Divider2.BackgroundColor3 = Isotopia.Theme.LinesAIR
    Divider2.Parent = Header
    
    local Options = Instance.new('Frame')
    Options.Name = 'Options'
    Options.BackgroundTransparency = 1
    Options.Position = UDim2.new(0, 0, 1, 0)
    Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Options.Size = UDim2.new(0, moduleWidth, 0, 8)
    Options.BorderSizePixel = 0
    Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Options.Parent = Module

    local UIPadding = Instance.new('UIPadding')
    UIPadding.PaddingTop = UDim.new(0, 8)
    UIPadding.Parent = Options

    local UIListLayout2 = Instance.new('UIListLayout')
    UIListLayout2.Padding = UDim.new(0, 5)
    UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout2.Parent = Options

    local ModuleScale = Instance.new('UIScale')
    ModuleScale.Scale = 1
    ModuleScale.Parent = Module

    Header.MouseEnter:Connect(function()
        Module.ClipsDescendants = false
        TweenService:Create(ModuleScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1.015
        }):Play()
    end)

    Header.MouseLeave:Connect(function()
        local tween = TweenService:Create(ModuleScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            Module.ClipsDescendants = true
        end)
    end)

    Header.MouseEnter:Connect(function()
        TweenService:Create(ModuleScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1.035
        }):Play()
    end)

    Header.MouseLeave:Connect(function()
        TweenService:Create(ModuleScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()
    end)

    function ModuleManager:Toggle(value)

        if settings.Locked then
            return ModuleManager._state
        end
    
        if value ~= nil then
            ModuleManager._state = value
        else
            ModuleManager._state = not ModuleManager._state
        end
        
        if settings.Flag then
        Window._config._flags[settings.Flag] = ModuleManager._state
        Config:save(tostring(game.GameId), Window._config)
    end
        
        if ModuleManager._state then
            TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
            }):Play()

            TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(255, 0, 0),
                BackgroundTransparency = settings.Locked and 0 or 0
            }):Play()

            TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(0, 0, 0),
                Position = UDim2.fromScale(0.53, 0.5)
            }):Play()

            if ModuleManager._uiStroke then
                TweenService:Create(ModuleManager._uiStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Color = Color3.fromRGB(255, 0, 0)
                }):Play()
            end

        else
            TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(moduleWidth, 93)
            }):Play()

            TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()

            TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(255, 255, 255),
                Position = UDim2.fromScale(0, 0.5)
            }):Play()

            if ModuleManager._uiStroke then
                TweenService:Create(ModuleManager._uiStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Color = Color3.fromRGB(
                        math.min(255, (Isotopia.Theme.inset.R * 255 + 50)),
                        math.min(255, (Isotopia.Theme.inset.G * 255 + 50)),
                        math.min(255, (Isotopia.Theme.inset.B * 255 + 50))
                    )
                }):Play()
            end
        end
        
        if settings.Callback then
            settings.Callback(ModuleManager._state)
        end
        updateSectionCanvas()
        return ModuleManager._state
    end
    
    Header.MouseButton1Click:Connect(function()
        ModuleManager:Toggle()
    end)
    
    function ModuleManager:Input(settings: any)
    LayoutOrderModule = LayoutOrderModule + 1

    local TextboxManager = {
        _text = ""
    }
    
    local cW = Isotopia._current_window
    if not cW then warn("no cW") end

    if self._size == 0 then
        self._size = 11
    end

    self._size += 32

    if ModuleManager._state then
        Module.Size = UDim2.fromOffset(moduleWidth, 93 + self._size)
    end

    Options.Size = UDim2.fromOffset(moduleWidth, self._size)

    local Label = Instance.new('TextLabel')
    Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextTransparency = 0.2
    Label.Text = settings.Title or "Enter text"
    Label.Size = UDim2.new(0, innerWidth, 0, 13)
    Label.AnchorPoint = Vector2.new(0, 0)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BorderSizePixel = 0
    Label.Parent = Options
    Label.TextSize = 10;
    Label.LayoutOrder = LayoutOrderModule

    local Textbox = Instance.new('TextBox')
    Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Textbox.PlaceholderText = settings.Placeholder or "Enter text..."
    Textbox.Text = Window._config._flags[settings.Flag] or ""
    Textbox.Name = 'Textbox'
    Textbox.Size = UDim2.new(0, innerWidth, 0, 15)
    Textbox.BorderSizePixel = 0
    Textbox.TextSize = 10
    Textbox.BackgroundColor3 = Window._mainColor
    Textbox.BackgroundTransparency = 0.9
    Textbox.ClearTextOnFocus = false
    Textbox.Parent = Options
    Textbox.LayoutOrder = LayoutOrderModule

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Textbox

    function TextboxManager:update_text(text: string)
    self._text = text
    if settings.Flag then
        Window._config._flags[settings.Flag] = self._text
        Config:save(tostring(game.GameId), Window._config)
    end
    if settings.callback then
        settings.callback(self._text)
    end
end

    Textbox.FocusLost:Connect(function()
        TextboxManager:update_text(Textbox.Text)
    end)

    updateSectionCanvas()
    return TextboxManager
end
    
    local function create_divider(parent, settings, layoutOrder)
        local dividerHeight = 0.5
        local OuterFrame = Instance.new('Frame')
        OuterFrame.Size = UDim2.new(0, innerWidth, 0, 20)
        OuterFrame.BackgroundTransparency = 1
        OuterFrame.Name = 'OuterFrame'
        OuterFrame.Parent = parent
        OuterFrame.LayoutOrder = layoutOrder

        if settings and (settings.showtopic or settings.Text) then
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.TextTransparency = 0
            TextLabel.Text = settings.Text or settings.Title or ""
            TextLabel.Size = UDim2.new(0, 153, 0, 13)
            TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Center
            TextLabel.BorderSizePixel = 0
            TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.TextSize = 11
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.ZIndex = 3;
            TextLabel.TextStrokeTransparency = 0;
            TextLabel.Parent = OuterFrame
        end;
        
        if not settings or settings and not settings.disableline then
            local Divider = Instance.new('Frame')
            Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
            Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Divider.BorderSizePixel = 0
            Divider.Name = 'Divider'
            Divider.Parent = OuterFrame
            Divider.ZIndex = 2;
            Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2)
            
            local Gradient = Instance.new('UIGradient')
            Gradient.Parent = Divider
            Gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))
            })
            Gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),   
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
            Gradient.Rotation = 0
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 2)
            UICorner.Parent = Divider
        end;

        return OuterFrame
    end

    function ModuleManager:Divider(settings: any)
    LayoutOrderModule = LayoutOrderModule + 1;

    if self._size == 0 then
        self._size = 11
    end

    self._size += 27

    if ModuleManager._state then
        Module.Size = UDim2.fromOffset(moduleWidth, 93 + self._size)
    end

    create_divider(Options, settings, LayoutOrderModule)

    updateSectionCanvas()
    return true;
end
    
    function ModuleManager:Button(settings)
    LayoutOrderModule = LayoutOrderModule + 1
    
    if ModuleManager._size == 0 then
        ModuleManager._size = 11
    end
    
    ModuleManager._size += 25
    
    if ModuleManager._state then
        Module.Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
    end
    
    Options.Size = UDim2.fromOffset(moduleWidth, ModuleManager._size)
    
    local Button = Instance.new('TextButton')
    Button.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Button.TextColor3 = Color3.fromRGB(0, 0, 0)
    Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Button.Text = settings.Title or "Button"
    Button.AutoButtonColor = false
    Button.Name = 'Button'
    Button.Size = UDim2.new(0, innerWidth, 0, 20)
    Button.BorderSizePixel = 0
    Button.TextSize = 12
    Button.Parent = Options
    Button.LayoutOrder = LayoutOrderModule
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Button
    
    if settings.Desc or settings.Description then
        Button.Size = UDim2.new(0, innerWidth, 0, 35)
        ModuleManager._size += 15
        
        if ModuleManager._state then
            Module.Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
        end
        
        Options.Size = UDim2.fromOffset(moduleWidth, ModuleManager._size)
        
        local DescriptionLabel = Instance.new('TextLabel')
        DescriptionLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        DescriptionLabel.TextColor3 = Isotopia.Theme.textMuted
        DescriptionLabel.TextTransparency = 0.5
        DescriptionLabel.Text = settings.Desc or settings.Description or ""
        DescriptionLabel.Size = UDim2.new(0, 200, 0, 15)
        DescriptionLabel.Position = UDim2.new(0.5, 0, 0.7, 0)
        DescriptionLabel.AnchorPoint = Vector2.new(0.5, 0)
        DescriptionLabel.BackgroundTransparency = 1
        DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Center
        DescriptionLabel.BorderSizePixel = 0
        DescriptionLabel.TextSize = 9
        DescriptionLabel.TextWrapped = true
        DescriptionLabel.Parent = Button
        
        Button.Position = UDim2.new(0.5, 0, 0.2, 0)
        Button.TextYAlignment = Enum.TextYAlignment.Center
    else
        Button.BackgroundTransparency = 0.8
        Button.BackgroundColor3 = Window._mainColor
        Button.TextColor3 = Color3.fromRGB(0, 0, 0)
    end
    
    if settings.Locked then
        Button.BackgroundTransparency = 0.9
        Button.BackgroundColor3 = Isotopia.Theme.stroke
        Button.TextColor3 = Color3.fromRGB(150, 150, 150)
        if Button:FindFirstChildWhichIsA('TextLabel') then
            Button:FindFirstChildWhichIsA('TextLabel').TextColor3 = Color3.fromRGB(100, 100, 100)
        end
    else
        if not (settings.Desc or settings.Description) then
            Button.BackgroundTransparency = 0.8
            Button.BackgroundColor3 = Isotopia.Theme.accent
            Button.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
        
        Button.MouseButton1Click:Connect(function()
            if settings.Callback then
                settings.Callback()
            end
        end)
    end
    updateSectionCanvas()
    return Button
end
    
   function ModuleManager:Slider(settings)
    LayoutOrderModule = LayoutOrderModule + 1
    local SliderManager = {}
    
    local min = 0
    local max = 100
    local default = 50
    local step = settings.Step or 1
    
    if settings.Value and type(settings.Value) == "table" then
        min = settings.Value.Min or min
        max = settings.Value.Max or max
        default = settings.Value.Default or default
    else
        min = settings.Min or min
        max = settings.Max or max
        default = settings.Default or default
    end

    if ModuleManager._size == 0 then
        ModuleManager._size = 11
    end

    ModuleManager._size += 27

    if ModuleManager._state then
        Module.Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
    end

    Options.Size = UDim2.fromOffset(moduleWidth, ModuleManager._size)

    local Slider = Instance.new('TextButton')
    Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Slider.TextSize = 14
    Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
    Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Slider.Text = ''
    Slider.AutoButtonColor = false
    Slider.BackgroundTransparency = 1
    Slider.Name = 'Slider'
    Slider.Size = UDim2.new(0, innerWidth, 0, 22)
    Slider.BorderSizePixel = 0
    Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Slider.Parent = Options
    Slider.LayoutOrder = LayoutOrderModule

    local hasDescription = settings.Desc or settings.Description
    if hasDescription then
        Slider.Size = UDim2.new(0, innerWidth, 0, 35)
        ModuleManager._size += 13
        Options.Size = UDim2.fromOffset(moduleWidth, ModuleManager._size)
        
        if ModuleManager._state then
            Module.Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
        end
    end
    
    local TextLabel = Instance.new('TextLabel')
    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    TextLabel.TextSize = 11
    TextLabel.TextColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Isotopia.Theme.text
    TextLabel.TextTransparency = 0.1
    TextLabel.Text = settings.Title or "Slider"
    TextLabel.Size = UDim2.new(0, 153, 0, 13)
    TextLabel.Position = UDim2.new(0, 0, hasDescription and 0 or 0.05, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.BorderSizePixel = 0
    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Parent = Slider

    if hasDescription then
        local DescriptionLabel = Instance.new('TextLabel')
        DescriptionLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        DescriptionLabel.TextSize = 9
        DescriptionLabel.TextColor3 = Isotopia.Theme.textMuted
        DescriptionLabel.TextTransparency = 0.3
        DescriptionLabel.Text = settings.Desc or settings.Description or ""
        DescriptionLabel.Size = UDim2.new(0, 153, 0, 12)
        DescriptionLabel.Position = UDim2.new(0, 0, 0.5, 0)
        DescriptionLabel.BackgroundTransparency = 1
        DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescriptionLabel.TextWrapped = true
        DescriptionLabel.BorderSizePixel = 0
        DescriptionLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        DescriptionLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        DescriptionLabel.Parent = Slider
    end
    
    local Drag = Instance.new('Frame')
    Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Drag.AnchorPoint = Vector2.new(0.5, 1)
    Drag.BackgroundTransparency = 0.9
    Drag.Position = UDim2.new(0.5, 0, hasDescription and 0.8 or 0.95, 0)
    Drag.Name = 'Drag'
    Drag.Size = UDim2.new(0, innerWidth, 0, 4)
    Drag.BorderSizePixel = 0
    Drag.BackgroundColor3 = Window._mainColor
    Drag.Parent = Slider
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Drag
    
    local Fill = Instance.new('Frame')
    Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Fill.AnchorPoint = Vector2.new(0, 0.5)
    Fill.BackgroundTransparency = 0.5
    Fill.Position = UDim2.new(0, 0, 0.5, 0)
    Fill.Name = 'Fill'
    Fill.Size = UDim2.new(0, 103, 0, 4)
    Fill.BorderSizePixel = 0
    Fill.BackgroundColor3 = Window._mainColor
    Fill.Parent = Drag
    
    local UICorner2 = Instance.new('UICorner')
    UICorner2.CornerRadius = UDim.new(0, 3)
    UICorner2.Parent = Fill
    
    local Circle = Instance.new('Frame')
    Circle.AnchorPoint = Vector2.new(1, 0.5)
    Circle.Name = 'Circle'
    Circle.Position = UDim2.new(1, 0, 0.5, 0)
    Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Circle.Size = UDim2.new(0, 6, 0, 6)
    Circle.BorderSizePixel = 0
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = Fill
    
    local UICorner3 = Instance.new('UICorner')
    UICorner3.CornerRadius = UDim.new(1, 0)
    UICorner3.Parent = Circle
    
    local Value = Instance.new('TextLabel')
    Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Value.TextColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(255, 255, 255)
    Value.TextTransparency = 0.2
    Value.Text = '50'
    Value.Name = 'Value'
    Value.Size = UDim2.new(0, 42, 0, 13)
    Value.AnchorPoint = Vector2.new(1, 0)
    Value.Position = UDim2.new(1, 0, 0, 0)
    Value.BackgroundTransparency = 1
    Value.TextXAlignment = Enum.TextXAlignment.Right
    Value.BorderSizePixel = 0
    Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Value.TextSize = 10
    Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Value.Parent = Slider

    function SliderManager:Set(value)
    if settings.Locked then
        return
    end
    
    local steppedValue
    if step > 0 then
        steppedValue = math.floor((value - min) / step + 0.5) * step + min
        steppedValue = math.clamp(steppedValue, min, max)
    else
        steppedValue = math.clamp(value, min, max)
    end
    
    if settings.Flag then
        Window._config._flags[settings.Flag] = steppedValue
        Config:save(tostring(game.GameId), Window._config)
    end
        
    local percentage = (steppedValue - min) / (max - min)
    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
    
    if step >= 1 then
        Value.Text = tostring(math.floor(steppedValue))
    else
        local decimalPlaces = math.max(0, -math.floor(math.log10(step)))
        Value.Text = string.format("%." .. decimalPlaces .. "f", steppedValue)
    end
    
    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
    }):Play()
    
    if settings.Callback then
        settings.Callback(steppedValue)
    end
end
    if settings.Flag and Window:flag_type(settings.Flag, 'number') then
        SliderManager:Set(Window._config._flags[settings.Flag])
    else
        SliderManager:Set(settings.Default or 50)
    end
    
    local dragging = false
    local function updateSlider(input)
        if not dragging then return end
        
        local absolutePosition
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            absolutePosition = input.Position.X
        elseif input.UserInputType == Enum.UserInputType.Touch then
            absolutePosition = input.Position.X
        else
            return
        end
        
        local relativeX = (absolutePosition - Drag.AbsolutePosition.X) / Drag.AbsoluteSize.X
        local percentage = math.clamp(relativeX, 0, 1)
        local rawValue = min + (max - min) * percentage
        
        local value
        if step > 0 then
            value = math.floor((rawValue - min) / step + 0.5) * step + min
            value = math.clamp(value, min, max)
        else
            value = math.clamp(rawValue, min, max)
        end
        
        SliderManager:Set(value)
    end

    Slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    Slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    Slider.InputChanged:Connect(function(input)
        if dragging then
            updateSlider(input)
        end
    end)

    Drag.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    Drag.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    Drag.InputChanged:Connect(function(input)
        if dragging then
            updateSlider(input)
        end
    end)
    updateSectionCanvas()
    return SliderManager
end
    
    function ModuleManager:Dropdown(settings)
    local function tableContains(tbl, value)
        for _, v in ipairs(tbl) do
            if v == value then
                return true
            end
        end
        return false
    end
    
    local function tableFind(tbl, value)
        for i, v in ipairs(tbl) do
            if v == value then
                return i
            end
        end
        return nil
    end
    function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end
    LayoutOrderModule = LayoutOrderModule + 1
    local DropdownManager = {
        _state = false,
        _multi = settings.Multi or false,
        _allowNone = settings.AllowNone or false,
        _selectedValues = {}
    }
    
    local options = settings.Values or settings.Options or {}
    if settings.Multi then
        if settings.Value and type(settings.Value) == "table" then
            DropdownManager._selectedValues = settings.Value
        else
            DropdownManager._selectedValues = {}
        end
    else
        if settings.Value then
            if type(settings.Value) == "string" then
                DropdownManager._selectedValues = {settings.Value}
            elseif type(settings.Value) == "table" then
                DropdownManager._selectedValues = settings.Value
            else
                DropdownManager._selectedValues = {}
            end
        elseif settings.Default then
            DropdownManager._selectedValues = {settings.Default}
        else
            DropdownManager._selectedValues = {}
        end
    end

    if ModuleManager._size == 0 then
        ModuleManager._size = 11
    end

    ModuleManager._size += 44

    if ModuleManager._state then
        Module.Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
    end
    
    Options.Size = UDim2.fromOffset(moduleWidth, ModuleManager._size)

    local Dropdown = Instance.new('TextButton')
    Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
    Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Dropdown.Text = ''
    Dropdown.AutoButtonColor = false
    Dropdown.BackgroundTransparency = 1
    Dropdown.Name = 'Dropdown'
    Dropdown.Size = UDim2.new(0, innerWidth, 0, 39)
    Dropdown.BorderSizePixel = 0
    Dropdown.TextSize = 14
    Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Dropdown.Parent = Options
    Dropdown.LayoutOrder = LayoutOrderModule

    local hasDescription = settings.Desc or settings.Description
    if hasDescription then
        Dropdown.Size = UDim2.new(0, innerWidth, 0, 52)
        ModuleManager._size += 13
        Options.Size = UDim2.fromOffset(moduleWidth, ModuleManager._size)
        
        if ModuleManager._state then
            Module.Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
        end
    end
    
    local TextLabel = Instance.new('TextLabel')
    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    TextLabel.TextSize = 11
    TextLabel.TextColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(255, 255, 255)
    TextLabel.TextTransparency = 0.2
    TextLabel.Text = settings.Title or "Dropdown"
    TextLabel.Size = UDim2.new(0, innerWidth, 0, 13)
    TextLabel.Position = UDim2.new(0, 0, hasDescription and 0 or 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.BorderSizePixel = 0
    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Parent = Dropdown

    if hasDescription then
        local DescriptionLabel = Instance.new('TextLabel')
        DescriptionLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        DescriptionLabel.TextSize = 9
        DescriptionLabel.TextColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Isotopia.Theme.textMuted
        DescriptionLabel.TextTransparency = 0.3
        DescriptionLabel.Text = settings.Desc or settings.Description or ""
        DescriptionLabel.Size = UDim2.new(0, innerWidth, 0, 12)
        DescriptionLabel.Position = UDim2.new(0, 0, 0.5, 0)
        DescriptionLabel.BackgroundTransparency = 1
        DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescriptionLabel.TextWrapped = true
        DescriptionLabel.BorderSizePixel = 0
        DescriptionLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        DescriptionLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        DescriptionLabel.Parent = Dropdown
    end
    
    local Box = Instance.new('TextButton')
    Box.ClipsDescendants = true
    Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Box.AnchorPoint = Vector2.new(0.5, 0)
    Box.BackgroundTransparency = 0.2
    Box.Position = UDim2.new(0.5, 0, hasDescription and 1.4 or 1.2, 0)
    Box.Name = 'Box'
    Box.Size = UDim2.new(0, innerWidth, 0, 22)
    Box.BorderSizePixel = 0
    Box.BackgroundColor3 = Isotopia.Theme.surface
    Box.Text = ""
    Box.AutoButtonColor = false
    Box.Parent = TextLabel
    Box.ZIndex = 10
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Box
    
    local CurrentOption = Instance.new('TextLabel')
    CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    CurrentOption.TextColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Isotopia.Theme.text
    CurrentOption.TextTransparency = 0.05
    CurrentOption.Name = 'CurrentOption'
    CurrentOption.Size = UDim2.new(1, -20, 0, 13)
    CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
    CurrentOption.Position = UDim2.new(0.05, 0, 0.5, 0)
    CurrentOption.BackgroundTransparency = 1
    CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
    CurrentOption.BorderSizePixel = 0
    CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
    CurrentOption.TextSize = 10
    CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CurrentOption.Parent = Box
    
    local function updateDisplayText()
        if #DropdownManager._selectedValues == 0 then
            CurrentOption.Text = "Select..."
        elseif #DropdownManager._selectedValues == 1 then
            CurrentOption.Text = DropdownManager._selectedValues[1]
        else
            CurrentOption.Text = #DropdownManager._selectedValues .. " selected"
        end
    end
    updateDisplayText()
    
    local Arrow = Instance.new('ImageLabel')
    Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Arrow.AnchorPoint = Vector2.new(0, 0.5)
    Arrow.Image = 'rbxassetid://84232453189324'
    Arrow.BackgroundTransparency = 1
    Arrow.Position = UDim2.new(0.91, 0, 0.5, 0)
    Arrow.Name = 'Arrow'
    Arrow.Size = UDim2.new(0, 8, 0, 8)
    Arrow.BorderSizePixel = 0
    Arrow.ImageColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Window._mainColor
    Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Arrow.Parent = Box
    
    local OptionsListGui = Instance.new('ScreenGui')
    OptionsListGui.Name = 'DropdownOptionsList'
    OptionsListGui.ResetOnSpawn = false
    OptionsListGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    OptionsListGui.Parent = getSafeParent()
    
    local OptionsList = Instance.new('Frame')
    OptionsList.Name = 'OptionsList'
    OptionsList.Size = UDim2.new(0, innerWidth, 0, 0)
    OptionsList.BackgroundColor3 = Isotopia.Theme.surface
    OptionsList.BackgroundTransparency = 0.1
    OptionsList.BorderSizePixel = 0
    OptionsList.Visible = false
    OptionsList.ZIndex = 999
    OptionsList.ClipsDescendants = true
    OptionsList.Parent = OptionsListGui
    
    local OptionsListCorner = Instance.new('UICorner')
    OptionsListCorner.CornerRadius = UDim.new(0, 4)
    OptionsListCorner.Parent = OptionsList
    
    local OptionsListUIStroke = Instance.new('UIStroke')
    OptionsListUIStroke.Color = Isotopia.Theme.stroke
    OptionsListUIStroke.Thickness = 1
    OptionsListUIStroke.Transparency = 0.3
    OptionsListUIStroke.Parent = OptionsList
    
    local OptionsListLayout = Instance.new('UIListLayout')
    OptionsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    OptionsListLayout.Padding = UDim.new(0, 1)
    OptionsListLayout.Parent = OptionsList
    
    local OptionsListPadding = Instance.new('UIPadding')
    OptionsListPadding.PaddingTop = UDim.new(0, 3)
    OptionsListPadding.PaddingBottom = UDim.new(0, 3)
    OptionsListPadding.Parent = OptionsList
    
   function DropdownManager:Set(value, isToggle)
    if settings.Locked then
        return
    end
    
    if DropdownManager._multi then
        if isToggle then
            local index = tableFind(DropdownManager._selectedValues, value)
            if index then
                table.remove(DropdownManager._selectedValues, index)
            else
                table.insert(DropdownManager._selectedValues, value)
            end
        else
            if type(value) == "table" then
                DropdownManager._selectedValues = value
            else
                DropdownManager._selectedValues = {value}
            end
        end
    else
        if DropdownManager._allowNone and DropdownManager._selectedValues[1] == value then
            DropdownManager._selectedValues = {}
        else
            DropdownManager._selectedValues = {value} 
        end
    end
    
    for _, optionBtn in pairs(OptionsList:GetChildren()) do
        if optionBtn:IsA("TextButton") and optionBtn.Name == "Option" then
            local optionText = optionBtn.Text
            if optionText:sub(1, 2) == "✓ " then
                optionText = optionText:sub(3)
            end
            
            local isSelected = tableContains(DropdownManager._selectedValues, optionText)
            
            if DropdownManager._multi then
                optionBtn.Text = isSelected and "✓ " .. optionText or optionText
            end
            optionBtn.TextTransparency = isSelected and 0 or 0.3
        end
    end
    
    updateDisplayText()
    
    if settings.Flag then
        local currentValue
        if DropdownManager._multi then
            if #DropdownManager._selectedValues > 0 then
                currentValue = table.concat(DropdownManager._selectedValues, ", ")
            else
                currentValue = ""
            end
        else
            currentValue = #DropdownManager._selectedValues > 0 and DropdownManager._selectedValues[1] or ""
        end

        Window._config._flags[settings.Flag] = currentValue
        Config:save(tostring(game.GameId), Window._config)
    end
    
    if settings.Callback then
        if DropdownManager._multi then
            settings.Callback(DropdownManager._selectedValues)
        else
            settings.Callback(#DropdownManager._selectedValues > 0 and DropdownManager._selectedValues[1] or "")
        end
    end
end

if settings.Flag and Window._config._flags[settings.Flag] then
    local savedValue = Window._config._flags[settings.Flag]
    
    if type(savedValue) == "string" then
        if DropdownManager._multi then
            DropdownManager._selectedValues = {}
            if savedValue ~= "" then
                for option in string.gmatch(savedValue, "([^,]+)") do
                    local trimmed = string.gsub(option, "^%s*(.-)%s*$", "%1")
                    table.insert(DropdownManager._selectedValues, trimmed)
                end
            end
        else
            DropdownManager._selectedValues = {savedValue}
        end
    elseif type(savedValue) == "table" then
        DropdownManager._selectedValues = savedValue
    end
    
    updateDisplayText()
end
    
    function DropdownManager:Toggle()
        if settings.Locked then
            return
        end
        
        if DropdownManager._state then
            OptionsList.Visible = false
            TweenService:Create(Arrow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Rotation = 0
            }):Play()
            TweenService:Create(OptionsList, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, innerWidth, 0, 0)
            }):Play()
            
            task.wait(0.3)
            OptionsListGui.Enabled = false
        else
            OptionsListGui.Enabled = true
         
            local boxAbsPos = Box.AbsolutePosition
            local boxAbsSize = Box.AbsoluteSize
            OptionsList.Position = UDim2.new(0, boxAbsPos.X, 0, boxAbsPos.Y + boxAbsSize.Y)
            OptionsList.Size = UDim2.new(0, innerWidth, 0, 0)
            OptionsList.Visible = true
            
            TweenService:Create(Arrow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Rotation = 180
            }):Play()
            
            TweenService:Create(OptionsList, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, innerWidth, 0, #options * 18 + 6)
            }):Play()
        end
        
        DropdownManager._state = not DropdownManager._state
    end

    if options and #options > 0 then
        for _, option in pairs(options) do
        local Option = Instance.new('TextButton')
        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Option.TextSize = 10
        Option.Size = UDim2.new(1, 0, 0, 16)
        Option.TextColor3 = settings.Locked and Color3.fromRGB(128, 128, 128) or Isotopia.Theme.text
        Option.TextTransparency = 0.3
        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Option.Text = option
        Option.AutoButtonColor = false
        Option.Name = 'Option'
        Option.BackgroundTransparency = 1
        Option.TextXAlignment = Enum.TextXAlignment.Left
        Option.BorderSizePixel = 0
        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Option.Parent = OptionsList
        
        local OptionPadding = Instance.new('UIPadding')
        OptionPadding.PaddingLeft = UDim.new(0, 8)
        OptionPadding.Parent = Option
        
        local isSelected = tableContains(DropdownManager._selectedValues, option)
        if isSelected then
            Option.TextTransparency = 0
            if DropdownManager._multi then
                Option.Text = "✓ " .. option
            end
        end
        
        Option.MouseEnter:Connect(function()
            if not settings.Locked then
                TweenService:Create(Option, TweenInfo.new(0.2), {
                    BackgroundTransparency = 0.7,
                    TextTransparency = 0
                }):Play()
            end
        end)
        
        Option.MouseLeave:Connect(function()
            if not settings.Locked then
                local isSelected = tableContains(DropdownManager._selectedValues, option)
                TweenService:Create(Option, TweenInfo.new(0.2), {
                    BackgroundTransparency = 1,
                    TextTransparency = isSelected and 0 or 0.3
                }):Play()
            end
        end)
        
        Option.MouseButton1Click:Connect(function()
            DropdownManager:Set(option, true)
            
            local isSelected = tableContains(DropdownManager._selectedValues, option)
            if DropdownManager._multi then
                Option.Text = isSelected and "✓ " .. option or option
            end
            Option.TextTransparency = isSelected and 0 or 0.3
            
            if not DropdownManager._multi then
                DropdownManager:Toggle()
            end
        end)
    end
    end
    
    Box.MouseButton1Click:Connect(function()
        DropdownManager:Toggle()
    end)
    
    local function handleOutsideClick(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            if OptionsList.Visible and OptionsListGui.Enabled then
                local mousePos = input.Position
                local listAbsPos = OptionsList.AbsolutePosition
                local listAbsSize = OptionsList.AbsoluteSize
                local boxAbsPos = Box.AbsolutePosition
                local boxAbsSize = Box.AbsoluteSize
                
                local inList = mousePos.X >= listAbsPos.X and mousePos.X <= listAbsPos.X + listAbsSize.X and
                              mousePos.Y >= listAbsPos.Y and mousePos.Y <= listAbsPos.Y + listAbsSize.Y
                              
                local inBox = mousePos.X >= boxAbsPos.X and mousePos.X <= boxAbsPos.X + boxAbsSize.X and
                             mousePos.Y >= boxAbsPos.Y and mousePos.Y <= boxAbsPos.Y + boxAbsSize.Y
                
                if not inList and not inBox then
                    DropdownManager:Toggle()
                end
            end
        end
    end
    
    UserInputService.InputBegan:Connect(handleOutsideClick)
    
    Module.AncestryChanged:Connect(function()
        if not Module.Parent then
            OptionsListGui:Destroy()
        end
    end)
    
    updateSectionCanvas()
    function DropdownManager:GetValue()
        if DropdownManager._multi then
            return DropdownManager._selectedValues
        else
            return #DropdownManager._selectedValues > 0 and DropdownManager._selectedValues[1] or ""
        end
    end
    
    function DropdownManager:SetValue(value)
        DropdownManager:Set(value, false)
    end
    
    function DropdownManager:Clear()
        DropdownManager._selectedValues = {}
        updateDisplayText()
        if settings.Callback then
            if DropdownManager._multi then
                settings.Callback({})
            else
                settings.Callback("")
            end
        end
    end
    return DropdownManager
end
    
    function ModuleManager:Checkbox(settings)
    LayoutOrderModule = LayoutOrderModule + 1
    
    if ModuleManager._size == 0 then
        ModuleManager._size = 11
    end
    
    ModuleManager._size += 20
    
    if ModuleManager._state then
        Module.Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
    end
    
    Options.Size = UDim2.fromOffset(moduleWidth, ModuleManager._size)
    
    local CheckboxManager = { _state = settings.Default or false }
    
    local Checkbox = Instance.new("TextButton")
    Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
    Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Checkbox.Text = ""
    Checkbox.AutoButtonColor = false
    Checkbox.BackgroundTransparency = 1
    Checkbox.Name = "Checkbox"
    Checkbox.Size = UDim2.new(0, innerWidth, 0, 15)
    Checkbox.BorderSizePixel = 0
    Checkbox.TextSize = 14
    Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Checkbox.Parent = Options
    Checkbox.LayoutOrder = LayoutOrderModule
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    TitleLabel.TextSize = 11
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextTransparency = 0.2
    TitleLabel.Text = settings.Title or "Checkbox"
    TitleLabel.Size = UDim2.new(0, 142, 0, 13)
    TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
    TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Checkbox

    local KeybindBox = Instance.new("Frame")
    KeybindBox.Name = "KeybindBox"
    KeybindBox.Size = UDim2.fromOffset(14, 14)
    KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
    KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
    KeybindBox.BackgroundColor3 = Window._mainColor
    KeybindBox.BorderSizePixel = 0
    KeybindBox.Parent = Checkbox
    
    local KeybindCorner = Instance.new("UICorner")
    KeybindCorner.CornerRadius = UDim.new(0, 4)
    KeybindCorner.Parent = KeybindBox
    
    local KeybindLabel = Instance.new("TextLabel")
    KeybindLabel.Name = "KeybindLabel"
    KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
    KeybindLabel.BackgroundTransparency = 1
    KeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeybindLabel.TextScaled = false
    KeybindLabel.TextSize = 10
    KeybindLabel.Font = Enum.Font.SourceSans
    KeybindLabel.Text = Window._config._keybinds[settings.Flag] 
        and string.gsub(tostring(Window._config._keybinds[settings.Flag]), "Enum.KeyCode.", "") 
        or "..."
    KeybindLabel.Parent = KeybindBox
    
    local Box = Instance.new("Frame")
    Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Box.AnchorPoint = Vector2.new(1, 0.5)
    Box.BackgroundTransparency = 0.9
    Box.Position = UDim2.new(1, 0, 0.5, 0)
    Box.Name = "Box"
    Box.Size = UDim2.new(0, 15, 0, 15)
    Box.BorderSizePixel = 0
    Box.BackgroundColor3 = Window._mainColor
    Box.Parent = Checkbox
    
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 4)
    BoxCorner.Parent = Box
    
    local Fill = Instance.new("Frame")
    Fill.AnchorPoint = Vector2.new(0.5, 0.5)
    Fill.BackgroundTransparency = 0.2
    Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
    Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Fill.Name = "Fill"
    Fill.BorderSizePixel = 0
    Fill.BackgroundColor3 = Window._mainColor
    Fill.Parent = Box
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 3)
    FillCorner.Parent = Fill
    
    function CheckboxManager:change_state(state: boolean)
    self._state = state
    if self._state then
        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.7
        }):Play()
        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(9, 9)
        }):Play()
    else
        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.9
        }):Play()
        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(0, 0)
        }):Play()
    end
    
    if settings.Flag then
        Window._config._flags[settings.Flag] = self._state
        Config:save(tostring(game.GameId), Window._config)
    end
        
    if settings.Callback then
        settings.Callback(self._state)
    end
end

if settings.Flag and Window:flag_type(settings.Flag, "boolean") then 
    CheckboxManager:change_state(Window._config._flags[settings.Flag])
elseif settings.Default then
    CheckboxManager:change_state(settings.Default)
end
    
    function CheckboxManager:scale_keybind(empty: boolean)
        if Window._config._keybinds[settings.Flag] and not empty then
            local keybind_string = string.gsub(tostring(Window._config._keybinds[settings.Flag]), 'Enum.KeyCode.', '')
            
            local font_params = Instance.new('GetTextBoundsParams')
            font_params.Text = keybind_string
            font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
            font_params.Size = 10
            font_params.Width = 10000
    
            local font_size = TextService:GetTextBoundsAsync(font_params)
            
            KeybindBox.Size = UDim2.fromOffset(font_size.X + 6, 14)
            KeybindLabel.Text = keybind_string
        else
            KeybindBox.Size = UDim2.fromOffset(14, 14)
            KeybindLabel.Text = "..."
        end
    end
    
    function CheckboxManager:connect_keybind()
        if not Window._config._keybinds[settings.Flag] then
            return
        end

        if Connections[settings.Flag..'_keybind'] then
            Connections[settings.Flag..'_keybind']:Disconnect()
        end

        Connections[settings.Flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
            if process then
                return
            end
            
            if tostring(input.KeyCode) ~= Window._config._keybinds[settings.Flag] then
                return
            end
            
            CheckboxManager:change_state(not CheckboxManager._state)
        end)
    end

    if settings.Flag and Window._config._keybinds[settings.Flag] then
        local keybind_string = string.gsub(tostring(Window._config._keybinds[settings.Flag]), 'Enum.KeyCode.', '')
        KeybindLabel.Text = keybind_string
        CheckboxManager:scale_keybind()
        CheckboxManager:connect_keybind()
    end
    
    Checkbox.MouseButton1Click:Connect(function()
        CheckboxManager:change_state(not CheckboxManager._state)
    end)
    
    Checkbox.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
        if Window._choosing_keybind then return end

        Window._choosing_keybind = true
        local chooseConnection
        chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
            if processed then return end
            if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if keyInput.KeyCode == Enum.KeyCode.Unknown then return end

            if keyInput.KeyCode == Enum.KeyCode.Backspace then
                CheckboxManager:scale_keybind(true)
                Window._config._keybinds[settings.Flag] = nil
                Config:save(tostring(game.GameId), Window._config)
                KeybindLabel.Text = "..."
                if Connections[settings.Flag .. "_keybind"] then
                    Connections[settings.Flag .. "_keybind"]:Disconnect()
                    Connections[settings.Flag .. "_keybind"] = nil
                end
                chooseConnection:Disconnect()
                Window._choosing_keybind = false
                return
            end

            chooseConnection:Disconnect()
            Window._config._keybinds[settings.Flag] = tostring(keyInput.KeyCode)
            Config:save(tostring(game.GameId), Window._config)
            if Connections[settings.Flag .. "_keybind"] then
                Connections[settings.Flag .. "_keybind"]:Disconnect()
                Connections[settings.Flag .. "_keybind"] = nil
            end
            CheckboxManager:connect_keybind()
            CheckboxManager:scale_keybind()
            Window._choosing_keybind = false

            local keybind_string = string.gsub(tostring(Window._config._keybinds[settings.Flag]), "Enum.KeyCode.", "")
            KeybindLabel.Text = keybind_string
        end)
    end)
    
    updateSectionCanvas()
    return CheckboxManager
end
    
    function ModuleManager:Label(settings)
        LayoutOrderModule = LayoutOrderModule + 1
        
        if ModuleManager._size == 0 then
            ModuleManager._size = 11
        end
        
        ModuleManager._size += 25
        
        if ModuleManager._state then
            Module.Size = UDim2.fromOffset(moduleWidth, 93 + ModuleManager._size)
        end
        
        Options.Size = UDim2.fromOffset(moduleWidth, ModuleManager._size)
        
        local Label = Instance.new('TextLabel')
        Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Label.TextColor3 = Isotopia.Theme.text
        Label.TextTransparency = 0.1
        Label.Text = settings.Text or "Label"
        Label.Size = UDim2.new(0, innerWidth, 0, 20)
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.BorderSizePixel = 0
        Label.TextSize = 12
        Label.Parent = Options
        Label.LayoutOrder = LayoutOrderModule
        updateSectionCanvas()
        return Label
    end
    
    if settings.Default then
        ModuleManager:Toggle(true)
    end
    updateSectionCanvas()
    return ModuleManager
end

function Isotopia:Notify(settings)
    local NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "IsotopiaNotification"
    NotificationGui.DisplayOrder = 999
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = getSafeParent()
    
    local Notification = Instance.new("Frame")
    Notification.Name = "Notification"
    Notification.Size = UDim2.new(0, 280, 0, 70)
    Notification.BackgroundColor3 = Isotopia.Theme.background
    Notification.BackgroundTransparency = Isotopia._current_window and Isotopia._current_window._transparent and 0.5 or 0.07
    Notification.BorderSizePixel = 0

    Notification.Position = UDim2.new(0.5, 0, 0.92, 0)
    Notification.AnchorPoint = Vector2.new(0.5, 1)
    Notification.Parent = NotificationGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 15)
    UICorner.Parent = Notification

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Isotopia.Theme.stroke
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = Isotopia._current_window and Isotopia._current_window._transparent and 0.5 or 0.2
    UIStroke.Parent = Notification
    
    local Icon = Instance.new("ImageLabel")
    Icon.Name = "Icon"
    Icon.Image = getIcon(settings.Icon)
    Icon.Size = UDim2.new(0, 20, 0, 20)
    Icon.Position = UDim2.new(0, 10, 0.5, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.BackgroundTransparency = 1
    Icon.Parent = Notification
    
    if settings.Spinning then
        TweenService:Create(Icon, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
            Rotation = 360
        }):Play()
    end
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Text = settings.Title or "Notification"
    Title.TextColor3 = Isotopia.Theme.text
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(0, 235, 0, 18)
    Title.Position = UDim2.new(0, 38, 0, 13)
    Title.TextWrapped = true
    Title.Parent = Notification
    
    local Content = Instance.new("TextLabel")
    Content.Name = "Content"
    Content.Text = settings.Content or settings.Text or ""
    Content.TextColor3 = Isotopia.Theme.textMuted
    Content.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Content.TextSize = 11
    Content.TextXAlignment = Enum.TextXAlignment.Left
    Content.BackgroundTransparency = 1
    Content.Size = UDim2.new(0, 235, 0, 30)
    Content.Position = UDim2.new(0, 40, 0, 30)
    Content.TextWrapped = true
    Content.Visible = (settings.Content or settings.Text) and true or false
    Content.Parent = Notification
    
    if not (settings.Content or settings.Text) then
        Title.Position = UDim2.new(0, 38, 0.5, 0)
        Title.AnchorPoint = Vector2.new(0, 0.5)
    end
    
    Notification.Position = UDim2.new(0.5, 0, 1.2, 0)
    
    local slideUp = TweenService:Create(Notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.92, 0)
    })
    slideUp:Play()
    
    local duration = settings.Duration or 5
    task.delay(duration, function()
        local slideDown = TweenService:Create(Notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 1.2, 0)
        })
        slideDown:Play()
        
        slideDown.Completed:Wait()
        NotificationGui:Destroy()
    end)
    
    Notification.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            local slideDown = TweenService:Create(Notification, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Position = UDim2.new(0.5, 0, 1.2, 0)
            })
            slideDown:Play()
            
            slideDown.Completed:Wait()
            NotificationGui:Destroy()
        end
    end)
    
    return Notification
end

function Isotopia:Popup(settings)
    local Window = Isotopia._current_window
    local cornerRadius = Window and Window._container and 
        Window._container:FindFirstChild("UICorner") and 
        Window._container.UICorner.CornerRadius or UDim.new(0, 10)

    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting
    TweenService:Create(blur, TweenInfo.new(0.1), { Size = 50 }):Play()

    local BlurGui = Instance.new("ScreenGui")
    BlurGui.Name = "IsotopiaBlur"
    BlurGui.ResetOnSpawn = false
    BlurGui.DisplayOrder = 998
    BlurGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    BlurGui.Parent = getSafeParent()

    local Backdrop = Instance.new("TextButton")
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.BackgroundTransparency = 1
    Backdrop.BorderSizePixel = 0
    Backdrop.Text = ""
    Backdrop.AutoButtonColor = false
    Backdrop.Active = true
    Backdrop.Name = "Backdrop"
    Backdrop.Parent = BlurGui

    local PopupGui = Instance.new("ScreenGui")
    PopupGui.Name = "IsotopiaPopup"
    PopupGui.ResetOnSpawn = false
    PopupGui.DisplayOrder = 999
    PopupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    PopupGui.Parent = getSafeParent()
    
    local popupScale = 1
    local device = Window and Window._device or "Unknown"
     if device == "PC" or device == "Unknown" then
        popupScale = 1.4
    end

    local PopupUIScale = Instance.new("UIScale")
    PopupUIScale.Scale = popupScale
    PopupUIScale.Parent = PopupFrame

    local PopupFrame = Instance.new("Frame")
    PopupFrame.Name = "PopupFrame"
    PopupFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    PopupFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    PopupFrame.Size = UDim2.new(0, 280, 0, 160)
    PopupFrame.BackgroundColor3 = Isotopia.Theme.inset
    PopupFrame.BackgroundTransparency = 1
    PopupFrame.BorderSizePixel = 0
    PopupFrame.Parent = PopupGui

    local PopupCorner = Instance.new("UICorner")
    PopupCorner.CornerRadius = cornerRadius
    PopupCorner.Parent = PopupFrame

    local PopupStroke = Instance.new("UIStroke")
    PopupStroke.Color = Isotopia.Theme.stroke
    PopupStroke.Thickness = 1.25
    PopupStroke.Transparency = 1
    PopupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    PopupStroke.Parent = PopupFrame

    local PopupGradient = Instance.new("UIGradient")
    PopupGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Isotopia.Theme.surface),
        ColorSequenceKeypoint.new(0.5, Isotopia.Theme.background),
        ColorSequenceKeypoint.new(1, Isotopia.Theme.inset)
    }
    PopupGradient.Rotation = 35
    PopupGradient.Parent = PopupFrame

    local TitleRow = Instance.new("Frame")
    TitleRow.BackgroundTransparency = 1
    TitleRow.Size = UDim2.new(1, -24, 0, 22)
    TitleRow.Position = UDim2.new(0, 12, 0, 12)
    TitleRow.Parent = PopupFrame

    local TitleIcon = Instance.new("ImageLabel")
    TitleIcon.Image = getIcon(settings.Icon)
    TitleIcon.ImageColor3 = Window and Window._mainColor or Isotopia.Theme.mainColor
    TitleIcon.Size = UDim2.new(0, 16, 0, 16)
    TitleIcon.AnchorPoint = Vector2.new(0, 0.5)
    TitleIcon.Position = UDim2.new(0, 0, 0.5, 0)
    TitleIcon.BackgroundTransparency = 1
    TitleIcon.ScaleType = Enum.ScaleType.Fit
    TitleIcon.Parent = TitleRow

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    TitleLabel.Text = settings.Title or "Popup"
    TitleLabel.TextColor3 = Isotopia.Theme.text
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1, -24, 1, 0)
    TitleLabel.Position = UDim2.new(0, 24, 0, 0)
    TitleLabel.Parent = TitleRow

    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ContentLabel.Text = settings.Content or ""
    ContentLabel.TextColor3 = Color3.fromRGB(160, 175, 195)
    ContentLabel.TextSize = 11
    ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ContentLabel.TextWrapped = true
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.Size = UDim2.new(1, -24, 0, 0)
    ContentLabel.AutomaticSize = Enum.AutomaticSize.Y
    ContentLabel.Position = UDim2.new(0, 12, 0, 38)
    ContentLabel.Parent = PopupFrame

    local function measureText(text, size, width, bold)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.Font = bold and Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold) or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
    params.Size = size
    params.Width = width
    local result = TextService:GetTextBoundsAsync(params)
    return result.X, result.Y
end

local padding = 12
local iconW = 24
local buttonH = 30

local titleMaxWidth = 280 - 24 - iconW
local titleTextW, titleTextH = measureText(settings.Title or "Popup", 14, 10000, true)

local popupWidth = math.max(280, math.min(420, titleTextW + 24 + iconW + padding * 2))

local contentH = select(2, measureText(settings.Content or "", 11, popupWidth - 24, false))
contentH = math.max(contentH, 14)

local titleH = 22
local totalHeight = padding + titleH + 6 + contentH + 10 + buttonH + padding

PopupFrame.Size = UDim2.new(0, popupWidth, 0, totalHeight)
ContentLabel.Size = UDim2.new(1, -24, 0, contentH)

local buttons = settings.Buttons or {}
local buttonCount = #buttons
local buttonWidth = buttonCount > 0 and math.floor((popupWidth - 24 - (buttonCount - 1) * 8) / buttonCount) or 0
local buttonsY = padding + titleH + 6 + contentH + 10

    for i, btnSettings in ipairs(buttons) do
        local xOffset = 12 + (i - 1) * (buttonWidth + 8)

        local Btn = Instance.new("TextButton")
        Btn.Name = "PopupButton_" .. i
        Btn.Size = UDim2.new(0, buttonWidth, 0, buttonH)
        Btn.Position = UDim2.new(0, xOffset, 0, buttonsY)
        Btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Btn.BackgroundTransparency = 0.3
        Btn.Text = ""
        Btn.AutoButtonColor = false
        Btn.BorderSizePixel = 0
        Btn.Parent = PopupFrame

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = cornerRadius
        BtnCorner.Parent = Btn

        local BtnStroke = Instance.new("UIStroke")
        BtnStroke.Color = Color3.fromRGB(255, 255, 255)
        BtnStroke.Thickness = 1
        BtnStroke.Transparency = 0.7
        BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        BtnStroke.Parent = Btn

        local BtnIcon = Instance.new("ImageLabel")
        BtnIcon.Image = getIcon(btnSettings.Icon)
        BtnIcon.ImageColor3 = Isotopia.Theme.text
        BtnIcon.Size = UDim2.new(0, 12, 0, 12)
        BtnIcon.AnchorPoint = Vector2.new(0, 0.5)
        BtnIcon.Position = UDim2.new(0, 10, 0.5, 0)
        BtnIcon.BackgroundTransparency = 1
        BtnIcon.ScaleType = Enum.ScaleType.Fit
        BtnIcon.Parent = Btn

        local BtnLabel = Instance.new("TextLabel")
        BtnLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        BtnLabel.Text = btnSettings.Title or "Button"
        BtnLabel.TextColor3 = Isotopia.Theme.text
        BtnLabel.TextSize = 11
        BtnLabel.BackgroundTransparency = 1
        BtnLabel.Size = UDim2.new(1, -30, 1, 0)
        BtnLabel.Position = UDim2.new(0, 28, 0, 0)
        BtnLabel.TextXAlignment = Enum.TextXAlignment.Left
        BtnLabel.Parent = Btn

        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.3 }):Play()
        end)

        Btn.MouseButton1Click:Connect(function()
    TweenService:Create(blur, TweenInfo.new(0.2), { Size = 0 }):Play()
    TweenService:Create(PopupFrame, TweenInfo.new(0.2), {
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(PopupStroke, TweenInfo.new(0.2), {
        Transparency = 1
    }):Play()

    for _, child in ipairs(PopupFrame:GetDescendants()) do
        pcall(function()
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
            elseif child:IsA("ImageLabel") then
                TweenService:Create(child, TweenInfo.new(0.2), { ImageTransparency = 1 }):Play()
            elseif child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            end
        end)
    end

    task.wait(0.25)
    PopupGui:Destroy()
    BlurGui:Destroy()
    blur:Destroy()

    if btnSettings.Callback then
        btnSettings.Callback()
    end
end)
    end

    task.defer(function()
        TweenService:Create(PopupFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.07
        }):Play()
        TweenService:Create(PopupStroke, TweenInfo.new(0.2), {
             Transparency = 0.2
        }):Play()
    end)

    return PopupFrame
end

return Isotopia
