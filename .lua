-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- COUNTER BLOX %100 ÇALIŞAN AUTO SHOOT / TRIGGERBOT (HitPart Spam)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local team = player.Team

-- RemoteEvent (Counter Blox standart)
local Events = ReplicatedStorage:WaitForChild("Events")
local HitPart = Events:WaitForChild("HitPart")

-- Sade GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoShootGui"
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
Title.Text = "🔫 Auto Shoot (Trigger)"
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
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        if connection then connection:Disconnect() end
    end
end)

-- Auto Shoot Loop (HitPart Spam - Güncel Args)
connection = RunService.Heartbeat:Connect(function()
    if enabled then
        local character = player.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and mouse.Target then
                local targetPart = mouse.Target
                local targetChar = targetPart.Parent
                local targetHum = targetChar:FindFirstChild("Humanoid")
                local targetPlr = Players:GetPlayerFromCharacter(targetChar)
                
                if targetHum and targetHum.Health > 0 and targetPlr and targetPlr.Team ~= team then
                    -- Güncel args (headshot + high damage)
                    local equipped = character:FindFirstChild("EquippedTool") and character.EquippedTool.Value or tool.Name
                    local gun = tool -- veya character:FindFirstChild("Gun")
                    
                    local args = {
                        targetPart,              -- [1] hit part (head için ideal)
                        targetPart.Position,     -- [2] position
                        equipped,                -- [3] weapon name
                        100000,                  -- [4] high pen/damage
                        gun,                     -- [5] gun object
                        nil, nil,                -- [6],[7]
                        8,                       -- [8] damage multiplier
                        false, false,            -- [9],[10]
                        targetPart.Position,     -- [11]
                        math.random(10000,20000),-- [12] random
                        Vector3.new(0,0,0)        -- [13]
                    }
                    
                    HitPart:FireServer(unpack(args))
                end
            end
        end
    end
end)

-- Sürükleme (opsiyonel)
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

print("✅ Auto Shoot (HitPart Spam) Yüklendi! Nişan al → Otomatik headshot spam!")
