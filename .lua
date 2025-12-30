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
    Content = "Only Auto Shoot Enabled",
    Duration = 3,
    Icon = "check"
})

-- WINDOW
local Window = WindUI:CreateWindow({
    Title = "Blox Strike",
    Author = "by x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(420, 300),
    Folder = "BloxStrike",
    AutoScale = true
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Draggable = true
})

-- AUTO TAB
local Auto_Tab = Window:Tab({
    Title = "Auto",
    Icon = "zap"
})

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- SETTINGS
_G.AUTO_SHOOT = false
_G.SHOT_DELAY = 0.08

-- UI CONTROLS
Auto_Tab:Toggle({
    Title = "Auto Shoot",
    Default = false,
    Callback = function(v)
        _G.AUTO_SHOOT = v
    end
})

Auto_Tab:Slider({
    Title = "Fire Rate",
    Step = 0.01,
    Value = {Min = 0.03, Max = 0.3, Default = 0.08},
    Callback = function(v)
        _G.SHOT_DELAY = v
    end
})

-- SIMPLE TARGET CHECK (Ekran ortasında düşman varsa)
local function hasTarget()
    local mousePos = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < 35 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- AUTO SHOOT LOOP
local lastShot = 0
RunService.RenderStepped:Connect(function()
    if not _G.AUTO_SHOOT then return end
    if tick() - lastShot < _G.SHOT_DELAY then return end
    if not hasTarget() then return end

    lastShot = tick()

    VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end)