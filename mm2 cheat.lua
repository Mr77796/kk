-- ============================================
-- MM2 Hub | Fox + Claude Team
-- Thicker UI + Keybinds + Settings + Custom Size
-- Fix: slider drag, menu drag via header
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

print("-[(Fox + Claude) has successfully loaded]-")

-- ============================================
-- CONFIG
-- ============================================
local Config = {
    Speed = 50,
    Jump = 100,
    FlySpeed = 60,
    AimFOV = 200,
    AimSmooth = 0.35,
    AimSticky = 0.6,
    KnifeRange = 8,
    KnifeCooldown = 0.7,
    MenuKey = Enum.KeyCode.RightControl,
    AimKey = Enum.KeyCode.E,
    KnifeKey = Enum.KeyCode.Q,
    IconVisible = true,
    IconPosX = 30,
    IconPosY = 300,
    AccentIndex = 1,
    Transparency = 0,
    MenuWidth = 500,
    MenuHeight = 650,
}

local State = {
    Speed = false, Jump = false, Fly = false,
    ESP = false, Fullbright = false, Noclip = false,
    Aim = false, AutoKnife = false, InfiniteJump = false,
    AimKeyHeld = false,
}

local ACCENT_COLORS = {
    {name = "Green",  color = Color3.fromRGB(0, 255, 170)},
    {name = "Blue",   color = Color3.fromRGB(60, 140, 255)},
    {name = "Red",    color = Color3.fromRGB(255, 70, 70)},
    {name = "Purple", color = Color3.fromRGB(180, 100, 255)},
    {name = "Yellow", color = Color3.fromRGB(255, 210, 60)},
    {name = "Pink",   color = Color3.fromRGB(255, 100, 180)},
}

local function getAccent()
    return ACCENT_COLORS[Config.AccentIndex or 1].color
end

-- ============================================
-- SETTINGS PERSISTENCE
-- ============================================
local SAVE_KEY = "MM2_FoxClaude_Settings"

local function saveSettings()
    local data = {
        Config = {
            Speed = Config.Speed,
            Jump = Config.Jump,
            FlySpeed = Config.FlySpeed,
            AimFOV = Config.AimFOV,
            AimSmooth = Config.AimSmooth,
            AimSticky = Config.AimSticky,
            KnifeRange = Config.KnifeRange,
            KnifeCooldown = Config.KnifeCooldown,
            MenuKey = Config.MenuKey.Name,
            AimKey = Config.AimKey.Name,
            KnifeKey = Config.KnifeKey.Name,
            IconVisible = Config.IconVisible,
            IconPosX = Config.IconPosX,
            IconPosY = Config.IconPosY,
            AccentIndex = Config.AccentIndex,
            Transparency = Config.Transparency,
            MenuWidth = Config.MenuWidth,
            MenuHeight = Config.MenuHeight,
        },
        State = {
            Speed = State.Speed,
            Jump = State.Jump,
            ESP = State.ESP,
            Fullbright = State.Fullbright,
            Noclip = State.Noclip,
            Aim = State.Aim,
            AutoKnife = State.AutoKnife,
            InfiniteJump = State.InfiniteJump,
        }
    }
    pcall(function()
        writefile(SAVE_KEY .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadSettings()
    local ok, raw = pcall(readfile, SAVE_KEY .. ".json")
    if not ok or not raw then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 then return nil end
    return data
end

local SavedData = loadSettings()

if SavedData and SavedData.Config then
    local C = SavedData.Config
    for k, v in pairs(C) do
        if Config[k] ~= nil then Config[k] = v end
    end
    if type(Config.MenuKey) == "string" then
        local ok, key = pcall(function() return Enum.KeyCode[Config.MenuKey] end)
        Config.MenuKey = (ok and key) or Enum.KeyCode.RightControl
    end
    if type(Config.AimKey) == "string" then
        local ok, key = pcall(function() return Enum.KeyCode[Config.AimKey] end)
        Config.AimKey = (ok and key) or Enum.KeyCode.E
    end
    if type(Config.KnifeKey) == "string" then
        local ok, key = pcall(function() return Enum.KeyCode[Config.KnifeKey] end)
        Config.KnifeKey = (ok and key) or Enum.KeyCode.Q
    end
end

-- ============================================
-- ROLE DETECTION
-- ============================================
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 60, 60),
    Innocent = Color3.fromRGB(60, 255, 60),
    Sheriff  = Color3.fromRGB(60, 140, 255),
}

local function getPlayerRole(player)
    local function scanTools(container)
        if not container then return nil end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name == "Knife" then return "Murderer" end
                if tool.Name == "Gun" or tool.Name == "Revolver" then return "Sheriff" end
            end
        end
    end
    return scanTools(player.Character)
        or scanTools(player:FindFirstChild("Backpack"))
        or "Innocent"
