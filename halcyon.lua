--[[ Halcyon UI Library (Roblox / Luau)
	local Lib = loadstring(game:HttpGet("RAW_URL"))()
	Lib:Loading{...}  ->  Lib:Window{...}  ->  win:Tab{...}
	tab:Section/Toggle/Slider/Dropdown/MultiDropdown/ColorPicker/Input/Button/Keybind
	Lib:Notify{Title, Text, Type = "Info"|"Success"|"Warning"|"Error", Duration}
	Values live in Lib.Flags[Flag or Name] and are saved automatically (colors as hex strings, read them with Lib:GetColor(flag)).
]]
local UIS, TS, HS, TXT = game:GetService("UserInputService"), game:GetService("TweenService"), game:GetService("HttpService"), game:GetService("TextService")
local U, O, Sc, V2 = UDim2.new, UDim2.fromOffset, UDim2.fromScale, Vector2.new
local CEN, RIGHT, AX, AY, AXY = Enum.TextXAlignment.Center, Enum.TextXAlignment.Right, Enum.AutomaticSize.X, Enum.AutomaticSize.Y, Enum.AutomaticSize.XY
local MED, BOLD = Enum.FontWeight.Medium, Enum.FontWeight.Bold
local QUINT, LINEAR = Enum.EasingStyle.Quint, Enum.EasingStyle.Linear

local Lib = {Flags = {}, Saved = {}, Setters = {}, Conns = {}, Guis = {}, Icons = {}, Themes = {}, Folder = "Halcyon", Config = "default",
	FontFamily = "rbxasset://fonts/families/GothamSSm.json", Mono = Font.fromEnum(Enum.Font.RobotoMono)}
function Lib.Font(w) return Font.new(Lib.FontFamily, w or Enum.FontWeight.Regular) end

-- Themes: a theme is a table of colors (hex or Color3); unspecified keys fall back to Dark ------------------------
function Lib:AddTheme(n, c)
	for k, v in pairs(c) do if type(v) == "string" then c[k] = Color3.fromHex(v) end end
	Lib.Themes[n] = Lib.Themes.Dark and setmetatable(c, {__index = Lib.Themes.Dark}) or c
end
Lib:AddTheme("Dark", {Bg = "0b0b0b", Raised = "1b1b1b", Field = "111111", Line = "1f1f1f", Border = "2b2b2b", Text = "f4f4f5", Sub = "8b8b8f",
	Muted = "5a5a5e", Accent = "f4f4f5", OnAccent = "0b0b0b", Track = "2b2b2b", Success = "3ecf8e", Warning = "f5a623", Danger = "ef4444"})
Lib:AddTheme("Light", {Bg = "ffffff", Raised = "efeff1", Field = "f7f7f8", Line = "e8e8ea", Border = "d4d4d8", Text = "0b0b0b", Sub = "6b6b70",
	Muted = "9a9aa0", Accent = "0b0b0b", OnAccent = "ffffff", Track = "d4d4d8"})
Lib:AddTheme("Midnight", {Bg = "0a0d14", Raised = "182033", Field = "0f1420", Line = "1a2233", Border = "26314a", Text = "e6ecff", Sub = "8794b3",
	Muted = "566184", Accent = "7c9cff", OnAccent = "0a0d14", Track = "26314a"})
Lib.Theme, Lib.ThemeName = Lib.Themes.Dark, "Dark"

