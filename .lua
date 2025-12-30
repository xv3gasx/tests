-- WIND UI LOADER
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)

if not ok or not WindUI then
    warn("WindUI load failed")
    return
end

WindUI:Notify({
    Title = "Auto Shoot Loaded",
    Content = "Stable Auto Shoot (No Camera / No Mouse Bug)",
    Duration = 3,
    Icon = "check"
})

-- WINDOW
local Window = WindUI:CreateWindow({
    Title = "Auto Shoot",
    Author = "by x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(420, 260),
    Folder = "AutoShoot",
    AutoScale = true
})

Window:EditOpenButton({
    Title = "Open Auto Shoot",
    Icon = "crosshair",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Draggable = true
})

-- TAB
local Auto_Tab = Window:Tab({
    Title = "Auto Shoot",
    Icon = "target"
})

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GLOBALS
_G.AUTO_SHOOT = false
_G.SHOT_DELAY = 0.15

-- UI CONTROLS
Auto_Tab:Toggle({
    Title = "Enable Auto Shoot",
    Default = false,
    Callback = function(v)
        _G.AUTO_SHOOT = v
    end
})

Auto_Tab:Slider({
    Title = "Shot Delay",
    Step = 0.01,
    Value = {Min = 0.05, Max = 0.5, Default = 0.15},
    Callback = function(v)
        _G.SHOT_DELAY = v
    end
})

-- FUNCTIONS
local function getGun()
    local char = LocalPlayer.Character
    if not char then return nil end

    for _,v in pairs(char:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then
            return v
        end
    end
end

local function hasTarget()
    local mouse = LocalPlayer:GetMouse()
    return mouse and mouse.Target ~= nil
end

-- AUTO SHOOT LOOP (STABLE)
local lastShot = 0

RunService.Heartbeat:Connect(function()
    if not _G.AUTO_SHOOT then return end
    if tick() - lastShot < _G.SHOT_DELAY then return end
    if not hasTarget() then return end

    local tool = getGun()
    if tool and tool.Activate then
        lastShot = tick()
        tool:Activate()
    end
end)