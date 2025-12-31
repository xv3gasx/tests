-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- COUNTER BLOX ÖZEL NO RECOIL + VERİLEN SPREAD SCRIPT (KOŞARKEN DA ÇALIŞIR!)
-- Spread: Tam verilen script gibi (Weapons.Spread NumberValue'lar 0)
-- Recoil: Sürekli Recoil/Kick/Sway 0 + RenderStepped reset

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local WeaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")

-- Sade GUI (modern)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoRecoilCustomSpreadGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 80)
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
Title.Text = "🎯 No Recoil + Custom Spread"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "KAPALI"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18
ToggleBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- Durum
local enabled = false
local spreadConnection
local recoilConnection

-- VERİLEN SPREAD SCRIPT FONKSİYONU (Tam kopya + geliştirilmiş)
local function noSpread(weapon)
    local spread = weapon:FindFirstChild("Spread")
    if spread then
        for _, v in ipairs(spread:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                v.Value = 0
            end
        end
    end
end

local function applySpreadToAll()
    if WeaponsFolder then
        for _, weapon in ipairs(WeaponsFolder:GetChildren()) do
            noSpread(weapon)
        end
    end
end

-- Recoil sıfırlama (Koşarken çalışan - ReplicatedStorage tarama + RenderStepped)
local function applyNoRecoil()
    -- ReplicatedStorage'de recoil named value'ları sıfırla
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and (string.find(v.Name:lower(), "recoil") or string.find(v.Name:lower(), "kick") or string.find(v.Name:lower(), "sway")) then
            v.Value = 0
        end
    end
    -- Weapons'te de recoil ara
    if WeaponsFolder then
        for _, weapon in ipairs(WeaponsFolder:GetChildren()) do
            pcall(function()
                local recoil = weapon:FindFirstChild("Recoil")
                if recoil then
                    for _, val in ipairs(recoil:GetDescendants()) do
                        if val:IsA("NumberValue") or val:IsA("IntValue") then
                            val.Value = 0
                        end
                    end
                end
            end)
        end
    end
end

-- Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        
        -- Spread Loop (0.1s'de tüm Weapons.Spread sıfırla - KOŞARKEN DA!)
        spreadConnection = RunService.Heartbeat:Connect(function()
            applySpreadToAll()
        end)
        
        -- Recoil Loop (Her frame sıfırla - taş gibi!)
        recoilConnection = RunService.RenderStepped:Connect(function()
            applyNoRecoil()
        end)
        
        -- Init uygula
        applySpreadToAll()
        applyNoRecoil()
        
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
        if spreadConnection then spreadConnection:Disconnect() end
        if recoilConnection then recoilConnection:Disconnect() end
    end
end)

-- Yeni silah gelince otomatik uygula
if WeaponsFolder then
    WeaponsFolder.ChildAdded:Connect(function(weapon)
        if enabled then
            task.wait(0.1)
            noSpread(weapon)
            applyNoRecoil()
        end
    end)
end

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

print("✅ Custom Spread + No Recoil Yüklendi! AÇIK yap → Koşarken spread/recoil YOK!")
print("Spread: Tam verdiğin script gibi (Weapons.Spread 0) | Recoil: Sürekli sıfırlama")