-- Core helpers -------------------------------------------------------------------------------------------------------
local bound, active, n = {}, {}, 0
local function nx() n = n + 1 return n end
local function mix(a, b) for k, v in pairs(b or {}) do a[k] = v end return a end
local function tw(o, p, t, s, d)
	local tween = TS:Create(o, TweenInfo.new(t or .15, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
	tween:Play()
	return tween
end
local function apply(o, p, now) if now then mix(o, p) else tw(o, p) end end -- set properties instantly (now) or tween them
local function on(s, f) table.insert(Lib.Conns, s:Connect(f)) end
local function prune() for i = #bound, 1, -1 do if not bound[i][1].Parent then table.remove(bound, i) end end end

-- Binds a property to a theme key (string) or function(theme); returns an updater that tweens to the current value.
local function reg(o, p, f)
	if type(f) == "string" then local k = f; f = function(t) return t[k] end end
	bound[#bound + 1] = {o, p, f}
	o[p] = f(Lib.Theme)
	return function() tw(o, {[p] = f(Lib.Theme)}) end
end

-- Instance builder. Special keys: T = {Prop = themeKey|fn}, R = corner, S = themed stroke, P = padding, L = list layout.
local function new(class, p, kids)
	local o, ups = Instance.new(class), {}
	p = p or {}
	if o:IsA("GuiObject") then o.BorderSizePixel, o.BackgroundTransparency = 0, 1 end
	if o:IsA("GuiButton") then o.AutoButtonColor = false end
	if o:IsA("TextButton") then o.Text = "" end
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then o.FontFace, o.TextSize, o.TextXAlignment = Lib.Font(), 13, Enum.TextXAlignment.Left end
	local T, R, S, P, L = p.T, p.R, p.S, p.P, p.L
	p.T, p.R, p.S, p.P, p.L = nil, nil, nil, nil, nil
	for k, v in pairs(p) do o[k] = v end
	for k, v in pairs(T or {}) do ups[#ups + 1] = reg(o, k, v) end
	if R then new("UICorner", {CornerRadius = UDim.new(0, R), Parent = o}) end
	if S then ups[#ups + 1] = reg(new("UIStroke", {Parent = o, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}), "Color", S) end
	if P then
		local q = type(P) == "number" and {P, P, P, P} or P
		new("UIPadding", {Parent = o, PaddingTop = UDim.new(0, q[1]), PaddingRight = UDim.new(0, q[2]), PaddingBottom = UDim.new(0, q[3]), PaddingLeft = UDim.new(0, q[4])})
	end
	if L then
		L = type(L) == "number" and {L} or L
		local h = L[2] == "H"
		new("UIListLayout", {Parent = o, Padding = UDim.new(0, L[1]), SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = h and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
			VerticalAlignment = h and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top})
	end
	return o, function() for _, u in ipairs(ups) do u() end end
end

local function label(p, text, size, color, weight, props)
	return new("TextLabel", mix({Parent = p, Text = text, TextSize = size, FontFace = Lib.Font(weight), T = {TextColor3 = color}}, props))
end
local function line(p, props) return new("Frame", mix({Parent = p, Size = U(1, 0, 0, 1), BackgroundTransparency = 0, T = {BackgroundColor3 = "Line"}}, props)) end
local function dot(p, f, props) return new("Frame", mix({Parent = p, Size = O(6, 6), BackgroundTransparency = 0, R = 3, T = {BackgroundColor3 = f}}, props)) end

local function icon(p, name, props)
	local img, up = new("ImageLabel", mix({Parent = p, Size = O(16, 16)}, props))
	local i = Lib.Icons[name] -- asset string, or {Image=, Offset=, Size=} for spritesheets
	if type(i) == "table" then img.Image, img.ImageRectOffset, img.ImageRectSize = i.Image, i.Offset, i.Size else img.Image = i or "" end
	return img, up
end

local function button(p, text, primary, props)
	local b = new("TextButton", mix({Parent = p, BackgroundTransparency = 0, R = 8, S = not primary and "Border" or nil, T = {BackgroundColor3 = primary and "Accent" or "Field"}}, props))
	local l = label(b, text, 14, primary and "OnAccent" or "Text", MED, {Size = Sc(1, 1), TextXAlignment = CEN})
	local s = b:FindFirstChildOfClass("UIStroke")
	b.MouseEnter:Connect(function() if s then tw(s, {Color = Lib.Theme.Sub}) else tw(b, {BackgroundTransparency = .15}) end end)
	b.MouseLeave:Connect(function() if s then tw(s, {Color = Lib.Theme.Border}) else tw(b, {BackgroundTransparency = 0}) end end)
	return b, l
end

-- Pointer tracking: f() runs on press and returns move(delta, position); used for dragging, resizing and sliders.
local function track(h, f)
	h.InputBegan:Connect(function(i)
		local t, s = i.UserInputType, i.Position
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
		local move, c, e = f()
		move(Vector3.zero, s)
		c = UIS.InputChanged:Connect(function(m)
			if m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch then move(m.Position - s, m.Position) end
		end)
		e = UIS.InputEnded:Connect(function(x) if x.UserInputType == t then c:Disconnect() e:Disconnect() end end)
	end)
end
local function drag(h, main)
	track(h, function() local p = main.Position
		return function(d) main.Position = U(p.X.Scale, p.X.Offset + d.X, p.Y.Scale, p.Y.Offset + d.Y) end end)
end

-- Pointer area over frame h: f(x, y) receives the pointer position normalised to 0-1; pad enlarges the hit zone vertically.
local function area(h, f, pad)
	pad = pad or 0
	local hit = new("TextButton", {Parent = h, Position = U(0, 0, 0, -pad / 2), Size = U(1, 0, 1, pad), ZIndex = 5})
	track(hit, function()
		return function(_, pos)
			f(math.clamp((pos.X - h.AbsolutePosition.X) / h.AbsoluteSize.X, 0, 1), math.clamp((pos.Y - h.AbsolutePosition.Y) / h.AbsoluteSize.Y, 0, 1))
		end
	end)
end

-- Small drawn widgets (no image assets needed) -----------------------------------------------------------------------
local function knob(p) -- ring handle used by the color picker
	local k = new("Frame", {Parent = p, AnchorPoint = V2(.5, .5), Size = O(14, 14), BackgroundTransparency = 0, R = 7})
	new("UIStroke", {Parent = k, Color = Color3.new(1, 1, 1), Thickness = 2})
	return k
end

local function check(p, boxed) -- tick (optionally inside a checkbox) on the right of p; returns paint(on, instant)
	local f = new("Frame", {Parent = p, AnchorPoint = V2(1, .5), Position = U(1, -10, .5, 0), Size = O(16, 16), R = 4, S = boxed and "Border" or nil, T = {BackgroundColor3 = "Accent"}})
	local legs = {}
	for _, d in ipairs{{O(5, 2), V2(5.5, 10), 45}, {O(9, 2), V2(9.5, 8.25), -52}} do
		legs[#legs + 1] = new("Frame", {Parent = f, AnchorPoint = V2(.5, .5), Position = O(d[2].X, d[2].Y), Size = d[1], Rotation = d[3], R = 1,
			T = {BackgroundColor3 = boxed and "OnAccent" or "Text"}})
	end
	return function(state, now)
		if boxed then apply(f, {BackgroundTransparency = state and 0 or 1}, now) end
		for _, l in ipairs(legs) do apply(l, {BackgroundTransparency = state and 0 or 1}, now) end
	end
end

local function field(p) -- select-style button with a text label and a drawn chevron; returns button, label
	local b = new("TextButton", {Parent = p, Size = O(150, 32), BackgroundTransparency = 0, R = 6, S = "Border", T = {BackgroundColor3 = "Field"}})
	local t = label(b, "", 13, "Text", nil, {Position = O(12, 0), Size = U(1, -38, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd})
	for _, d in ipairs{{-18.1, 45}, {-13.9, -45}} do
		new("Frame", {Parent = b, AnchorPoint = V2(.5, .5), Position = U(1, d[1], .5, 0), Size = O(6, 1.5), Rotation = d[2], BackgroundTransparency = 0, R = 1, T = {BackgroundColor3 = "Sub"}})
	end
	return b, t
end

local function search(p, placeholder, fill, props) -- minimal search field with a drawn magnifier; returns frame, textbox
	local f = new("Frame", mix({Parent = p, BackgroundTransparency = 0, R = 6, S = "Border", T = {BackgroundColor3 = fill}}, props))
	local stroke = f:FindFirstChildOfClass("UIStroke")
	local ring = new("Frame", {Parent = f, AnchorPoint = V2(.5, .5), Position = U(0, 16, .5, -1), Size = O(9, 9), R = 5, S = "Sub"})
	ring:FindFirstChildOfClass("UIStroke").Thickness = 1.5
	new("Frame", {Parent = f, AnchorPoint = V2(.5, .5), Position = U(0, 21, .5, 4), Size = O(5, 1.5), Rotation = 45, BackgroundTransparency = 0, R = 1, T = {BackgroundColor3 = "Sub"}})
	local box = new("TextBox", {Parent = f, Position = O(32, 0), Size = U(1, -42, 1, 0), ClearTextOnFocus = false, PlaceholderText = placeholder,
		T = {TextColor3 = "Text", PlaceholderColor3 = "Muted"}})
	box.Focused:Connect(function() tw(stroke, {Color = Lib.Theme.Sub}) end)
	box.FocusLost:Connect(function() tw(stroke, {Color = Lib.Theme.Border}) end)
	return f, box
end

local function measure(text, size, width, weight) -- wrapped text height in pixels
	local p = Instance.new("GetTextBoundsParams")
	p.Text, p.Font, p.Size, p.Width = text, Lib.Font(weight), size, width
	local ok, b = pcall(TXT.GetTextBoundsAsync, TXT, p)
	return ok and math.ceil(b.Y) or (size + 4) * math.max(1, math.ceil(#text * size * .55 / width))
end

-- Colors are stored as "rrggbb" (or "rrggbbaa" when the picker has Alpha) so they survive JSON configs.
local function toHex(c, a) return a and (c:ToHex() .. string.format("%02x", math.floor(a * 255 + .5))) or c:ToHex() end
local function fromHex(x)
	local s = tostring(x):gsub("[#%s]", "")
	local ok, c = pcall(Color3.fromHex, s:sub(1, 6))
	local a = tonumber(s:sub(7, 8), 16)
	return ok and c or Color3.new(1, 1, 1), a and a / 255 or 1
end
function Lib:GetColor(f) return fromHex(Lib.Flags[f] or "ffffff") end -- returns Color3, alpha

-- Persistence: every element writes to Lib.Flags and schedules a debounced save --------------------------------------
local function write(f, d) pcall(function() if not isfolder(Lib.Folder) then makefolder(Lib.Folder) end writefile(Lib.Folder .. "/" .. f, d) end) end
local function read(f) local ok, d = pcall(readfile, Lib.Folder .. "/" .. f) return ok and d or nil end
local function decode(c) local ok, d = pcall(function() return HS:JSONDecode(read(c .. ".json")) end) return ok and d or nil end
local pending
local function save()
	if pending then return end
	pending = task.delay(.5, function() pending = nil; Lib:Save() end)
end
function Lib:Save(c) Lib.Config = c or Lib.Config; write(Lib.Config .. ".json", HS:JSONEncode(mix(table.clone(Lib.Saved), Lib.Flags))) end
function Lib:Load(c)
	local d = decode(c); if not d then return false end
	Lib.Config, Lib.Saved = c, d
	for k, v in pairs(d) do if Lib.Setters[k] then Lib.Setters[k](v) end end
	if d.__theme then Lib:SetTheme(d.__theme) end
	return true
end
function Lib:Delete(c) pcall(delfile, Lib.Folder .. "/" .. c .. ".json") end
function Lib:List()
	local r = {}
	pcall(function() for _, f in ipairs(listfiles(Lib.Folder)) do local m = f:match("([^/\\]+)%.json$"); if m then r[#r + 1] = m end end end)
	return r
end

function Lib:SetTheme(t)
	local th = Lib.Themes[t]; if not th then return end
	Lib.Theme, Lib.ThemeName, Lib.Flags.__theme = th, t, t
	for i = #bound, 1, -1 do
		local b = bound[i]
		if b[1].Parent then tw(b[1], {[b[2]] = b[3](th)}, .25) else table.remove(bound, i) end
	end
	save()
end
function Lib:SetColor(k, c) Lib.Theme[k] = c; Lib:SetTheme(Lib.ThemeName) end
function Lib:Destroy()
	for _, c in ipairs(Lib.Conns) do c:Disconnect() end
	for _, g in ipairs(Lib.Guis) do g:Destroy() end
	Lib.Conns, Lib.Guis = {}, {}; table.clear(bound); table.clear(active)
end

-- bind: shared element plumbing. view(v) updates visuals; the returned set(v) also stores, saves and fires Callback.
local function bind(o, default, view)
	local flag = o.Flag; if flag == nil then flag = o.Name end
	local function set(v)
		view(v)
		if flag then Lib.Flags[flag] = v; save() end
		if o.Callback and v ~= nil then task.spawn(o.Callback, v) end
	end
	local v; if flag then Lib.Setters[flag] = set; v = Lib.Saved[flag] end
	if v == nil then v = default end
	set(v)
	return set
end

-- Keybind chip (used by Toggle{Keybind=} and Keybind elements). Saved as "<flag>_key".
local function chip(p, flag, default, press)
	local kf, key, listening = tostring(flag) .. "_key"
	local b = new("TextButton", {Parent = p, LayoutOrder = 1, AutomaticSize = AX, Size = O(0, 22), BackgroundTransparency = 0, R = 5, S = "Border", P = {0, 8, 0, 8},
		FontFace = Lib.Mono, TextSize = 11, TextXAlignment = CEN, T = {BackgroundColor3 = "Field", TextColor3 = "Sub"}})
	new("UISizeConstraint", {Parent = b, MinSize = V2(24, 0)})
	local function set(k) key = k and Enum.KeyCode[k]; b.Text = k or "None"; Lib.Flags[kf] = k or false; save() end
	Lib.Setters[kf] = set
	local k = Lib.Saved[kf]; if k == nil and typeof(default) == "EnumItem" then k = default.Name end
	set(k or nil)
	b.Activated:Connect(function() listening, Lib.Listening, b.Text = true, true, "..." end)
	on(UIS.InputBegan, function(i, gp)
		if listening then
			if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
			listening = false
			set(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode.Name or nil)
			task.defer(function() Lib.Listening = nil end)
		elseif not gp and not Lib.Listening and key and i.KeyCode == key then press() end
	end)
end

-- Window chrome ------------------------------------------------------------------------------------------------------
local function controls(p, onMin, onClose)
	local box = new("Frame", {Parent = p, AnchorPoint = V2(1, .5), Position = U(1, -10, .5, 0), Size = O(0, 28), AutomaticSize = AX, L = {4, "H"}})
	for i, d in ipairs{{f = onMin, w = 10, r = {0}}, {f = onClose, w = 14, r = {45, -45}}} do
		if d.f then
			local b, ls = new("TextButton", {Parent = box, Size = O(28, 28), LayoutOrder = i}), {}
			b.Activated:Connect(d.f)
			for _, r in ipairs(d.r) do ls[#ls + 1] = new("Frame", {Parent = b, AnchorPoint = V2(.5, .5), Position = Sc(.5, .5), Size = O(d.w, 1), Rotation = r, BackgroundTransparency = 0, T = {BackgroundColor3 = "Sub"}}) end
			b.MouseEnter:Connect(function() for _, l in ipairs(ls) do tw(l, {BackgroundColor3 = Lib.Theme.Text}) end end)
			b.MouseLeave:Connect(function() for _, l in ipairs(ls) do tw(l, {BackgroundColor3 = Lib.Theme.Sub}) end end)
		end
	end
end

local function brand(p, name, ver, props)
	local f = new("Frame", mix({Parent = p, Size = Sc(1, 1), L = {10, "H"}}, props))
	local lg = new("Frame", {Parent = f, Size = O(16, 16), R = 4, S = "Text"})
	dot(lg, "Text", {AnchorPoint = V2(.5, .5), Position = Sc(.5, .5), Size = O(4, 4), R = 2})
	label(f, name:upper(), 13, "Text", BOLD, {AutomaticSize = AX, Size = O(0, 16), LayoutOrder = 1})
	if ver then label(f, ver, 12, "Muted", nil, {AutomaticSize = AX, Size = O(0, 16), LayoutOrder = 2, FontFace = Lib.Mono}) end
end

local function host()
	local ok, p = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
	return ok and p or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local function shell(name, size, min) -- ScreenGui + rounded main frame (+ invisible edge/corner resize zones when min is set)
	local gui = new("ScreenGui", {Name = name, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = host()})
	table.insert(Lib.Guis, gui)
	local main = new("Frame", {Parent = gui, Position = U(.5, -size.X / 2, .5, -size.Y / 2), Size = O(size.X, size.Y), BackgroundTransparency = 0, R = 10, S = "Line", T = {BackgroundColor3 = "Bg"}})
	local scale = new("UIScale", {Parent = main, Scale = .95})
	tw(scale, {Scale = 1}, .25)
	for _, z in ipairs(min and {{U(0, 8, 1, -14), U(1, -8, 0, 0), 1, 0}, {U(1, -14, 0, 8), U(0, 0, 1, -8), 0, 1}, {O(14, 14), U(1, -14, 1, -14), 1, 1}} or {}) do
		track(new("Frame", {Parent = main, Size = z[1], Position = z[2], Active = true, ZIndex = 10}), function()
			local s = main.AbsoluteSize
			return function(d) main.Size = O(math.max(min.X, s.X + d.X * z[3]), math.max(min.Y, s.Y + d.Y * z[4])) end
		end)
	end
	return gui, main, scale
end

-- Notifications ------------------------------------------------------------------------------------------------------
-- Lib:Notify{Title, Text, Type = "Info"|"Success"|"Warning"|"Error", Duration = seconds (0 keeps it until clicked)} -> {Close}
local KIND, stack = {Info = "Accent", Success = "Success", Warning = "Warning", Error = "Danger"}, nil
function Lib:Notify(o)
	o = mix({Title = "Notice", Text = "", Type = "Info", Duration = 4}, o)
	if not (stack and stack.Parent) then
		local gui = new("ScreenGui", {Name = "HalcyonNotify", ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = host()})
		table.insert(Lib.Guis, gui)
		stack = new("Frame", {Parent = gui, AnchorPoint = V2(1, 1), Position = U(1, -20, 1, -20), Size = U(0, 300, 1, -40), L = 8})
		stack.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end

	local W, color = 300, KIND[o.Type] or "Accent"
	local body = o.Text ~= "" and measure(o.Text, 12, 252) or 0
	local H = body > 0 and 48 + body or 44
	local wrap = new("Frame", {Parent = stack, Size = O(W, 0), LayoutOrder = nx()})
	local card = new("CanvasGroup", {Parent = wrap, Position = O(W + 24, 0), Size = O(W, H), GroupTransparency = 1, BackgroundTransparency = 0, R = 10, S = "Border", T = {BackgroundColor3 = "Bg"}})
	dot(card, color, {Position = O(16, 19)})
	label(card, o.Title, 14, "Text", MED, {Position = O(32, 13), Size = O(252, 18), TextTruncate = Enum.TextTruncate.AtEnd})
	if body > 0 then label(card, o.Text, 12, "Sub", nil, {Position = O(32, 34), Size = O(252, body), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top}) end
	local bar = o.Duration > 0 and new("Frame", {Parent = card, AnchorPoint = V2(0, 1), Position = Sc(0, 1), Size = U(1, 0, 0, 2), BackgroundTransparency = .5, T = {BackgroundColor3 = color}})

	local closed
	local function close()
		if closed then return end
		closed = true
		local i = table.find(active, close); if i then table.remove(active, i) end
		tw(card, {Position = O(W + 24, 0), GroupTransparency = 1}, .3, QUINT, Enum.EasingDirection.In)
		task.delay(.22, function()
			tw(wrap, {Size = O(W, 0)}, .22)
			task.wait(.24)
			wrap:Destroy(); prune()
		end)
	end
	new("TextButton", {Parent = card, Size = Sc(1, 1), ZIndex = 5}).Activated:Connect(close)

	table.insert(active, close)
	for _ = 1, #active - 5 do active[1]() end -- at most five on screen
	tw(wrap, {Size = O(W, H)}, .3, QUINT)
	tw(card, {Position = O(0, 0), GroupTransparency = 0}, .4, QUINT)
	if bar then
		tw(bar, {Size = U(0, 0, 0, 2)}, o.Duration, LINEAR)
		task.delay(o.Duration, close)
	end
	return {Close = close}
end

-- Loading / transition screen ----------------------------------------------------------------------------------------
-- Lib:Loading{Name, Version, Status, Steps = {{text, seconds}, ...}, Blur = true, Callback} -> {Set(alpha, text, time), Close()}
-- With Steps the screen plays itself and closes when finished; otherwise drive it with :Set() and :Close().
function Lib:Loading(o)
	o = mix({Name = "Halcyon", Version = "", Status = "Initializing", Blur = true, Callback = function() end}, o)
	local gui = new("ScreenGui", {Name = o.Name .. "Loader", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = host()})
	table.insert(Lib.Guis, gui)
	local root = new("CanvasGroup", {Parent = gui, Size = Sc(1, 1), GroupTransparency = 1})
	new("Frame", {Parent = root, Size = Sc(1, 1), Active = true, BackgroundTransparency = .12, T = {BackgroundColor3 = "Bg"}})
	local mid = new("Frame", {Parent = root, AnchorPoint = V2(.5, .5), Position = U(.5, 0, .5, 14), Size = O(240, 150)})
	local logo = new("Frame", {Parent = mid, AnchorPoint = V2(.5, 0), Position = U(.5, 0, 0, 0), Size = O(44, 44), R = 11, S = "Text"})
	logo:FindFirstChildOfClass("UIStroke").Thickness = 2
	dot(logo, "Text", {AnchorPoint = V2(.5, .5), Position = Sc(.5, .5), Size = O(8, 8), R = 4})
	label(mid, o.Name:upper(), 15, "Text", BOLD, {Position = O(0, 62), Size = U(1, 0, 0, 20), TextXAlignment = CEN})
	label(mid, o.Version, 11, "Muted", nil, {Position = O(0, 82), Size = U(1, 0, 0, 14), TextXAlignment = CEN, FontFace = Lib.Mono})
	local bar = new("Frame", {Parent = mid, Position = O(0, 116), Size = U(1, 0, 0, 3), BackgroundTransparency = 0, R = 2, T = {BackgroundColor3 = "Track"}})
	local fill = new("Frame", {Parent = bar, Size = Sc(0, 1), BackgroundTransparency = 0, R = 2, T = {BackgroundColor3 = "Accent"}})
	local status = label(mid, o.Status, 12, "Sub", nil, {Position = O(0, 128), Size = U(.75, 0, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd})
	local pct = label(mid, "0%", 12, "Muted", nil, {AnchorPoint = V2(1, 0), Position = U(1, 0, 0, 128), Size = U(.25, 0, 0, 16), TextXAlignment = RIGHT, FontFace = Lib.Mono})

	local blur
	if o.Blur then
		blur = Instance.new("BlurEffect")
		blur.Size, blur.Parent = 0, game:GetService("Lighting")
		table.insert(Lib.Guis, blur)
		tw(blur, {Size = 16}, .5)
	end
	tw(root, {GroupTransparency = 0}, .4)
	tw(mid, {Position = Sc(.5, .5)}, .6, QUINT)

	local prog, closed = Instance.new("NumberValue"), false
	prog.Changed:Connect(function(x) fill.Size, pct.Text = Sc(x, 1), string.format("%d%%", math.floor(x * 100 + .5)) end)
	local spin = TS:Create(logo, TweenInfo.new(1.1, QUINT, Enum.EasingDirection.InOut, -1, false, .1), {Rotation = 90}) -- 90 degrees is a square's symmetry, so the loop is seamless
	spin:Play()

	local ld = {}
	function ld:Set(a, text, t)
		if text then status.Text = text end
		tw(prog, {Value = math.clamp(a, 0, 1)}, t or .35)
	end
	function ld:Close()
		if closed then return end
		closed = true
		ld:Set(1, "Ready")
		task.delay(.5, function()
			spin:Cancel()
			tw(root, {GroupTransparency = 1}, .4)
			if blur then tw(blur, {Size = 0}, .4) end
			task.wait(.4)
			if blur then blur:Destroy() end
			prog:Destroy(); gui:Destroy()
			task.spawn(o.Callback)
		end)
	end

	if o.Steps then
		task.spawn(function()
			local total, done = 0, 0
			for _, st in ipairs(o.Steps) do total += st[2] end
			total = math.max(total, .01)
			for _, st in ipairs(o.Steps) do
				done += st[2]
				ld:Set(done / total, st[1], st[2])
				task.wait(st[2])
			end
			ld:Close()
		end)
	end
	return ld
end

-- Elements -----------------------------------------------------------------------------------------------------------
local TabM = {}
local function row(tab, o) -- label/description on the left, returns r and a right-aligned container for the control
	local r = new("Frame", {Parent = tab.Page, Size = U(1, 0, 0, 56), LayoutOrder = nx()})
	local t = new("Frame", {Parent = r, AnchorPoint = V2(0, .5), Position = Sc(0, .5), Size = U(.5, 0, 0, 0), AutomaticSize = AY, L = 2})
	label(t, o.Name, 14, "Text", MED, {Size = U(1, 0, 0, 18), LayoutOrder = 1})
	if o.Desc then label(t, o.Desc, 12, "Sub", nil, {Size = U(1, 0, 0, 16), LayoutOrder = 2, TextTruncate = Enum.TextTruncate.AtEnd}) end
	line(r, {AnchorPoint = V2(0, 1), Position = Sc(0, 1)})
	local right = new("Frame", {Parent = r, AnchorPoint = V2(1, .5), Position = Sc(1, .5), Size = O(0, 0), AutomaticSize = AXY, L = {10, "H"}})
	tab.Items[#tab.Items + 1] = {Frame = r, Text = string.lower(o.Name .. " " .. (o.Desc or ""))} -- searchable
	return r, right
end
local function fl(o) if o.Flag == nil then return o.Name end return o.Flag end
local function fire(o) return function() if o.Callback then task.spawn(o.Callback) end end end

function TabM:Section(s)
	local l = label(self.Page, s:upper(), 11, "Muted", MED, {Size = U(1, 0, 0, 38), TextYAlignment = Enum.TextYAlignment.Bottom, P = {0, 0, 8, 0}, LayoutOrder = nx()})
	self.Items[#self.Items + 1] = {Frame = l, Head = true}
end

function TabM:Toggle(o) -- {Name, Desc, Flag, Default, Keybind = Enum.KeyCode|true, Callback(bool)}
	local _, right = row(self, o)
	local state
	local tr, upT = new("TextButton", {Parent = right, LayoutOrder = 2, Size = O(36, 20), BackgroundTransparency = 0, R = 10, T = {BackgroundColor3 = function(t) return state and t.Accent or t.Track end}})
	local knobF, upK = new("Frame", {Parent = tr, AnchorPoint = V2(0, .5), Position = U(0, 3, .5, 0), Size = O(14, 14), BackgroundTransparency = 0, R = 7,
		T = {BackgroundColor3 = function(t) return state and t.OnAccent or t.Sub end}})
	local set = bind(o, o.Default or false, function(v) state = v; upT(); upK(); tw(knobF, {Position = U(0, v and 19 or 3, .5, 0)}) end)
	tr.Activated:Connect(function() set(not state) end)
	if o.Keybind then chip(right, fl(o), o.Keybind, function() set(not state) end) end
	return {Set = set}
end

function TabM:Slider(o) -- {Name, Desc, Flag, Min, Max, Step, Default, Suffix, Callback(number)}
	local _, right = row(self, o)
	local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
	local val = label(right, "", 13, "Sub", nil, {LayoutOrder = 2, Size = O(44, 20), TextXAlignment = RIGHT})
	local hit = new("TextButton", {Parent = right, LayoutOrder = 1, Size = O(170, 20)})
	local bar = new("Frame", {Parent = hit, AnchorPoint = V2(0, .5), Position = Sc(0, .5), Size = U(1, 0, 0, 4), BackgroundTransparency = 0, R = 2, T = {BackgroundColor3 = "Track"}})
	local fill = new("Frame", {Parent = bar, Size = Sc(0, 1), BackgroundTransparency = 0, R = 2, T = {BackgroundColor3 = "Accent"}})
	local thumb = new("Frame", {Parent = bar, AnchorPoint = V2(.5, .5), Size = O(14, 14), BackgroundTransparency = 0, R = 7, T = {BackgroundColor3 = "Accent"}})
	local function snap(v) return math.clamp(math.floor((v - min) / step + .5) * step + min, min, max) end
	local set = bind(o, snap(o.Default or min), function(v)
		local a = (v - min) / (max - min)
		fill.Size, thumb.Position, val.Text = Sc(a, 1), Sc(a, .5), string.format("%g", v) .. (o.Suffix or "")
	end)
	track(hit, function() return function(_, pos) set(snap(min + (max - min) * math.clamp((pos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1))) end end)
	return {Set = set}
end

local function options(o) return type(o.Options) == "function" and o.Options() or o.Options end

function TabM:Dropdown(o) -- {Name, Desc, Flag, Options = {...}|function, Default, Callback(option)}
	local _, right = row(self, o)
	local b, t = field(right)
	local d = o.Default; if d == nil and type(o.Options) == "table" then d = o.Options[1] end
	local cur
	local set = bind(o, d, function(v) cur = v; t.Text = tostring(v or "") end)
	b.Activated:Connect(function() self.Win.Menu(b, options(o), function(x) return x == cur end, set) end)
	return {Set = set}
end

function TabM:MultiDropdown(o) -- {Name, Desc, Flag, Options = {...}|function, Default = {...}, Max, Callback({...})}; the value is an array
	local _, right = row(self, o)
	local b, t = field(right)
	local sel, count = {}, 0
	local set = bind(o, o.Default or {}, function(v)
		v = type(v) == "table" and v or {}
		sel, count = {}, #v
		for _, x in ipairs(v) do sel[x] = true end
		t.Text = count == 0 and "None" or count == 1 and tostring(v[1]) or count .. " selected"
	end)
	local function toggle(x)
		if not sel[x] and o.Max and count >= o.Max then
			Lib:Notify{Title = "Limit reached", Text = "Choose up to " .. o.Max .. ".", Type = "Warning", Duration = 2}
			return
		end
		local nv = {}
		for _, y in ipairs(options(o)) do
			if (y == x) ~= (sel[y] == true) then nv[#nv + 1] = y end -- flip x, keep everything else (and keep option order)
		end
		set(nv)
	end
	b.Activated:Connect(function() self.Win.Menu(b, options(o), function(x) return sel[x] == true end, toggle, true) end)
	return {Set = set}
end

function TabM:ColorPicker(o) -- {Name, Desc, Flag, Default = Color3|hex, Alpha = bool, Callback(Color3, alpha)}
	local _, right = row(self, o)
	local alpha, cb = o.Alpha, o.Callback
	local code = label(right, "", 12, "Sub", nil, {LayoutOrder = 1, AutomaticSize = AX, Size = O(0, 22), FontFace = Lib.Mono})
	local swatch = new("TextButton", {Parent = right, LayoutOrder = 2, Size = O(32, 22), BackgroundTransparency = 0, R = 5, S = "Border"})
	local h, s, v, a, ui, own, set = 0, 0, 1, 1

	local function refresh()
		local c, hue = Color3.fromHSV(h, s, v), Color3.fromHSV(h, 1, 1)
		local text = "#" .. string.upper(toHex(c, alpha and a))
		swatch.BackgroundColor3, code.Text = c, text
		if not ui then return end
		ui.base.BackgroundColor3 = hue
		ui.cursor.Position, ui.cursor.BackgroundColor3 = Sc(s, 1 - v), c
		ui.hue.Position, ui.hue.BackgroundColor3 = Sc(h, .5), hue
		ui.box.Text = text
		if ui.alpha then ui.alpha.Position, ui.alpha.BackgroundColor3, ui.tint.BackgroundColor3 = Sc(a, .5), c, c end
	end
	local function commit() -- user edits: keep hue/saturation exact instead of round-tripping through hex
		own = true
		set(toHex(Color3.fromHSV(h, s, v), alpha and a))
		own = false
	end

	local d = o.Default or "ffffff"
	if typeof(d) == "Color3" then d = toHex(d, alpha and 1) end
	set = bind(mix(table.clone(o), {Callback = function(x) if cb then cb(fromHex(x)) end end}), d, function(x)
		if not own then
			local c, al = fromHex(x)
			h, s, v = c:ToHSV()
			if alpha then a = al end
		end
		refresh()
	end)

	swatch.Activated:Connect(function()
		local hy = alpha and 182 or 160
		self.Win.Popup(swatch, 220, hy + 48, function(g)
			local inner = new("Frame", {Parent = g, Position = O(10, 10), Size = O(200, hy + 28)})
			local sv = new("Frame", {Parent = inner, Size = O(200, 124)})
			local base = new("Frame", {Parent = sv, Size = Sc(1, 1), BackgroundTransparency = 0, R = 6})
			for _, l in ipairs{{Color3.new(1, 1, 1), NumberSequence.new(0, 1), 0}, {Color3.new(0, 0, 0), NumberSequence.new(1, 0), 90}} do
				local f = new("Frame", {Parent = sv, Size = Sc(1, 1), BackgroundTransparency = 0, BackgroundColor3 = l[1], R = 6})
				new("UIGradient", {Parent = f, Transparency = l[2], Rotation = l[3]})
			end
			local cursor = knob(sv)
			area(sv, function(x, y) s, v = x, 1 - y; commit() end)

			local hue = new("Frame", {Parent = inner, Position = O(0, 136), Size = O(200, 12), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), R = 6})
			local keys = {}
			for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 1, 1)) end
			new("UIGradient", {Parent = hue, Color = ColorSequence.new(keys)})
			local hueKnob = knob(hue)
			area(hue, function(x) h = x; commit() end, 12)

			local alphaKnob, tint
			if alpha then
				local at = new("Frame", {Parent = inner, Position = O(0, 158), Size = O(200, 12), BackgroundTransparency = 0, R = 6, T = {BackgroundColor3 = "Raised"}})
				tint = new("Frame", {Parent = at, Size = Sc(1, 1), BackgroundTransparency = 0, R = 6})
				new("UIGradient", {Parent = tint, Transparency = NumberSequence.new(1, 0)})
				alphaKnob = knob(at)
				area(at, function(x) a = x; commit() end, 12)
			end

			local box = new("TextBox", {Parent = inner, Position = O(0, hy), Size = O(200, 28), BackgroundTransparency = 0, R = 6, S = "Border", ClearTextOnFocus = false,
				FontFace = Lib.Mono, TextSize = 12, TextXAlignment = CEN, T = {BackgroundColor3 = "Raised", TextColor3 = "Text"}})
			box.FocusLost:Connect(function()
				local x = box.Text:gsub("[#%s]", "")
				if (#x == 6 or alpha and #x == 8) and x:match("^%x+$") then
					local c, al = fromHex(x)
					h, s, v = c:ToHSV()
					if alpha then a = al end
					commit()
				else refresh() end
			end)

			ui = {base = base, cursor = cursor, hue = hueKnob, alpha = alphaKnob, tint = tint, box = box}
			g.Destroying:Connect(function() ui = nil end)
			refresh()
		end, true)
	end)
	return {
		Set = function(c, al) set(typeof(c) == "Color3" and toHex(c, alpha and (al or a)) or c) end,
		Get = function() return Color3.fromHSV(h, s, v), a end,
	}
end

function TabM:Input(o) -- {Name, Desc, Flag, Default, Placeholder, Callback(text)}
	local _, right = row(self, o)
	local box = new("TextBox", {Parent = right, Size = O(150, 32), BackgroundTransparency = 0, R = 6, S = "Border", P = {0, 12, 0, 12}, ClearTextOnFocus = false, ClipsDescendants = true,
		PlaceholderText = o.Placeholder or "", TextSize = 13, T = {BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "Muted"}})
	local set = bind(o, o.Default or "", function(v) box.Text = v end)
	box.FocusLost:Connect(function() set(box.Text) end)
	return {Set = set, Get = function() return box.Text end}
end

function TabM:Button(o) -- {Name, Desc, Text, Callback()}
	local _, right = row(self, o)
	button(right, o.Text or o.Name, false, {Size = O(110, 32), R = 6}).Activated:Connect(fire(o))
end

function TabM:Keybind(o) -- {Name, Desc, Flag, Default = Enum.KeyCode, Callback()} fires when the key is pressed
	local _, right = row(self, o)
	chip(right, fl(o), o.Default, fire(o))
end

-- Window -------------------------------------------------------------------------------------------------------------
-- Lib:Window{Name, Version, Crumb, Game, Size, Min, ToggleKey, Config, Folder}
function Lib:Window(o)
	o = mix({Name = "Halcyon", Version = "", Crumb = "Game", Game = "", Size = V2(780, 540), Min = V2(700, 420), ToggleKey = Enum.KeyCode.RightShift, Config = Lib.Config, Folder = Lib.Folder}, o)
	Lib.Folder, Lib.Config = o.Folder, o.Config
	Lib.Saved = decode(o.Config) or {}
	if Lib.Saved.__theme then Lib:SetTheme(Lib.Saved.__theme) end
	local tk = Lib.Saved.__toggle_key; if tk == nil then tk = o.ToggleKey.Name end
	Lib.Flags.__toggle_key = tk

	local gui, main, scale = shell(o.Name, o.Size, o.Min)
	local Win, tabs, lastSection = {Gui = gui}, {}, nil

	local side = new("Frame", {Parent = main, Size = U(0, 200, 1, 0)})
	line(main, {Position = O(200, 0), Size = U(0, 1, 1, 0)})
	local head = new("Frame", {Parent = side, Size = U(1, 0, 0, 56), P = {0, 0, 0, 20}})
	brand(head, o.Name, o.Version)
	local nav = new("Frame", {Parent = side, Position = O(0, 56), Size = U(1, 0, 1, -56), P = {0, 12, 0, 12}, L = 2})
	local content = new("Frame", {Parent = main, Position = O(201, 0), Size = U(1, -201, 1, 0), ClipsDescendants = true})
	local top = new("Frame", {Parent = content, Size = U(1, 0, 0, 56)})
	local crumb = new("Frame", {Parent = top, Size = U(1, -260, 1, 0), P = {0, 0, 0, 32}, L = {10, "H"}, ClipsDescendants = true})
	label(crumb, o.Crumb, 13, "Sub", nil, {AutomaticSize = AX, Size = O(0, 18), LayoutOrder = 1})
	label(crumb, o.Game, 13, "Text", MED, {AutomaticSize = AX, Size = O(0, 18), LayoutOrder = 2})
	controls(top, function()
		Win:Show(false)
		Lib:Notify{Title = "Interface hidden", Text = "Press " .. tostring(Lib.Flags.__toggle_key) .. " to show it again.", Duration = 3}
	end, function() Lib:Destroy() end)
	drag(top, main); drag(head, main)

	-- search: filters the elements of every tab (and hides sections left empty)
	local function filter(q)
		q = q:lower():match("^%s*(.-)%s*$")
		for _, e in ipairs(tabs) do
			local sect, hits, any = nil, 0, false
			for _, it in ipairs(e.items) do
				if it.Head then
					if sect then sect.Frame.Visible = q == "" or hits > 0 end
					sect, hits = it, 0
				else
					local ok = q == "" or it.Text:find(q, 1, true) ~= nil
					it.Frame.Visible = ok
					if ok then hits += 1; any = true end
				end
			end
			if sect then sect.Frame.Visible = q == "" or hits > 0 end
			e.empty.Visible = q ~= "" and not any
		end
	end
	local _, query = search(top, "Search", "Field", {AnchorPoint = V2(1, .5), Position = U(1, -84, .5, 0), Size = O(168, 30), Active = true})
	query:GetPropertyChangedSignal("Text"):Connect(function() filter(query.Text) end)

	function Win:Show(v)
		if v == nil then v = not main.Visible end
		main.Visible = v
		if v then scale.Scale = .96; tw(scale, {Scale = 1}, .2) end
	end
	on(UIS.InputBegan, function(i, gp) if not gp and not Lib.Listening and i.KeyCode.Name == Lib.Flags.__toggle_key then Win:Show() end end)

	-- Popup: fades/slides in under anchor a; clicking outside closes it. build(group, close) fills the popup.
	function Win.Popup(a, w, h, build, right)
		local gate = new("TextButton", {Parent = main, Size = Sc(1, 1), ZIndex = 50})
		local ap, as, mp, ms = a.AbsolutePosition, a.AbsoluteSize, main.AbsolutePosition, main.AbsoluteSize
		local x = math.clamp(ap.X - mp.X + (right and as.X - w or 0), 8, math.max(8, ms.X - w - 8))
		local y = ap.Y - mp.Y + as.Y + 6
		if y + h > ms.Y - 8 then y = math.max(8, ap.Y - mp.Y - h - 6) end -- flip above when there is no room below
		local group = new("CanvasGroup", {Parent = gate, Position = O(x, y + 6), Size = O(w, h), Active = true, GroupTransparency = 1, BackgroundTransparency = 0, R = 8, S = "Border",
			T = {BackgroundColor3 = "Field"}})
		local closed
		local function close()
			if closed then return end
			closed = true
			tw(group, {GroupTransparency = 1, Position = O(x, y + 6)}, .12)
			task.delay(.12, function() gate:Destroy(); prune() end)
		end
		gate.Activated:Connect(close)
		tw(group, {GroupTransparency = 0, Position = O(x, y)}, .18, QUINT)
		build(group, close)
		return close
	end

	-- Menu: option list popup under a; multi keeps it open. isSel(v) -> bool, pick(v). Long lists get a search field.
	function Win.Menu(a, opts, isSel, pick, multi)
		if #opts == 0 then return end
		local find = #opts > 6
		local top = find and 42 or 0
		Win.Popup(a, a.AbsoluteSize.X, math.min(#opts * 30, 180) + 8 + top, function(g, close)
			local box
			if find then _, box = search(g, "Search", "Raised", {Position = O(8, 8), Size = U(1, -16, 0, 28)}) end
			local m = new("ScrollingFrame", {Parent = g, Position = O(0, top), Size = U(1, 0, 1, -top), CanvasSize = U(), AutomaticCanvasSize = AY, ScrollBarThickness = 2, P = 4, L = 2,
				T = {ScrollBarImageColor3 = "Border"}})
			local rows = {}
			for i, v in ipairs(opts) do
				local b = new("TextButton", {Parent = m, Size = U(1, 0, 0, 28), LayoutOrder = i, R = 5, T = {BackgroundColor3 = "Raised"}})
				local t = label(b, tostring(v), 13, "Sub", nil, {Position = O(10, 0), Size = U(1, -40, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd})
				local mark = check(b, multi)
				local function paint(now)
					local state = isSel(v)
					mark(state, now)
					apply(t, {TextColor3 = state and Lib.Theme.Text or Lib.Theme.Sub}, now)
				end
				paint(true)
				b.MouseEnter:Connect(function() tw(b, {BackgroundTransparency = 0}) end)
				b.MouseLeave:Connect(function() tw(b, {BackgroundTransparency = 1}) end)
				b.Activated:Connect(function()
					pick(v)
					if multi then paint() else close() end
				end)
				rows[i] = {Frame = b, Text = tostring(v):lower()}
			end
			local none = label(m, "No matches", 13, "Muted", nil, {Size = U(1, 0, 0, 28), LayoutOrder = #opts + 1, Visible = false, TextXAlignment = CEN})
			if box then
				box:GetPropertyChangedSignal("Text"):Connect(function()
					local q, hits = box.Text:lower(), 0
					for _, r in ipairs(rows) do
						local ok = q == "" or r.Text:find(q, 1, true) ~= nil
						r.Frame.Visible = ok
						if ok then hits += 1 end
					end
					none.Visible = hits == 0
				end)
				if not UIS.TouchEnabled then task.defer(box.CaptureFocus, box) end
			end
		end)
	end

	local function choose(e)
		for _, x in ipairs(tabs) do x.set(x == e) end
		e.page.Position = O(0, 64); tw(e.page, {Position = O(0, 56)}, .2)
	end

	function Win:Tab(t) -- {Name, Icon, Section, Title, Desc}
		t = mix({Icon = "", Section = "GAME", Title = t.Name}, t)
		if t.Section ~= lastSection then
			lastSection = t.Section
			label(nav, t.Section:upper(), 11, "Muted", MED, {Size = U(1, 0, 0, 30), TextYAlignment = Enum.TextYAlignment.Bottom, P = {0, 0, 6, 12}, LayoutOrder = nx()})
		end
		local act = false
		local c = function(th) return act and th.Text or th.Sub end
		local item = new("TextButton", {Parent = nav, Size = U(1, 0, 0, 36), LayoutOrder = nx(), R = 6, T = {BackgroundColor3 = "Raised"}})
		local _, u1 = icon(item, t.Icon, {Position = O(12, 10), T = {ImageColor3 = c}})
		local _, u2 = label(item, t.Name, 14, c, MED, {Position = O(36, 0), Size = U(1, -36, 1, 0)})
		local page = new("ScrollingFrame", {Parent = content, Position = O(0, 56), Size = U(1, 0, 1, -56), Visible = false, CanvasSize = U(), AutomaticCanvasSize = AY,
			ScrollBarThickness = 2, P = {8, 32, 24, 32}, L = 0, T = {ScrollBarImageColor3 = "Border"}})
		label(page, t.Title, 26, "Text", BOLD, {Size = U(1, 0, 0, 36), LayoutOrder = nx()})
		label(page, t.Desc or "", 13, "Sub", nil, {Size = U(1, 0, 0, 20), LayoutOrder = nx()})

		local e = {page = page, items = {}}
		e.empty = label(page, "No results", 13, "Muted", nil, {Size = U(1, 0, 0, 56), TextXAlignment = CEN, LayoutOrder = 1000000, Visible = false})
		function e.set(v) act, page.Visible = v, v; u1(); u2(); tw(item, {BackgroundTransparency = v and 0 or 1}) end
		tabs[#tabs + 1] = e
		item.Activated:Connect(function() choose(e) end)
		item.MouseEnter:Connect(function() if not act then tw(item, {BackgroundTransparency = .6}) end end)
		item.MouseLeave:Connect(function() if not act then tw(item, {BackgroundTransparency = 1}) end end)
		if #tabs == 1 then choose(e) end
		return setmetatable({Win = Win, Page = page, Items = e.items}, {__index = TabM})
	end

	function Win:Settings() -- built-in tab: theme, UI toggle key, config management
		local t = Win:Tab({Name = "Settings", Icon = "settings", Section = "SYSTEM", Desc = "Appearance and configuration."})
		t:Section("Appearance")
		t:Dropdown({Name = "Theme", Desc = "Color scheme for the interface.", Flag = "__theme", Default = Lib.ThemeName, Callback = function(v) Lib:SetTheme(v) end,
			Options = function() local r = {} for k in pairs(Lib.Themes) do r[#r + 1] = k end table.sort(r) return r end})
		t:Keybind({Name = "Toggle UI", Desc = "Show or hide the window.", Flag = "__toggle", Default = o.ToggleKey})
		t:Section("Configuration")
		local name = t:Input({Name = "Config name", Desc = "Used when saving, loading or deleting.", Flag = false, Default = Lib.Config, Placeholder = "default"})
		t:Dropdown({Name = "Saved configs", Desc = "Pick an existing config.", Flag = false, Options = function() return Lib:List() end, Callback = name.Set})
		for _, b in ipairs{{"Save", "Write current values to this config."}, {"Load", "Apply values from this config."}, {"Delete", "Remove this config file."}} do
			t:Button({Name = b[1], Desc = b[2], Callback = function()
				local c = name.Get(); if c == "" then c = Lib.Config end
				local ok = Lib[b[1]](Lib, c) ~= false
				Lib:Notify{Title = ok and ("Config " .. b[1]:lower() .. "d") or "Config not found", Text = c, Type = ok and "Success" or "Error", Duration = 2.5}
			end})
		end
		return t
	end

	return Win
end

return Lib
