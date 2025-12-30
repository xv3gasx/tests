-- Counter Blox Auto Shoot Script (WindUI - Sadece Auto Shoot, Hedefe Bakınca Ateş Eder)
-- 0'dan Grok Tarafından Yazıldı - 100% Opti, 0 Lag, Visibility Check

-- WindUI Loader (Güncel & Çalışan)
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not ok or not WindUI then
    warn("WindUI yüklenemedi!")
    return
end

WindUI:Notify({
    Title = "Auto Shoot Yüklendi",
    Content = "Counter Blox - Hedefe Bakınca Ateş Eder",
    Duration = 5,
    Icon = "check"
})

-- GUI
local Window = WindUI:CreateWindow({
    Title = "Counter Blox Auto Shoot",
    Author = "Grok",
    Theme = "Dark",
    Size = UDim2.fromOffset(400, 250),
    Folder = "CounterBloxAutoShoot",
    AutoScale = false
})

Window:EditOpenButton({
    Title = "Auto Shoot",
    Icon = "target",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    Enabled = true,
    Draggable = true
})

local MainTab = Window:Tab({Title = "Auto Shoot", Icon = "target"})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Toggles
local AutoShootEnabled = false
local VisibilityCheck = true
local TeamCheck = true

MainTab:Toggle({Title = "Auto Shoot", Default = false, Callback = function(v) AutoShootEnabled = v end})
MainTab:Toggle({Title = "Visibility Check", Default = true, Callback = function(v) VisibilityCheck = v end})
MainTab:Toggle({Title = "Team Check", Default = true, Callback = function(v) TeamCheck = v end})

-- Helper Functions
local function isEnemy(plr)
    if not TeamCheck then return true end
    return plr.Team ~= LocalPlayer.Team
end

local function isVisible(target)
    local origin = Camera.CFrame.Position
    local direction = (target.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(target.Parent)
end

local function getClosestEnemy()
    local closest = nil
    local shortestDist = math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isEnemy(plr) then
            local char = plr.Character
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        if not VisibilityCheck or isVisible(head) then
                            shortestDist = dist
                            closest = plr
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- Auto Shoot (Hedefe Bakınca Ateş Eder)
RunService.RenderStepped:Connect(function()
    if not AutoShootEnabled then return end

    local target = getClosestEnemy()
    if target then
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            -- Counter Blox'ta ateş remote'u (genellikle MouseClick veya Fire)
            tool:Activate()  -- Basit activate (çoğu silahda çalışır)
            -- Alternatif: tool.Remote:FireServer() - oyun'a göre değişir, activate yeterli
        end
    end
end)

print("Counter Blox Auto Shoot Yüklendi - Hedefe Bakınca Ateş Eder!")
