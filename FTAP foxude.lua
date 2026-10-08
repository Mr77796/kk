-- ============================================
-- Foxude | FTAP Hub v7
-- Anchor fix: PartOwner is searched in all children
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

print("-[(Foxude) v7 loaded]-")

local GrabEvents, CharacterEvents, SetNetworkOwner, Struggle
local GameCorrectionEvents, StopAllVelocity, RagdollRemote
pcall(function()
    GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents", 10)
    CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents", 10)
    if GrabEvents then SetNetworkOwner = GrabEvents:WaitForChild("SetNetworkOwner", 10) end
    if CharacterEvents then
        Struggle = CharacterEvents:WaitForChild("Struggle", 10)
        RagdollRemote = CharacterEvents:WaitForChild("RagdollRemote", 10)
    end
    GameCorrectionEvents = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
    if GameCorrectionEvents then
        StopAllVelocity = GameCorrectionEvents:FindFirstChild("StopAllVelocity")
    end
end)

local Config = {
    GrabRange = 30,
    ThrowPower = 300,
    FlyEnabled = false, FlySpeed = 60,
    SpeedEnabled = false, SpeedValue = 40,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    ESPEnabled = false, ESPShowName = true, ESPShowDist = true, ESPShowHP = true,
    FullbrightEnabled = false,
    AntiGrabEnabled = false,
    AntiKickGrabEnabled = false,
    AntiExplosionEnabled = false,
    SelfDefenseEnabled = false,
    SelfDefenseKickEnabled = false,
    AntiFlingEnabled = false,
    StrengthEnabled = false,
    AnchorGrabEnabled = false,
    MenuKey = Enum.KeyCode.RightControl,
    IconVisible = true, IconPosX = 30, IconPosY = 300,
    Transparency = 0, MenuWidth = 400, MenuHeight = 650,
    AccentR = 0, AccentG = 255, AccentB = 170,
    AccentColor = Color3.fromRGB(0, 255, 170),
}

local function updateAccentFromRGB()
    Config.AccentColor = Color3.fromRGB(Config.AccentR, Config.AccentG, Config.AccentB)
end

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
    AnchoredParts = {},
    AnchorConnections = {},
    AnchorGrabConnection = nil,
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

local function getAllTargets()
    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                table.insert(targets, {hrp = hrp, hum = p.Character:FindFirstChildOfClass("Humanoid"), player = p, char = p.Character})
            end
        end
    end
    return targets
end

local function findClosestTarget(maxDist)
    maxDist = maxDist or math.huge
    local myHRP = getHRP() if not myHRP then return nil end
    local best, bestDist = nil, maxDist
    for _, t in ipairs(getAllTargets()) do
        local d = (t.hrp.Position - myHRP.Position).Magnitude
        if d < bestDist then bestDist = d best = t end
    end
    return best
end

-- MOVEMENT
local function setFly(enabled)
    Config.FlyEnabled = enabled
    local char = getChar() if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = getHum() if not hrp then return end
    if enabled then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "Foxude_FlyBV"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.Name = "Foxude_FlyBG"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.Parent = hrp
        if hum then hum.PlatformStand = true end
        RunService:BindToRenderStep("Foxude_Fly", Enum.RenderPriority.Camera.Value, function()
            if not Config.FlyEnabled then return end
            local c = getChar() if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart") if not h then return end
            local b = h:FindFirstChild("Foxude_FlyBV") local g = h:FindFirstChild("Foxude_FlyBG")
            if not b or not g then return end
            local cam = workspace.CurrentCamera
            g.CFrame = cam.CFrame
            local m = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then m += cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then m -= cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then m -= cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then m += cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then m += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then m -= Vector3.yAxis end
            b.Velocity = m.Magnitude > 0 and m.Unit * Config.FlySpeed or Vector3.zero
        end)
    else
        RunService:UnbindFromRenderStep("Foxude_Fly")
        if hrp:FindFirstChild("Foxude_FlyBV") then hrp.Foxude_FlyBV:Destroy() end
        if hrp:FindFirstChild("Foxude_FlyBG") then hrp.Foxude_FlyBG:Destroy() end
        if hum then hum.PlatformStand = false end
    end
end

local function setSpeed(enabled, value)
    Config.SpeedEnabled = enabled
    if value then Config.SpeedValue = value end
    local hum = getHum()
    if hum then hum.WalkSpeed = enabled and Config.SpeedValue or 16 end
end

RunService.Heartbeat:Connect(function()
    if not Config.SpeedEnabled then return end
    local hum = getHum() if not hum then return end
    if hum.WalkSpeed ~= Config.SpeedValue then hum.WalkSpeed = Config.SpeedValue end
end)