end

-- ============================================
-- NOTIFY
-- ============================================
local activeNotifies = {}

local function Notify(title, text, duration)
    duration = duration or 3
    local sg = Instance.new("ScreenGui")
    sg.Name = "MM2Notify"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = CoreGui

    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0, 300, 0, 68)
    f.Position = UDim2.new(1, 360, 0, 20)
    f.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

    local accent = Instance.new("Frame", f)
    accent.Size = UDim2.new(0, 4, 1, -16)
    accent.Position = UDim2.new(0, 0, 0, 8)
    accent.BackgroundColor3 = getAccent()
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -28, 0, 26)
    t.Position = UDim2.new(0, 18, 0, 8)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = getAccent()
    t.Font = Enum.Font.GothamBold
    t.TextSize = 16
    t.TextXAlignment = Enum.TextXAlignment.Left

    local d = Instance.new("TextLabel", f)
    d.Size = UDim2.new(1, -28, 0, 22)
    d.Position = UDim2.new(0, 18, 0, 34)
    d.BackgroundTransparency = 1
    d.Text = text
    d.TextColor3 = Color3.fromRGB(200, 200, 210)
    d.Font = Enum.Font.Gotham
    d.TextSize = 13
    d.TextXAlignment = Enum.TextXAlignment.Left

    table.insert(activeNotifies, f)
    local slotIndex = #activeNotifies
    local yOffset = 20 + (slotIndex - 1) * 76

    f.Position = UDim2.new(1, 360, 0, yOffset)
    TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
        Position = UDim2.new(1, -320, 0, yOffset)
    }):Play()

    task.delay(duration, function()
        TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Position = UDim2.new(1, 360, 0, yOffset)
        }):Play()
        task.wait(0.35)
        sg:Destroy()
        for i, n in ipairs(activeNotifies) do
            if n == f then table.remove(activeNotifies, i) break end
        end
        for i, n in ipairs(activeNotifies) do
            if n.Parent then
                local newY = 20 + (i - 1) * 76
                TweenService:Create(n, TweenInfo.new(0.2), {
                    Position = UDim2.new(1, -320, 0, newY)
                }):Play()
            end
        end
    end)
end

-- ============================================
-- GUI (THICK)
-- ============================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "MM2_FoxClaude"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, Config.MenuWidth, 0, Config.MenuHeight)
Main.Position = UDim2.new(0.5, -Config.MenuWidth/2, 0.5, -Config.MenuHeight/2)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Main.BackgroundTransparency = Config.Transparency
Main.BorderSizePixel = 0
Main.Active = false -- ключевое: не перехватывает ввод
Main.Draggable = false
Main.ClipsDescendants = true
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)

-- Header
local HeaderContainer = Instance.new("Frame", Main)
HeaderContainer.Size = UDim2.new(1, 0, 0, 68)
HeaderContainer.Position = UDim2.new(0, 0, 0, 0)
HeaderContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
HeaderContainer.BorderSizePixel = 0
HeaderContainer.ClipsDescendants = true
HeaderContainer.Active = true -- перехватывает ввод для drag
Instance.new("UICorner", HeaderContainer).CornerRadius = UDim.new(0, 18)

local headerCornerFix = Instance.new("Frame", HeaderContainer)
headerCornerFix.Size = UDim2.new(1, 0, 0, 18)
headerCornerFix.Position = UDim2.new(0, 0, 1, -18)
headerCornerFix.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
headerCornerFix.BorderSizePixel = 0
headerCornerFix.ZIndex = 2
headerCornerFix.Active = false

local Title = Instance.new("TextLabel", HeaderContainer)
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 24, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2  •  FOX + CLAUDE"
Title.TextColor3 = getAccent()
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Active = false

local CloseBtn = Instance.new("TextButton", HeaderContainer)
CloseBtn.Size = UDim2.new(0, 42, 0, 42)
CloseBtn.Position = UDim2.new(1, -54, 0, 13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 22
CloseBtn.ZIndex = 3
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 12)
CloseBtn.MouseButton1Click:Connect(function()
    Gui.Enabled = false
end)

-- ============================================
-- MANUAL DRAG (только за Header)
-- ============================================
local dragging = false
local dragStart = nil
local startPos = nil

HeaderContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Tabs
local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1, -28, 0, 50)
TabBar.Position = UDim2.new(0, 14, 0, 78)
TabBar.BackgroundTransparency = 1

