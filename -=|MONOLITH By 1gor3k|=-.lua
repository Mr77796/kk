local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
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
    MenuKey = Enum.KeyCode.RightControl,
}

local State = {
    GrabbedTarget = nil,
    GrabConstraints = {},
    StrengthConnection = nil,
    AntiGrabConnection = nil,
    AntiKickGrabConnection = nil,
    AntiExplosionConnection = nil,
    AntiExplosionCharConn = nil,
    SelfDefenseCoroutine = nil,
    LastGrab = 0,
    oldCameraOffset = nil,
    IsListeningForBind = false,
}

local function getChar() local c = LP.Character if not c or not c.Parent then return nil end return c end
local function getHRP() local c = getChar() if not c then return nil end return c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p)
    if not p then return false end
    local c = p.Character if not c or not c.Parent then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function findClosestTarget(maxDist)
    maxDist = maxDist or math.huge
    local myHRP = getHRP() if not myHRP then return nil end
    local best, bestDist = nil, maxDist
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestDist then 
                    bestDist = d
                    best = {hrp = hrp, hum = p.Character:FindFirstChildOfClass("Humanoid"), player = p, char = p.Character} 
                end
            end
        end
    end
    return best
end

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

local function setAntiGrab(enabled)
    Config.AntiGrabEnabled = enabled
    if State.AntiGrabConnection then State.AntiGrabConnection:Disconnect(); State.AntiGrabConnection = nil end
    if not enabled then return end

    State.AntiGrabConnection = RunService.Heartbeat:Connect(function()
        local character = LP.Character
        if not character then return end
        local head = character:FindFirstChild("Head")
        if not head then return end
        local partOwner = head:FindFirstChild("PartOwner")
        if not partOwner then return end

        pcall(function()
            if Struggle then Struggle:FireServer() end
            if StopAllVelocity then StopAllVelocity:FireServer() end
        end)

        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then part.Anchored = true end
        end

        task.spawn(function()
            local held = LP:FindFirstChild("IsHeld")
            if held then while held.Value do task.wait() end else task.wait(0.5) end
            local c = LP.Character
            if c then for _, part in ipairs(c:GetChildren()) do if part:IsA("BasePart") then part.Anchored = false end end end
        end)
    end)
end

local function setAntiKickGrab(enabled)
    Config.AntiKickGrabEnabled = enabled
    if State.AntiKickGrabConnection then State.AntiKickGrabConnection:Disconnect(); State.AntiKickGrabConnection = nil end
    if not enabled then return end

    State.AntiKickGrabConnection = RunService.Heartbeat:Connect(function()
        local hrp = getHRP() if not hrp then return end
        local firePart = hrp:FindFirstChild("FirePlayerPart")
        if firePart and firePart:FindFirstChild("PartOwner") and firePart.PartOwner.Value ~= LP.Name then
            pcall(function() if RagdollRemote then RagdollRemote:FireServer(hrp, 0) end end)
            task.wait(0.1)
            pcall(function() if Struggle then Struggle:FireServer() end end)
        end
    end)
end