local function setNoclip(enabled) Config.NoclipEnabled = enabled end
RunService.Stepped:Connect(function()
    if not Config.NoclipEnabled then return end
    local char = getChar() if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

local function setInfJump(enabled) Config.InfJumpEnabled = enabled end
UIS.JumpRequest:Connect(function()
    if Config.InfJumpEnabled then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- STRENGTH
local function setStrength(enabled)
    Config.StrengthEnabled = enabled
    if State.StrengthConnection then
        State.StrengthConnection:Disconnect()
        State.StrengthConnection = nil
    end
    if not enabled then return end
    State.StrengthConnection = workspace.ChildAdded:Connect(function(model)
        if model.Name == "GrabParts" then
            local grabPart = model:FindFirstChild("GrabPart")
            if not grabPart then return end
            local weld = grabPart:FindFirstChild("WeldConstraint")
            if not weld or not weld.Part1 then return end
            local partToImpulse = weld.Part1
            local velocityObj = Instance.new("BodyVelocity", partToImpulse)
            velocityObj.MaxForce = Vector3.new(0, 0, 0)
            velocityObj.Velocity = Vector3.zero
            model:GetPropertyChangedSignal("Parent"):Connect(function()
                if not model.Parent then
                    if UIS:GetLastInputType() == Enum.UserInputType.MouseButton2 then
                        velocityObj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        velocityObj.Velocity = workspace.CurrentCamera.CFrame.LookVector * Config.ThrowPower
                        Debris:AddItem(velocityObj, 1)
                    else
                        velocityObj:Destroy()
                    end
                end
            end)
        end
    end)
end

-- DEFENSE
local function setAntiGrab(enabled)
    Config.AntiGrabEnabled = enabled
    if State.AntiGrabConnection then
        State.AntiGrabConnection:Disconnect()
        State.AntiGrabConnection = nil
    end
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
            if held then
                while held.Value do task.wait() end
            else
                task.wait(0.5)
            end
            local c = LP.Character
            if c then
                for _, part in ipairs(c:GetChildren()) do
                    if part:IsA("BasePart") then part.Anchored = false end
                end
            end
        end)
    end)
end

local function setAntiKickGrab(enabled)
    Config.AntiKickGrabEnabled = enabled
    if State.AntiKickGrabConnection then
        State.AntiKickGrabConnection:Disconnect()
        State.AntiKickGrabConnection = nil
    end
    if not enabled then return end

    State.AntiKickGrabConnection = RunService.Heartbeat:Connect(function()
        local character = LP.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local firePart = hrp:FindFirstChild("FirePlayerPart")
        if not firePart then return end
        local partOwner = firePart:FindFirstChild("PartOwner")
        if partOwner and partOwner.Value ~= LP.Name then
            pcall(function()
                if RagdollRemote then RagdollRemote:FireServer(hrp, 0) end
            end)
            task.wait(0.1)
            pcall(function()
                if Struggle then Struggle:FireServer() end
            end)
        end
    end)
end

local function setupAntiExplosion(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    local partOwner = humanoid:FindFirstChild("Ragdolled")
    if not partOwner then return end

    State.AntiExplosionConnection = partOwner:GetPropertyChangedSignal("Value"):Connect(function()
        if partOwner.Value then
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") then part.Anchored = true end
            end
        else
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") then part.Anchored = false end
            end
        end
    end)
end

local function setAntiExplosion(enabled)
    Config.AntiExplosionEnabled = enabled
    if State.AntiExplosionConnection then
        State.AntiExplosionConnection:Disconnect()
        State.AntiExplosionConnection = nil
    end
    if State.AntiExplosionCharConn then
        State.AntiExplosionCharConn:Disconnect()
        State.AntiExplosionCharConn = nil
    end
    if not enabled then return end

    local char = LP.Character
    if char then setupAntiExplosion(char) end

    State.AntiExplosionCharConn = LP.CharacterAdded:Connect(function(c)
        if State.AntiExplosionConnection then
            State.AntiExplosionConnection:Disconnect()
            State.AntiExplosionConnection = nil
        end
        setupAntiExplosion(c)
    end)
end

local function setSelfDefense(enabled)
    Config.SelfDefenseEnabled = enabled
    if State.SelfDefenseCoroutine then
        State.SelfDefenseCoroutine:Disconnect()
        State.SelfDefenseCoroutine = nil
    end
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
                local velocity = target:FindFirstChild("Foxude_Suspend") or Instance.new("BodyVelocity")
                velocity.Name = "Foxude_Suspend"
                velocity.Parent = target
                velocity.Velocity = Vector3.new(0, 50, 0)
                velocity.MaxForce = Vector3.new(0, math.huge, 0)
                Debris:AddItem(velocity, 100)
            end
        end
    end)
end

local function setSelfDefenseKick(enabled)
    Config.SelfDefenseKickEnabled = enabled
    if enabled then
        Notify("Self Defense", "Kick Silent — stub (like in VenomX)", 3)
    end
end

local function setAntiFling(enabled)
    Config.AntiFlingEnabled = enabled
end

-- ============================================
-- ANCHOR GRAB v7 (correct PartOwner search)
-- ============================================
local function isDescendantOf(target, other)
    local currentParent = target.Parent
    while currentParent do
        if currentParent == other then return true end
        currentParent = currentParent.Parent
    end
    return false
end

local function createAnchorHighlight(parent)
    local highlight = Instance.new("Highlight")
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillTransparency = 1
    highlight.Name = "Foxude_AnchorHL"
    highlight.OutlineColor = Color3.fromRGB(0, 0, 255)
    highlight.OutlineTransparency = 0.5
    highlight.Parent = parent
    return highlight
end

local function findPartOwner(obj)
    if obj:FindFirstChild("PartOwner") then
        return obj:FindFirstChild("PartOwner")
    end
    for _, child in ipairs(obj:GetDescendants()) do
        if child.Name == "PartOwner" then
            return child
        end
    end
    return nil
end

local function unanchorTarget(target)
    if not target then return end
    if target:IsA("Model") then
        for _, child in ipairs(target:GetDescendants()) do
            if child:IsA("BasePart") then child.Anchored = false end
        end
        local hl = target:FindFirstChild("Foxude_AnchorHL")
        if hl then hl:Destroy() end
    elseif target:IsA("BasePart") then
        target.Anchored = false
        local hl = target:FindFirstChild("Foxude_AnchorHL")
        if hl then hl:Destroy() end
    end
    for i, v in ipairs(State.AnchoredParts) do
        if v == target then table.remove(State.AnchoredParts, i) break end
    end