local Tabs = {"Move", "Visual", "Combat", "Extra", "Settings"}
local TabGrid = Instance.new("UIGridLayout", TabBar)
TabGrid.CellSize = UDim2.new(1/#Tabs, -10, 1, 0)
TabGrid.CellPadding = UDim2.new(0, 10, 0, 0)
TabGrid.SortOrder = Enum.SortOrder.LayoutOrder

local TabFrames = {}
local TabButtons = {}

local function SwitchTab(name)
    for n, fr in pairs(TabFrames) do
        fr.Visible = (n == name)
    end
    for n, btn in pairs(TabButtons) do
        if n == name then
            btn.BackgroundColor3 = getAccent()
            btn.TextColor3 = Color3.fromRGB(12, 12, 16)
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.TextColor3 = Color3.fromRGB(180, 180, 190)
        end
    end
end

for i, name in ipairs(Tabs) do
    local b = Instance.new("TextButton", TabBar)
    b.Name = name
    b.LayoutOrder = i
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    b.Text = name
    b.TextColor3 = Color3.fromRGB(180, 180, 190)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    b.MouseButton1Click:Connect(function() SwitchTab(name) end)
    TabButtons[name] = b
end

-- Content
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -28, 1, -148)
Content.Position = UDim2.new(0, 14, 0, 138)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.Active = false

for _, name in ipairs(Tabs) do
    local fr = Instance.new("ScrollingFrame", Content)
    fr.Name = name
    fr.Size = UDim2.new(1, 0, 1, 0)
    fr.BackgroundTransparency = 1
    fr.ScrollBarThickness = 4
    fr.CanvasSize = UDim2.new(0, 0, 0, 0)
    fr.AutomaticCanvasSize = Enum.AutomaticSize.Y
    fr.Visible = (name == "Move")
    fr.BorderSizePixel = 0
    fr.ScrollBarImageColor3 = getAccent()
    fr.Active = false
    TabFrames[name] = fr
    local lay = Instance.new("UIListLayout", fr)
    lay.Padding = UDim.new(0, 10)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", fr)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 6)
end

-- ============================================
-- UI BUILDERS
-- ============================================
local function AddToggle(parent, text, order, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -4, 0, 50)
    btn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -90, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local st = Instance.new("TextLabel", btn)
    st.Size = UDim2.new(0, 60, 0, 30)
    st.Position = UDim2.new(1, -74, 0.5, -15)
    st.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    st.Text = "OFF"
    st.TextColor3 = Color3.fromRGB(160, 160, 170)
    st.Font = Enum.Font.GothamBold
    st.TextSize = 13
    st.BorderSizePixel = 0
    Instance.new("UICorner", st).CornerRadius = UDim.new(0, 9)

    local en = false
    local function setEnabled(val, silent)
        en = val
        if en then
            st.Text = "ON"
            st.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
            st.TextColor3 = Color3.new(1,1,1)
            btn.BackgroundColor3 = Color3.fromRGB(20, 38, 32)
        else
            st.Text = "OFF"
            st.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            st.TextColor3 = Color3.fromRGB(160, 160, 170)
            btn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
        end
        if not silent then callback(en) end
    end

    btn.MouseButton1Click:Connect(function()
        setEnabled(not en)
        saveSettings()
    end)

    return setEnabled
end

local function AddSlider(parent, text, order, min, max, default, callback)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, -4, 0, 70)
    fr.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    fr.LayoutOrder = order
    fr.BorderSizePixel = 0
    fr.Active = false
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 12)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -28, 0, 24)
    lbl.Position = UDim2.new(0, 18, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. " : " .. tostring(default)
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Active = false

    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1, -32, 0, 8)
    track.Position = UDim2.new(0, 16, 0, 44)
    track.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    track.BorderSizePixel = 0
    track.Active = true
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = getAccent()
    fill.BorderSizePixel = 0
    fill.Active = false
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Active = false
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function setValue(val, silent)
        val = math.clamp(val, min, max)
        local rel = (val - min) / (max - min)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -10, 0.5, -10)
        lbl.Text = text .. " : " .. tostring(val)
        if not silent then
            callback(val)
            saveSettings()
        end
    end

    local drag = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            local rel = math.clamp(
                (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                0, 1
            )
            local val = math.floor(min + (max - min) * rel)
            setValue(val)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            if drag then
                drag = false
                saveSettings()
            end
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local rel = math.clamp(
                (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                0, 1
            )
            local val = math.floor(min + (max - min) * rel)
            setValue(val, true)
            if not silent then
                -- silent не определён тут, вызываем callback вручную
            end
            callback(val)
        end
    end)

    return setValue
end

local function AddKeybind(parent, text, order, getter, setter)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, -4, 0, 50)
    fr.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    fr.LayoutOrder = order
    fr.BorderSizePixel = 0
    fr.Active = false
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 12)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -160, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Active = false

    local kb = Instance.new("TextButton", fr)
    kb.Size = UDim2.new(0, 130, 0, 32)
    kb.Position = UDim2.new(1, -144, 0.5, -16)
    kb.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    kb.Text = getter().Name
    kb.TextColor3 = Color3.new(1,1,1)
    kb.Font = Enum.Font.GothamBold
    kb.TextSize = 13
    kb.BorderSizePixel = 0
    Instance.new("UICorner", kb).CornerRadius = UDim.new(0, 9)

    local listening = false
    local listenerConn

    local function stopListening()
        listening = false
        kb.Text = getter().Name
        kb.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        kb.TextColor3 = Color3.new(1,1,1)
        if listenerConn then listenerConn:Disconnect() listenerConn = nil end
    end

    kb.MouseButton1Click:Connect(function()
        if listening then stopListening() return end
        listening = true
        kb.Text = "Нажми клавишу..."
        kb.BackgroundColor3 = getAccent()
        kb.TextColor3 = Color3.fromRGB(12, 12, 16)

        listenerConn = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                setter(input.KeyCode)
                saveSettings()
                stopListening()
                Notify("Keybind", text .. " → " .. input.KeyCode.Name, 2)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                setter(Enum.UserInputType.MouseButton1)
                saveSettings()
                stopListening()
                Notify("Keybind", text .. " → LMB", 2)
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                setter(Enum.UserInputType.MouseButton2)
                saveSettings()
                stopListening()
                Notify("Keybind", text .. " → RMB", 2)
            end
        end)
    end)

    return stopListening