local function setupAntiExplosion(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    local ragdolled = humanoid:FindFirstChild("Ragdolled")
    if not ragdolled then return end

    State.AntiExplosionConnection = ragdolled:GetPropertyChangedSignal("Value"):Connect(function()
        if not Config.AntiExplosionEnabled then return end
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then part.Anchored = ragdolled.Value end
        end
    end)
end

local function setAntiExplosion(enabled)
    Config.AntiExplosionEnabled = enabled
    if State.AntiExplosionConnection then State.AntiExplosionConnection:Disconnect(); State.AntiExplosionConnection = nil end
    if State.AntiExplosionCharConn then State.AntiExplosionCharConn:Disconnect(); State.AntiExplosionCharConn = nil end
    if not enabled then return end
    local char = LP.Character
    if char then setupAntiExplosion(char) end
    State.AntiExplosionCharConn = LP.CharacterAdded:Connect(setupAntiExplosion)
end

local function setSelfDefense(enabled)
    Config.SelfDefenseEnabled = enabled
    if State.SelfDefenseCoroutine then State.SelfDefenseCoroutine:Disconnect(); State.SelfDefenseCoroutine = nil end
    if not enabled then return end

    State.SelfDefenseCoroutine = RunService.Heartbeat:Connect(function()
        local character = LP.Character
        if not character then return end
        local head = character:FindFirstChild("Head")
        if not head then return end
        local partOwner = head:FindFirstChild("PartOwner")
        if not partOwner then return end

        local attacker = Players:FindFirstChild(partOwner.Value)
        if attacker and attacker.Character then
            pcall(function()
                if Struggle then Struggle:FireServer() end
                if SetNetworkOwner and attacker.Character.Head then
                    SetNetworkOwner:FireServer(attacker.Character.Head, attacker.Character.HumanoidRootPart.CFrame)
                end
            end)
            task.wait(0.1)
            local target = attacker.Character:FindFirstChild("Torso") or attacker.Character:FindFirstChild("UpperTorso")
            if target then
                local velocity = target:FindFirstChild("Monolith_Suspend") or Instance.new("BodyVelocity")
                velocity.Name = "Monolith_Suspend"; velocity.Parent = target
                velocity.Velocity = Vector3.new(0, 50, 0); velocity.MaxForce = Vector3.new(0, math.huge, 0)
                Debris:AddItem(velocity, 2)
            end
        end
    end)
end

local function setStrength(enabled)
    Config.StrengthEnabled = enabled
    if State.StrengthConnection then State.StrengthConnection:Disconnect(); State.StrengthConnection = nil end
    if not enabled then return end
    State.StrengthConnection = workspace.ChildAdded:Connect(function(model)
        if model.Name == "GrabParts" then
            local grabPart = model:FindFirstChild("GrabPart")
            if not grabPart then return end
            local weld = grabPart:FindFirstChild("WeldConstraint")
            if not weld or not weld.Part1 then return end
            local partToImpulse = weld.Part1
            local velocityObj = Instance.new("BodyVelocity", partToImpulse)
            velocityObj.MaxForce = Vector3.new(0, 0, 0); velocityObj.Velocity = Vector3.zero
            model:GetPropertyChangedSignal("Parent"):Connect(function()
                if not model.Parent then
                    if UIS:GetLastInputType() == Enum.UserInputType.MouseButton2 then
                        velocityObj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        velocityObj.Velocity = Camera.CFrame.LookVector * Config.ThrowPower
                    end
                    Debris:AddItem(velocityObj, 1)
                end
            end)
        end
    end)
end

local function grabTarget(target)
    if not target or not target.hrp then return end
    if tick() - State.LastGrab < 0.3 then return end
    State.LastGrab = tick()
    for _, c in pairs(State.GrabConstraints) do if c then c:Destroy() end end
    State.GrabConstraints = {}
    local myHRP = getHRP() if not myHRP then return end
    State.GrabbedTarget = target
    if SetNetworkOwner then pcall(function() SetNetworkOwner:FireServer(target.hrp, target.hrp.CFrame) end) end
    local bv = Instance.new("BodyVelocity", target.hrp)
    bv.Name = "Monolith_GrabBV"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.zero
    table.insert(State.GrabConstraints, bv)
end

local function releaseGrab()
    if not State.GrabbedTarget then return end
    local target = State.GrabbedTarget
    local targetHRP = target.hrp
    for _, c in pairs(State.GrabConstraints) do if c then c:Destroy() end end
    State.GrabConstraints = {}; State.GrabbedTarget = nil
    if not targetHRP or not targetHRP.Parent then return end
    local bv = Instance.new("BodyVelocity", targetHRP)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Camera.CFrame.LookVector * Config.ThrowPower + Vector3.new(0, Config.ThrowPower * 0.4, 0)
    Debris:AddItem(bv, 1)
end

local Window = WindUI:CreateWindow({
    Title = "MONOLITH",
    Author = "1gor3k",
    Folder = "MonolithConfig",
    Size = UDim2.fromOffset(560, 520),
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 160,
    HideSearchBar = false,
    NewElements = true,
    ScrollBarEnabled = true,
    Acrylic = false,
    OpenButton = {
        Title = "M", Enabled = true, Draggable = true, CornerRadius = UDim.new(1, 0),
        Color = ColorSequence.new(Color3.fromHex("#00FFAA"), Color3.fromHex("#00AAFF")), OnlyMobile = false,
    },
})

local GrabTab = Window:Tab({ Title = "Grab", Icon = "hand" })
local DefTab = Window:Tab({ Title = "Defense", Icon = "shield" })
local MoveTab = Window:Tab({ Title = "Movement", Icon = "person-running" })
local VisTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "gear" })

local GrabSec = GrabTab:Section({ Title = "Grab Settings", Opened = true })
GrabSec:Slider({ Title = "Grab Range", Value = { Min = 10, Max = 100, Default = 30 }, Step = 1, Callback = function(v) Config.GrabRange = v end })
GrabSec:Slider({ Title = "Throw Power", Value = { Min = 100, Max = 10000, Default = 300 }, Step = 100, Callback = function(v) Config.ThrowPower = v end })
GrabSec:Button({ Title = "Grab Closest (Q)", Icon = "hand", Callback = function() local t = findClosestTarget(Config.GrabRange) if t then grabTarget(t) WindUI:Notify({Title="MONOLITH", Content="Grabbed!", Icon="check"}) end end })
GrabSec:Button({ Title = "Release (E)", Icon = "arrow-up-from-line", Callback = function() releaseGrab() WindUI:Notify({Title="MONOLITH", Content="Released!", Icon="arrow-up"}) end })