end

local function cleanupAnchorGrab()
    for _, target in ipairs(State.AnchoredParts) do
        unanchorTarget(target)
    end
    for _, conn in ipairs(State.AnchorConnections) do
        if conn then conn:Disconnect() end
    end
    State.AnchoredParts = {}
    State.AnchorConnections = {}
end

local function setAnchorGrab(enabled)
    Config.AnchorGrabEnabled = enabled
    if State.AnchorGrabConnection then
        State.AnchorGrabConnection:Disconnect()
        State.AnchorGrabConnection = nil
    end
    if not enabled then return end

    State.AnchorGrabConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            local grabParts = workspace:FindFirstChild("GrabParts")
            if not grabParts then return end

            local grabPart = grabParts:FindFirstChild("GrabPart")
            if not grabPart then return end

            local weld = grabPart:FindFirstChild("WeldConstraint")
            if not weld or not weld.Part1 then return end

            local primaryPart = weld.Part1
            if not primaryPart then return end

            if isDescendantOf(primaryPart, workspace.Map) then return end

            for _, player in ipairs(Players:GetChildren()) do
                if player.Character and isDescendantOf(primaryPart, player.Character) then
                    return
                end
            end

            local partOwner = findPartOwner(primaryPart)
            local isMine = partOwner and partOwner.Value == LP.Name

            local target = primaryPart
            local ancestor = primaryPart:FindFirstAncestorOfClass("Model")
            if ancestor and ancestor ~= workspace and ancestor ~= workspace.Map then
                target = ancestor
            end

            if isMine then
                local wasAnchored = false
                for _, v in ipairs(State.AnchoredParts) do
                    if v == target then wasAnchored = true break end
                end
                if wasAnchored then
                    unanchorTarget(target)
                end
                return
            end

            for _, v in ipairs(State.AnchoredParts) do
                if v == target then return end
            end

            table.insert(State.AnchoredParts, target)
            createAnchorHighlight(target)

            local conn = target.DescendantAdded:Connect(function(desc)
                if desc.Name == "PartOwner" and desc.Value ~= LP.Name then
                    local hl = target:FindFirstChild("Foxude_AnchorHL")
                    if hl then hl.OutlineColor = Color3.fromRGB(255, 0, 0) end
                end
            end)
            table.insert(State.AnchorConnections, conn)

            if target:IsA("Model") then
                for _, child in ipairs(target:GetDescendants()) do
                    if child:IsA("BasePart") then
                        child.Anchored = true
                    end
                end
            else
                primaryPart.Anchored = true
            end
        end)
    end)
end

local function unanchorAll()
    cleanupAnchorGrab()
end

-- ESP
local espFolder = Instance.new("Folder", CoreGui)
espFolder.Name = "Foxude_ESP"
local function clearESP(player)
    for _, v in ipairs(espFolder:GetChildren()) do
        if v:GetAttribute("Owner") == player.UserId then v:Destroy() end
    end
end

local function buildESP(player)
    if player == LP then return end
    local char = player.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
    clearESP(player)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP"
    bb.Size = UDim2.new(0, 140, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    bb.Parent = espFolder
    bb:SetAttribute("Owner", player.UserId)
    local nl = Instance.new("TextLabel", bb)
    nl.Name = "NameLbl"
    nl.Size = UDim2.new(1, 0, 0, 18)
    nl.BackgroundTransparency = 1
    nl.Text = player.Name
    nl.TextColor3 = Config.AccentColor
    nl.TextStrokeTransparency = 0.3
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 13
    nl.Visible = Config.ESPShowName
    local hp = Instance.new("TextLabel", bb)
    hp.Name = "HPLbl"
    hp.Size = UDim2.new(1, 0, 0, 16)
    hp.Position = UDim2.new(0, 0, 0, 18)
    hp.BackgroundTransparency = 1
    hp.TextColor3 = Color3.fromRGB(255, 100, 100)
    hp.TextStrokeTransparency = 0.3
    hp.Font = Enum.Font.Gotham
    hp.TextSize = 11
    hp.Visible = Config.ESPShowHP
    local dist = Instance.new("TextLabel", bb)
    dist.Name = "DistLbl"
    dist.Size = UDim2.new(1, 0, 0, 16)
    dist.Position = UDim2.new(0, 0, 0, 34)
    dist.BackgroundTransparency = 1
    dist.TextColor3 = Color3.new(1,1,1)
    dist.TextStrokeTransparency = 0.3
    dist.Font = Enum.Font.Gotham
    dist.TextSize = 11
    dist.Visible = Config.ESPShowDist
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 6, 4)
    box.Adornee = hrp
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.5
    box.Color3 = Config.AccentColor
    box.Parent = espFolder
    box:SetAttribute("Owner", player.UserId)
end

local function refreshESP()
    espFolder:ClearAllChildren()
    if not Config.ESPEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do buildESP(p) end
end

Players.PlayerAdded:Connect(function(p) if Config.ESPEnabled then task.wait(1); buildESP(p) end end)
Players.PlayerRemoving:Connect(function(p) clearESP(p) end)

