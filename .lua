-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Basit GUI oluştur
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.Name = "AutoShootGui"

-- Buton oluştur
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 50)
ToggleButton.Position = UDim2.new(0.5, -75, 0.9, -25)  -- Ekranın altında ortala
ToggleButton.Text = "Auto Shoot: KAPALI"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- Kırmızı (kapalı)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = ScreenGui

-- Toggle durumu
local autoShootEnabled = false

-- Buton tıklama event
ToggleButton.MouseButton1Click:Connect(function()
    autoShootEnabled = not autoShootEnabled
    if autoShootEnabled then
        ToggleButton.Text = "Auto Shoot: AÇIK"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)  -- Yeşil (açık)
    else
        ToggleButton.Text = "Auto Shoot: KAPALI"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- Kırmızı
    end
end)

-- Ana döngü: Auto Shoot
spawn(function()
    while true do
        task.wait()  -- Performanslı bekleme
        if autoShootEnabled then
            local character = player.Character
            if character then
                local tool = character:FindFirstChildOfClass("Tool")
                if tool and mouse.Target then  -- Silah varsa ve nişan alıyorsa
                    -- Mouse sol tuşunu sanal olarak bas
                    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 0)  -- down
                    task.wait(0.03)  -- Ateş hızı ayarı
                    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 0)  -- up
                end
            end
        end
    end
end)

print("Basit Auto Shoot GUI yüklendi! Butona tıklayarak aç/kapat.")
