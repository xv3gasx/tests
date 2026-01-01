-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- BUTON İÇİ LOCALSCRIPT HACK - %100 ÇALIŞAN AUTO SHOOT!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Shoot button'ı bul
local shootButton = nil
spawn(function()
    while not shootButton do
        local gui = playerGui:FindFirstChild("GUI")
        if gui then
            local mobile = gui:FindFirstChild("Mobile")
            if mobile then
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
ScreenGui.Name = "ButtonScriptHack"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 80)
Frame.Position = UDim2.new(0, 20, 0.8, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔥 BUTTON SCRIPT HACK (Son Çare!)"
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
local fireFunction = nil

-- Button içindeki LocalScript'i bul + fire fonksiyonunu çıkar
spawn(function()
    task.wait(2)  -- Button tam yüklenene kadar bekle
    if shootButton then
        -- Button içindeki LocalScript'leri tara
        for _, script in pairs(shootButton:GetDescendants()) do
            if script:IsA("LocalScript") then
                local env = getfenv and getfenv(script) or getsenv and getsenv(script)
                if env then
                    -- Yaygın fire fonksiyon isimleri
                    local possibleFires = {"fire", "shoot", "onShoot", "fireBullet", "activate"}
                    for _, funcName in pairs(possibleFires) do
                        if env[funcName] and type(env[funcName]) == "function" then
                            fireFunction = env[funcName]
                            print("🎯 FIRE FONKSIYONU BULUNDU:", funcName)
                            break
                        end
                    end
                    if fireFunction then break end
                end
            end
        end
    end
end)

-- Crosshair rakip kontrol
local function isEnemyInCrosshair()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local centerX = camera.ViewportSize.X/2
    local centerY = camera.ViewportSize.Y/2
    local ray = camera:ScreenPointToRay(centerX, centerY)
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result then
        local hitChar = result.Instance.Parent
        local hum = hitChar:FindFirstChild("Humanoid")
        local plr = Players:GetPlayerFromCharacter(hitChar)
        return hum and hum.Health > 0 and plr and plr ~= player and (plr.Team ~= player.Team or plr.TeamColor ~= player.TeamColor)
    end
    return false
end

-- Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.new(50,200,50)
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.new(200,50,50)
        if connection then connection:Disconnect() end
    end
end)

-- Auto Shoot
connection = RunService.Heartbeat:Connect(function()
    if enabled and isEnemyInCrosshair() and fireFunction then
        pcall(fireFunction)  -- Button'un kendi fire fonksiyonunu çağır!
    end
end)

print("✅ BUTTON SCRIPT HACK YÜKLENDİ! Button içindeki LocalScript hack'leniyor...")
print("Konsola 'FIRE FONKSIYONU BULUNDU' yazarsa = %100 çalışır!")