end

local function AddDropdown(parent, text, order, options, defaultIndex, callback)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, -4, 0, 50)
    fr.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    fr.LayoutOrder = order
    fr.BorderSizePixel = 0
    fr.Active = false
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 12)

    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -160, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Active = false

    local dd = Instance.new("TextButton", fr)
    dd.Size = UDim2.new(0, 130, 0, 32)
    dd.Position = UDim2.new(1, -144, 0.5, -16)
    dd.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    dd.Text = options[defaultIndex] and options[defaultIndex].name or "---"
    dd.TextColor3 = Color3.new(1,1,1)
    dd.Font = Enum.Font.GothamBold
    dd.TextSize = 13
    dd.BorderSizePixel = 0
    Instance.new("UICorner", dd).CornerRadius = UDim.new(0, 9)

    local open = false
    local listFrame

    local function closeList()
        open = false
        if listFrame then listFrame:Destroy() listFrame = nil end
    end

    dd.MouseButton1Click:Connect(function()
        if open then closeList() return end
        open = true
        listFrame = Instance.new("Frame", fr)
        listFrame.Size = UDim2.new(0, 130, 0, #options * 30 + 8)
        listFrame.Position = UDim2.new(1, -144, 0, 50)
        listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        listFrame.BorderSizePixel = 0
        listFrame.ZIndex = 50
        listFrame.Active = false
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)

        local listLay = Instance.new("UIListLayout", listFrame)
        listLay.Padding = UDim.new(0, 2)
        local pad = Instance.new("UIPadding", listFrame)
        pad.PaddingTop = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 4)

        for i, opt in ipairs(options) do
            local ob = Instance.new("TextButton", listFrame)
            ob.Size = UDim2.new(1, -8, 0, 28)
            ob.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            ob.Text = opt.name
            ob.TextColor3 = Color3.new(1,1,1)
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 13
            ob.BorderSizePixel = 0
            ob.ZIndex = 51
            Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 6)
            ob.MouseButton1Click:Connect(function()
                dd.Text = opt.name
                callback(i)
                saveSettings()
                closeList()
            end)
        end
    end)

    return function()
        dd.Text = options[defaultIndex] and options[defaultIndex].name or "---"
    end
end

-- ============================================
-- MOVE TAB
-- ============================================
local MoveTab = TabFrames.Move

local setSpeedSlider = AddSlider(MoveTab, "Speed", 1, 16, 200, Config.Speed, function(v)
    Config.Speed = v
    if State.Speed and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.WalkSpeed = v
    end
end)

local setSpeedToggle = AddToggle(MoveTab, "Speed Boost", 2, function(s)
    State.Speed = s
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.WalkSpeed = s and Config.Speed or 16
    end
    Notify("Speed", s and "ON" or "OFF", 2)
end)

local setJumpSlider = AddSlider(MoveTab, "Jump", 3, 50, 300, Config.Jump, function(v)
    Config.Jump = v
    if State.Jump and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.JumpPower = v
    end
end)

local setJumpToggle = AddToggle(MoveTab, "Jump Boost", 4, function(s)
    State.Jump = s
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        hum.UseJumpPower = true
        hum.JumpPower = s and Config.Jump or 50
    end
    Notify("Jump", s and "ON" or "OFF", 2)
end)