RunService.Heartbeat:Connect(function()
    if not Config.ESPEnabled then return end
    local myHRP = getHRP()
    for _, v in ipairs(espFolder:GetChildren()) do
        local uid = v:GetAttribute("Owner")
        if not uid then continue end
        local p = Players:GetPlayerByUserId(uid)
        if not p or not p.Character then v:Destroy() continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hrp then v:Destroy() continue end
        if v:IsA("BillboardGui") or v:IsA("BoxHandleAdornment") then
            v.Adornee = hrp
            if v:IsA("BoxHandleAdornment") then v.Color3 = Config.AccentColor end
        end
        if v:IsA("BillboardGui") and hum and myHRP then
            local nl = v:FindFirstChild("NameLbl")
            local hp = v:FindFirstChild("HPLbl")
            local dist = v:FindFirstChild("DistLbl")
            if nl then nl.TextColor3 = Config.AccentColor end
            if hp then hp.Text = "HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) end
            if dist then dist.Text = math.floor((hrp.Position - myHRP.Position).Magnitude) .. " studs" end
        end
    end
end)

-- FULLBRIGHT
local savedLight = {}
local function setFullbright(enabled)
    Config.FullbrightEnabled = enabled
    if enabled then
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
end

-- GRAB
local function clearGrab()
    for _, c in pairs(State.GrabConstraints) do
        if c then c:Destroy() end
    end
    State.GrabConstraints = {}
    State.GrabbedTarget = nil
end

local function grabTarget(target, mode)
    if not target or not target.hrp then return end
    if tick() - State.LastGrab < 0.3 then return end
    State.LastGrab = tick()
    clearGrab()
    local myHRP = getHRP()
    if not myHRP then return end
    State.GrabbedTarget = target
    if SetNetworkOwner then
        pcall(function() SetNetworkOwner:FireServer(target.hrp, target.hrp.CFrame) end)
    end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "Foxude_GrabBV"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = target.hrp
    table.insert(State.GrabConstraints, bv)
end

local function releaseGrab()
    if not State.GrabbedTarget then return end
    local target = State.GrabbedTarget
    local targetHRP = target.hrp
    clearGrab()
    if not targetHRP or not targetHRP.Parent then return end
    local look = Camera.CFrame.LookVector
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = look * Config.ThrowPower + Vector3.new(0, Config.ThrowPower * 0.4, 0)
    bv.Parent = targetHRP
    Debris:AddItem(bv, 1)
end

RunService.Heartbeat:Connect(function(dt)
    if not State.GrabbedTarget then return end
    local target = State.GrabbedTarget
    if not target.hrp or not target.hrp.Parent then clearGrab() return end
    local myHRP = getHRP()
    if not myHRP then clearGrab() return end
    local bv = target.hrp:FindFirstChild("Foxude_GrabBV")
    if bv then
        local goalPos = myHRP.Position + myHRP.CFrame.LookVector * 5
        local dir = (goalPos - target.hrp.Position)
        if dir.Magnitude < 1 then
            bv.Velocity = Vector3.zero
        else
            bv.Velocity = dir * 8
        end
    end
end)

local function rejoin()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end)
end

local function serverHop()
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local res = game:HttpGet(url)
        local data = HttpService:JSONDecode(res)
        for _, s in ipairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                return
            end
        end
    end)
end

local API = {
    SetFly = setFly, SetSpeed = setSpeed, SetNoclip = setNoclip, SetInfJump = setInfJump,
    SetESP = function(e) Config.ESPEnabled = e; refreshESP() end,
    SetFullbright = setFullbright,
    SetStrength = setStrength,
    SetAntiGrab = setAntiGrab,
    SetAntiKickGrab = setAntiKickGrab,
    SetAntiExplosion = setAntiExplosion,
    SetSelfDefense = setSelfDefense,
    SetSelfDefenseKick = setSelfDefenseKick,
    SetAntiFling = setAntiFling,
    SetAnchorGrab = setAnchorGrab,
    UnanchorAll = unanchorAll,
    Grab = function(mode) local t = findClosestTarget(Config.GrabRange) if t then Config.GrabMode = mode or Config.GrabMode grabTarget(t, Config.GrabMode) end end,
    Release = releaseGrab,
    Rejoin = rejoin,
    ServerHop = serverHop,
    Config = Config, State = State,
}

-- SAVE/LOAD
local SAVE_KEY = "Foxude_Settings_v7.json"
local function saveSettings()
    pcall(function()
        local data = {
            FlySpeed = Config.FlySpeed, SpeedValue = Config.SpeedValue,
            GrabRange = Config.GrabRange, ThrowPower = Config.ThrowPower,
            FlyEnabled = Config.FlyEnabled, SpeedEnabled = Config.SpeedEnabled,
            NoclipEnabled = Config.NoclipEnabled, InfJumpEnabled = Config.InfJumpEnabled,
            ESPEnabled = Config.ESPEnabled, ESPShowName = Config.ESPShowName,
            ESPShowDist = Config.ESPShowDist, ESPShowHP = Config.ESPShowHP,
            FullbrightEnabled = Config.FullbrightEnabled,
            AntiGrabEnabled = Config.AntiGrabEnabled,
            AntiKickGrabEnabled = Config.AntiKickGrabEnabled,
            AntiExplosionEnabled = Config.AntiExplosionEnabled,
            SelfDefenseEnabled = Config.SelfDefenseEnabled,
            AntiFlingEnabled = Config.AntiFlingEnabled,
            StrengthEnabled = Config.StrengthEnabled,
            MenuKey = Config.MenuKey.Name, IconVisible = Config.IconVisible,
            IconPosX = Config.IconPosX, IconPosY = Config.IconPosY,
            Transparency = Config.Transparency, MenuWidth = Config.MenuWidth,
            MenuHeight = Config.MenuHeight,
            AccentR = Config.AccentR, AccentG = Config.AccentG, AccentB = Config.AccentB,
        }
        writefile(SAVE_KEY, HttpService:JSONEncode(data))
    end)
