local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local GrabEvents, CharacterEvents, SetNetworkOwner, Struggle, StopAllVelocity, RagdollRemote
pcall(function()
    GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents", 10)
    CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents", 10)
    if GrabEvents then SetNetworkOwner = GrabEvents:WaitForChild("SetNetworkOwner", 10) end
    if CharacterEvents then
        Struggle = CharacterEvents:WaitForChild("Struggle", 10)
        RagdollRemote = CharacterEvents:WaitForChild("RagdollRemote", 10)
    end
    local GameCorrectionEvents = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
    if GameCorrectionEvents then
        StopAllVelocity = GameCorrectionEvents:FindFirstChild("StopAllVelocity")
    end
end)

local SkyPresets = {
    ["Default"] = {Up = "rbxassetid://15983964246", Dn = "rbxassetid://15983966825", Ft = "rbxassetid://5260817288", Bk = "rbxassetid://15983968922", Lf = "rbxassetid://15983967420", Rt = "rbxassetid://15983966246"},
    ["Vaporwave"] = {Up = "rbxassetid://14164405298", Dn = "rbxassetid://14164386126", Ft = "rbxassetid://14164389230", Bk = "rbxassetid://14164368678", Lf = "rbxassetid://14164398493", Rt = "rbxassetid://14164402782"},
    ["Galaxy"] = {Up = "rbxassetid://14543371676", Dn = "rbxassetid://14543358958", Ft = "rbxassetid://14543257810", Bk = "rbxassetid://14543264135", Lf = "rbxassetid://14543275895", Rt = "rbxassetid://14543280890"},
    ["Storm"] = {Up = "rbxassetid://1618913654", Dn = "rbxassetid://1618913943", Ft = "rbxassetid://1618913244", Bk = "rbxassetid://1618912481", Lf = "rbxassetid://1618912849", Rt = "rbxassetid://1618911568"}
}

local Config = {
    GrabRange = 30, ThrowPower = 300,
    FlyEnabled = false, FlySpeed = 60,
    SpeedEnabled = false, SpeedValue = 40,
    NoclipEnabled = false, InfJumpEnabled = false,
    ESPEnabled = false,
    FullbrightEnabled = false,
    AntiGrabEnabled = false, AntiKickGrabEnabled = false, AntiExplosionEnabled = false,
    SelfDefenseEnabled = false,
    StrengthEnabled = false,
    ThirdPersonEnabled = false,
    AntiAFKEnabled = false,
    MenuKey = Enum.KeyCode.RightControl,
    Language = "RU",
}

local State = {
    GrabbedTarget = nil, GrabConstraints = {},
    StrengthConnection = nil, AntiGrabConnection = nil, AntiKickGrabConnection = nil,
    AntiExplosionConnection = nil, AntiExplosionCharConn = nil, SelfDefenseCoroutine = nil,
    LastGrab = 0, oldCameraOffset = nil, IsListeningForBind = false,
    AFKConnection = nil, SkyObject = nil, Shaders = nil,
    OriginalBrightness = Lighting.Brightness,
    OriginalAmbient = Lighting.Ambient,
    OriginalOutdoorAmbient = Lighting.OutdoorAmbient,
    OriginalFogEnd = Lighting.FogEnd,
}

