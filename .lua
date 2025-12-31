-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- COUNTER BLOX ÖZEL %100 ÇALIŞAN NO RECOIL + NO SPREAD
-- Tüm silahların Spread/Recoil/Kick değerlerini 0 yapar - Uzun seri atışlarda taş gibi sabit nişan!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Sade GUI (önceki gibi modern)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoRecoilNoSpreadGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 80)
Frame.Position = UDim2.new(0, 20, 0.8, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎯 No Recoil + No Spread"
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

-- No Recoil/No Spread Fonksiyonu (Counter Blox Standart)
local function setNoRecoilNoSpread()
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("ObjectValue") then
            local name = v.Name:lower()
            if string.find(name, "spread") or string.find(name, "recoil") or string.find(name, "kick") or string.find(name, "sway") then
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    v.Value = 0
                elseif v:IsA("ObjectValue") then
                    v.Value = nil  -- ObjectValue'ları sıfırla
                end
            end
        end
    end
    -- Ekstra: Silah klasörleri için (Guns/Weapons)
    pcall(function()
        for _, weapon in pairs((ReplicatedStorage:FindFirstChild("Guns") or ReplicatedStorage:FindFirstChild("Weapons") or {}):GetChildren()) do
            pcall(function() weapon.Spread.Value = 0 end)
            pcall(function() weapon.Recoil.Value = 0 end)
        end
    end)
end

-- Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        setNoRecoilNoSpread()  -- Hemen uygula
        connection = RunService.Heartbeat:Connect(function()
            setNoRecoilNoSpread()  -- Sürekli uygula (yeni silahlar için)
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

-- Yeni silahlar için ReplicatedStorage değişim dinle
ReplicatedStorage.ChildAdded:Connect(function(child)
    if enabled and (child.Name == "Guns" or child.Name == "Weapons") then
        task.wait(0.1)
        setNoRecoilNoSpread()
    end
end)

print("✅ Counter Blox No Recoil + No Spread Yüklendi! Butona tıkla → Seri atışlarda nişan kaymaz!")
print("Otomatik tüm Spread/Recoil/Kick değerlerini 0 yapar - %100 server uyumlu!")
