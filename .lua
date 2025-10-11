-- WindUI Loader
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI load failed") end

-- Notification
WindUI:Notify({
    Title = "Kill Aura Loaded",
    Content = "Use menu to toggle",
    Duration = 3,
    Icon = "skull"
})

-- Window
local Window = WindUI:CreateWindow({
    Title = "Murder Mystery 2 - Smooth Kill Aura",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(520, 340),
    Folder = "KillAuraUI",
    AutoScale = false
})

local Tab = Window:Tab({
    Title = "Kill Aura",
    Icon = "sword"
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local KnifeAuraEnabled = false

-- Knife Check / Force Equip
local function ensureKnife()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "Knife" then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack and backpack:FindFirstChild("Knife") then
            LocalPlayer.Character.Humanoid:EquipTool(backpack.Knife)
        end
    end
end

-- Get closest player (within 500 studs)
local function getClosestPlayer()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local closest, minDist = nil, 500
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < minDist then
                    closest = p
                    minDist = dist
                end
            end
        end
    end
    return closest
end

-- Smooth movement function
local function moveSmooth(target)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local distance = (hrp.Position - target.Position).Magnitude
    local tweenTime = math.clamp(distance / 60, 0.05, 0.4) -- hız ayarı

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {CFrame = CFrame.new(target.Position)}
    )
    tween:Play()
end

-- Main Loop
task.spawn(function()
    while task.wait(0.1) do
        if KnifeAuraEnabled then
            ensureKnife()
            local targetPlayer = getClosestPlayer()
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = targetPlayer.Character.HumanoidRootPart
                moveSmooth(hrp)
            end
        end
    end
end)

-- WindUI Toggle
Tab:Toggle({
    Title = "Enable Smooth Kill Aura",
    Default = false,
    Callback = function(state)
        KnifeAuraEnabled = state
        if state then
            WindUI:Notify({
                Title = "Kill Aura Active",
                Content = "Smoothly moving to targets...",
                Duration = 3,
                Icon = "zap"
            })
        else
            WindUI:Notify({
                Title = "Kill Aura Disabled",
                Content = "Stopped.",
                Duration = 3,
                Icon = "square"
            })
        end
    end
})