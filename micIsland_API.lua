--// DYNAMIC ISLAND UI v2 (đen trắng) - LocalScript
--// Đặt trong: StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================== THEME / CẤU HÌNH ====================--
local T = {
	Bg      = Color3.fromRGB(8, 8, 8),
	Side    = Color3.fromRGB(12, 12, 12),
	Card    = Color3.fromRGB(14, 14, 14),
	Item    = Color3.fromRGB(26, 26, 26),
	Stroke  = Color3.fromRGB(40, 40, 40),
	Text    = Color3.fromRGB(245, 245, 245),
	Sub     = Color3.fromRGB(135, 135, 135),
	On      = Color3.fromRGB(230, 230, 230),
	Off     = Color3.fromRGB(48, 48, 48),
	Knob    = Color3.fromRGB(18, 18, 18),
	KnobOff = Color3.fromRGB(120, 120, 120),
}

local CFG = {
	HomeIcon   = "", -- dán "rbxassetid://ID" nếu muốn icon ảnh, để trống sẽ dùng ký tự ⌂
	IslandTop  = 10,
	PillSize   = Vector2.new(110, 32),
	WideSize   = Vector2.new(220, 46),
	StripWidth = 46,
}

local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
local WIN = Vector2.new(math.min(680, vp.X - 24), math.min(400, vp.Y - 110))
local SIDEBAR_W = WIN.X < 540 and 112 or 150

--==================== HELPERS ====================--
local function tw(obj, t, props, style, dir)
	local tween = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function corner(p, r) return new("UICorner", { CornerRadius = r or UDim.new(0, 10) }, p) end
local function addStroke(p, c, th) return new("UIStroke", { Color = c or T.Stroke, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end

local function lbl(parent, text, size, color, font, align)
	return new("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size or 14,
		TextColor3 = color or T.Text, Font = font or Enum.Font.GothamMedium,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local pages = {}
local function setScroll(on) for _, p in ipairs(pages) do p.ScrollingEnabled = on end end

local function drag(btn, onMove)
	local dragging = false
	btn.InputBegan:Connect(function(i)
		if isPress(i) then dragging = true; setScroll(false); onMove(i.Position, true) end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then onMove(i.Position, false) end
	end)
	UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then dragging = false; setScroll(true) end
	end)
end

local function snap(v, min, max, step)
	v = math.floor((v - min) / step + 0.5) * step + min
	return math.clamp(math.floor(v * 1000 + 0.5) / 1000, min, max)
end

--==================== ICON VẼ BẰNG FRAME (đen trắng) ====================--
local function slidersIcon(parent, pos)
	local f = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = pos, BackgroundTransparency = 1 }, parent)
	local parts = {}
	for idx, ky in ipairs({ 10, 5, 11 }) do
		local x = (idx - 1) * 7 + 3
		table.insert(parts, new("Frame", { Size = UDim2.fromOffset(2, 16), Position = UDim2.fromOffset(x, 1), BackgroundColor3 = T.Sub, BorderSizePixel = 0 }, f))
		table.insert(parts, new("Frame", { Size = UDim2.fromOffset(6, 3), Position = UDim2.fromOffset(x - 2, ky), BackgroundColor3 = T.Sub, BorderSizePixel = 0 }, f))
	end
	return f, function(c) for _, p in ipairs(parts) do p.BackgroundColor3 = c end end
end

