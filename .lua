-- Auto Shoot Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Remote
local ReplicateShot = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ReplicateShot")

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0, 100)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.Text = "Auto Shoot: OFF"
ToggleButton.Parent = ScreenGui

local AutoShootEnabled = false

ToggleButton.MouseButton1Click:Connect(function()
    AutoShootEnabled = not AutoShootEnabled
    ToggleButton.Text = "Auto Shoot: " .. (AutoShootEnabled and "ON" or "OFF")
end)

-- Auto Shoot Loop
spawn(function()
    while true do
        if AutoShootEnabled then
            pcall(function()
                ReplicateShot:FireServer()
            end)
        end
        task.wait(0.1) -- Ateş hızı
    end
end)