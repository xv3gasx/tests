-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)
-- PES ETMİYORUZ - CONTEXTACTION AUTO SHOOT (Crosshair Rakip = Otomatik Ateş)

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

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
                    print("✅ SHOOT BUTTON BULUNDU:", shootButton:GetFullName())
                    break
                end
            end
        end
        task.wait(1)
    end
end)

-- GUI Toggle
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ContextAutoShoot"
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
Title.Text = "🔥 Auto Shoot (ContextAction)"
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

ToggleBtn.MouseButton1Click:Connect(function()
    if not shootButton then
        print("Shoot button bekleniyor...")
        return
    end
    
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "AÇIK ✅"
        ToggleBtn.BackgroundColor3 = Color3.new(50,200,50)
        
        -- ContextAction bind et (mobil shoot action gibi)
        ContextActionService:BindAction("AutoShootAction", function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                -- Ateş et (mobil button gibi)
                shootButton.Activated:Fire()
            end
            return Enum.ContextActionResult.Sink  -- Input'u tüket (bozulma olmasın)
        end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)  -- Fake input
        
    else
        ToggleBtn.Text = "KAPALI ❌"
        ToggleBtn.BackgroundColor3 = Color3.new(200,50,50)
        ContextActionService:UnbindAction("AutoShootAction")
    end
end)

-- Crosshair kontrol + Otomatik tetikle
RunService.Heartbeat:Connect(function()
    if enabled then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local centerRay = camera:ScreenPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {char}
            params.FilterType = Enum.RaycastFilterType.Blacklist

            local result = workspace:Raycast(centerRay.Origin, centerRay.Direction * 1000, params)
            if result then
                local hitChar = result.Instance.Parent
                local hum = hitChar:FindFirstChild("Humanoid")
                local plr = Players:GetPlayerFromCharacter(hitChar)
                if hum and hum.Health > 0 and plr and plr ~= player and plr.Team ~= player.Team then
                    -- Rakip crosshair'de → Action tetikle (ateş!)
                    ContextActionService:CallFunction("AutoShootAction", Enum.UserInputState.Begin, nil)
                end
            end
        end
    end
end)

print("✅ ContextAction Auto Shoot yüklendi! Crosshair rakibe = Otomatik ateş (hareket bozulmaz)!")