--==================== SWITCH / KEYBIND ====================--
local function makeSwitch(parent, default, onChange, small)
	local W, H, K = 44, 24, 18
	if small then W, H, K = 38, 20, 14 end
	local sw = new("TextButton", { Size = UDim2.fromOffset(W, H), Text = "", AutoButtonColor = false, BackgroundColor3 = T.Off }, parent)
	corner(sw, UDim.new(1, 0))
	local knob = new("Frame", { Size = UDim2.fromOffset(K, K), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = T.KnobOff }, sw)
	corner(knob, UDim.new(1, 0))
	local obj = { State = default and true or false, Instance = sw }
	local function render(anim)
		local t = anim and 0.2 or 0
		tw(sw, t, { BackgroundColor3 = obj.State and T.On or T.Off })
		tw(knob, t, {
			Position = obj.State and UDim2.new(1, -(K + 3), 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = obj.State and T.Knob or T.KnobOff,
		})
	end
	function obj:Set(v, silent)
		obj.State = v and true or false
		render(true)
		if onChange and not silent then task.spawn(onChange, obj.State) end
	end
	sw.Activated:Connect(function() obj:Set(not obj.State) end)
	render(false)
	return obj
end

--==================== SCREEN GUI + ISLAND ====================--
local gui = new("ScreenGui", { Name = "DynamicIslandUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

local island = new("TextButton", {
	Name = "Island", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, CFG.IslandTop),
	Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.new(0, 0, 0), Text = "", AutoButtonColor = false, ZIndex = 5,
}, gui)
corner(island, UDim.new(1, 0)); addStroke(island, Color3.fromRGB(55, 55, 55))

-- Avatar tròn của người chơi, nằm BÊN TRONG Dynamic Island
local avatar = new("ImageLabel", {
    Name = "PlayerAvatar",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0, 20, 0.5, 0),
    Size = UDim2.fromOffset(27, 27),
    BackgroundColor3 = T.Item,
    BackgroundTransparency = 0,
    Image = "",
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 8,
}, island)
corner(avatar, UDim.new(1, 0))
addStroke(avatar, Color3.fromRGB(70, 70, 70), 1.5)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, avatar)

-- Bộ đếm thời gian nằm cạnh avatar, trượt sang phải khi mở Dynamic Island
local timerLabel = new("TextLabel", {
    Name = "IslandTimer",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 42, 0.5, 0),
    Size = UDim2.fromOffset(62, 24),
    BackgroundTransparency = 1,
    Text = "00:00",
    TextColor3 = T.Text,
    TextTransparency = 0,
    Font = Enum.Font.GothamSemibold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ClipsDescendants = true,
    ZIndex = 9,
}, island)

local timerStartedAt = os.clock()
local function formatElapsed(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    end
    return string.format("%02d:%02d", minutes, secs)
end

task.spawn(function()
    while gui.Parent do
        timerLabel.Text = formatElapsed(os.clock() - timerStartedAt)
        task.wait(1)
    end
end)

task.spawn(function()
    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)
    if ok and avatar.Parent then
        avatar.Image = image
    end
end)

local homeBtn = new("TextButton", {
	Name = "HomeButton", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.fromRGB(240, 240, 240),
	Text = (CFG.HomeIcon == "") and "⌂" or "", Font = Enum.Font.GothamBold, TextSize = 24,
	TextColor3 = Color3.fromRGB(10, 10, 10), TextTransparency = 1, AutoButtonColor = false, Visible = false, ZIndex = 6,
}, island)
corner(homeBtn, UDim.new(1, 0))
if CFG.HomeIcon ~= "" then
	new("ImageLabel", { BackgroundTransparency = 1, Image = CFG.HomeIcon, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), ImageColor3 = Color3.fromRGB(10, 10, 10) }, homeBtn)
end

--==================== WINDOW ====================--
local windowTop = CFG.IslandTop + CFG.WideSize.Y + 8

local window = new("CanvasGroup", {
	Name = "Window", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, windowTop),
	Size = UDim2.fromOffset(CFG.StripWidth, 0), BackgroundColor3 = T.Bg, GroupTransparency = 1, Visible = false, ZIndex = 2,
}, gui)
corner(window, UDim.new(0, 16)); addStroke(window, T.Stroke)

local main = new("Frame", {
	Name = "Main", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(WIN.X, WIN.Y), BackgroundTransparency = 1,
}, window)

-- Sidebar (TAB - trái)
local sidebar = new("Frame", { Size = UDim2.new(0, SIDEBAR_W, 1, 0), BackgroundColor3 = T.Side, BorderSizePixel = 0 }, main)
new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Stroke, BorderSizePixel = 0 }, sidebar)