local Lang = {
    RU = { Title="MONOLITH", Grab="Захват", Defense="Защита", Movement="Движение", Visuals="Визуал", Misc="Разное", Speed="Скорость", Fly="Полет", Noclip="Ноклип", InfJump="Беск. прыжок", ESP="ESP", Fullbright="Полная яркость", ThirdPerson="Вид от 3-го лица", AntiGrab="Анти-Захват", AntiKick="Анти-Кик", AntiExplosion="Анти-Взрыв", AntiFling="Анти-Флинг", SelfDefense="Самооборона", Strength="Супер-бросок", GrabRange="Дистанция захвата", ThrowPower="Сила броска", FlySpeed="Скорость полета", SpeedVal="Скорость", Rejoin="Перезайти", ServerHop="Сменить сервер", AntiAFK="Анти-АФК", SetKey="Назначить клавишу", Skybox="Скайбокс", Shaders="Шейдеры", FlingAll="Швырнуть всех", Language="Язык" },
    EN = { Title="MONOLITH", Grab="Grab", Defense="Defense", Movement="Movement", Visuals="Visuals", Misc="Misc", Speed="Speed", Fly="Fly", Noclip="Noclip", InfJump="Inf Jump", ESP="ESP", Fullbright="Fullbright", ThirdPerson="3rd Person", AntiGrab="Anti-Grab", AntiKick="Anti-Kick", AntiExplosion="Anti-Explosion", AntiFling="Anti-Fling", SelfDefense="Self Defense", Strength="Strength", GrabRange="Grab Range", ThrowPower="Throw Power", FlySpeed="Fly Speed", SpeedVal="Speed", Rejoin="Rejoin", ServerHop="Server Hop", AntiAFK="Anti-AFK", SetKey="Set Menu Key", Skybox="Skybox", Shaders="Shaders", FlingAll="Fling All", Language="Language" },
    UA = { Title="MONOLITH", Grab="Захват", Defense="Захист", Movement="Рух", Visuals="Візуал", Misc="Різне", Speed="Швидкість", Fly="Політ", Noclip="Нокліп", InfJump="Безк. стрибок", ESP="ESP", Fullbright="Повна яскравість", ThirdPerson="Вигляд від 3-ї особи", AntiGrab="Анти-Захват", AntiKick="Анти-Кік", AntiExplosion="Анти-Вибух", AntiFling="Анти-Флінг", SelfDefense="Самозахист", Strength="Супер-кидок", GrabRange="Дистанція захвату", ThrowPower="Сила кидка", FlySpeed="Швидкість польоту", SpeedVal="Швидкість", Rejoin="Перезайти", ServerHop="Змінити сервер", AntiAFK="Анти-АФК", SetKey="Призначити клавішу", Skybox="Скайбокс", Shaders="Шейдери", FlingAll="Жбурнути всіх", Language="Мова" }
}

local function T(key) return Lang[Config.Language][key] or key end
local function getChar() local c = LP.Character if not c or not c.Parent then return nil end return c end
local function getHRP() local c = getChar() if not c then return nil end return c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p) if not p then return false end local c = p.Character if not c or not c.Parent then return false end local h = c:FindFirstChildOfClass("Humanoid") return h and h.Health > 0 end

local function findClosestTarget(maxDist)
    maxDist = maxDist or math.huge
    local myHRP = getHRP() if not myHRP then return nil end
    local best, bestDist = nil, maxDist
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestDist then bestDist = d; best = {hrp = hrp, hum = p.Character:FindFirstChildOfClass("Humanoid"), player = p, char = p.Character} end
            end
        end
    end
    return best
end

-- Логика (Fly, Speed, Anti, Skybox, Shaders)
local function setFly(enabled)
    Config.FlyEnabled = enabled
    local hrp = getHRP() local hum = getHum()
    if not hrp then return end
    if enabled then
        local bv = Instance.new("BodyVelocity", hrp); bv.Name = "Monolith_FlyBV"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.zero
        local bg = Instance.new("BodyGyro", hrp); bg.Name = "Monolith_FlyBG"; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.P = 9e4
        if hum then hum.PlatformStand = true end
        RunService:BindToRenderStep("Monolith_Fly", Enum.RenderPriority.Camera.Value, function()
            if not Config.FlyEnabled then return end
            local h = getHRP() if not h then return end
            local b = h:FindFirstChild("Monolith_FlyBV") local g = h:FindFirstChild("Monolith_FlyBG")
            if not b or not g then return end
            g.CFrame = Camera.CFrame
            local m = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then m += Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then m -= Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then m -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then m += Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then m += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then m -= Vector3.yAxis end
            b.Velocity = m.Magnitude > 0 and m.Unit * Config.FlySpeed or Vector3.zero
        end)
    else
        RunService:UnbindFromRenderStep("Monolith_Fly")
        if hrp then
            if hrp:FindFirstChild("Monolith_FlyBV") then hrp.Monolith_FlyBV:Destroy() end
            if hrp:FindFirstChild("Monolith_FlyBG") then hrp.Monolith_FlyBG:Destroy() end
        end
        if hum then hum.PlatformStand = false end
    end
end

local function setSpeed(enabled, value)
    Config.SpeedEnabled = enabled
    if value then Config.SpeedValue = value end
    local hum = getHum()
    if hum then hum.WalkSpeed = enabled and Config.SpeedValue or 16 end
end

local function FlingAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bv = Instance.new("BodyVelocity"); bv.Velocity = Vector3.new(math.random(-500, 500), 500, math.random(-500, 500)); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.Parent = hrp
                Debris:AddItem(bv, 0.5)
            end
        end
    end
    WindUI:Notify({Title="MONOLITH", Content="Fling All Executed!", Icon="wind"})
end