local setFlySlider = AddSlider(MoveTab, "Fly Speed", 5, 10, 300, Config.FlySpeed, function(v)
    Config.FlySpeed = v
end)

local flyBV, flyBG
local function startFly()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 9e4
    flyBG.Parent = hrp

    if hum then hum.PlatformStand = true end

    RunService:BindToRenderStep("FoxFly", Enum.RenderPriority.Camera.Value, function()
        if not State.Fly or not flyBV or not flyBG then return end
        local cam = workspace.CurrentCamera
        flyBG.CFrame = cam.CFrame
        local m = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then m += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then m -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then m -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then m += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then m += Vector3.yAxis end        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then m -= Vector3.yAxis end
        flyBV.Velocity = m.Magnitude > 0 and m.Unit * Config.FlySpeed or Vector3.zero
    end)
end

local function stopFly()
    RunService:UnbindFromRenderStep("FoxFly")
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local char = LP.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

AddToggle(MoveTab, "Fly", 6, function(s)
    State.Fly = s
    if s then startFly() else stopFly() end
    Notify("Fly", s and "ON" or "OFF", 2)
end)

local noclipSaved = {}
local noclipConn

local function startNoclip()
    noclipSaved = {}
    noclipConn = RunService.Stepped:Connect(function()
        local char = LP.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                if noclipSaved[p] == nil then
                    noclipSaved[p] = true
                end
                p.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    for part, orig in pairs(noclipSaved) do
        if part and part.Parent then
            part.CanCollide = orig
        end
    end
    noclipSaved = {}
    local char = LP.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.CanCollide = true
            end
        end
    end
end

local setNoclipToggle = AddToggle(MoveTab, "Noclip", 7, function(s)
    State.Noclip = s
    if s then startNoclip() else stopNoclip() end
    Notify("Noclip", s and "ON" or "OFF", 2)
end)

local setInfJumpToggle = AddToggle(MoveTab, "Infinite Jump", 8, function(s)
    State.InfiniteJump = s
    Notify("Infinite Jump", s and "ON" or "OFF", 2)
end)

UIS.JumpRequest:Connect(function()
    if State.InfiniteJump and LP.Character then
        local hum = LP.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ============================================
-- VISUAL TAB
-- ============================================
local VisTab = TabFrames.Visual

local espFolder = Instance.new("Folder", CoreGui)
espFolder.Name = "MM2_ESP"

local function clearPlayerESP(player)
    for _, v in ipairs(espFolder:GetChildren()) do
        if v:GetAttribute("Owner") == player.UserId then v:Destroy() end
    end
end

local function buildESP(player)
    if player == LP then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    clearPlayerESP(player)

    local role = getPlayerRole(player)
    local color = ROLE_COLORS[role]

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 120, 0, 24)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    bb.Parent = espFolder
    bb:SetAttribute("Owner", player.UserId)

    local label = Instance.new("TextLabel", bb)
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = player.Name .. " [" .. role .. "]"
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold

    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 6, 4)
    box.Adornee = hrp
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.5
    box.Color3 = color
    box.Parent = espFolder
    box:SetAttribute("Owner", player.UserId)
end

