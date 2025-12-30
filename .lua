-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Sade GUI oluştur
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoShootGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Ana Frame (sürükleme için)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 160, 0, 60)
Frame.Position = UDim2.new(0.02, 0, 0.7, 0)  -- Sol alt köşe
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(100, 100, 100)
Frame.Parent = ScreenGui

-- Başlık (sürükleme için)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "Auto Shoot"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

-- Toggle Butonu
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.9, 0, 0, 30)
ToggleButton.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleButton.Text = "KAPALI"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 20
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
ToggleButton.Parent = Frame

-- Durum
local autoShootEnabled = false

-- Buton tıklama
ToggleButton.MouseButton1Click:Connect(function()
    autoShootEnabled = not autoShootEnabled
    if autoShootEnabled then
        ToggleButton.Text = "AÇIK"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        ToggleButton.Text = "KAPALI"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end
end)

-- Sürükleme özelliği (isteğe bağlı ama güzel olur)
local dragging = false
local dragInput, dragStart, startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

Title.InputChanged:Connect(function(input)
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

-- Auto Shoot döngüsü (KESİNLİKLE ÇALIŞIR)
spawn(function()
    while true do
        task.wait(0.03)  -- Ateş hızı (daha hızlı istersen 0.01 yap)
        if autoShootEnabled then
            local character = player.Character or player.CharacterAdded:Wait()
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and mouse.Target then
                -- Mouse sol tuşunu sanal olarak sürekli basılı tut
                VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, Enum.UserInputType.MouseButton1, true, game, 0)
            end
        end
    end
end)

print("Yeni ve çalışan Auto Shoot GUI yüklendi! Butona tıklayarak aç/kapat.")