local function setSkybox(presetName)
    if State.SkyObject then State.SkyObject:Destroy() end
    local preset = SkyPresets[presetName]
    if not preset then return end
    local sky = Instance.new("Sky")
    sky.SkyboxUp = preset.Up; sky.SkyboxDn = preset.Dn; sky.SkyboxFt = preset.Ft; sky.SkyboxBk = preset.Bk; sky.SkyboxLf = preset.Lf; sky.SkyboxRt = preset.Rt
    sky.Parent = Lighting
    State.SkyObject = sky
end

local function toggleShaders(enabled)
    if enabled then
        if not State.Shaders then
            State.Shaders = {}
            local bloom = Instance.new("BloomEffect", Lighting); bloom.Intensity = 0.5; bloom.Size = 24; table.insert(State.Shaders, bloom)
            local color = Instance.new("ColorCorrectionEffect", Lighting); color.Saturation = 0.2; color.Contrast = 0.1; table.insert(State.Shaders, color)
        end
    else
        if State.Shaders then for _, v in ipairs(State.Shaders) do v:Destroy() end; State.Shaders = nil end
    end
end

local function toggleFullbright(enabled)
    Config.FullbrightEnabled = enabled
    if enabled then
        Lighting.Brightness = 3; Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.FogEnd = 1e6; Lighting.GlobalShadows = false
    else
        Lighting.Brightness = State.OriginalBrightness; Lighting.Ambient = State.OriginalAmbient; Lighting.OutdoorAmbient = State.OriginalOutdoorAmbient; Lighting.FogEnd = State.OriginalFogEnd; Lighting.GlobalShadows = true
    end
end

-- ============================================
-- АВТОСОХРАНЕНИЕ (WindUI ConfigManager)
-- ============================================
local Window = WindUI:CreateWindow({
    Title = T("Title"), Author = "1gor3k", Folder = "MonolithConfig",
    Size = UDim2.fromOffset(560, 520), Theme = "Dark", Resizable = true, SideBarWidth = 160,
    HideSearchBar = false, NewElements = true, ScrollBarEnabled = true, Acrylic = false,
    OpenButton = { Title = "M", Enabled = true, Draggable = true, CornerRadius = UDim.new(1, 0), Color = ColorSequence.new(Color3.fromHex("#00FFAA"), Color3.fromHex("#00AAFF")), OnlyMobile = false },
})

-- Создаем конфиг, который будет автосохраняться
local MyConfig = Window.ConfigManager:CreateConfig("AutoSave", true)

local GrabTab = Window:Tab({ Title = T("Grab"), Icon = "hand" })
local DefTab = Window:Tab({ Title = T("Defense"), Icon = "shield" })
local MoveTab = Window:Tab({ Title = T("Movement"), Icon = "person-running" })
local VisTab = Window:Tab({ Title = T("Visuals"), Icon = "eye" })
local MiscTab = Window:Tab({ Title = T("Misc"), Icon = "gear" })

-- Grab
local GrabSec = GrabTab:Section({ Title = T("Grab"), Opened = true })
GrabSec:Slider({ Title = T("GrabRange"), Flag = "GrabRange", Value = { Min = 10, Max = 100, Default = 30 }, Step = 1, Callback = function(v) Config.GrabRange = v end })
GrabSec:Slider({ Title = T("ThrowPower"), Flag = "ThrowPower", Value = { Min = 100, Max = 10000, Default = 300 }, Step = 100, Callback = function(v) Config.ThrowPower = v end })
GrabSec:Button({ Title = T("Grab") .. " (Q)", Icon = "hand", Callback = function() local t = findClosestTarget(Config.GrabRange) if t then grabTarget(t) end end })
GrabSec:Button({ Title = "Release (E)", Icon = "arrow-up-from-line", Callback = function() releaseGrab() end })
GrabTab:Section({ Title = T("Strength") }):Toggle({ Title = T("Strength"), Flag = "StrengthEnabled", Value = false, Callback = setStrength })

-- Defense
local DefProtSec = DefTab:Section({ Title = T("Defense"), Opened = true })
DefProtSec:Toggle({ Title = T("AntiGrab"), Flag = "AntiGrabEnabled", Value = false, Callback = function(s) setAntiGrab(s) end })
DefProtSec:Toggle({ Title = T("AntiKick"), Flag = "AntiKickGrabEnabled", Value = false, Callback = function(s) setAntiKickGrab(s) end })
DefProtSec:Toggle({ Title = T("AntiExplosion"), Flag = "AntiExplosionEnabled", Value = false, Callback = setAntiExplosion })
DefProtSec:Toggle({ Title = T("AntiFling"), Flag = "AntiFlingEnabled", Value = false, Callback = function(s) Config.AntiFlingEnabled = s end })
DefTab:Section({ Title = T("SelfDefense") }):Toggle({ Title = T("SelfDefense"), Flag = "SelfDefenseEnabled", Value = false, Callback = function(s) setSelfDefense(s) end })

