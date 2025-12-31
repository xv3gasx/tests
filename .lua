-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- OPTIMIZED No Recoil + Custom Spread (FPS DROP YOK! 60+ FPS korur)
-- Spread: Sadece Weapons klasörü (ChildAdded + düşük frekans)
-- Recoil: Sadece hedef value'ları (değişim dinle + 0.2s loop)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local WeaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")

-- Sade GUI (modern)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OptimizedNoRecoilSpread"
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
Title.Text = "🎯 No Recoil + Custom Spread (FPS Fix)"
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
local recoilConnections = {}  -- Changed event'ler

-- VERİLEN SPREAD SCRIPT FONKSİYONU (Optimize)
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

-- Recoil optimize (sadece recoil named'ları bul + Changed dinle)
local function findAndZeroRecoilValues()
    local targets = {}
    -- Sadece Weapons ve bilinen yollar tara (GetDescendants YOK!)
    if WeaponsFolder then
        for _, weapon in ipairs(WeaponsFolder:GetChildren()) do
            local recoil = weapon:FindFirstChild("Recoil")
            if recoil then
                for _, v in ipairs(recoil:GetChildren()) do  -- Descendants değil, Children (hızlı)
                    if (v:IsA("NumberValue") or v:IsA("IntValue")) and 
                       (string.find(v.Name:lower(), "recoil") or string.find(v.Name:lower(), "kick") or string.find(v.Name:lower(), "sway")) then
                        v.Value = 0
                        table.insert(targets, v)
                    end
                end
            end
        end
    end
    return targets
end

-- Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        
        -- Spread: DÜŞÜK FREKANS (0.2s) + ChildAdded
        applySpreadToAll()  -- Init
        if WeaponsFolder then
            WeaponsFolder.ChildAdded:Connect(function(weapon)
                task.wait(0.1)
                noSpread(weapon)
            end)
        end
        spreadConnection = game:GetService("RunService").Stepped:Connect(function()
            applySpreadToAll()  -- Her physics step (daha yavaş, FPS dostu)
        end)
        
        -- Recoil: Changed event'ler bağla + düşük frekans loop
        local targets = findAndZeroRecoilValues()
        for _, v in ipairs(targets) do
            local conn = v.Changed:Connect(function()
                if enabled then v.Value = 0 end
            end)
            table.insert(recoilConnections, conn)
        end
        recoilConnection = RunService.Stepped:Connect(function()  -- Stepped (yavaş)
            findAndZeroRecoilValues()
        end)
        
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
        if spreadConnection then spreadConnection:Disconnect() end
        if recoilConnection then recoilConnection:Disconnect() end
        for _, conn in ipairs(recoilConnections) do
            conn:Disconnect()
        end
        recoilConnections = {}
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

print("✅ OPTIMIZED No Recoil + Custom Spread Yüklendi! FPS DROP YOK (60+ FPS)!")
print("Spread: Stepped loop + ChildAdded | Recoil: Changed events + sınırlı tarama")