local function refreshESP()
    espFolder:ClearAllChildren()
    if not State.ESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        buildESP(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    if State.ESP then
        task.wait(1)
        buildESP(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    clearPlayerESP(p)
end)

RunService.Heartbeat:Connect(function()
    if not State.ESP then return end
    for _, v in ipairs(espFolder:GetChildren()) do
        local uid = v:GetAttribute("Owner")
        if not uid then continue end
        local p = Players:GetPlayerByUserId(uid)
        if not p or not p.Character then
            v:Destroy()
            continue
        end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            v:Destroy()
            continue
        end
        if v:IsA("BillboardGui") or v:IsA("BoxHandleAdornment") then
            v.Adornee = hrp
        end
        local role = getPlayerRole(p)
        local color = ROLE_COLORS[role]
        if v:IsA("BoxHandleAdornment") then
            v.Color3 = color
        elseif v:IsA("BillboardGui") then
            local lbl = v:FindFirstChildOfClass("TextLabel")
            if lbl then
                lbl.TextColor3 = color
                lbl.Text = p.Name .. " [" .. role .. "]"
            end
        end
    end
end)

local setESPToggle = AddToggle(VisTab, "ESP (роли)", 1, function(s)
    State.ESP = s
    refreshESP()
    Notify("ESP", s and "ON" or "OFF", 2)
end)

local savedLight = {}
local setFullbrightToggle = AddToggle(VisTab, "Fullbright", 2, function(s)
    State.Fullbright = s
    if s then
        savedLight.Brightness = Lighting.Brightness
        savedLight.Ambient = Lighting.Ambient
        savedLight.Outdoor = Lighting.OutdoorAmbient
        savedLight.FogEnd = Lighting.FogEnd
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.FogEnd = 1e6
    else
        Lighting.Brightness = savedLight.Brightness or 1
        Lighting.Ambient = savedLight.Ambient or Color3.fromRGB(128,128,128)
        Lighting.OutdoorAmbient = savedLight.Outdoor or Color3.fromRGB(128,128,128)
        Lighting.FogEnd = savedLight.FogEnd or 1000
    end
    Notify("Fullbright", s and "ON" or "OFF", 2)
end)

-- ============================================
-- COMBAT TAB
-- ============================================
local CombatTab = TabFrames.Combat

local setAimFOVSlider = AddSlider(CombatTab, "Aim FOV", 1, 50, 500, Config.AimFOV, function(v) Config.AimFOV = v end)
local setAimSmoothSlider = AddSlider(CombatTab, "Aim Smooth", 2, 5, 100,
    math.floor(Config.AimSmooth * 100), function(v) Config.AimSmooth = v / 100 end)

local aimStickyTarget = nil
local aimStickyTime = 0

local function isValidTarget(p)
    if p == LP then return false end
    local char = p.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return false end
    return hum.Health > 0
end

local function getClosestTarget()
    local cam = workspace.CurrentCamera
    local cx = cam.ViewportSize.X / 2
    local cy = cam.ViewportSize.Y / 2
    local closest, minDist = nil, Config.AimFOV

    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p) then
            local hrp = p.Character.HumanoidRootPart
            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen and pos.Z > 0 then
                local dist = math.sqrt((pos.X - cx)^2 + (pos.Y - cy)^2)
                if dist < minDist then
                    minDist = dist
                    closest = p
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not State.Aim then
        aimStickyTarget = nil
        return
    end
    if not State.AimKeyHeld then return end

    local now = tick()
    local cam = workspace.CurrentCamera

    if aimStickyTarget and isValidTarget(aimStickyTarget) then
        local hrp = aimStickyTarget.Character and aimStickyTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen and pos.Z > 0 then
                local dist = math.sqrt(
                    (pos.X - cam.ViewportSize.X/2)^2 +
                    (pos.Y - cam.ViewportSize.Y/2)^2
                )
                if dist <= Config.AimFOV and now - aimStickyTime < Config.AimSticky then
                    cam.CFrame = cam.CFrame:Lerp(
                        CFrame.new(cam.CFrame.Position, hrp.Position),
                        Config.AimSmooth
                    )
                    return
                end
            end
        end
    end

    local target = getClosestTarget()
    aimStickyTarget = target
    aimStickyTime = now
    if not target then return end

    local hrp = target.Character.HumanoidRootPart
    cam.CFrame = cam.CFrame:Lerp(
        CFrame.new(cam.CFrame.Position, hrp.Position),
        Config.AimSmooth
    )
end)

local setAimToggle = AddToggle(CombatTab, "Aim (hold key)", 3, function(s)
    State.Aim = s
    aimStickyTarget = nil
    Notify("Aim", s and "ON" or "OFF", 2)
end)

local setKnifeRangeSlider = AddSlider(CombatTab, "Knife Range", 4, 5, 15, Config.KnifeRange, function(v)
    Config.KnifeRange = v
end)
local setKnifeCDSlider = AddSlider(CombatTab, "Knife Cooldown", 5, 40, 150,
    math.floor(Config.KnifeCooldown * 100), function(v) Config.KnifeCooldown = v / 100 end)

local lastKnifeTime = 0
RunService.Heartbeat:Connect(function()
    if not State.AutoKnife then return end
    if tick() - lastKnifeTime < Config.KnifeCooldown then return end

    local myChar = LP.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local knife
    for _, tool in ipairs(myChar:GetChildren()) do
        if tool:IsA("Tool") and tool.Name == "Knife" then
            knife = tool
            break
        end
    end
    if not knife then return end

    local closest, closestDist = nil, Config.KnifeRange
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then continue end
        local dist = (myHRP.Position - hrp.Position).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = p
        end
    end

    if closest then
        local hrp = closest.Character.HumanoidRootPart
        myHRP.CFrame = CFrame.new(
            myHRP.Position,
            Vector3.new(hrp.Position.X, myHRP.Position.Y, hrp.Position.Z)
        )
        pcall(function() knife:Activate() end)
        lastKnifeTime = tick()
    end
end)

local setAutoKnifeToggle = AddToggle(CombatTab, "Auto-Knife (мардер)", 6, function(s)
    State.AutoKnife = s
    Notify("Auto-Knife", s and "ON" or "OFF", 2)
end)

-- ============================================
-- EXTRA TAB
-- ============================================
local ExtraTab = TabFrames.Extra