-- Movement
local MoveSpeedSec = MoveTab:Section({ Title = T("Speed"), Opened = true })
MoveSpeedSec:Toggle({ Title = T("Speed"), Flag = "SpeedEnabled", Value = false, Callback = function(s) setSpeed(s, Config.SpeedValue) end })
MoveSpeedSec:Slider({ Title = T("SpeedVal"), Flag = "SpeedValue", Value = { Min = 16, Max = 150, Default = 40 }, Step = 1, Callback = function(v) Config.SpeedValue = v; if Config.SpeedEnabled then setSpeed(true, v) end end })
local MoveFlySec = MoveTab:Section({ Title = T("Fly") })
MoveFlySec:Toggle({ Title = T("Fly"), Flag = "FlyEnabled", Value = false, Callback = function(s) setFly(s) end })
MoveFlySec:Slider({ Title = T("FlySpeed"), Flag = "FlySpeed", Value = { Min = 10, Max = 200, Default = 60 }, Step = 1, Callback = function(v) Config.FlySpeed = v end })
local MoveMiscSec = MoveTab:Section({ Title = T("Misc") })
MoveMiscSec:Toggle({ Title = T("Noclip"), Flag = "NoclipEnabled", Value = false, Callback = function(s) Config.NoclipEnabled = s end })
MoveMiscSec:Toggle({ Title = T("InfJump"), Flag = "InfJumpEnabled", Value = false, Callback = function(s) Config.InfJumpEnabled = s end })

-- Visuals
local VisCamSec = VisTab:Section({ Title = T("Visuals"), Opened = true })
VisCamSec:Toggle({ Title = T("ThirdPerson"), Flag = "ThirdPersonEnabled", Value = false, Callback = function(state)
    Config.ThirdPersonEnabled = state
    if state then
        if not State.oldCameraOffset then State.oldCameraOffset = { Max = LP.CameraMaxZoomDistance, Min = LP.CameraMinZoomDistance, Mode = LP.CameraMode } end
        LP.CameraMaxZoomDistance = 15; LP.CameraMinZoomDistance = 8; LP.CameraMode = Enum.CameraMode.Classic
    else
        if State.oldCameraOffset then LP.CameraMaxZoomDistance = State.oldCameraOffset.Max; LP.CameraMinZoomDistance = State.oldCameraOffset.Min; LP.CameraMode = State.oldCameraOffset.Mode; State.oldCameraOffset = nil end
    end
end })
local VisSkySec = VisTab:Section({ Title = T("Skybox") })
VisSkySec:Dropdown({ Title = T("Skybox"), Flag = "Skybox", Values = {"Default", "Vaporwave", "Galaxy", "Storm"}, Value = "Default", Callback = function(v) setSkybox(v) end })
VisSkySec:Toggle({ Title = T("Shaders"), Flag = "ShadersEnabled", Value = false, Callback = function(s) toggleShaders(s) end })
VisTab:Section({ Title = T("ESP") }):Toggle({ Title = T("ESP"), Flag = "ESPEnabled", Value = false, Callback = function(s) Config.ESPEnabled = s; if s then _G.RefreshESP() else _G.ClearESP() end end })
VisTab:Section({ Title = T("Fullbright") }):Toggle({ Title = T("Fullbright"), Flag = "FullbrightEnabled", Value = false, Callback = toggleFullbright })

-- Misc
local MiscActionsSec = MiscTab:Section({ Title = T("Misc"), Opened = true })
MiscActionsSec:Button({ Title = T("Rejoin"), Icon = "rotate-cw", Callback = function() TeleportService:Teleport(game.PlaceId, LP) end })
MiscActionsSec:Button({ Title = T("ServerHop"), Icon = "shuffle", Callback = function()
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local res = game:HttpGet(url)
        for _, s in ipairs(HttpService:JSONDecode(res).data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP) return end
        end
    end)
end })
MiscActionsSec:Button({ Title = T("FlingAll"), Icon = "wind", Callback = FlingAll })
MiscTab:Section({ Title = T("AntiAFK") }):Toggle({ Title = T("AntiAFK"), Flag = "AntiAFKEnabled", Value = false, Callback = function(s)
    Config.AntiAFKEnabled = s
    if s then State.AFKConnection = LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    else if State.AFKConnection then State.AFKConnection:Disconnect(); State.AFKConnection = nil end end
end })

