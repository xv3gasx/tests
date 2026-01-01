-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- İLK YÖNTEM AMA CROSSHAIR RAKİP KONTROLÜ İLE (Kontroller bozar ama çalışır!)

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- Shoot button'ı bul (senin path)
local shootButton = nil
spawn(function()
    while not shootButton do
        local gui = playerGui:FindFirstChild("GUI")
        if gui and gui:IsA("ScreenGui") then
            local mobile = gui:FindFirstChild("Mobile")
            if mobile and mobile:IsA("Frame") then
                local shoot = mobile:FindFirstChild("Shoot")
                if shoot and shoot:IsA("ImageButton") then
                    shootButton = shoot
                    print("✅ SHOOT BUTTON BULUNDU:", shootButton:GetFullName())
                    break
                end
            end
        end
        task.wait(1)
    end
end)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrosshairAutoShoot"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 90)
Frame.Position = UDim2.new(0, 20, 0.8, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔫 Crosshair Auto Shoot"
Title.TextColor3 = Color3.new(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.new(200,50,50)
ToggleBtn.Text = "KAPALI"
ToggleBtn.TextColor3 = Color3.new(255,255,255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18
ToggleBtn.Parent = Frame

local Warning = Instance.new("TextLabel")
Warning.Size = UDim2.new(0.9, 0, 0.25, 0)
Warning.Position = UDim2.new(0.05, 0, 0.75, 0)
Warning.BackgroundTransparency = 1
Warning.Text = "⚠️ Kontroller bozulur!"
Warning.TextColor3 = Color3.new(255,200,0)
Warning.Font = Enum.Font.Gotham
Warning.TextSize = 14
Warning.Parent = Frame

local enabled = false
local connection

-- Crosshair'de rakip var mı?
local function isEnemyInCrosshair()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local centerRay = camera:ScreenPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(centerRay.Origin, centerRay.Direction * 1000, params)
    if result then
        local hitChar = result.Instance.Parent
        local hum = hitChar:FindFirstChild("Humanoid")
        local plr = Players:GetPlayerFromCharacter(hitChar)
        return hum and hum.Health > 0 and plr and plr ~= player and plr.Team ~= player.Team
    end
    return false
end

-- Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    if not shootButton then
        print("Shoot button bekleniyor...")
        return
    end
    
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.new(50,200,50)
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.new(200,50,50)
        if connection then connection:Disconnect() end
    end
end)

-- Auto Shoot (Sadece crosshair rakipse ateş!)
connection = RunService.Heartbeat:Connect(function()
    if enabled and shootButton and isEnemyInCrosshair() then
        local pos = shootButton.AbsolutePosition + shootButton.AbsoluteSize / 2
        -- İLK YÖNTEM: Sürekli mouse spam (kontroller bozar ama çalışır!)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.wait(0.03)  -- Hızlı ateş
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
    end
end)

print("✅ CROSSHAIR AUTO SHOOT YÜKLENDİ! Rakip ortadaysa spam ateş eder!")
print("⚠️ UYARI: Kontroller bozulur ama %100 çalışır!")
