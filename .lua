-- WINDUI LOADER
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
    Content = "Blox Strike Auto Shoot (Silent Aim Friendly)",
    Duration = 3,
    Icon = "check"
})

-- AUTO TAB
local Auto_Tab = Window:Tab({Title="Auto", Icon="bolt"})

-- GLOBAL
_G.AUTO_SHOOT = false

-- Toggle
Auto_Tab:Toggle({
    Title="Auto Shoot",
    Callback=function(v) _G.AUTO_SHOOT=v end
})

-- AUTO SHOOT LOOP
local lastShot = 0
local SHOT_DELAY = 0.08 -- saniye

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

RunService.RenderStepped:Connect(function()
    if _G.AUTO_SHOOT then
        local t = getTarget() -- mevcut getTarget fonksiyonunu kullan
        if t and tick() - lastShot > SHOT_DELAY then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                lastShot = tick()
                pcall(function() tool:Activate() end)
            end
        end
    end
end)