local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Config = {
    Speed = 50, Jump = 100, FlySpeed = 60,
    AimFOV = 200, AimSmooth = 0.35, AimSticky = 0.6,
    KnifeRange = 8, KnifeCooldown = 0.7,
    MenuKey = Enum.KeyCode.RightControl,
    AimKey = Enum.KeyCode.E,
    KnifeKey = Enum.KeyCode.Q,
    AccentIndex = 1,
    Transparency = 0,
    MenuWidth = 560, MenuHeight = 650,
    FlingPower = 800,
    FlingUp = 500,
    FlingSpin = 30,
    SpinSpeed = 40,
    BlackHoleActive = false,
    BlackHoleRadius = 15,
    BlackHoleSpeed = 30,
    BlackHoleRange = 40,
    BlackHoleMode = "Все",
    BlackHoleTasks = {},
    RamActive = false,
    RamSpeed = 150,
    RamKillRange = 6,
}

local State = {
    Speed = false, Jump = false, Fly = false,
    ESP = false, Fullbright = false, Noclip = false,
    Aim = false, AutoKnife = false, InfiniteJump = false,
    AimKeyHeld = false, FlingActive = false,
    FlingTarget = nil, FlingThread = nil,
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

local SAVE_KEY = "MM2_FoxClaude_Settings"

local function saveSettings()
    local data = {
        Config = {
            Speed = Config.Speed, Jump = Config.Jump, FlySpeed = Config.FlySpeed,
            AimFOV = Config.AimFOV, AimSmooth = Config.AimSmooth, AimSticky = Config.AimSticky,
            KnifeRange = Config.KnifeRange, KnifeCooldown = Config.KnifeCooldown,
            MenuKey = Config.MenuKey.Name, AimKey = Config.AimKey.Name, KnifeKey = Config.KnifeKey.Name,
            AccentIndex = Config.AccentIndex, Transparency = Config.Transparency,
            MenuWidth = Config.MenuWidth, MenuHeight = Config.MenuHeight,
            FlingPower = Config.FlingPower, FlingUp = Config.FlingUp, FlingSpin = Config.FlingSpin,
            SpinSpeed = Config.SpinSpeed, BlackHoleRadius = Config.BlackHoleRadius,
            BlackHoleSpeed = Config.BlackHoleSpeed, BlackHoleRange = Config.BlackHoleRange,
            RamSpeed = Config.RamSpeed, RamKillRange = Config.RamKillRange,
        },
        State = {
            Speed = State.Speed, Jump = State.Jump, ESP = State.ESP,
            Fullbright = State.Fullbright, Noclip = State.Noclip,
            Aim = State.Aim, AutoKnife = State.AutoKnife, InfiniteJump = State.InfiniteJump,
        }
    }
    pcall(function() writefile(SAVE_KEY .. ".json", HttpService:JSONEncode(data)) end)
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
    for k, v in pairs(C) do if Config[k] ~= nil then Config[k] = v end end
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
    return scanTools(player.Character) or scanTools(player:FindFirstChild("Backpack")) or "Innocent"
end

local function notify(title, text, duration)
    WindUI:Notify({Title = title, Content = text, Icon = "wind", Duration = duration or 3})
end

local Window = WindUI:CreateWindow({
    Title = "MM2 • FOX + CLAUDE",
    Author = "1gor3k",
    Folder = "MM2FoxClaude",
    Size = UDim2.fromOffset(Config.MenuWidth, Config.MenuHeight),
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 160,
    HideSearchBar = false,
    NewElements = true,
    ScrollBarEnabled = true,
    Acrylic = false,
    OpenButton = { Title = "F", Enabled = true, Draggable = true, CornerRadius = UDim.new(1, 0), Color = ColorSequence.new(getAccent(), getAccent()), OnlyMobile = false },
})

local MyConfig = Window.ConfigManager:CreateConfig("AutoSave", true)

local MoveTab = Window:Tab({ Title = "Move", Icon = "person-running" })
local VisTab = Window:Tab({ Title = "Visual", Icon = "eye" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshairs" })
local FapTab = Window:Tab({ Title = "Фтап", Icon = "wind" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "gear" })

local MoveSec = MoveTab:Section({ Title = "Speed", Opened = true })
MoveSec:Slider({ Title = "Speed", Flag = "SpeedValue", Value = { Min = 16, Max = 200, Default = Config.Speed }, Step = 1, Callback = function(v)
    Config.Speed = v
    if State.Speed and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.WalkSpeed = v
    end
end })
MoveSec:Toggle({ Title = "Speed Boost", Flag = "SpeedEnabled", Value = false, Callback = function(s)
    State.Speed = s
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.WalkSpeed = s and Config.Speed or 16
    end
    notify("Speed", s and "ON" or "OFF", 2)
end })

local JumpSec = MoveTab:Section({ Title = "Jump" })
JumpSec:Slider({ Title = "Jump", Flag = "JumpValue", Value = { Min = 50, Max = 300, Default = Config.Jump }, Step = 1, Callback = function(v)
    Config.Jump = v
    if State.Jump and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.JumpPower = v
    end
end })
JumpSec:Toggle({ Title = "Jump Boost", Flag = "JumpEnabled", Value = false, Callback = function(s)
    State.Jump = s
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        hum.UseJumpPower = true
        hum.JumpPower = s and Config.Jump or 50
    end
    notify("Jump", s and "ON" or "OFF", 2)
end })

local FlySec = MoveTab:Section({ Title = "Fly" })
FlySec:Slider({ Title = "Fly Speed", Flag = "FlySpeedValue", Value = { Min = 10, Max = 300, Default = Config.FlySpeed }, Step = 1, Callback = function(v) Config.FlySpeed = v end })

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
        if UIS:IsKeyDown(Enum.KeyCode.Space) then m += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then m -= Vector3.yAxis end
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
FlySec:Toggle({ Title = "Fly", Flag = "FlyEnabled", Value = false, Callback = function(s)
    State.Fly = s
    if s then startFly() else stopFly() end
    notify("Fly", s and "ON" or "OFF", 2)
end })

local noclipSaved = {}
local noclipConn
local function startNoclip()
    noclipSaved = {}
    noclipConn = RunService.Stepped:Connect(function()
        local char = LP.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                if noclipSaved[p] == nil then noclipSaved[p] = true end
                p.CanCollide = false
            end
        end
    end)
end
local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    for part, orig in pairs(noclipSaved) do
        if part and part.Parent then part.CanCollide = orig end
    end
    noclipSaved = {}
    local char = LP.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
        end
    end
end
MoveTab:Section({ Title = "Noclip" }):Toggle({ Title = "Noclip", Flag = "NoclipEnabled", Value = false, Callback = function(s)
    State.Noclip = s
    if s then startNoclip() else stopNoclip() end
    notify("Noclip", s and "ON" or "OFF", 2)
end })

MoveTab:Section({ Title = "Infinite Jump" }):Toggle({ Title = "Infinite Jump", Flag = "InfJumpEnabled", Value = false, Callback = function(s)
    State.InfiniteJump = s
    notify("Infinite Jump", s and "ON" or "OFF", 2)
end })

UIS.JumpRequest:Connect(function()
    if State.InfiniteJump and LP.Character then
        local hum = LP.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

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
    for _, p in ipairs(Players:GetPlayers()) do buildESP(p) end
end

Players.PlayerAdded:Connect(function(p) if State.ESP then task.wait(1); buildESP(p) end end)
Players.PlayerRemoving:Connect(function(p) clearPlayerESP(p) end)

RunService.Heartbeat:Connect(function()
    if not State.ESP then return end
    for _, v in ipairs(espFolder:GetChildren()) do
        local uid = v:GetAttribute("Owner")
        if not uid then continue end
        local p = Players:GetPlayerByUserId(uid)
        if not p or not p.Character then v:Destroy() continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then v:Destroy() continue end
        if v:IsA("BillboardGui") or v:IsA("BoxHandleAdornment") then v.Adornee = hrp end
        local role = getPlayerRole(p)
        local color = ROLE_COLORS[role]
        if v:IsA("BoxHandleAdornment") then v.Color3 = color
        elseif v:IsA("BillboardGui") then
            local lbl = v:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.TextColor3 = color; lbl.Text = p.Name .. " [" .. role .. "]" end
        end
    end
end)

VisTab:Section({ Title = "ESP", Opened = true }):Toggle({ Title = "ESP (роли)", Flag = "ESPEnabled", Value = false, Callback = function(s)
    State.ESP = s
    refreshESP()
    notify("ESP", s and "ON" or "OFF", 2)
end })

local savedLight = {}
VisTab:Section({ Title = "Fullbright" }):Toggle({ Title = "Fullbright", Flag = "FullbrightEnabled", Value = false, Callback = function(s)
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
    notify("Fullbright", s and "ON" or "OFF", 2)
end })

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
                if dist < minDist then minDist = dist; closest = p end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not State.Aim then aimStickyTarget = nil; return end
    if not State.AimKeyHeld then return end
    local now = tick()
    local cam = workspace.CurrentCamera
    if aimStickyTarget and isValidTarget(aimStickyTarget) then
        local hrp = aimStickyTarget.Character and aimStickyTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen and pos.Z > 0 then
                local dist = math.sqrt((pos.X - cam.ViewportSize.X/2)^2 + (pos.Y - cam.ViewportSize.Y/2)^2)
                if dist <= Config.AimFOV and now - aimStickyTime < Config.AimSticky then
                    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, hrp.Position), Config.AimSmooth)
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
    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, hrp.Position), Config.AimSmooth)