local title = lbl(sidebar, "MY HUB", 16, T.Text, Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(18, 0)
title.Size = UDim2.new(1, -24, 0, 50)

local tabList = new("Frame", { Position = UDim2.fromOffset(10, 54), Size = UDim2.new(1, -20, 1, -64), BackgroundTransparency = 1 }, sidebar)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)

-- Content (MODULE - phải)
local content = new("Frame", { Position = UDim2.fromOffset(SIDEBAR_W, 0), Size = UDim2.new(1, -SIDEBAR_W, 1, 0), BackgroundTransparency = 1 }, main)

--==================== TAB / MODULE LIBRARY ====================--
local Tabs, currentTab = {}, nil

local switchId = 0
local function selectTab(tab)
	if currentTab == tab then return end
	currentTab = tab
	switchId += 1
	local id = switchId
	for _, t in ipairs(Tabs) do
		local a = (t == tab)
		tw(t.Button, 0.25, { BackgroundTransparency = a and 0 or 1, TextColor3 = a and T.Text or T.Sub })
		tw(t.Indicator, 0.25, { BackgroundTransparency = a and 0 or 1 })
		if not a and t.Group.Visible then -- tab cũ mờ dần + trượt nhẹ lên
			tw(t.Group, 0.18, { GroupTransparency = 1, Position = UDim2.fromOffset(0, -10) })
			task.delay(0.2, function() if t ~= currentTab then t.Group.Visible = false end end)
		end
	end
	if not tab.Group.Visible then -- tab mới bắt đầu từ dưới, mờ
		tab.Group.Position = UDim2.fromOffset(0, 16)
		tab.Group.GroupTransparency = 1
		tab.Group.Visible = true
	end
	task.delay(0.1, function()
		if id == switchId then
			tw(tab.Group, 0.4, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
		end
	end)
end

local function CreateTab(name)
	local tab = { _count = 0 }

	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Item, BackgroundTransparency = 1, Text = name,
		Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false, LayoutOrder = #Tabs + 1,
	}, tabList)
	corner(btn, UDim.new(0, 8))
	new("UIPadding", { PaddingLeft = UDim.new(0, 16) }, btn)
	local ind = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -10, 0.5, 0), Size = UDim2.fromOffset(3, 18), BackgroundColor3 = T.Text, BackgroundTransparency = 1, BorderSizePixel = 0 }, btn)
	corner(ind, UDim.new(1, 0))

	local group = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false }, content)
	local page = new("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = T.Text, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, group)
	table.insert(pages, page)

	local function column(anchorX, posX)
		local c = new("Frame", {
			AnchorPoint = Vector2.new(anchorX, 0), Position = UDim2.new(posX, anchorX == 1 and -8 or 0, 0, 0),
			Size = UDim2.new(0.5, -9, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		}, page)
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, c)
		return c
	end
	tab.Left, tab.Right = column(0, 0), column(1, 1)
	tab.Button, tab.Page, tab.Indicator, tab.Group = btn, page, ind, group
	table.insert(Tabs, tab)
	btn.Activated:Connect(function() selectTab(tab) end)

	---------------------------------------------------------------
	-- MODULE (card)
	---------------------------------------------------------------
	function tab:AddModule(opts)
		opts = opts or {}
		tab._count += 1
		local side = opts.Side or ((tab._count % 2 == 1) and "Left" or "Right")
		local m = { Enabled = false }

		local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Card, LayoutOrder = tab._count }, side == "Left" and tab.Left or tab.Right)
		corner(card, UDim.new(0, 12)); addStroke(card, T.Stroke)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)

		-- Header
		local header = new("Frame", { Size = UDim2.new(1, 0, 0, 84), BackgroundTransparency = 1, LayoutOrder = 1 }, card)

		local nameL = lbl(header, opts.Name or "Module", 16, T.Text)
		nameL.Position = UDim2.fromOffset(18, 12); nameL.Size = UDim2.new(1, -64, 0, 20)
		local descL = lbl(header, opts.Description or "", 12, T.Sub, Enum.Font.Gotham)
		descL.Position = UDim2.fromOffset(18, 34); descL.Size = UDim2.new(1, -36, 0, 16)

		local _, setSliderColor = slidersIcon(header, UDim2.fromOffset(14, 53))
		local sw = makeSwitch(header, opts.Default, function(v)
			m.Enabled = v
			m:SetExpanded(v)
			if opts.Callback then opts.Callback(v) end
		end)
		sw.Instance.AnchorPoint = Vector2.new(1, 0.5)
		sw.Instance.Position = UDim2.new(1, -14, 0, 62)
		m.Enabled = sw.State
		function m:Set(v) sw:Set(v) end

		-- Body (mở rộng)
		local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 2 }, card)
		new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke, BorderSizePixel = 0 }, body)
		local inner = new("Frame", { Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, body)
		new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, inner)
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, inner)

		local expanded, order = false, 0
		local function nextOrder() order += 1; return order end
		local function row(h)
			return new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, inner)
		end

		local panels, anim, animating = {}, 0, false
		local function fullHeight() return inner.AbsoluteSize.Y + 1 end

		function m:SetExpanded(v)
			if order == 0 then return end -- module không có option thì không có gì để hiện
			v = v and true or false
			expanded = v
			setSliderColor(v and T.Text or T.Sub)
			anim += 1
			local id = anim
			animating = true
			local t = tw(body, 0.3, { Size = UDim2.new(1, 0, 0, v and fullHeight() or 0) })
			t.Completed:Connect(function()
				if id ~= anim then return end -- đã có lần bật/tắt mới hơn
				animating = false
				if expanded then
					body.Size = UDim2.new(1, 0, 0, fullHeight())
				else
					for _, p in ipairs(panels) do p.Visible = false end -- đóng dropdown/bảng màu đang mở
				end
			end)
		end
		inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if expanded and not animating then body.Size = UDim2.new(1, 0, 0, fullHeight()) end
		end)
		if sw.State then -- mặc định bật thì hiện sẵn
			expanded = true
			setSliderColor(T.Text)
			task.defer(function()
				if expanded and not animating then body.Size = UDim2.new(1, 0, 0, fullHeight()) end
			end)
		end

		----------------------------------------------------------
		-- CÁC LOẠI OPTION
		----------------------------------------------------------
		function m:AddLabel(text)
			local f = row(20)
			local l = lbl(f, text, 13, T.Text, Enum.Font.GothamBold)
			l.Size = UDim2.fromScale(1, 1)
		end

		function m:AddDivider()
			new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke, BorderSizePixel = 0, LayoutOrder = nextOrder() }, inner)
		end

		function m:AddButton(text, callback)
			local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Item, Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, AutoButtonColor = false, LayoutOrder = nextOrder() }, inner)
			corner(b, UDim.new(0, 8)); addStroke(b, T.Stroke)
			b.Activated:Connect(function()
				tw(b, 0.08, { BackgroundColor3 = T.On, TextColor3 = T.Knob })
				task.delay(0.1, function() tw(b, 0.25, { BackgroundColor3 = T.Item, TextColor3 = T.Text }) end)
				if callback then task.spawn(callback) end
			end)
		end

		-- Toggle (có thể kèm keybind)
		function m:AddToggle(name, default, callback)
			local f = row(28)
			local l = lbl(f, name, 13); l.Size = UDim2.new(1, -120, 1, 0)
			local s = makeSwitch(f, default, callback, true)
			s.Instance.AnchorPoint = Vector2.new(1, 0.5); s.Instance.Position = UDim2.new(1, 0, 0.5, 0)
			if default and callback then task.spawn(callback, true) end
			return s
		end

		-- Slider 1 đầu
		function m:AddSlider(name, min, max, default, callback, step)
			step = step or 1
			local f = row(38)
			local l = lbl(f, name, 13); l.Size = UDim2.new(1, -60, 0, 18)
			local val = lbl(f, "", 13, T.Sub, Enum.Font.Gotham, Enum.TextXAlignment.Right)
			val.AnchorPoint = Vector2.new(1, 0); val.Position = UDim2.fromScale(1, 0); val.Size = UDim2.fromOffset(60, 18)
			local bar = new("TextButton", { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = T.Off, Text = "", AutoButtonColor = false }, f)
			corner(bar, UDim.new(1, 0))
			local fill = new("Frame", { BackgroundColor3 = T.On, BorderSizePixel = 0 }, bar); corner(fill, UDim.new(1, 0))
			local knob = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.Text }, bar); corner(knob, UDim.new(1, 0))
			local function apply(v, silent)
				v = snap(v, min, max, step)
				local rel = (v - min) / (max - min)
				fill.Size = UDim2.fromScale(rel, 1)
				knob.Position = UDim2.new(rel, 0, 0.5, 0)
				val.Text = tostring(v)
				if callback and not silent then task.spawn(callback, v) end
			end
			drag(bar, function(pos)
				local rel = math.clamp((pos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				apply(min + rel * (max - min))
			end)
			apply(default or min, true)
			return { Set = function(_, v) apply(v) end }
		end

		-- Slider 2 đầu (khoảng min - max)
		function m:AddRange(name, min, max, lo, hi, callback, step)
			step = step or 1
			local f = row(38)
			local l = lbl(f, name, 13); l.Size = UDim2.new(1, -90, 0, 18)
			local val = lbl(f, "", 13, T.Sub, Enum.Font.Gotham, Enum.TextXAlignment.Right)
			val.AnchorPoint = Vector2.new(1, 0); val.Position = UDim2.fromScale(1, 0); val.Size = UDim2.fromOffset(90, 18)
			local bar = new("TextButton", { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = T.Off, Text = "", AutoButtonColor = false }, f)
			corner(bar, UDim.new(1, 0))
			local fill = new("Frame", { BackgroundColor3 = T.On, BorderSizePixel = 0 }, bar)
			local k1 = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.Text }, bar); corner(k1, UDim.new(1, 0))
			local k2 = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.Text }, bar); corner(k2, UDim.new(1, 0))
			local a, b, active = lo or min, hi or max, 1
			local function render(silent)
				local ra, rb = (a - min) / (max - min), (b - min) / (max - min)
				fill.Position = UDim2.fromScale(ra, 0); fill.Size = UDim2.fromScale(rb - ra, 1)
				k1.Position = UDim2.new(ra, 0, 0.5, 0); k2.Position = UDim2.new(rb, 0, 0.5, 0)
				val.Text = a .. " - " .. b
				if callback and not silent then task.spawn(callback, a, b) end
			end
			drag(bar, function(pos, began)
				local rel = math.clamp((pos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				local v = snap(min + rel * (max - min), min, max, step)
				if began then
					if a == b then active = (v > a) and 2 or 1
					else active = (math.abs(v - a) <= math.abs(v - b)) and 1 or 2 end
				end
				if active == 1 then a = math.min(v, b) else b = math.max(v, a) end
				render()
			end)
			render(true)
			return { Set = function(_, x, y) a, b = x, y; render() end }
		end

		-- Textbox
		function m:AddTextbox(name, default, placeholder, callback)
			local f = row(30)
			local l = lbl(f, name, 13); l.Size = UDim2.new(1, -140, 1, 0)
			local tb = new("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(130, 26),
				BackgroundColor3 = T.Item, Text = default or "", PlaceholderText = placeholder or "", PlaceholderColor3 = T.Sub,
				TextColor3 = T.Text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false,
			}, f)
			corner(tb, UDim.new(0, 8)); addStroke(tb, T.Stroke)
			tb.FocusLost:Connect(function(enter) if callback then task.spawn(callback, tb.Text, enter) end end)
			return tb
		end

		-- Dropdown helper
		local function dropdownBase(name, text)
			local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, inner)
			new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
			local head = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1 }, holder)
			local l = lbl(head, name, 13); l.Size = UDim2.new(1, -140, 1, 0)
			local btn = new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(130, 26),
				BackgroundColor3 = T.Item, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Text,
				AutoButtonColor = false, TextTruncate = Enum.TextTruncate.AtEnd,
			}, head)
			corner(btn, UDim.new(0, 8)); addStroke(btn, T.Stroke)
			new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, btn)
			local list = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Item, Visible = false, LayoutOrder = 2 }, holder)
			corner(list, UDim.new(0, 8)); addStroke(list, T.Stroke)
			new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)
			btn.Activated:Connect(function() list.Visible = not list.Visible end)
			table.insert(panels, list)
			return list, btn
		end

		-- Dropdown chọn 1
		function m:AddDropdown(name, options, default, callback)
			local current = default or options[1]
			local list, btn, setListOpen = dropdownBase(name, current)
			local items = {}
			local function refresh()
				btn.Text = current
				for opt, ob in pairs(items) do ob.TextColor3 = (opt == current) and T.Text or T.Sub end
			end
			for i, opt in ipairs(options) do
				local ob = new("TextButton", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = opt, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = i }, list)
				new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, ob)
				items[opt] = ob
				ob.Activated:Connect(function()
					current = opt; refresh(); list.Visible = false
					if callback then task.spawn(callback, opt) end
				end)
			end
			refresh()
			return { Set = function(_, v) current = v; refresh() end }
		end

		-- Dropdown chọn nhiều
		function m:AddMultiDropdown(name, options, defaults, callback)
			local sel = {}
			for _, d in ipairs(defaults or {}) do sel[d] = true end
			local list, btn = dropdownBase(name, "None")
			local boxes = {}
			local function chosen()
				local t = {}
				for _, opt in ipairs(options) do if sel[opt] then table.insert(t, opt) end end
				return t
			end
			local function refresh()
				local t = chosen()
				btn.Text = (#t == 0) and "None" or table.concat(t, ", ")
				for opt, box in pairs(boxes) do box.BackgroundTransparency = sel[opt] and 0 or 1 end
			end
			for i, opt in ipairs(options) do
				local ob = new("TextButton", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = opt, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = i }, list)
				new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, ob)
				local outer = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, ob)
				corner(outer, UDim.new(0, 3)); addStroke(outer, T.Sub)
				local box = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.On, BackgroundTransparency = 1 }, outer)
				corner(box, UDim.new(0, 3))
				boxes[opt] = box
				ob.Activated:Connect(function()
					sel[opt] = not sel[opt] or nil
					refresh()
					if callback then task.spawn(callback, chosen()) end
				end)
			end
			refresh()
			return { Get = chosen }
		end

		-- Bảng màu (palette + SV + hue)
		function m:AddColor(name, default, callback)
			default = default or Color3.new(1, 1, 1)
			local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, inner)
			new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
			local head = new("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 1 }, holder)
			local l = lbl(head, name, 13); l.Size = UDim2.new(1, -60, 1, 0)
			local swatch = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(38, 20), BackgroundColor3 = default, Text = "", AutoButtonColor = false }, head)
			corner(swatch, UDim.new(0, 6)); addStroke(swatch, T.Sub)

			local panel = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2 }, holder)
			new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, panel)

			-- preset palette
			local presets = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1 }, panel)
			new("UIGridLayout", { CellSize = UDim2.fromOffset(20, 20), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, presets)

			-- SV square
			local h, s, v = default:ToHSV()
			local svBox = new("TextButton", { Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = Color3.fromHSV(h, 1, 1), Text = "", AutoButtonColor = false, LayoutOrder = 2 }, panel)
			corner(svBox, UDim.new(0, 6))
			local wf = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, svBox); corner(wf, UDim.new(0, 6))
			new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, wf)
			local bf = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, svBox); corner(bf, UDim.new(0, 6))
			new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }, bf)
			local svMark = new("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 }, svBox)
			corner(svMark, UDim.new(1, 0)); addStroke(svMark, Color3.new(1, 1, 1), 2)

			-- Hue bar
			local hueBar = new("TextButton", { Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, LayoutOrder = 3 }, panel)
			corner(hueBar, UDim.new(1, 0))
			local seq = {}
			for i = 0, 6 do table.insert(seq, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1 == 0 and 0 or i / 6, 1, 1))) end
			new("UIGradient", { Color = ColorSequence.new(seq) }, hueBar)
			local hueMark = new("Frame", { Size = UDim2.fromOffset(4, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1) }, hueBar)
			corner(hueMark, UDim.new(1, 0)); addStroke(hueMark, Color3.new(0, 0, 0), 1)

			local function render(silent)
				local c = Color3.fromHSV(h, s, v)
				swatch.BackgroundColor3 = c
				svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				svMark.Position = UDim2.fromScale(s, 1 - v)
				hueMark.Position = UDim2.fromScale(h, 0.5)
				if callback and not silent then task.spawn(callback, c) end
			end
			local function setColor(c)
				local nh, ns, nv = c:ToHSV()
				if ns > 0 then h = nh end
				s, v = ns, nv
				render()
			end

			local palette = {
				Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170), Color3.fromRGB(85, 85, 85), Color3.fromRGB(0, 0, 0),
				Color3.fromRGB(255, 59, 48), Color3.fromRGB(255, 149, 0), Color3.fromRGB(255, 204, 0), Color3.fromRGB(52, 199, 89),
				Color3.fromRGB(0, 199, 190), Color3.fromRGB(10, 132, 255), Color3.fromRGB(94, 92, 230), Color3.fromRGB(255, 45, 85),
			}
			for i, c in ipairs(palette) do
				local p = new("TextButton", { BackgroundColor3 = c, Text = "", AutoButtonColor = false, LayoutOrder = i }, presets)
				corner(p, UDim.new(0, 6)); addStroke(p, T.Stroke)
				p.Activated:Connect(function() setColor(c) end)
			end

			drag(svBox, function(pos)
				s = math.clamp((pos.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
				v = 1 - math.clamp((pos.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
				render()
			end)
			drag(hueBar, function(pos)
				h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.999)
				render()
			end)
			swatch.Activated:Connect(function() panel.Visible = not panel.Visible end)
			table.insert(panels, panel)
			render(true)
			return { Set = function(_, c) setColor(c) end, Get = function() return Color3.fromHSV(h, s, v) end }
		end

		-- Nhóm nút bật/tắt dạng lưới (như Cooldown Protection / Auto Ability)
		function m:AddToggleButtons(list)
			local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, inner)
			new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 38), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
			for i, it in ipairs(list) do
				local state = it.Default or false
				local b = new("TextButton", { BackgroundColor3 = T.Item, Text = it.Name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = state and T.Text or T.Sub, AutoButtonColor = false, LayoutOrder = i }, holder)
				corner(b, UDim.new(0, 8)); addStroke(b, T.Stroke)
				local bar = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -5), Size = UDim2.new(0.7, 0, 0, 3), BackgroundColor3 = state and T.On or T.Off, BorderSizePixel = 0 }, b)
				corner(bar, UDim.new(1, 0))
				b.Activated:Connect(function()
					state = not state
					tw(b, 0.2, { TextColor3 = state and T.Text or T.Sub })
					tw(bar, 0.2, { BackgroundColor3 = state and T.On or T.Off })
					if it.Callback then task.spawn(it.Callback, state) end
				end)
			end
		end

		return m
	end

	if #Tabs == 1 then selectTab(tab) end
	return tab