end

local Saved = nil
pcall(function() Saved = HttpService:JSONDecode(readfile(SAVE_KEY)) end)

if Saved then
    for _, k in ipairs({"FlySpeed","SpeedValue","GrabRange","ThrowPower",
        "IconVisible","IconPosX","IconPosY","Transparency","MenuWidth","MenuHeight",
        "ESPShowName","ESPShowDist","ESPShowHP","AccentR","AccentG","AccentB"}) do
        if Saved[k] ~= nil then Config[k] = Saved[k] end
    end
    if Saved.MenuKey then
        local ok, key = pcall(function() return Enum.KeyCode[Saved.MenuKey] end)
        if ok then Config.MenuKey = key end
    end
    updateAccentFromRGB()
end

-- NOTIFY
local notifyStack = 0
local N_H, N_GAP, N_W = 62, 6, 260
local function Notify(title, body, dur)
    dur = dur or 3
    notifyStack += 1
    local slot = notifyStack
    local sg = Instance.new("ScreenGui")
    sg.Name = "Foxude_Notify_" .. slot
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = CoreGui
    local yOff = 16 + (slot - 1) * (N_H + N_GAP)
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0, N_W, 0, N_H - N_GAP)
    f.Position = UDim2.new(1, 20, 0, yOff)
    f.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(0, 3, 1, -16)
    bar.Position = UDim2.new(0, 0, 0, 8)
    bar.BackgroundColor3 = Config.AccentColor
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local tl = Instance.new("TextLabel", f)
    tl.Size = UDim2.new(1, -20, 0, 20)
    tl.Position = UDim2.new(0, 14, 0, 7)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = Config.AccentColor
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 13
    tl.TextXAlignment = Enum.TextXAlignment.Left
    local bl = Instance.new("TextLabel", f)
    bl.Size = UDim2.new(1, -20, 0, 18)
    bl.Position = UDim2.new(0, 14, 0, 27)
    bl.BackgroundTransparency = 1
    bl.Text = body
    bl.TextColor3 = Color3.fromRGB(190, 190, 200)
    bl.Font = Enum.Font.Gotham
    bl.TextSize = 11
    bl.TextXAlignment = Enum.TextXAlignment.Left
    local rIn = UDim2.new(1, -(N_W + 16), 0, yOff)
    TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = rIn}):Play()
    task.delay(dur, function()
        TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Position = UDim2.new(1, 20, 0, yOff)
        }):Play()
        task.wait(0.3)
        sg:Destroy()
        notifyStack = math.max(0, notifyStack - 1)
    end)
end

-- GUI
local Gui = Instance.new("ScreenGui")
Gui.Name = "Foxude"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

local WIN_W, WIN_H = Config.MenuWidth, Config.MenuHeight
local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Main.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Main.BackgroundColor3 = Color3.fromRGB(11, 11, 15)
Main.BackgroundTransparency = Config.Transparency
Main.BorderSizePixel = 0
Main.Active = false
Main.Draggable = false
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(30, 30, 42)
stroke.Thickness = 1

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
Header.BorderSizePixel = 0
Header.Active = true
Header.ClipsDescendants = true
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)
local hFix = Instance.new("Frame", Header)
hFix.Size = UDim2.new(1, 0, 0, 14)
hFix.Position = UDim2.new(0, 0, 1, -14)
hFix.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
hFix.BorderSizePixel = 0
hFix.ZIndex = 2
hFix.Active = false

local dot = Instance.new("Frame", Header)
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 14, 0.5, -4)
dot.BackgroundColor3 = Config.AccentColor
dot.ZIndex = 3
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 30, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "FOXUDE  ·  FTAP v7"
Title.TextColor3 = Config.AccentColor
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Active = false

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 17
CloseBtn.ZIndex = 3
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)
CloseBtn.MouseButton1Click:Connect(function() Gui.Enabled = false end)

local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
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

local TABS = {"Grab", "Defense", "Move", "Visual", "Misc", "Settings"}
local TabFrames, TabBtns = {}, {}

local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1, -16, 0, 32)
TabBar.Position = UDim2.new(0, 8, 0, 56)
TabBar.BackgroundTransparency = 1

local TabGrid = Instance.new("UIGridLayout", TabBar)
TabGrid.CellSize = UDim2.new(1/#TABS, -6, 1, 0)
TabGrid.CellPadding = UDim2.new(0, 6, 0, 0)
TabGrid.SortOrder = Enum.SortOrder.LayoutOrder

local function switchTab(name)
    for n, fr in pairs(TabFrames) do fr.Visible = (n == name) end
    for n, btn in pairs(TabBtns) do
        if n == name then
            btn.BackgroundColor3 = Config.AccentColor
            btn.TextColor3 = Color3.fromRGB(10, 10, 14)
        else
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            btn.TextColor3 = Color3.fromRGB(160, 160, 175)
        end
    end
end

for i, name in ipairs(TABS) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Name = name
    btn.LayoutOrder = i
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(160, 160, 175)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    TabBtns[name] = btn
end

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -16, 1, -100)
Content.Position = UDim2.new(0, 8, 0, 94)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.Active = false

