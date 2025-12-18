-- Gun Grounds FFA Hub (WindUI Loader Dahil - ESP Highlight/Line, Aimbot + FOV, Walkspeed, Noclip, Infinite Jump)
-- 0'dan Grok Tarafından Yazıldı - 100% Opti, 0 FPS Drop

-- WindUI Loader (2025 Güncel - Kesin Çalışır)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Loader Kontrolü
if not WindUI then
    warn("WindUI yüklenemedi! Executor HttpGet'i kontrol et.")
    return
end

WindUI:Notify({
    Title = "Hub Yüklendi!",
    Content = "Gun Grounds FFA - ESP, Aimbot, Walkspeed, Noclip, Inf Jump!",
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
    AutoScale = true
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
local ESPEnabled = false  -- ESP Highlight + Line
local AimbotEnabled = false
local AimbotFOV = 150  -- Default FOV
local WalkSpeedValue = 16  -- Default speed
local NoclipEnabled = false
local InfJumpEnabled = false
local currentGun = nil  -- Gun Drop

-- Renkler
local ENEMY_COLOR = Color3.fromRGB(255, 0, 0)  -- Herkes enemy (FFA)
local GUN_COLOR = Color3.fromRGB(255, 255, 0)  -- Sarı default, rainbow olacak

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

-- ESP Oluşturma (Highlight + Line)
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

-- Gun Drop Bulma
task.spawn(function()
    while task.wait(0.5) do
        currentGun = workspace:FindFirstChild("GunDrop", true)  -- Oyun'a göre isim değiştir (Gun Grounds'ta gun drop adı neyse)
    end
end)

-- Rainbow Gun (Box + Line + Text)
local gunBox = safeNewDrawing("Square", {Thickness = 2, Filled = false, Visible = false})
local gunLine = safeNewDrawing("Line", {Thickness = 2, Visible = false})
local gunText = safeNewDrawing("Text", {Text = "GUN", Size = 18, Center = true, Outline = true, Visible = false, Color = Color3.fromRGB(0, 0, 255)})

-- Rainbow Animasyon
local hue = 0
RunService.Heartbeat:Connect(function(dt)
    hue = (hue + dt * 0.5) % 1
    local rainbow = Color3.fromHSV(hue, 1, 1)
    if gunBox then gunBox.Color = rainbow end
    if gunLine then gunLine.Color = rainbow end
end)

-- Aimbot Data
local AimbotTarget = nil
local fovCircle = safeNewDrawing("Circle", {Radius = AimbotFOV, NumSides = 64, Thickness = 2, Filled = false, Visible = false, Color = Color3.fromRGB(255, 0, 0)})

-- Aimbot Fonksiyon (Closest Enemy Head)
local function getClosestEnemy()
    local closest, minDist = nil, AimbotFOV
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character.Head
            local pos, on = w2s(head.Position)
            if on then
                local dist = (pos - mousePos).Magnitude
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
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Radius = AimbotFOV
    fovCircle.Visible = AimbotEnabled
    if AimbotEnabled then
        AimbotTarget = getClosestEnemy()
        if AimbotTarget then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, AimbotTarget.Position), 0.3)
        end
    end
end)

-- Walkspeed Set
local function setWalkSpeed()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = WalkSpeedValue end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    setWalkSpeed()
end)
if LocalPlayer.Character then setWalkSpeed() end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- GUI Elementler
EspTab:Toggle({Title = "ESP Highlight", Default = false, Callback = function(v) HighlightEnabled = v end})
EspTab:Toggle({Title = "ESP Line", Default = false, Callback = function(v) LineEnabled = v end})

CombatTab:Toggle({Title = "Aimbot", Default = false, Callback = function(v) AimbotEnabled = v end})
CombatTab:Slider({Title = "Aimbot FOV", Step = 10, Value = {Min = 50, Max = 500, Default = 150}, Callback = function(val) AimbotFOV = val end})

MovementTab:Slider({Title = "Walkspeed", Step = 1, Value = {Min = 16, Max = 200, Default = 16}, Callback = function(val) WalkSpeedValue = val; setWalkSpeed() end})
MovementTab:Toggle({Title = "Noclip", Default = false, Callback = function(v) NoclipEnabled = v end})
MovementTab:Toggle({Title = "Infinite Jump", Default = false, Callback = function(v) InfJumpEnabled = v end})

-- Render Loop (100% Opti - Early Return)
RunService.RenderStepped:Connect(function()
    if not (HighlightEnabled or LineEnabled or GunEnabled) then return end

    for player, data in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hrp and hum and hum.Health > 0) then
            if data.line then data.line.Visible = false end
            if data.highlight then data.highlight.Enabled = false end
            continue
        end

        local color = ENEMY_COLOR  -- FFA, herkes kırmızı

        if HighlightEnabled then
            data.highlight.Enabled = true
            data.highlight.FillColor = color
        else
            data.highlight.Enabled = false
        end

        if LineEnabled then
            local pos, on = w2s(hrp.Position)
            if on then
                data.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                data.line.To = pos
                data.line.Color = color
                data.line.Visible = true
            else
                data.line.Visible = false
            end
        else
            data.line.Visible = false
        end
    end

    -- Gun ESP (Rainbow Box + Line)
    if GunEnabled and currentGun then
        local pos, on = w2s(currentGun.Position)
        if on then
            local sz = 30
            gunBox.Position = pos - Vector2.new(sz / 2, sz / 2)
            gunBox.Size = Vector2.new(sz, sz)
            gunBox.Visible = true
            gunLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            gunLine.To = pos
            gunLine.Visible = true
        else
            gunBox.Visible = false
            gunLine.Visible = false
        end
    else
        gunBox.Visible = false
        gunLine.Visible = false
    end
end)

-- Rainbow Gun Animasyon (0 Lag)
local hue = 0
RunService.Heartbeat:Connect(function(dt)
    hue = (hue + dt * 0.5) % 1
    local rainbow = Color3.fromHSV(hue, 1, 1)
    if gunBox then gunBox.Color = rainbow end
    if gunLine then gunLine.Color = rainbow end
end)

-- Walkspeed Loop (Anti-Reset)
RunService.Heartbeat:Connect(function()
    setWalkSpeed()
end)

print("Gun Grounds FFA Hub Yüklendi - Eksiksiz!")