end)

local AimSec = CombatTab:Section({ Title = "Aim", Opened = true })
AimSec:Slider({ Title = "Aim FOV", Flag = "AimFOV", Value = { Min = 50, Max = 500, Default = Config.AimFOV }, Step = 10, Callback = function(v) Config.AimFOV = v end })
AimSec:Slider({ Title = "Aim Smooth", Flag = "AimSmooth", Value = { Min = 5, Max = 100, Default = math.floor(Config.AimSmooth * 100) }, Step = 5, Callback = function(v) Config.AimSmooth = v / 100 end })
AimSec:Toggle({ Title = "Aim (hold key)", Flag = "AimEnabled", Value = false, Callback = function(s)
    State.Aim = s
    aimStickyTarget = nil
    notify("Aim", s and "ON" or "OFF", 2)
end })

local KnifeSec = CombatTab:Section({ Title = "Auto-Knife" })
KnifeSec:Slider({ Title = "Knife Range", Flag = "KnifeRange", Value = { Min = 5, Max = 15, Default = Config.KnifeRange }, Step = 1, Callback = function(v) Config.KnifeRange = v end })
KnifeSec:Slider({ Title = "Knife Cooldown", Flag = "KnifeCD", Value = { Min = 40, Max = 150, Default = math.floor(Config.KnifeCooldown * 100) }, Step = 5, Callback = function(v) Config.KnifeCooldown = v / 100 end })

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
        if tool:IsA("Tool") and tool.Name == "Knife" then knife = tool; break end
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
        if dist < closestDist then closestDist = dist; closest = p end
    end
    if closest then
        local hrp = closest.Character.HumanoidRootPart
        myHRP.CFrame = CFrame.new(myHRP.Position, Vector3.new(hrp.Position.X, myHRP.Position.Y, hrp.Position.Z))
        pcall(function() knife:Activate() end)
        lastKnifeTime = tick()
    end