for _, name in ipairs(TABS) do
    local sf = Instance.new("ScrollingFrame", Content)
    sf.Name = name
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.Visible = (name == "Grab")
    sf.Active = false
    sf.BorderSizePixel = 0
    TabFrames[name] = sf
    local ll = Instance.new("UIListLayout", sf)
    ll.Padding = UDim.new(0, 7)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 6)
end

local function sectionLabel(parent, text, order)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -4, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(100, 100, 120)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
end

local function AddToggle(parent, text, order, callback)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, -4, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = order
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -64, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Active = false
    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0, 40, 0, 20)
    pill.Position = UDim2.new(1, -50, 0.5, -10)
    pill.BackgroundColor3 = Color3.fromRGB(38, 38, 50)
    pill.BorderSizePixel = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(120, 120, 135)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local on = false
    local function setState(val, silent)
        on = val
        if on then
            TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = Config.AccentColor}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = UDim2.new(1, -17, 0.5, -7),
                BackgroundColor3 = Color3.new(1,1,1)
            }):Play()
            row.BackgroundColor3 = Color3.fromRGB(16, 30, 24)
        else
            TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(38,38,50)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = UDim2.new(0, 3, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(120,120,135)
            }):Play()
            row.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        end
        if not silent then callback(on) end
    end
    row.MouseButton1Click:Connect(function()
        setState(not on)
        saveSettings()
    end)
    return setState
end

local function AddSlider(parent, text, order, min, max, default, fmt, callback)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, -4, 0, 52)
    fr.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    fr.LayoutOrder = order
    fr.BorderSizePixel = 0
    fr.Active = false
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -20, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(200, 200, 215)
    lbl.Active = false
    local track = Instance.new("Frame", fr)
    track.Size = UDim2.new(1, -20, 0, 5)
    track.Position = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    track.BorderSizePixel = 0
    track.Active = true
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Config.AccentColor
    fill.BorderSizePixel = 0
    fill.Active = false
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    local function setValue(val, silent)
        val = math.clamp(math.floor(val), min, max)
        local rel = (val - min)/(max - min)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. "  " .. (fmt and string.format(fmt, val) or tostring(val))
        if not silent then callback(val); saveSettings() end
    end
    setValue(default, true)
    local isDragging = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then isDragging = true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            if isDragging then isDragging = false; saveSettings() end
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not isDragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            setValue(val, false)
        end
    end)
    return setValue
end

local function AddButton(parent, text, order, callback, color)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -4, 0, 40)
    btn.BackgroundColor3 = color or Color3.fromRGB(26, 26, 34)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- GRAB TAB
local GrabTab = TabFrames.Grab
sectionLabel(GrabTab, "GRAB SETTINGS", 0)
local setGrabRange = AddSlider(GrabTab, "Grab Range", 1, 10, 100, Config.GrabRange, "%d st", function(v) Config.GrabRange = v end)
local setThrowPower = AddSlider(GrabTab, "Throw Power", 2, 100, 2000, Config.ThrowPower, "%d", function(v) Config.ThrowPower = v end)
sectionLabel(GrabTab, "STRENGTH (RMB on release)", 3)
local setStrength = AddToggle(GrabTab, "Strength (GrabParts)", 4, function(s) API.SetStrength(s); Notify("Strength", s and "ON" or "OFF", 2) end)
sectionLabel(GrabTab, "ANCHOR (hold - move, release - anchor)", 5)
local setAnchorToggle = AddToggle(GrabTab, "Anchor Grab", 6, function(s) API.SetAnchorGrab(s); Notify("Anchor", s and "ON" or "OFF", 2) end)
AddButton(GrabTab, "Unanchor All", 7, function() API.UnanchorAll(); Notify("Anchor", "Released all", 2) end, Color3.fromRGB(200, 100, 40))
sectionLabel(GrabTab, "ACTIONS", 8)
AddButton(GrabTab, "GRAB (Q)", 9, function() API.Grab("Spin"); Notify("Foxude", "Grabbed", 2) end, Config.AccentColor)
AddButton(GrabTab, "RELEASE (E)", 10, function() API.Release(); Notify("Foxude", "Released", 2) end, Color3.fromRGB(200, 100, 40))

-- DEFENSE TAB
local DefTab = TabFrames.Defense
sectionLabel(DefTab, "ANTI-GRAB", 0)
local setAntiGrab = AddToggle(DefTab, "Anti Grab (Struggle)", 1, function(s) API.SetAntiGrab(s); Notify("Anti-Grab", s and "ON" or "OFF", 2) end)
local setAntiKickGrab = AddToggle(DefTab, "Anti Kick Grab", 2, function(s) API.SetAntiKickGrab(s); Notify("Anti-Kick Grab", s and "ON" or "OFF", 2) end)
local setAntiExplosion = AddToggle(DefTab, "Anti Explosion", 3, function(s) API.SetAntiExplosion(s); Notify("Anti-Explosion", s and "ON" or "OFF", 2) end)
sectionLabel(DefTab, "SELF DEFENSE", 4)
local setSelfDefense = AddToggle(DefTab, "Self Defense / Air Suspend", 5, function(s) API.SetSelfDefense(s); Notify("Self Defense", s and "ON" or "OFF", 2) end)
local setSelfDefenseKick = AddToggle(DefTab, "Self Defense / Kick Silent", 6, function(s) API.SetSelfDefenseKick(s) end)
sectionLabel(DefTab, "OTHER", 7)
local setAntiFling = AddToggle(DefTab, "Anti-Fling", 8, function(s) API.SetAntiFling(s); Notify("Anti-Fling", s and "ON" or "OFF", 2) end)

