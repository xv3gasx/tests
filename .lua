-- WindUI Loader
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:Notify({
    Title = "Load Successful ^^",
    Content = "Join Discord For More Scripts/Updates",
    Duration = 3,
    Icon = "swords",
})

-- Window
local Window = WindUI:CreateWindow({
    Title = "Murder Mystery 2 Script",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 390),
    Folder = "GUI",
    AutoScale = false
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
    Keybind = Enum.KeyCode.RightShift
})

-- Tabs
local ESP_Tab = Window:Tab({ Title = "ESP", Icon = "app-window" })
local TP_Tab = Window:Tab({ Title = "TP", Icon = "zap" })
local Local_Tab = Window:Tab({ Title = "Local Player", Icon = "user" })

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Globals
_G.ESPEnabled = false
_G.WalkSpeedValue = 16
_G.InfiniteJumpEnabled = false
_G.NoclipEnabled = false

-- Colors
local colors = {Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0)}

-- Role Detection
local function detectRole(player)
    local role = "Innocent"
    pcall(function()
        if player:FindFirstChild("Backpack") then
            if player.Backpack:FindFirstChild("Knife") then role="Murderer"
            elseif player.Backpack:FindFirstChild("Gun") then role="Sheriff" end
        end
        local char = player.Character
        if char then
            for _,tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    if tool.Name=="Knife" then role="Murderer"
                    elseif tool.Name=="Gun" then role="Sheriff" end
                end
            end
        end
    end)
    return role
end

-- ESP: Highlight Only
local ESP = {}
local function AddESP(player)
    if player==LocalPlayer or ESP[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name="ESP_Highlight"
    highlight.FillTransparency=0
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled=false
    ESP[player] = {Highlight=highlight}

    player.CharacterAdded:Connect(function(char)
        pcall(function()
            highlight.Parent = char
            highlight.Adornee = char
            if _G.ESPEnabled then
                highlight.FillColor = colors[detectRole(player)]
                highlight.Enabled = true
            end
        end)
    end)

    if player.Character then
        pcall(function()
            highlight.Parent = player.Character
            highlight.Adornee = player.Character
            if _G.ESPEnabled then
                highlight.FillColor = colors[detectRole(player)]
                highlight.Enabled = true
            end
        end)
    end
end

local function RemoveESP(player)
    if ESP[player] and ESP[player].Highlight then
        pcall(function() ESP[player].Highlight:Destroy() end)
        ESP[player]=nil
    end
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _,p in pairs(Players:GetPlayers()) do AddESP(p) end

-- Teleports
local function teleportBehind(target)
    pcall(function()
        local hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myHRP then
            local backPos = hrp.Position - (hrp.CFrame.LookVector * 8)
            myHRP.CFrame = CFrame.new(backPos, hrp.Position)
        end
    end)
end

local function getSheriff()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local hasGun = p.Backpack:FindFirstChild("Gun") or (p.Character and p.Character:FindFirstChild("Gun"))
            if hasGun then return p end
        end
    end
end

local function getMurderer()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local hasKnife = p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife"))
            if hasKnife then return p end
        end
    end
end

-- WalkSpeed
local function setWalkSpeed()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= _G.WalkSpeedValue then
            hum.WalkSpeed = _G.WalkSpeedValue
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5) setWalkSpeed() end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if _G.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _,part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- TP Buttons
TP_Tab:Button({Title="Teleport to Murderer",Callback=function()
    local m = getMurderer()
    if m then teleportBehind(m)
    else WindUI:Notify({Title="Murderer Not Found",Content="Wait for match.",Duration=3,Icon="x"})
    end
end})

TP_Tab:Button({Title="Teleport to Sheriff",Callback=function()
    local s = getSheriff()
    if s then teleportBehind(s)
    else WindUI:Notify({Title="Sheriff Not Found",Content="Wait for match.",Duration=3,Icon="x"})
    end
end})

-- ESP Toggle
ESP_Tab:Toggle({Title="Player ESP",Default=false,Callback=function(state)
    _G.ESPEnabled = state
    for player,data in pairs(ESP) do
        if data.Highlight then
            pcall(function()
                data.Highlight.Enabled = state
                if state then
                    data.Highlight.FillColor = colors[detectRole(player)]
                end
            end)
        end
    end
end})

-- Local Player Controls
Local_Tab:Slider({Title="WalkSpeed",Step=1,Value={Min=16,Max=100,Default=16},Callback=function(val)
    _G.WalkSpeedValue = val
    setWalkSpeed()
end})

Local_Tab:Toggle({Title="Infinite Jump",Default=false,Callback=function(state)
    _G.InfiniteJumpEnabled = state
end})

Local_Tab:Toggle({Title="Noclip",Default=false,Callback=function(state)
    _G.NoclipEnabled = state
end})