end)

KnifeSec:Toggle({ Title = "Auto-Knife", Flag = "AutoKnifeEnabled", Value = false, Callback = function(s)
    State.AutoKnife = s
    notify("Auto-Knife", s and "ON" or "OFF", 2)
end })

local function getAlivePlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then table.insert(list, p.Name) end
        end
    end
    return list
end

local selectedPlayer = nil

local function stopFling()
    State.FlingActive = false
    if State.FlingThread then
        pcall(function() task.cancel(State.FlingThread) end)
        State.FlingThread = nil
    end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    local myHRP = char and char:FindFirstChild("HumanoidRootPart")
    if myHRP then
        if myHRP:FindFirstChild("FoxFlingSpinBV") then myHRP.FoxFlingSpinBV:Destroy() end
        if myHRP:FindFirstChild("FoxFlingSpinBG") then myHRP.FoxFlingSpinBG:Destroy() end
        myHRP.Anchored = false
    end
    if State.FlingTarget and State.FlingTarget.Character then
        local tHRP = State.FlingTarget.Character:FindFirstChild("HumanoidRootPart")
        if tHRP then
            if tHRP:FindFirstChild("FoxFlingTargetBV") then tHRP.FoxFlingTargetBV:Destroy() end
            if tHRP:FindFirstChild("FoxFlingTargetBG") then tHRP.FoxFlingTargetBG:Destroy() end
        end
    end
    State.FlingTarget = nil
