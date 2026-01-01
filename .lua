-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- KONTROLLER AZ BOZULUR + İKONLAR KAYBOLMAZ AUTO SHOOT (Hold Style)

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Shoot button'ı bul
local shootButton = nil
spawn(function()
    while not shootButton do
        local gui = playerGui:FindFirstChild("GUI")
        if gui and gui:IsA("ScreenGui") then
            local mobile = gui:FindFirstChild("Mobile")
            if mobile and mobile:IsA("Frame") then
                local shoot = mobile:FindFirstChild("Shoot")
                if shoot and shoot:IsA("ImageButton") then
                    shootButton = shoot
                    print("✅ SHOOT BUTTON BULUNDU:", shootButton:GetFullName())
                    break
                end
            end
        end
        task.wait(1)
    end
end)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HoldAutoShoot"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 80)
Frame.Position = UDim2.new(0, 20, 0.8, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔥 Hold Auto Shoot (Az Bozar)"
Title.TextColor3 = Color3.new(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.new(200,50,50)
ToggleBtn.Text = "KAPALI"
ToggleBtn.TextColor3 = Color3.new(255,255,255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20
ToggleBtn.Parent = Frame

local enabled = false
local connection

ToggleBtn.MouseButton1Click:Connect(function()
    if not shootButton then
        print("Shoot button bekleniyor...")
        return
    end
    
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK (Hold Ateş)"
        ToggleBtn.BackgroundColor3 = Color3.new(50,200,50)
        
        -- SADECE DOWN GÖNDER (UP YOK = ikonlar kaybolmaz, kontroller az bozulur)
        connection = RunService.Heartbeat:Connect(function()
            local pos = shootButton.AbsolutePosition + shootButton.AbsoluteSize / 2
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        end)
        
    else
        ToggleBtn.Text = "KAPALI"
        ToggleBtn.BackgroundColor3 = Color3.new(200,50,50)
        if connection then
            connection:Disconnect()
            -- Kapatırken son UP gönder (stuck kalmasın)
            local pos = shootButton.AbsolutePosition + shootButton.AbsoluteSize / 2
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end
end)

print("✅ Hold Auto Shoot yüklendi! AÇIK = Sürekli hold ateş (ikonlar kalır)!")
