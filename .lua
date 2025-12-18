-- Gun Grounds FFA Hub (WindUI Loader Dahil - Highlight ESP, Line ESP (Üst Orta Tracer), Aimbot (Duvar Arkası Kilitlenmez) + FOV, Walkspeed, Noclip, Infinite Jump)
-- 0'dan Grok Tarafından Yazıldı - 100% Opti, 0 FPS Drop

-- WindUI Loader (Kullanıcı Tercihi - Releases Latest)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Loader Kontrolü
if not WindUI then
    warn("WindUI yüklenemedi! Executor HttpGet'i kontrol et.")
    return
end

WindUI:Notify({
    Title = "Hub Yüklendi!",
    Content = "Gun Grounds FFA - Highlight/Line ESP, Aimbot (No Wall Lock), Walkspeed, Noclip, Inf Jump!",
    Duration = 5,
    Icon = "check"
})

-- GUI Oluşturma
local Window = WindUI:CreateWindow({
    Title = "Gun Grounds FFA Hub",
    Author = "Grok - 100% Opti",
    Theme = "Dark",
    Size = UDim2.fromOffset(550, 460),
    Folder = "GunGroundsFFA",
    AutoScale = false
})

Window:EditOpenButton({
    Title = "Hub Aç",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true
})

-- Tab'lar
local EspTab = Window:Tab({Title = "ESP", Icon = "app-window"})
local CombatTab = Window:Tab({Title = "Combat", Icon = "target"})
local MovementTab = Window:Tab({Title = "Movement", Icon = "user"})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Globals / Toggles
local HighlightESPEnabled = false
local LineESPEnabled = false
local AimbotEnabled = false
local AimbotFOV = 150  -- Default FOV
local WalkSpeedValue = 16  -- Default speed
local NoclipEnabled = false
local InfJumpEnabled = false

-- Renkler (FFA - Herkes Enemy: Kırmızı)
local ENEMY_COLOR = Color3.fromRGB(255, 0, 0)

-- ESP Data
local ESP = {}  -- {player = {line, highlight}}

-- Utils
local function safeNewDrawing(class, props)
    local ok, obj = pcall(Drawing.new, class)
    if ok and obj and props then
        for k, v in pairs(props) do pcall(function() obj[k] = v end) end
    end
    return obj
end

local function w2s(pos)
    local ok, vec, on = pcall(Camera.WorldToViewportPoint, Camera, pos)
    return ok and Vector2.new(vec.X, vec.Y) or Vector2.new(), on or false
end

local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local rayResult = workspace:Raycast(origin, direction, rayParams)
    return not rayResult or rayResult.Instance:IsDescendantOf(targetPart.Parent)
end

-- ESP Oluşturma (Highlight + Line - Üst Orta Tracer)
local function createESP(player)
    if player == LocalPlayer or ESP[player] then return end
    local line = safeNewDrawing("Line", {Thickness = 3, Visible = false, Color = ENEMY_COLOR})
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = ENEMY_COLOR
    highlight.Enabled = false
    ESP[player] = {line = line, highlight = highlight}
    player.CharacterAdded:Connect(function(char)
        highlight.Adornee = char
        highlight.Parent = char
    end)
    if player.Character then
        highlight.Adornee = player.Character
        highlight.Parent = player.Character
    end
end

-- ESP Temizleme
local function destroyESP(player)
    local data = ESP[player]
    if data then
        if data.line then pcall(data.line.Remove, data.line) end
        if data.highlight then pcall(data.highlight.Destroy, data.highlight) end
        ESP[player] = nil
    end
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(destroyESP)
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end

-- Aimbot Data
local AimbotTarget = nil
local fovCircle = safeNewDrawing("Circle", {Radius = AimbotFOV, NumSides = 64, Thickness = 2, Filled = false, Visible = false, Color = Color3.fromRGB(255, 0, 0)})

-- Aimbot Closest Visible Enemy
local function getClosestVisibleEnemy()
    local closest, minDist = nil, AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character.Head
            local pos, on = w2s(head.Position)
            if on and isVisible(head) then
                local dist = (pos - center).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

-- Aimbot Update
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