GrabTab:Section({ Title = "Strength" }):Toggle({ Title = "Strength (RMB on throw)", Value = false, Callback = setStrength })

local DefProtSec = DefTab:Section({ Title = "Protection", Opened = true })
DefProtSec:Toggle({ Title = "Anti-Grab", Value = false, Callback = function(s) setAntiGrab(s) WindUI:Notify({Title="Anti-Grab", Content=s and "ON" or "OFF"}) end })
DefProtSec:Toggle({ Title = "Anti-Kick Grab", Value = false, Callback = function(s) setAntiKickGrab(s) WindUI:Notify({Title="Anti-Kick", Content=s and "ON" or "OFF"}) end })
DefProtSec:Toggle({ Title = "Anti-Explosion", Value = false, Callback = setAntiExplosion })
DefProtSec:Toggle({ Title = "Anti-Fling", Value = false, Callback = function(s) Config.AntiFlingEnabled = s end })

DefTab:Section({ Title = "Self Defense" }):Toggle({ Title = "Air Suspend Attacker", Value = false, Callback = function(s) setSelfDefense(s) WindUI:Notify({Title="Self Defense", Content=s and "ON" or "OFF"}) end })

local MoveSpeedSec = MoveTab:Section({ Title = "Speed", Opened = true })
MoveSpeedSec:Toggle({ Title = "Speed Boost", Value = false, Callback = function(s) setSpeed(s, Config.SpeedValue) WindUI:Notify({Title="Speed", Content=s and "ON" or "OFF"}) end })
MoveSpeedSec:Slider({ Title = "Speed Value", Value = { Min = 16, Max = 150, Default = 40 }, Step = 1, Callback = function(v) Config.SpeedValue = v; if Config.SpeedEnabled then setSpeed(true, v) end end })

local MoveFlySec = MoveTab:Section({ Title = "Fly" })
MoveFlySec:Toggle({ Title = "Fly", Value = false, Callback = function(s) setFly(s) WindUI:Notify({Title="Fly", Content=s and "ON" or "OFF"}) end })
MoveFlySec:Slider({ Title = "Fly Speed", Value = { Min = 10, Max = 200, Default = 60 }, Step = 1, Callback = function(v) Config.FlySpeed = v end })

local MoveMiscSec = MoveTab:Section({ Title = "Misc" })
MoveMiscSec:Toggle({ Title = "Noclip", Value = false, Callback = function(s) Config.NoclipEnabled = s end })
MoveMiscSec:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(s) Config.InfJumpEnabled = s end })

local VisCamSec = VisTab:Section({ Title = "Camera", Opened = true })
VisCamSec:Toggle({
    Title = "Force 3rd Person",
    Desc = "Вид от 3-го лица",
    Value = false,
    Callback = function(state)
        Config.ThirdPersonEnabled = state
        if state then
            if not State.oldCameraOffset then
                State.oldCameraOffset = { Max = LP.CameraMaxZoomDistance, Min = LP.CameraMinZoomDistance, Mode = LP.CameraMode }
            end
            LP.CameraMaxZoomDistance = 15
            LP.CameraMinZoomDistance = 8
            LP.CameraMode = Enum.CameraMode.Classic
        else
            if State.oldCameraOffset then
                LP.CameraMaxZoomDistance = State.oldCameraOffset.Max
                LP.CameraMinZoomDistance = State.oldCameraOffset.Min
                LP.CameraMode = State.oldCameraOffset.Mode
                State.oldCameraOffset = nil
            end
        end
    end,
})

VisTab:Section({ Title = "ESP" }):Toggle({ Title = "Enable ESP", Value = false, Callback = function(s) Config.ESPEnabled = s; if s then _G.RefreshESP() else _G.ClearESP() end end })

local VisWorldSec = VisTab:Section({ Title = "World" })
VisWorldSec:Toggle({ Title = "Fullbright", Value = false, Callback = function(s)
    Config.FullbrightEnabled = s
    if s then
        Lighting.Brightness = 2; Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.FogEnd = 1e6
    else
        Lighting.Brightness = 1; Lighting.Ambient = Color3.fromRGB(128,128,128); Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128); Lighting.FogEnd = 1000
    end
end })

local MiscActionsSec = MiscTab:Section({ Title = "Actions", Opened = true })
MiscActionsSec:Button({ Title = "Rejoin", Icon = "rotate-cw", Callback = function() TeleportService:Teleport(game.PlaceId, LP) end })
MiscActionsSec:Button({ Title = "Server Hop", Icon = "shuffle", Callback = function()
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local res = game:HttpGet(url)
        for _, s in ipairs(HttpService:JSONDecode(res).data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP) return end
        end
    end)
end })