local MiscSettingsSec = MiscTab:Section({ Title = "Settings" })
MiscSettingsSec:Dropdown({
    Title = T("Language"), Flag = "Language",
    Values = {"Русский", "English", "Українська"}, Value = "Русский",
    Callback = function(v)
        if v == "Русский" then Config.Language = "RU"
        elseif v == "English" then Config.Language = "EN"
        elseif v == "Українська" then Config.Language = "UA" end
        WindUI:Notify({Title="MONOLITH", Content="Перезапусти скрипт для применения языка.", Icon="info", Duration=5})
    end,
})

MiscSettingsSec:Button({ 
    Title = T("SetKey") .. ": " .. Config.MenuKey.Name, Icon = "keyboard",
    Callback = function() 
        if State.IsListeningForBind then return end
        State.IsListeningForBind = true
        WindUI:Notify({Title="Keybind", Content="Нажми на любую клавишу...", Icon="info", Duration=3})
    end 
})

-- ESP
local espFolder = Instance.new("Folder", game:GetService("CoreGui"))
espFolder.Name = "Monolith_ESP"
_G.ClearESP = function() espFolder:ClearAllChildren() end
local function buildESP(p)
    if p == LP or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local bb = Instance.new("BillboardGui", espFolder); bb.Size = UDim2.new(0, 150, 0, 40); bb.StudsOffset = Vector3.new(0, 2.5, 0); bb.AlwaysOnTop = true; bb.Adornee = hrp; bb:SetAttribute("Owner", p.UserId)
    local nl = Instance.new("TextLabel", bb); nl.Name = "NameLbl"; nl.Size = UDim2.new(1, 0, 0, 20); nl.BackgroundTransparency = 1; nl.Text = p.Name; nl.TextColor3 = Color3.fromRGB(255, 255, 255); nl.Font = Enum.Font.GothamBold; nl.TextSize = 13; nl.TextStrokeTransparency = 0.3
    local hp = Instance.new("TextLabel", bb); hp.Name = "HPLbl"; hp.Size = UDim2.new(1, 0, 0, 16); hp.Position = UDim2.new(0, 0, 0, 18); hp.BackgroundTransparency = 1; hp.TextColor3 = Color3.fromRGB(255, 75, 75); hp.Font = Enum.Font.Gotham; hp.TextSize = 11; hp.TextStrokeTransparency = 0.3
end
_G.RefreshESP = function() espFolder:ClearAllChildren(); for _, p in ipairs(Players:GetPlayers()) do buildESP(p) end end

RunService.Heartbeat:Connect(function()
    if Config.SpeedEnabled then local hum = getHum(); if hum and hum.WalkSpeed ~= Config.SpeedValue then hum.WalkSpeed = Config.SpeedValue end end
    if Config.AntiFlingEnabled then local char = getChar(); if char then local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp and hrp.Velocity.Magnitude > 500 then hrp.Velocity = Vector3.zero end end end
    if Config.ESPEnabled then
        local myHRP = getHRP()
        for _, v in ipairs(espFolder:GetChildren()) do
            local uid = v:GetAttribute("Owner"); if not uid then continue end
            local p = Players:GetPlayerByUserId(uid); if not p or not p.Character then v:Destroy() continue end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local hum = p.Character:FindFirstChildOfClass("Humanoid"); if not hrp then v:Destroy() continue end
            v.Adornee = hrp
            if hum and myHRP then local hpLabel = v:FindFirstChild("HPLbl"); if hpLabel then hpLabel.Text = tostring(math.floor(hum.Health)) .. " HP" end end
        end
    end
end)

RunService.Stepped:Connect(function()
    if Config.NoclipEnabled then local char = getChar(); if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end
end)

UIS.JumpRequest:Connect(function()
    if Config.InfJumpEnabled then local hum = getHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if State.IsListeningForBind then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Config.MenuKey = input.KeyCode
            State.IsListeningForBind = false
            WindUI:Notify({Title="Keybind", Content="Клавиша меню изменена на: " .. Config.MenuKey.Name, Icon="check"})
        end
        return
    end
    if input.KeyCode == Config.MenuKey then Window:Toggle() end
    if input.KeyCode == Enum.KeyCode.Q then local t = findClosestTarget(Config.GrabRange) if t then grabTarget(t) end
    elseif input.KeyCode == Enum.KeyCode.E then releaseGrab() end
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.8)
    if Config.SpeedEnabled then setSpeed(true, Config.SpeedValue) end
    if Config.FlyEnabled then setFly(true) end
    if Config.ESPEnabled then _G.RefreshESP() end
    if Config.NoclipEnabled then Config.NoclipEnabled = true end
    if Config.AntiExplosionEnabled then setAntiExplosion(true) end
end)