local infoLbl = Instance.new("TextLabel", ExtraTab)
infoLbl.Size = UDim2.new(1, -4, 0, 70)
infoLbl.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
infoLbl.Text = "Иконка — тапни открыть/закрыть\nКлавиши меню/Aim/Knife — в Settings\nТяни меню за шапку"
infoLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 13
infoLbl.TextWrapped = true
infoLbl.LayoutOrder = 1
infoLbl.BorderSizePixel = 0
Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 12)

local emotesBtn = Instance.new("TextButton", ExtraTab)
emotesBtn.Size = UDim2.new(1, -4, 0, 50)
emotesBtn.BackgroundColor3 = getAccent()
emotesBtn.Text = "Открыть Emotes"
emotesBtn.TextColor3 = Color3.fromRGB(12, 12, 16)
emotesBtn.Font = Enum.Font.GothamBold
emotesBtn.TextSize = 15
emotesBtn.LayoutOrder = 2
emotesBtn.BorderSizePixel = 0
Instance.new("UICorner", emotesBtn).CornerRadius = UDim.new(0, 12)
emotesBtn.MouseButton1Click:Connect(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"))()
    end)
    Notify("Emotes", "Загрузка...", 2)
end)

local unloadBtn = Instance.new("TextButton", ExtraTab)
unloadBtn.Size = UDim2.new(1, -4, 0, 50)
unloadBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
unloadBtn.Text = "Unload"
unloadBtn.TextColor3 = Color3.new(1,1,1)
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.TextSize = 15
unloadBtn.LayoutOrder = 3
unloadBtn.BorderSizePixel = 0
Instance.new("UICorner", unloadBtn).CornerRadius = UDim.new(0, 12)
unloadBtn.MouseButton1Click:Connect(function()
    stopFly()
    if State.Noclip then stopNoclip() end
    espFolder:Destroy()
    Gui:Destroy()
    if FloatingIcon and FloatingIcon.Parent then FloatingIcon:Destroy() end
end)

-- ============================================
-- SETTINGS TAB
-- ============================================
local SettingsTab = TabFrames.Settings

AddKeybind(SettingsTab, "Клавиша меню", 1,
    function() return Config.MenuKey end,
    function(k) Config.MenuKey = k end
)

AddKeybind(SettingsTab, "Клавиша Aim (hold)", 2,
    function() return Config.AimKey end,
    function(k) Config.AimKey = k end
)

AddKeybind(SettingsTab, "Клавиша Auto-Knife", 3,
    function() return Config.KnifeKey end,
    function(k) Config.KnifeKey = k end
)

AddToggle(SettingsTab, "Показывать иконку", 4, function(s)
    Config.IconVisible = s
    if IconBtn then IconBtn.Visible = s end
    Notify("Icon", s and "ON" or "OFF", 2)
end)

AddSlider(SettingsTab, "Прозрачность меню %", 5, 0, 80, math.floor(Config.Transparency * 100), function(v)
    Config.Transparency = v / 100
    Main.BackgroundTransparency = Config.Transparency
end)

AddDropdown(SettingsTab, "Цвет акцента", 6, ACCENT_COLORS, Config.AccentIndex or 1, function(i)
    Config.AccentIndex = i
    local c = getAccent()
    Title.TextColor3 = c
    for n, btn in pairs(TabButtons) do
        if TabFrames[n].Visible then
            btn.BackgroundColor3 = c
        end
    end
    emotesBtn.BackgroundColor3 = c
    IconBtn.TextColor3 = c
    IconStroke.Color = c
    Notify("Accent", ACCENT_COLORS[i].name, 2)
end)

local resetBtn = Instance.new("TextButton", SettingsTab)
resetBtn.Size = UDim2.new(1, -4, 0, 50)
resetBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 40)
resetBtn.Text = "Сбросить настройки"
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 15
resetBtn.LayoutOrder = 7
resetBtn.BorderSizePixel = 0
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 12)
resetBtn.MouseButton1Click:Connect(function()
    pcall(function() delfile(SAVE_KEY .. ".json") end)
    Notify("Settings", "Сброшено. Перезапусти скрипт.", 4)
end)

AddSlider(SettingsTab, "Ширина меню", 8, 350, 900, Config.MenuWidth, function(v)
    Config.MenuWidth = v
    Main.Size = UDim2.new(0, v, 0, Main.Size.Y.Offset)
end)

AddSlider(SettingsTab, "Высота меню", 9, 400, 950, Config.MenuHeight, function(v)
    Config.MenuHeight = v
    Main.Size = UDim2.new(0, Main.Size.X.Offset, 0, v)
end)