local bindBtn = MiscTab:Section({ Title = "Settings" }):Button({ 
    Title = "Set Menu Key: " .. Config.MenuKey.Name, 
    Icon = "keyboard",
    Callback = function() 
        if State.IsListeningForBind then return end
        State.IsListeningForBind = true
        WindUI:Notify({Title="Keybind", Content="Нажми на любую клавишу...", Icon="info", Duration=3})
    end 
})

local espFolder = Instance.new("Folder", game:GetService("CoreGui"))
espFolder.Name = "Monolith_ESP"

_G.ClearESP = function()
    espFolder:ClearAllChildren()
end

local function buildESP(p)
    if p == LP or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bb = Instance.new("BillboardGui", espFolder)
    bb.Name = "ESPText"
    bb.Size = UDim2.new(0, 150, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    bb:SetAttribute("Owner", p.UserId)

    local nl = Instance.new("TextLabel", bb)
    nl.Name = "NameLbl"; nl.Size = UDim2.new(1, 0, 0, 20); nl.BackgroundTransparency = 1
    nl.Text = p.Name; nl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nl.Font = Enum.Font.GothamBold; nl.TextSize = 13; nl.TextStrokeTransparency = 0.3

    local hp = Instance.new("TextLabel", bb)
    hp.Name = "HPLbl"; hp.Size = UDim2.new(1, 0, 0, 16); hp.Position = UDim2.new(0, 0, 0, 18)
    hp.BackgroundTransparency = 1; hp.TextColor3 = Color3.fromRGB(255, 75, 75)
    hp.Font = Enum.Font.Gotham; hp.TextSize = 11; hp.TextStrokeTransparency = 0.3
end

_G.RefreshESP = function()
    espFolder:ClearAllChildren()
    for _, p in ipairs(Players:GetPlayers()) do buildESP(p) end
end

RunService.Heartbeat:Connect(function()
    if Config.SpeedEnabled then
        local hum = getHum()
        if hum and hum.WalkSpeed ~= Config.SpeedValue then hum.WalkSpeed = Config.SpeedValue end
    end
    
    if Config.AntiFlingEnabled then
        local char = getChar()
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Velocity.Magnitude > 500 then hrp.Velocity = Vector3.zero end
        end
    end
    
    if State.GrabbedTarget then
        local target = State.GrabbedTarget
        if not target.hrp or not target.hrp.Parent then State.GrabbedTarget = nil return end
        local myHRP = getHRP() if not myHRP then State.GrabbedTarget = nil return end
        local bv = target.hrp:FindFirstChild("Monolith_GrabBV")
        if bv then
            local goalPos = myHRP.Position + myHRP.CFrame.LookVector * 5
            local dir = (goalPos - target.hrp.Position)
            bv.Velocity = dir.Magnitude < 1 and Vector3.zero or dir * 8
        end
    end

    if Config.ESPEnabled then
        local myHRP = getHRP()
        for _, v in ipairs(espFolder:GetChildren()) do
            local uid = v:GetAttribute("Owner")
            if not uid then continue end
            local p = Players:GetPlayerByUserId(uid)
            if not p or not p.Character then v:Destroy() continue end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if not hrp then v:Destroy() continue end
            
            v.Adornee = hrp
            if hum and myHRP then
                local hpLabel = v:FindFirstChild("HPLbl")
                if hpLabel then hpLabel.Text = tostring(math.floor(hum.Health)) .. " HP" end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if Config.NoclipEnabled then
        local char = getChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if Config.InfJumpEnabled then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if State.IsListeningForBind then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Config.MenuKey = input.KeyCode
            State.IsListeningForBind = false
            bindBtn:SetTitle("Set Menu Key: " .. Config.MenuKey.Name)
            WindUI:Notify({Title="Keybind", Content="Меню теперь на клавише: " .. Config.MenuKey.Name, Icon="check"})
        end
        return
    end

    if input.KeyCode == Config.MenuKey then
        Window:Toggle()
    end

    if input.KeyCode == Enum.KeyCode.Q then
        local t = findClosestTarget(Config.GrabRange)
        if t then grabTarget(t) end
    elseif input.KeyCode == Enum.KeyCode.E then
        releaseGrab()
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.8)
    if Config.SpeedEnabled then setSpeed(true, Config.SpeedValue) end
    if Config.FlyEnabled then setFly(true) end
    if Config.ESPEnabled then _G.RefreshESP() end
    if Config.NoclipEnabled then Config.NoclipEnabled = true end
    if Config.AntiExplosionEnabled then setAntiExplosion(true) end
end)
