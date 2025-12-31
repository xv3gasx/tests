-- LocalScript (Executor ile çalıştır - Synapse/Krnl vs.)
-- COUNTER BLOX ÖZEL %100 NO RECOIL + NO SPREAD (KOŞARKEN DA ÇALIŞIR!)
-- cbClient hook + RenderStep ile client-side tam kontrol

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Sade GUI (modern)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltimateNoRecoilSpread"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 80)
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
Title.Text = "🎯 No Recoil + No Spread (Koşu Dahil)"
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
local noRecoilConnection
local oldIndex

-- cbClient bul (Counter Blox client environment)
local ClientGui = player.PlayerGui:WaitForChild("Client", 10)
local cbClient = getsenv and getsenv(ClientGui) or nil

if not cbClient then
    -- Fallback: ReplicatedStorage loop (eğer cbClient yoksa)
    warn("cbClient bulunamadı! ReplicatedStorage fallback kullanılıyor.")
end

-- No Spread Hook (__index ile Spread/Accuracy her zaman 0 dön)
local function applyNoSpreadHook()
    if oldIndex then return end
    oldIndex = hookmetamethod(ClientGui, "__index", function(self, idx)
        if idx == "Value" then
            local name = self.Name
            local parentName = self.Parent and self.Parent.Name
            if (name == "Spread" or parentName == "Spread") then
                return 0
            elseif name == "AccuracyDivisor" or name == "AccuracyOffset" then
                return 0.001
            end
        end
        return oldIndex(self, idx)
    end)
end

-- No Recoil RenderStep (RecoilX/Y sıfırla + resetaccuracy)
local function applyNoRecoil()
    if noRecoilConnection then return end
    noRecoilConnection = RunService:BindToRenderStep("NoRecoil", Enum.RenderPriority.Camera.Value + 1, function()
        if cbClient then
            pcall(function()
                cbClient.resetaccuracy()
                cbClient.RecoilX = 0
                cbClient.RecoilY = 0
            end)
        end
    end)
end

-- Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        
        -- Hook'ları uygula
        applyNoSpreadHook()
        applyNoRecoil()
        
        -- Fallback: ReplicatedStorage sürekli sıfırla (koşu için ekstra)
        spawn(function()
            while enabled do
                for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if (v:IsA("NumberValue") or v:IsA("IntValue")) and (string.find(v.Name:lower(), "spread") or string.find(v.Name:lower(), "recoil") or string.find(v.Name:lower(), "kick") or string.find(v.Name:lower(), "accuracy")) then
                        v.Value = 0
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
        -- Temizle
        if noRecoilConnection then
            RunService:UnbindFromRenderStep("NoRecoil")
            noRecoilConnection = nil
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

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

print("✅ CBlox No Recoil + No Spread (Koşu Fix) Yüklendi! AÇIK yap → Her durumda lazer gibi!")
print("cbClient hook + RenderStep = %100 KOŞARKEN DA ÇALIŞIR!")