end

local function startFling()
    if State.FlingActive then return end
    if not selectedPlayer then
        notify("Фтап", "Сначала выбери игрока", 2)
        return
    end
    local target = Players:FindFirstChild(selectedPlayer)
    if not target or not target.Character then
        notify("Фтап", "Игрок не найден / мёртв", 2)
        return
    end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then
        notify("Фтап", "У игрока нет HRP", 2)
        return
    end

    State.FlingActive = true
    State.FlingTarget = target

    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP then
        notify("Фтап", "У тебя нет HRP", 2)
        State.FlingActive = false
        return
    end

    if myHum then myHum.PlatformStand = true end

    myHRP.CFrame = targetHRP.CFrame

    local spinBV = Instance.new("BodyVelocity")
    spinBV.Name = "FoxFlingSpinBV"
    spinBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    spinBV.Velocity = Vector3.zero
    spinBV.Parent = myHRP

    local spinBG = Instance.new("BodyGyro")
    spinBG.Name = "FoxFlingSpinBG"
    spinBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    spinBG.P = 9e4
    spinBG.Parent = myHRP

    State.FlingThread = task.spawn(function()
        local angle = 0
        while State.FlingActive do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then break end
            if not target or not target.Character then
                notify("Фтап", "Цель пропала", 2)
                break
            end
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if not tHRP or not tHRP.Parent then
                notify("Фтап", "Цель мертва", 2)
                break
            end

            angle = angle + math.rad(Config.SpinSpeed)
            hrp.CFrame = CFrame.new(tHRP.Position) * CFrame.Angles(0, angle, 0)
            spinBV.Velocity = Vector3.zero
            spinBG.CFrame = hrp.CFrame

            task.wait()
        end
        if spinBV then spinBV:Destroy() end
        if spinBG then spinBG:Destroy() end
        if myHum then myHum.PlatformStand = false end
        State.FlingActive = false
        State.FlingTarget = nil
    end)

    task.spawn(function()
        while State.FlingActive do
            if not target or not target.Character then break end
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if not tHRP then break end
            local bv = tHRP:FindFirstChild("FoxFlingTargetBV") or Instance.new("BodyVelocity", tHRP)
            bv.Name = "FoxFlingTargetBV"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(
                math.random(-Config.FlingPower, Config.FlingPower),
                Config.FlingUp,
                math.random(-Config.FlingPower, Config.FlingPower)
            )
            local bg = tHRP:FindFirstChild("FoxFlingTargetBG") or Instance.new("BodyAngularVelocity", tHRP)
            bg.Name = "FoxFlingTargetBG"
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.AngularVelocity = Vector3.new(
                math.random(-Config.FlingSpin, Config.FlingSpin),
                math.random(-Config.FlingSpin, Config.FlingSpin),
                math.random(-Config.FlingSpin, Config.FlingSpin)
            )
            task.wait(0.25)
        end
        if target and target.Character then
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                if tHRP:FindFirstChild("FoxFlingTargetBV") then tHRP.FoxFlingTargetBV:Destroy() end
                if tHRP:FindFirstChild("FoxFlingTargetBG") then tHRP.FoxFlingTargetBG:Destroy() end
            end
        end
    end)
end

local function isMyPart(part)
    local char = LP.Character
    return char ~= nil and part:IsDescendantOf(char)
end

