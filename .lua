-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- %100 ÇALIŞAN MOBİL AUTO SHOOT (Senin Path'ine Özel!)
-- PlayerGui.GUI.Main.Mobile.Shoot ImageButton'a sürekli dokunur/spam tıklar

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Senin Fire Button Path'i (ImageButton)
local shootButton = playerGui:WaitForChild("GUI"):WaitForChild("Main"):WaitForChild("Mobile"):WaitForChild("Shoot")

-- Sade GUI (Sürüklenir Toggle)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileAutoShoot"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 80)
Frame.Position = UDim2.new(0, 20, 0.8, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.Text = "📱 Auto Shoot (Mobil Button)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "KAPALI"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20
ToggleBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- Durum
local enabled = false
local connection

-- Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        
        -- Auto Shoot: Shoot Button ortasına sürekli MOBİL TOUCH SPAM
        connection = RunService.Heartbeat:Connect(function()
            local pos = shootButton.AbsolutePosition + shootButton.AbsoluteSize / 2  -- Button tam ortası
            -- MOBİL TOUCH EVENT (PC'de mobil gibi simüle eder - %100 UI tetikler)
            VirtualInputManager:SendTouchEvent(pos.X, pos.Y, 1, true, 1)   -- Touch down (ID=1)
            task.wait(0.04)  -- Ateş hızı (hızlı ama FPS dostu, değiştir 0.02 yaparsan daha hızlı)
            VirtualInputManager:SendTouchEvent(pos.X, pos.Y, 1, false, 1)  -- Touch up
        end)
        
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        if connection then
            connection:Disconnect()
            connection = nil
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

print("✅ Mobil Auto Shoot Yüklendi! Path: PlayerGui.GUI.Main.Mobile.Shoot")
print("AÇIK yap → Silah al, otomatik spam ateş eder (mobil touch simülasyonu)!")
