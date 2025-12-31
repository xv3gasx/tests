local ALLOWED_PLACEID = 301549746

if game.PlaceId ~= ALLOWED_PLACEID then
    game:GetService("Players").LocalPlayer:Kick(
        "Unsupported game. If you think this is a mistake, contact us: discord.gg/kxYEUeARvA"
    )
    return
end

-- WindUI Loader
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
    Title = "discord.gg/kxYEUeARvA",
    Content = "Click G to open menu",
    Duration = 3,
    Icon = "check"
})

local Window = WindUI:CreateWindow({
    Title = "Visual Fixes",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(320, 180),
    Folder = "VisualFixes",
    AutoScale = true
})
Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Draggable = true
})

-- Visual Fixes tab
local Visual_Tab = Window:Tab({Title="Visual Fixes", Icon="eye-off"})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Toggles
local REMOVE_FOG = false
local REMOVE_FLASH = false

Visual_Tab:Toggle({
    Title = "Remove Fog",
    Callback = function(v)
        REMOVE_FOG = v
        if REMOVE_FOG then
            local lighting = game:GetService("Lighting")
            lighting.FogEnd = 100000
            lighting.FogStart = 0
        end
    end
})

Visual_Tab:Toggle({
    Title = "Remove Flashbang",
    Callback = function(v)
        REMOVE_FLASH = v
    end
})

-- RenderStepped loop
RunService.RenderStepped:Connect(function()
    -- Remove Fog
    if REMOVE_FOG then
        local lighting = game:GetService("Lighting")
        lighting.FogEnd = 100000
        lighting.FogStart = 0
    end

    -- Remove Flashbang / Screen effects
    if REMOVE_FLASH then
        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGui then
            for _, gui in pairs(PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    for _, obj in pairs(gui:GetDescendants()) do
                        if obj:IsA("Frame") or obj:IsA("ImageLabel") then
                            obj.Visible = false
                        end
                    end
                end
            end
        end
    end
end)