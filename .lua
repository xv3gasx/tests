-- SETTINGS
local HITBOX_SIZE = Vector3.new(6, 6, 6) -- büyüt / küçült
local HITBOX_TRANSPARENCY = 0.7
local TEAM_CHECK = true

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UTILS
local function isEnemy(plr)
    if not TEAM_CHECK then return true end
    if not LocalPlayer.Team or not plr.Team then return true end
    return plr.Team ~= LocalPlayer.Team
end

-- HITBOX LOOP
RunService.RenderStepped:Connect(function()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isEnemy(plr) then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                hrp.Size = HITBOX_SIZE
                hrp.Transparency = HITBOX_TRANSPARENCY
                hrp.CanCollide = false
                hrp.Massless = true
            end
        end
    end
end)