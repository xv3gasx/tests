-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- REMOTES
local Events = ReplicatedStorage:WaitForChild("Events")

local HitPart          = Events:FindFirstChild("HitPart")
local ReplicateShot    = Events:FindFirstChild("ReplicateShot")
local ReplicateAnim    = Events:FindFirstChild("ReplicateAnimation")
local ControlTurn      = Events:FindFirstChild("ControlTurn")
local Trail            = Events:FindFirstChild("Trail")
local RemoteEvent      = Events:FindFirstChild("RemoteEvent")

-- SETTINGS
local AUTO_SHOOT = true
local FIRE_DELAY = 0.08 -- mermi hızı

-- UTILS
local function getGun()
    return LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
end

local function getTarget()
    local best, dist = nil, math.huge
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local head = plr.Character:FindFirstChild("Head")
            if hum and hum.Health > 0 and head then
                local pos, on = Camera:WorldToViewportPoint(head.Position)
                if on then
                    local d = (Vector2.new(pos.X,pos.Y) -
                              Vector2.new(Mouse.X,Mouse.Y)).Magnitude
                    if d < dist then
                        dist = d
                        best = head
                    end
                end
            end
        end
    end
    return best
end

-- CORE SHOOT FUNCTION
local function fireShot()
    local gun = getGun()
    local target = getTarget()
    if not gun or not target then return end

    local origin = Camera.CFrame.Position
    local hitPos = target.Position

    -- Kamera bozulur (bilerek)
    Camera.CFrame = CFrame.new(origin, hitPos)

    -- 1) Animasyon
    if ReplicateAnim then
        ReplicateAnim:FireServer("Fire")
    end

    -- 2) Mermi replikasyonu
    if ReplicateShot then
        ReplicateShot:FireServer()
    end

    -- 3) Hit bildirimi
    if HitPart then
        HitPart:FireServer(
            target,
            hitPos,
            gun.Name,
            4096,
            gun,
            1,false,false,
            hitPos,
            52,
            Vector3.new(0,1,0),
            false,false,false,true
        )
    end

    -- 4) Trail
    if Trail then
        Trail:FireServer(
            CFrame.new(origin, hitPos),
            hitPos,
            {workspace.Map}
        )
    end

    -- 5) Efekt
    if RemoteEvent and gun:FindFirstChild("Flash") then
        RemoteEvent:FireServer({
            "createparticle",
            "muzzle",
            gun.Flash
        })
    end
end

-- LOOP
task.spawn(function()
    while task.wait(FIRE_DELAY) do
        if AUTO_SHOOT then
            fireShot()
        end
    end
end)

print("[AutoShoot] Dynamic shooter started")