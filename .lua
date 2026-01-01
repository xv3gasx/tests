-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- HAREKETLERİ BOZMAYAN MOBİL AUTO SHOOT (Final Versiyon)

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Shoot button'ı bul (senin path)
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
                    print("Shoot button bulundu:", shootButton:GetFullName())
                    break
                end
            end
        end
        task.wait(1)
    end
end)

-- Toggle GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SafeAutoShoot"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 80)
Frame.Position = UDim2.new(0, 20, 0.8, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.Text = "📱 Auto Shoot (Hareket Bozulmaz)"
Title.TextColor3 = Color3.new(1,1,1)
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
    if not shootButton then
        print("Shoot button henüz yüklenmedi, silah al bekle.")
        return
    end

    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.new(0,1,0)

        -- HAREKET BOZULMASIN DİYE: Sadece "down" gönder, "up" gönderme!
        -- Roblox mobil button'ları "down" ile ateş eder, "up" göndermezsen nişan/hareket bozulmaz
        connection = RunService.Heartbeat:Connect(function()
            local pos = shootButton.AbsolutePosition + shootButton.AbsoluteSize / 2
            -- Sadece DOWN gönder (up gönderme = hareket bozulmaz!)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        end)
    else
        ToggleBtn.Text = "KAPALI"
        ToggleBtn.BackgroundColor3 = Color3.new(1,0,0)
        if connection then
            connection:Disconnect()
            -- Güvenli çıkış: son bir up gönder (stuck olmasın)
            if shootButton then
                local pos = shootButton.AbsolutePosition + shootButton.AbsoluteSize / 2
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            end
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

print("✅ Hareketleri bozmayan Auto Shoot yüklendi! AÇIK yap → Yürüyüp nişan alırken bile ateş eder!")