-- MOVE
local MoveTab = TabFrames.Move
sectionLabel(MoveTab, "MOVEMENT", 0)
local setFlySpeed = AddSlider(MoveTab, "Fly Speed", 1, 10, 200, Config.FlySpeed, "%d st/s", function(v) Config.FlySpeed = v end)
local setFly = AddToggle(MoveTab, "Fly", 2, function(s) API.SetFly(s); Notify("Fly", s and "ON" or "OFF", 2) end)
local setSpeedVal = AddSlider(MoveTab, "Speed", 3, 16, 150, Config.SpeedValue, "%d", function(v) Config.SpeedValue = v; if Config.SpeedEnabled then API.SetSpeed(true, v) end end)
local setSpeed = AddToggle(MoveTab, "Speed Boost", 4, function(s) API.SetSpeed(s, Config.SpeedValue); Notify("Speed", s and "ON" or "OFF", 2) end)
local setNoclip = AddToggle(MoveTab, "Noclip", 5, function(s) API.SetNoclip(s); Notify("Noclip", s and "ON" or "OFF", 2) end)
local setInfJump = AddToggle(MoveTab, "Infinite Jump", 6, function(s) API.SetInfJump(s); Notify("Inf Jump", s and "ON" or "OFF", 2) end)

-- VISUAL
local VisTab = TabFrames.Visual
sectionLabel(VisTab, "ESP", 0)
local setESP = AddToggle(VisTab, "ESP", 1, function(s) API.SetESP(s); Notify("ESP", s and "ON" or "OFF", 2) end)
local setESPName = AddToggle(VisTab, "ESP · Name", 2, function(s) Config.ESPShowName = s end)
local setESPDist = AddToggle(VisTab, "ESP · Distance", 3, function(s) Config.ESPShowDist = s end)
local setESPHP = AddToggle(VisTab, "ESP · HP", 4, function(s) Config.ESPShowHP = s end)
sectionLabel(VisTab, "WORLD", 5)
local setFullbright = AddToggle(VisTab, "Fullbright", 6, function(s) API.SetFullbright(s); Notify("Fullbright", s and "ON" or "OFF", 2) end)

-- MISC
local MiscTab = TabFrames.Misc
sectionLabel(MiscTab, "UTILITY", 0)
AddButton(MiscTab, "Rejoin", 1, function() API.Rejoin() end, Color3.fromRGB(60, 120, 180))
AddButton(MiscTab, "Server Hop", 2, function() API.ServerHop() end, Color3.fromRGB(80, 60, 180))

-- SETTINGS
local SettingsTab = TabFrames.Settings
sectionLabel(SettingsTab, "MENU", 0)

local function AddKeybind(parent, text, order, getter, setter)
    local fr = Instance.new("Frame", parent)
    fr.Size = UDim2.new(1, -4, 0, 36)
    fr.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    fr.LayoutOrder = order
    fr.BorderSizePixel = 0
    fr.Active = false
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", fr)
    lbl.Size = UDim2.new(1, -130, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Active = false
    local kb = Instance.new("TextButton", fr)
    kb.Size = UDim2.new(0, 100, 0, 24)
    kb.Position = UDim2.new(1, -110, 0.5, -12)
    kb.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    kb.Text = getter().Name
    kb.TextColor3 = Color3.new(1,1,1)
    kb.Font = Enum.Font.GothamBold
    kb.TextSize = 11
    kb.BorderSizePixel = 0
    Instance.new("UICorner", kb).CornerRadius = UDim.new(0, 6)
    local listening = false
    local listenerConn
    local function stop()
        listening = false
        kb.Text = getter().Name
        kb.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        if listenerConn then listenerConn:Disconnect() listenerConn = nil end
    end
    kb.MouseButton1Click:Connect(function()
        if listening then stop() return end
        listening = true
        kb.Text = "Press..."
        kb.BackgroundColor3 = Config.AccentColor
        listenerConn = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                setter(input.KeyCode)
                saveSettings()
                stop()
                Notify("Keybind", text .. " -> " .. input.KeyCode.Name, 2)
            end
        end)
    end)
end

AddKeybind(SettingsTab, "Menu Key", 1, function() return Config.MenuKey end, function(k) Config.MenuKey = k end)
sectionLabel(SettingsTab, "ICON", 2)
local setIconVisible = AddToggle(SettingsTab, "Show Icon", 3, function(s)
    Config.IconVisible = s
    if IconBtn then IconBtn.Visible = s end
end)
sectionLabel(SettingsTab, "MENU SIZE", 4)
local setTransparency = AddSlider(SettingsTab, "Transparency %", 5, 0, 80, math.floor(Config.Transparency*100), "%.0f%%", function(v)
    Config.Transparency = v/100
    Main.BackgroundTransparency = Config.Transparency
end)
local setMenuWidth = AddSlider(SettingsTab, "Width", 6, 300, 700, Config.MenuWidth, "%d px", function(v)
    Config.MenuWidth = v
    Main.Size = UDim2.new(0, v, 0, Main.Size.Y.Offset)
end)
local setMenuHeight = AddSlider(SettingsTab, "Height", 7, 400, 800, Config.MenuHeight, "%d px", function(v)
    Config.MenuHeight = v
    Main.Size = UDim2.new(0, Main.Size.X.Offset, 0, v)
end)
sectionLabel(SettingsTab, "CUSTOM COLOR", 8)
local setR = AddSlider(SettingsTab, "Red", 9, 0, 255, Config.AccentR, "%d", function(v) Config.AccentR = v; updateAccentFromRGB(); applyAccent() end)
local setG = AddSlider(SettingsTab, "Green", 10, 0, 255, Config.AccentG, "%d", function(v) Config.AccentG = v; updateAccentFromRGB(); applyAccent() end)
local setB = AddSlider(SettingsTab, "Blue", 11, 0, 255, Config.AccentB, "%d", function(v) Config.AccentB = v; updateAccentFromRGB(); applyAccent() end)

