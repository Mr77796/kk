print("Welcome To Reda Hub")

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

local Window = Library.CreateLib("Reda Hub", "RJTheme1")

local Tab = Window:NewTab("Main")

local Section = Tab:NewSection("All Functions")


Section:NewTextBox("Speed", "Speed", function(s) 
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
 end)


Section:NewTextBox("Gravity", "Gravity", function(g) 
    game.Workspace.Gravity = g
 end)


Section:NewTextBox("JumpPower", "JumpPower", function(j) 
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = j
 end)


 Section:NewTextBox("Size", "Size", function(z) 
    game.Players.LocalPlayer.Character.Humanoid.HipHeight = z
 end)


 Section:NewTextBox("print", "you can talk with all with develop log", function(p)
   print(p)
end)


Section:NewButton("Dex", "Dex", function()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/memeenjoyer43/darkdex/refs/heads/main/script"))()
end)


Section:NewButton("Fly Gui V3", "Fly Gui V3", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
end)


Section:NewButton("Infinity Yield", "Infinity Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)


Section:NewButton("Animations", "Animations 7yd7", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"))()
end)


Section:NewButton("Esp", "Esp", function()
while wait(0.5) do
    for i, childrik in ipairs(workspace:GetDescendants()) do
        if childrik:FindFirstChild("Humanoid") then
            if not childrik:FindFirstChild("EspBox") then
                if childrik ~= game.Players.LocalPlayer.Character then
                    local esp = Instance.new("BoxHandleAdornment",childrik)
                    esp.Adornee = childrik
                    esp.ZIndex = 0
                    esp.Size = Vector3.new(5, 5, 5)
                    esp.Transparency = 0.65
                    esp.Color3 = Color3.fromRGB(255,48,48)
                    esp.AlwaysOnTop = true
                    esp.Name = "EspBox"
                end
            end
        end
    end
end
end)