end

--==================== ANIMATION (ISLAND + WINDOW) ====================--
local expanded, windowOpen, busy = false, false, false

local function openWindow()
	windowOpen = true
	window.Size = UDim2.fromOffset(CFG.StripWidth, 0)
	window.GroupTransparency = 1
	window.Visible = true
	tw(window, 0.2, { GroupTransparency = 0 })
	tw(window, 0.45, { Size = UDim2.fromOffset(CFG.StripWidth, WIN.Y) }).Completed:Wait()      -- kéo tờ giấy xuống
	tw(window, 0.5, { Size = UDim2.fromOffset(WIN.X, WIN.Y) }, Enum.EasingStyle.Back).Completed:Wait() -- bung rộng
end

local function closeWindow()
	windowOpen = false
	tw(window, 0.4, { Size = UDim2.fromOffset(CFG.StripWidth, WIN.Y) }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut).Completed:Wait()
	tw(window, 0.3, { GroupTransparency = 1 })
	tw(window, 0.4, { Size = UDim2.fromOffset(CFG.StripWidth, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Wait()
	window.Visible = false
end

local function expandIsland()
	expanded = true
	-- Mở rộng thanh; đồng hồ trượt qua bên phải, nút Home giữ chính giữa.
	tw(island, 0.5, { Size = UDim2.fromOffset(CFG.WideSize.X, CFG.WideSize.Y) }, Enum.EasingStyle.Back)
	tw(timerLabel, 0.42, {
		Position = UDim2.new(0, 153, 0.5, 0),
		Size = UDim2.fromOffset(72, 28),
		TextSize = 17,
		TextTransparency = 0,
	}, Enum.EasingStyle.Quint)
	homeBtn.Visible = true
	homeBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
	homeBtn.Size = UDim2.fromOffset(0, 0)
	tw(homeBtn, 0.45, { Size = UDim2.fromOffset(36, 36), TextTransparency = 0 }, Enum.EasingStyle.Back).Completed:Wait()
end

local function collapseIsland()
	expanded = false
	-- Đồng hồ luôn hiển thị khi đóng, trở về cạnh avatar và nhỏ hơn một chút.
	tw(timerLabel, 0.32, {
		Position = UDim2.new(0, 42, 0.5, 0),
		Size = UDim2.fromOffset(62, 24),
		TextSize = 14,
		TextTransparency = 0,
	}, Enum.EasingStyle.Quint)
	tw(homeBtn, 0.25, { Size = UDim2.fromOffset(0, 0), TextTransparency = 1 })
	task.wait(0.15)
	homeBtn.Visible = false
	tw(island, 0.45, { Size = UDim2.fromOffset(CFG.PillSize.X, CFG.PillSize.Y) }, Enum.EasingStyle.Back).Completed:Wait()
end

island.Activated:Connect(function()
	if busy then return end
	busy = true
	if not expanded then
		expandIsland()
	else
		if windowOpen then closeWindow() end
		collapseIsland()
	end
	busy = false
end)

homeBtn.Activated:Connect(function()
	if busy then return end
	busy = true
	tw(homeBtn, 0.12, { Size = UDim2.fromOffset(30, 30) }).Completed:Wait()
	tw(homeBtn, 0.2, { Size = UDim2.fromOffset(36, 36) }, Enum.EasingStyle.Back)
	if windowOpen then closeWindow() else openWindow() end
	busy = false
end)

task.defer(function()
	tw(island, 0.6, { Size = UDim2.fromOffset(CFG.PillSize.X, CFG.PillSize.Y) }, Enum.EasingStyle.Back)
end)

--==================== PUBLIC API ====================--
-- Dùng như thư viện: local UI = loadstring(game:HttpGet(URL))()
-- Sau đó: local tab = UI:CreateTab("Combat")
-- Không tạo tab demo mặc định; code bên ngoài tự thêm tab/module.

local API = {
    Version = "1.0.0",
    CreateTab = CreateTab,
    AddTab = CreateTab,
}

function API:GetGui()
    return gui
end

function API:GetIsland()
    return island
end

function API:GetAvatar()
    return avatar
end

function API:GetTimer()
    return timerLabel
end

function API:IsExpanded()
    return expanded
end

function API:IsWindowOpen()
    return windowOpen
end

function API:Open()
    task.spawn(function()
        if busy then return end
        busy = true
        if not expanded then expandIsland() end
        if not windowOpen then openWindow() end
        busy = false
    end)
end

function API:Close()
    task.spawn(function()
        if busy then return end
        busy = true
        if windowOpen then closeWindow() end
        if expanded then collapseIsland() end
        busy = false
    end)
end

function API:Toggle()
    if windowOpen then
        self:Close()
    else
        self:Open()
    end
end

function API:SetAvatarImage(image)
    if typeof(image) == "string" then
        avatar.Image = image
    end
end

function API:Destroy()
    if gui and gui.Parent then
        gui:Destroy()
    end
end

-- Hỗ trợ cả kiểu loader không nhận giá trị return.
_G.KittylolDynamicIsland = API
return API