local function applyAccent()
    local c = Config.AccentColor
    Title.TextColor3 = c
    dot.BackgroundColor3 = c
    for n, btn in pairs(TabBtns) do
        if TabFrames[n].Visible then btn.BackgroundColor3 = c end
    end
    if IconBtn then IconBtn.TextColor3 = c end
    if IconStroke then IconStroke.Color = c end
end

-- Restore saved settings
if Saved then
    if Saved.FlyEnabled then setFly(true, true); API.SetFly(true) end
    if Saved.SpeedEnabled then setSpeed(true, true); API.SetSpeed(true, Config.SpeedValue) end
    if Saved.NoclipEnabled then setNoclip(true, true); API.SetNoclip(true) end
    if Saved.InfJumpEnabled then setInfJump(true, true); API.SetInfJump(true) end
    if Saved.ESPEnabled then setESP(true, true); API.SetESP(true) end
    if Saved.ESPShowName ~= nil then setESPName(Saved.ESPShowName, true) end
    if Saved.ESPShowDist ~= nil then setESPDist(Saved.ESPShowDist, true) end
    if Saved.ESPShowHP ~= nil then setESPHP(Saved.ESPShowHP, true) end
    if Saved.FullbrightEnabled then setFullbright(true, true); API.SetFullbright(true) end
    if Saved.AntiGrabEnabled then setAntiGrab(true, true); API.SetAntiGrab(true) end
    if Saved.AntiKickGrabEnabled then setAntiKickGrab(true, true); API.SetAntiKickGrab(true) end
    if Saved.AntiExplosionEnabled then setAntiExplosion(true, true); API.SetAntiExplosion(true) end
    if Saved.SelfDefenseEnabled then setSelfDefense(true, true); API.SetSelfDefense(true) end
    if Saved.AntiFlingEnabled then setAntiFling(true, true) end
    if Saved.StrengthEnabled then setStrength(true, true); API.SetStrength(true) end
    if Saved.MenuWidth then setMenuWidth(Saved.MenuWidth, true); Main.Size = UDim2.new(0, Saved.MenuWidth, 0, Main.Size.Y.Offset) end
    if Saved.MenuHeight then setMenuHeight(Saved.MenuHeight, true); Main.Size = UDim2.new(0, Main.Size.X.Offset, 0, Saved.MenuHeight) end
    if Saved.Transparency then setTransparency(math.floor(Saved.Transparency*100), true); Main.BackgroundTransparency = Saved.Transparency end
    if Saved.IconVisible ~= nil then setIconVisible(Saved.IconVisible, true) end
    if Saved.AccentR then setR(Saved.AccentR, true) end
    if Saved.AccentG then setG(Saved.AccentG, true) end
    if Saved.AccentB then setB(Saved.AccentB, true) end
    updateAccentFromRGB()
    applyAccent()
end

-- Floating icon
local FloatingIcon = Instance.new("ScreenGui")
FloatingIcon.Name = "Foxude_Icon"
FloatingIcon.ResetOnSpawn = false
FloatingIcon.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FloatingIcon.Parent = CoreGui

local IconBtn = Instance.new("TextButton")
IconBtn.Size = UDim2.new(0, 52, 0, 52)
IconBtn.Position = UDim2.new(0, Config.IconPosX or 30, 0, Config.IconPosY or 300)
IconBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
IconBtn.Text = "F"
IconBtn.TextColor3 = Config.AccentColor
IconBtn.Font = Enum.Font.GothamBold
IconBtn.TextSize = 22
IconBtn.AutoButtonColor = false
IconBtn.Active = true
IconBtn.Draggable = false
IconBtn.BorderSizePixel = 0
IconBtn.Visible = Config.IconVisible ~= false
IconBtn.Parent = FloatingIcon
Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(0, 26)

local IconStroke = Instance.new("UIStroke", IconBtn)
IconStroke.Thickness = 2
IconStroke.Color = Config.AccentColor
IconStroke.Transparency = 0.3

local iconDragging, iconDragStart, iconStartPos, iconWasDragged = false, nil, nil, false
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
        if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then iconWasDragged = true end
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

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Config.MenuKey then
        Gui.Enabled = not Gui.Enabled
    end
    if inp.KeyCode == Enum.KeyCode.Q and not Gui.Enabled then
        API.Grab("Spin")
    end
    if inp.KeyCode == Enum.KeyCode.E and not Gui.Enabled then
        API.Release()
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.8)
    if Config.SpeedEnabled then API.SetSpeed(true, Config.SpeedValue) end
    if Config.FlyEnabled then API.SetFly(true) end
    if Config.ESPEnabled then API.SetESP(true) end
    if Config.NoclipEnabled then API.SetNoclip(true) end
    if Config.AntiExplosionEnabled then API.SetAntiExplosion(true) end
    clearGrab()
end)

task.spawn(function()
    while Gui.Parent do
        task.wait(5)
        saveSettings()
    end
end)

switchTab("Grab")
Notify("Foxude v7", "loaded. RC - menu, Q - grab, E - release", 5)
print("-[(Foxude) v7 ready]-")
