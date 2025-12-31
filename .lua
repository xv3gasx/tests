-- AUTO SHOOT (INPUT BASED) - Counter Blox uyumlu

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera

local LP = Players.LocalPlayer

-- AYARLAR
local ENABLED = true
local TEAM_CHECK = true
local FIRE_DELAY = 0.08 -- fire rate (küçük = hızlı)

local lastFire = 0

local function isEnemy(plr)
    if not TEAM_CHECK then return true end
    if not LP.Team or not plr.Team then return true end
    return plr.Team ~= LP.Team
end

local function getTargetFromCrosshair()
    local origin = Camera.CFrame.Position
    local direction = Camera.CFrame.LookVector * 1000

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LP.Character}

    local result = workspace:Raycast(origin, direction, params)
    if not result then return nil end

    local part = result.Instance
    local model = part:FindFirstAncestorOfClass("Model")
    if not model then return nil end

    local hum = model:FindFirstChildOfClass("Humanoid")
    local plr = Players:GetPlayerFromCharacter(model)

    if hum and hum.Health > 0 and plr and plr ~= LP and isEnemy(plr) then
        return true
    end

    return nil
end

RunService.RenderStepped:Connect(function()
    if not ENABLED then return end
    if tick() - lastFire < FIRE_DELAY then return end

    if getTargetFromCrosshair() then
        lastFire = tick()

        -- Mouse1 DOWN
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait()
        -- Mouse1 UP
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end)
print("a")