-- Auto Shoot Script for Counter Blox-like games
-- Only requires a toggle button, no external UI library

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Auto shoot toggle
local AutoShootEnabled = false

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 150, 0, 50)
Frame.Position = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1,0,1,0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
ToggleButton.TextColor3 = Color3.fromRGB(255,255,255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Text = "Auto Shoot: OFF"
ToggleButton.Parent = Frame

ToggleButton.MouseButton1Click:Connect(function()
    AutoShootEnabled = not AutoShootEnabled
    ToggleButton.Text = "Auto Shoot: "..(AutoShootEnabled and "ON" or "OFF")
end)

-- Remotes
local HitPart = ReplicatedStorage.Events:WaitForChild("HitPart")
local ControlTurn = ReplicatedStorage.Events:WaitForChild("ControlTurn")
local Trail = ReplicatedStorage.Events:WaitForChild("Trail")
local ReplicateAnimation = ReplicatedStorage.Events:WaitForChild("ReplicateAnimation")
local RemoteEvent = ReplicatedStorage.Events:WaitForChild("RemoteEvent")
local ReplicateShot = ReplicatedStorage.Events:WaitForChild("ReplicateShot")

-- Example variables (replace these with the actual instances in your game)
local Geometry = workspace:WaitForChild("Map"):WaitForChild("Geometry")
local Part = Geometry:FindFirstChildWhichIsA("Part") or Geometry:FindFirstChild("Part")
local Gun = LocalPlayer:WaitForChild("Gun") or LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")
local Flash = Gun and Gun:FindFirstChild("Flash") or nil

-- Fire function
local function Fire()
    if not AutoShootEnabled then return end

    -- HitPart
    if Part then
        local RemoteArgs = {
            Part,
            Vector3.new(-3881900, 8536280, -1237733),
            "Glock",
            4096,
            Gun,
            [7] = 1,
            [8] = false,
            [9] = false,
            [10] = Vector3.new(-671, 1011, -899),
            [11] = 52,
            [12] = Vector3.new(0,1,0),
            [13] = false,
            [14] = false,
            [15] = false,
            [16] = true
        }
        HitPart:FireServer(unpack(RemoteArgs,1,table.maxn(RemoteArgs)))
    end

    -- ControlTurn
    ControlTurn:FireServer(-0.22411058843135834, false)

    -- Trail
    if Geometry then
        Trail:FireServer(
            CFrame.new(-666, 1010, -887, 0,0,-1,0,1,0,1,0,0),
            Vector3.new(-666,1006,-906),
            {Geometry}
        )
    end

    -- ReplicateAnimation Fire
    ReplicateAnimation:FireServer("Fire")

    -- ReplicateAnimation StopPlant (optional, can remove if unnecessary)
    ReplicateAnimation:FireServer("StopPlant")

    -- RemoteEvent muzzle
    if Flash then
        RemoteEvent:FireServer({"createparticle","muzzle",Flash})
    end

    -- RemoteEvent bullethole
    if Part then
        RemoteEvent:FireServer({"createparticle","bullethole",Part,Vector3.new(-666,1006,-906)})
    end

    -- ReplicateShot
    ReplicateShot:FireServer()
end

-- RunService loop for auto shoot
RunService.RenderStepped:Connect(function()
    if AutoShootEnabled then
        Fire()
    end
end)