local function stopBlackHole()
    Config.BlackHoleActive = false
    for _, t in ipairs(Config.BlackHoleTasks) do pcall(function() task.cancel(t) end) end
    Config.BlackHoleTasks = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "FoxBlackHoleBV" then obj:Destroy() end
        if obj.Name == "FoxBlackHoleAntiGrav" then obj:Destroy() end
    end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function startBlackHole()
    if Config.BlackHoleActive then return end
    Config.BlackHoleActive = true

    local selfHum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if selfHum then selfHum.PlatformStand = true end

    task.spawn(function()
        while Config.BlackHoleActive do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local targets = {}
                if Config.BlackHoleMode == "Все" or Config.BlackHoleMode == "Только пропы" then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and not obj.Anchored then
                            if obj ~= hrp and not isMyPart(obj) then
                                local isChar = false
                                for _, p in ipairs(Players:GetPlayers()) do
                                    if p.Character and obj:IsDescendantOf(p.Character) then isChar = true; break end
                                end
                                if not isChar and not obj:FindFirstChild("FoxBlackHoleBV") then
                                    if (obj.Position - hrp.Position).Magnitude <= Config.BlackHoleRange then
                                        table.insert(targets, obj)
                                    end
                                end
                            end
                        end
                    end
                end
                if Config.BlackHoleMode == "Все" or Config.BlackHoleMode == "Только игроки" then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and p.Character then
                            local hrp2 = p.Character:FindFirstChild("HumanoidRootPart")
                            if hrp2 and not hrp2:FindFirstChild("FoxBlackHoleBV") and hrp2 ~= hrp and not isMyPart(hrp2) then
                                if (hrp2.Position - hrp.Position).Magnitude <= Config.BlackHoleRange then
                                    table.insert(targets, hrp2)
                                end
                            end
                        end
                    end
                end
                for _, part in ipairs(targets) do
                    if part ~= hrp and not isMyPart(part) and part.Parent then
                        local mass = part:FindFirstChild("FoxBlackHoleAntiGrav") or Instance.new("BodyForce", part)
                        mass.Name = "FoxBlackHoleAntiGrav"
                        mass.Force = Vector3.new(0, part:GetMass() * workspace.Gravity, 0)
                        local bv = part:FindFirstChild("FoxBlackHoleBV") or Instance.new("BodyVelocity", part)
                        bv.Name = "FoxBlackHoleBV"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        local offset = math.random() * math.pi * 2
                        local th = task.spawn(function()
                            while Config.BlackHoleActive and part.Parent do
                                if not hrp.Parent then break end
                                if isMyPart(part) then break end
                                local a = (tick() * Config.BlackHoleSpeed) + offset
                                local pos = hrp.Position + Vector3.new(
                                    math.cos(a) * Config.BlackHoleRadius,
                                    math.random(3, 15),
                                    math.sin(a) * Config.BlackHoleRadius
                                )
                                local delta = pos - part.Position
                                if delta.Magnitude > 0.01 then bv.Velocity = delta.Unit * 80 end
                                task.wait()
                            end
                            if bv then bv:Destroy() end
                            if mass then mass:Destroy() end
                        end)
                        table.insert(Config.BlackHoleTasks, th)
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

local function stopRam()
    Config.RamActive = false
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if hrp:FindFirstChild("FoxRamBV") then hrp.FoxRamBV:Destroy() end
        if hrp:FindFirstChild("FoxRamBG") then hrp.FoxRamBG:Destroy() end
    end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function startRam()
    if Config.RamActive then return end
    Config.RamActive = true
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp then Config.RamActive = false; return end
    if hum then hum.PlatformStand = true end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "FoxRamBV"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "FoxRamBG"
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 9e4
    bg.Parent = hrp

    task.spawn(function()
        while Config.RamActive do
            local c = LP.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            if not h or not h.Parent then break end
            local cam = workspace.CurrentCamera
            bg.CFrame = cam.CFrame
            bv.Velocity = cam.CFrame.LookVector * Config.RamSpeed
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    if tHRP and (tHRP.Position - h.Position).Magnitude <= Config.RamKillRange then
                        local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                        if tHum then pcall(function() tHum.Health = 0 end) end
                    end
                end
            end
            task.wait()
        end
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        local c = LP.Character
        local h2 = c and c:FindFirstChildOfClass("Humanoid")
        if h2 then h2.PlatformStand = false end
    end)
end

local FlingSelectSec = FapTab:Section({ Title = "Выбор игрока", Opened = true })
local playerDropdown = FlingSelectSec:Dropdown({
    Title = "Игрок",
    Flag = "FlingTarget",
    Values = getAlivePlayers(),
    Value = nil,
    Callback = function(v) selectedPlayer = v end
})

FlingSelectSec:Button({ Title = "Обновить список", Icon = "refresh-cw", Callback = function()
    local list = getAlivePlayers()
    playerDropdown:Refresh(list)
    notify("Фтап", "Список обновлён (" .. #list .. ")", 2)
end })

local FlingSetSec = FapTab:Section({ Title = "Настройки флинга", Opened = true })
FlingSetSec:Slider({ Title = "Мощность швырка", Flag = "FlingPower", Value = { Min = 100, Max = 3000, Default = Config.FlingPower }, Step = 50, Callback = function(v) Config.FlingPower = v end })
FlingSetSec:Slider({ Title = "Подброс вверх", Flag = "FlingUp", Value = { Min = 100, Max = 2000, Default = Config.FlingUp }, Step = 50, Callback = function(v) Config.FlingUp = v end })
FlingSetSec:Slider({ Title = "Вращение цели", Flag = "FlingSpin", Value = { Min = 5, Max = 100, Default = Config.FlingSpin }, Step = 5, Callback = function(v) Config.FlingSpin = v end })
FlingSetSec:Slider({ Title = "Скорость твоего вращения", Flag = "SpinSpeed", Value = { Min = 5, Max = 200, Default = Config.SpinSpeed }, Step = 5, Callback = function(v) Config.SpinSpeed = v end })

FapTab:Section({ Title = "Действие" }):Toggle({
    Title = "Флинг (тп в игрока + кручение + швырок)",
    Flag = "FlingEnabled",
    Value = false,
    Callback = function(s)
        if s then startFling() else stopFling() end
        notify("Фтап", s and "ON" or "OFF", 2)
    end
})

local BlackHoleSetSec = FapTab:Section({ Title = "Чёрная дыра", Opened = true })
BlackHoleSetSec:Dropdown({ Title = "Режим", Flag = "BlackHoleMode", Values = {"Все", "Только игроки", "Только пропы"}, Value = "Все", Callback = function(v) Config.BlackHoleMode = v end })
BlackHoleSetSec:Slider({ Title = "Радиус вращения", Flag = "BlackHoleRadius", Value = { Min = 5, Max = 50, Default = Config.BlackHoleRadius }, Step = 1, Callback = function(v) Config.BlackHoleRadius = v end })
BlackHoleSetSec:Slider({ Title = "Скорость", Flag = "BlackHoleSpeed", Value = { Min = 10, Max = 100, Default = Config.BlackHoleSpeed }, Step = 5, Callback = function(v) Config.BlackHoleSpeed = v end })
BlackHoleSetSec:Slider({ Title = "Радиус сбора", Flag = "BlackHoleRange", Value = { Min = 10, Max = 100, Default = Config.BlackHoleRange }, Step = 5, Callback = function(v) Config.BlackHoleRange = v end })

FapTab:Section({ Title = "Чёрная дыра" }):Toggle({
    Title = "Включить Чёрную дыру",
    Flag = "BlackHoleActive",
    Value = false,
    Callback = function(state)
        if state then startBlackHole() else stopBlackHole() end
    end,
})

local RamSetSec = FapTab:Section({ Title = "Влёт в чела (сдох)", Opened = true })
RamSetSec:Slider({ Title = "Скорость влёта", Flag = "RamSpeed", Value = { Min = 50, Max = 500, Default = Config.RamSpeed }, Step = 10, Callback = function(v) Config.RamSpeed = v end })
RamSetSec:Slider({ Title = "Радиус убийства", Flag = "RamKillRange", Value = { Min = 2, Max = 20, Default = Config.RamKillRange }, Step = 1, Callback = function(v) Config.RamKillRange = v end })

FapTab:Section({ Title = "Влёт в чела" }):Toggle({
    Title = "Влёт в чела (быстрый + сдох)",
    Flag = "RamActive",
    Value = false,
    Callback = function(s)
        if s then startRam() else stopRam() end
        notify("Влёт", s and "ON" or "OFF", 2)
    end
})

local SettingsKeySec = SettingsTab:Section({ Title = "Keybinds", Opened = true })
SettingsKeySec:Button({ Title = "Клавиша меню: " .. Config.MenuKey.Name, Icon = "keyboard", Callback = function()
    notify("Keybind", "Нажми клавишу для меню...", 3)
    local conn
    conn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Config.MenuKey = input.KeyCode
            saveSettings()
            notify("Keybind", "Меню → " .. input.KeyCode.Name, 2)
            conn:Disconnect()
        end
    end)
end })
SettingsKeySec:Button({ Title = "Клавиша Aim: " .. Config.AimKey.Name, Icon = "crosshairs", Callback = function()
    notify("Keybind", "Нажми клавишу для Aim...", 3)
    local conn
    conn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Config.AimKey = input.KeyCode
            saveSettings()
            notify("Keybind", "Aim → " .. input.KeyCode.Name, 2)
            conn:Disconnect()
        end
    end)
end })
SettingsKeySec:Button({ Title = "Клавиша Auto-Knife: " .. Config.KnifeKey.Name, Icon = "utensils", Callback = function()
    notify("Keybind", "Нажми клавишу для Auto-Knife...", 3)
    local conn
    conn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Config.KnifeKey = input.KeyCode
            saveSettings()
            notify("Keybind", "Auto-Knife → " .. input.KeyCode.Name, 2)
            conn:Disconnect()
        end
    end)
end })

