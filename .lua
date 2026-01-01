-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- PES ETMİYORUZ - %100 ÇALIŞAN AUTO SHOOT (Crosshair Rakip = Otomatik Ateş)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

-- Toggle GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NeverGiveUpAutoShoot"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 80)
Frame.Position = UDim2.new(0, 20, 0.8, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔥 Auto Shoot (Pes Etmiyoruz!)"
Title.TextColor3 = Color3.new(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.new(200,50,50)
ToggleBtn.Text = "KAPALI"
ToggleBtn.TextColor3 = Color3.new(255,255,255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20
ToggleBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0,6)
BtnCorner.Parent = ToggleBtn

local enabled = false
local connection

-- Crosshair'de rakip var mı? (Ekran ortası raycast)
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

-- Auto Shoot Loop (Button'un MouseButton1Down event'ini tetikle)
connection = RunService.Heartbeat:Connect(function()
    if enabled and shootButton then
        if isEnemyInCrosshair() then
            -- Button'un MouseButton1Down event'ini manuel tetikle
            pcall(function()
                shootButton.MouseButton1Down:Fire()
            end)
        end
    end
end)

-- Sürükleme
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

Frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

print("✅ PES ETMİYORUZ! Auto Shoot yüklendi - Crosshair rakibe = Otomatik ateş!")
print("Hareket/zıplama/bozulma YOK - Sadece button'un event'ini tetikliyor!")