-- ============================================
-- FLOATING ICON
-- ============================================
local FloatingIcon = Instance.new("ScreenGui")
FloatingIcon.Name = "MM2_Icon"
FloatingIcon.ResetOnSpawn = false
FloatingIcon.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FloatingIcon.Parent = CoreGui

local IconBtn = Instance.new("TextButton")
IconBtn.Size = UDim2.new(0, 60, 0, 60)
IconBtn.Position = UDim2.new(0, Config.IconPosX or 30, 0, Config.IconPosY or 300)
IconBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
IconBtn.Text = "F"
IconBtn.TextColor3 = getAccent()
IconBtn.Font = Enum.Font.GothamBold
IconBtn.TextSize = 26
IconBtn.AutoButtonColor = false
IconBtn.Active = true
IconBtn.Draggable = false
IconBtn.BorderSizePixel = 0
IconBtn.Visible = Config.IconVisible ~= false
IconBtn.Parent = FloatingIcon
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(0, 30)

local IconStroke = Instance.new("UIStroke", IconBtn)
IconStroke.Thickness = 2
IconStroke.Color = getAccent()
IconStroke.Transparency = 0.3

local iconDragging = false
local iconDragStart = nil
local iconStartPos = nil
local iconWasDragged = false

IconBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging = true
        iconWasDragged = false
        iconDragStart = input.Position
        iconStartPos = IconBtn.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not iconDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - iconDragStart
        if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
            iconWasDragged = true
        end
        IconBtn.Position = UDim2.new(
            iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if iconDragging and not iconWasDragged then
            Gui.Enabled = not Gui.Enabled
        end
        if iconDragging then
            Config.IconPosX = IconBtn.Position.X.Offset
            Config.IconPosY = IconBtn.Position.Y.Offset
            saveSettings()
        end
        iconDragging = false
    end
end)

-- ============================================
-- KEYBINDS
-- ============================================
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end

    if inp.KeyCode == Config.MenuKey then
        Gui.Enabled = not Gui.Enabled
    end

    if inp.KeyCode == Config.AimKey then
        State.AimKeyHeld = true
    end

    if inp.KeyCode == Config.KnifeKey then
        State.AutoKnife = not State.AutoKnife
        Notify("Auto-Knife", State.AutoKnife and "ON" or "OFF", 2)
        if setAutoKnifeToggle then setAutoKnifeToggle(State.AutoKnife, true) end
    end
end)

UIS.InputEnded:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Config.AimKey then
        State.AimKeyHeld = false
    end
end)

-- ============================================
-- RESPAWN
-- ============================================
LP.CharacterAdded:Connect(function(char)
    task.wait(0.7)
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    if State.Speed then hum.WalkSpeed = Config.Speed end
    if State.Jump then
        hum.UseJumpPower = true
        hum.JumpPower = Config.Jump
    end
    if State.Fly then startFly() end
    if State.ESP then
        task.wait(0.3)
        refreshESP()
    end
    if State.Noclip then
        noclipSaved = {}
        if not noclipConn then startNoclip() end
    end
end)

-- ============================================
-- RESTORE SAVED
-- ============================================
if SavedData then
    setSpeedSlider(Config.Speed, true)
    setJumpSlider(Config.Jump, true)
    setFlySlider(Config.FlySpeed, true)
    setAimFOVSlider(Config.AimFOV, true)
    setAimSmoothSlider(math.floor(Config.AimSmooth * 100), true)
    setKnifeRangeSlider(Config.KnifeRange, true)
    setKnifeCDSlider(math.floor(Config.KnifeCooldown * 100), true)

    if SavedData.State then
        local S = SavedData.State
        if S.Speed then setSpeedToggle(true, true); State.Speed = true end
        if S.Jump then setJumpToggle(true, true); State.Jump = true end
        if S.ESP then setESPToggle(true, true); State.ESP = true; refreshESP() end
        if S.Fullbright then setFullbrightToggle(true, true); State.Fullbright = true
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.OutdoorAmbient = Color3.new(1,1,1)
            Lighting.FogEnd = 1e6
        end
        if S.Noclip then setNoclipToggle(true, true); State.Noclip = true; startNoclip() end
        if S.Aim then setAimToggle(true, true); State.Aim = true end
        if S.AutoKnife then setAutoKnifeToggle(true, true); State.AutoKnife = true end
        if S.InfiniteJump then setInfJumpToggle(true, true); State.InfiniteJump = true end

        task.defer(function()
            local char = LP.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            if not hum then return end
            if State.Speed then hum.WalkSpeed = Config.Speed end
            if State.Jump then
                hum.UseJumpPower = true
                hum.JumpPower = Config.Jump
            end
        end)
    end
end

SwitchTab("Move")
Notify("Fox + Claude", "loaded" .. (SavedData and " (settings restored)" or ""), 5)
print("MM2 Fox+Claude ready")