local SettingsMiscSec = SettingsTab:Section({ Title = "Misc" })
SettingsMiscSec:Slider({ Title = "Прозрачность меню %", Flag = "Transparency", Value = { Min = 0, Max = 80, Default = math.floor(Config.Transparency * 100) }, Step = 5, Callback = function(v)
    Config.Transparency = v / 100
end })
SettingsMiscSec:Dropdown({ Title = "Цвет акцента", Flag = "AccentIndex", Values = (function()
    local t = {}
    for _, c in ipairs(ACCENT_COLORS) do table.insert(t, c.name) end
    return t
end)(), Value = ACCENT_COLORS[Config.AccentIndex or 1].name, Callback = function(v)
    for i, c in ipairs(ACCENT_COLORS) do
        if c.name == v then Config.AccentIndex = i; break end
    end
    notify("Accent", v, 2)
end })
SettingsMiscSec:Button({ Title = "Сбросить настройки", Icon = "rotate-ccw", Callback = function()
    pcall(function() delfile(SAVE_KEY .. ".json") end)
    notify("Settings", "Сброшено. Перезапусти скрипт.", 4)
end })

SettingsTab:Section({ Title = "Actions" }):Button({ Title = "Unload", Icon = "x", Callback = function()
    stopFly()
    stopFling()
    stopBlackHole()
    stopRam()
    if State.Noclip then stopNoclip() end
    espFolder:Destroy()
    Window:Destroy()
end })

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Config.MenuKey then
        Window:Toggle()
    end
    if inp.KeyCode == Config.AimKey then
        State.AimKeyHeld = true
    end
    if inp.KeyCode == Config.KnifeKey then
        State.AutoKnife = not State.AutoKnife
        notify("Auto-Knife", State.AutoKnife and "ON" or "OFF", 2)
    end
end)

UIS.InputEnded:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Config.AimKey then
        State.AimKeyHeld = false
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.7)
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    if State.Speed then hum.WalkSpeed = Config.Speed end
    if State.Jump then hum.UseJumpPower = true; hum.JumpPower = Config.Jump end
    if State.Fly then startFly() end
    if State.ESP then task.wait(0.3); refreshESP() end
    if State.Noclip then noclipSaved = {}; if not noclipConn then startNoclip() end end
end)

WindUI:Notify({Title = "MONOLITH", Content = "Loaded" .. (SavedData and " (settings restored)" or ""), Icon = "wind", Duration = 5})
