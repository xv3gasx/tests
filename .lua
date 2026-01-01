-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- MOBİL AUTO SHOOT (Hata Düzeltildi + Otomatik Path Bekle)

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Shoot Button Path (Senin verdiğin)
local shootButton
pcall(function()
    shootButton = playerGui:WaitForChild("GUI", 10)  -- 10 sn bekle
    shootButton = shootButton:WaitForChild("Main", 10)
    shootButton = shootButton:WaitForChild("Mobile", 10)
    shootButton = shootButton:WaitForChild("Shoot", 10)
end)

if not shootButton then
    warn("Shoot button bulunamadı! Path'i kontrol et veya mobil modda test et.")
    print("Konsola bak: PlayerGui > GUI > Main > Mobile > Shoot var mı?")
    return  -- Script durur, hata vermez
end

print("Shoot button BULUNDU:", shootButton:GetFullName())  -- Konsola tam path yazar

-- Sade GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileAutoShootFixed"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 80)
Frame.Position = UDim2.new(0, 20, 0.8, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.Text = "📱 Auto Shoot (Fixed)"
Title.TextColor3 = Color3.new(1,1,1)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.new(1,0,0)
ToggleBtn.Text = "KAPALI"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20
ToggleBtn.Parent = Frame

local enabled = false
local connection

ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.new(0,1,0)
        
        connection = RunService.Heartbeat:Connect(function()
            if shootButton and shootButton.Parent then  -- Button hala var mı kontrol
                local pos = shootButton.AbsolutePosition + shootButton.AbsoluteSize / 2
                -- MouseButtonEvent ile dene (bazı oyunlarda TouchEvent çalışmaz)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)  -- Down
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1) -- Up
            end
        end)
        
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.new(1,0,0)
        if connection then connection:Disconnect() end
    end
end)

print("Script yüklendi! Konsola Shoot button path'i yazacak.")
