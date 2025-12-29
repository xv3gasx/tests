local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)
if not ok or not WindUI then
    warn("WindUI load failed")
    return
end
WindUI:Notify({
    Title = "Loaded",
    Content = "Counter Bloxment (Anti-Cheat Bypass)",
    Duration = 3,
    Icon = "check"
})

local Window = WindUI:CreateWindow({
    Title = "Counter Blox",
    Author = "by x.v3gas.x (Movement by Grok)",
    Theme = "Dark",
    Size = UDim2.fromOffset(520, 420),
    Folder = "CounterBlox",
    AutoScale = true
})
Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Draggable = true
})

local ESP_Tab = Window:Tab({Title="ESP", Icon="eye"})
local Aim_Tab = Window:Tab({Title="Aim", Icon="target"})
local Movement_Tab = Window:Tab({Title="Movement", Icon="user"})  -- Yeni Tab

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.TEAM_CHECK = false
_G.ESP_LINE = false
_G.ESP_BOX = false
_G.ESP_NAME = false
_G.ESP_HEALTH = false
_G.ESP_HIGHLIGHT = false
_G.SILENT_AIM = false
_G.AIM_FOV = 150
_G.AIM_VISIBLE = true

-- Movement Globals (Anti-Cheat Bypass)
_G.WalkSpeedEnabled = false
_G.WalkSpeedValue = 30
_G.NoclipEnabled = false
_G.InfJumpEnabled = false

local function dnew(class, props)
    local obj = Drawing.new(class)
    for k,v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

-- ESP Toggle'lar
ESP_Tab:Toggle({Title="Team Check", Callback=function(v) _G.TEAM_CHECK = v end})
ESP_Tab:Toggle({Title="Line ESP", Callback=function(v) _G.ESP_LINE=v end})
ESP_Tab:Toggle({Title="Box ESP", Callback=function(v) _G.ESP_BOX=v end})
ESP_Tab:Toggle({Title="NameTag ESP", Callback=function(v) _G.ESP_NAME=v end})
ESP_Tab:Toggle({Title="Health ESP", Callback=function(v) _G.ESP_HEALTH=v end})
ESP_Tab:Toggle({Title="Highlight ESP", Callback=function(v) _G.ESP_HIGHLIGHT=v end})

-- Aim Toggle'lar
Aim_Tab:Toggle({Title="Silent Aim", Callback=function(v) _G.SILENT_AIM=v end})
Aim_Tab:Slider({
    Title="Aim FOV",
    Step=5,
    Value={Min=50,Max=500,Default=150},
    Callback=function(v) _G.AIM_FOV=v end
})
Aim_Tab:Toggle({Title="Visibility Check", Default=true, Callback=function(v) _G.AIM_VISIBLE=v end})

-- Movement Toggle'lar (Anti-Cheat Bypass)
Movement_Tab:Toggle({Title="Walkspeed (Bypass)", Default=false, Callback=function(v) _G.WalkSpeedEnabled = v end})
Movement_Tab:Slider({
    Title="Walkspeed Value",
    Step=1,
    Value={Min=16,Max=100,Default=30},
    Callback=function(v) _G.WalkSpeedValue = v end
})
Movement_Tab:Toggle({Title="Noclip", Default=false, Callback=function(v) _G.NoclipEnabled = v end})
Movement_Tab:Toggle({Title="Infinite Jump", Default=false, Callback=function(v) _G.InfJumpEnabled = v end})

local function isEnemy(plr)
    if not _G.TEAM_CHECK then return true end
    if LocalPlayer.Team == nil or plr.Team == nil then return true end
    return plr.Team ~= LocalPlayer.Team
end

local function isVisible(part, character)
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, character}
    return workspace:Raycast(origin, direction, params) == nil
end

local ESP = {}
local function removeESP(plr)
    if ESP[plr] then
        for _,v in pairs(ESP[plr]) do
            if typeof(v) == "Instance" then
                pcall(function() v:Destroy() end)
            else
                pcall(function() v:Remove() end)
            end
        end
        ESP[plr] = nil
    end
end

local function createESP(plr)
    if plr == LocalPlayer then return end
    ESP[plr] = {
        Line = dnew("Line",{Thickness=1.5,Color=Color3.new(1,1,1),Visible=false}),
        Box = dnew("Square",{Thickness=1,Color=Color3.new(1,1,1),Filled=false,Visible=false}),
        Name = dnew("Text",{Size=13,Center=true,Outline=true,Visible=false}),
        HealthBar = dnew("Line",{Thickness=2,Visible=false}),
        Highlight = nil
    }
    local function applyHighlight(char)
        if ESP[plr].Highlight then ESP[plr].Highlight:Destroy() end
        local h = Instance.new("Highlight")
        h.FillTransparency = 0.6
        h.OutlineTransparency = 1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = false
        h.Adornee = char
        h.Parent = char
        ESP[plr].Highlight = h
    end
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        applyHighlight(char)
    end)
    if plr.Character then
        applyHighlight(plr.Character)
    end
end

for _,p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

local function getHealthColor(hp)
    if hp > 0.66 then return Color3.fromRGB(0,255,0)
    elseif hp > 0.33 then return Color3.fromRGB(255,255,0)
    else return Color3.fromRGB(255,0,0)
    end
end

local FOV = dnew("Circle",{Thickness=2,NumSides=64,Filled=false,Color=Color3.fromRGB(255,255,255),Visible=false})

local function getTarget()
    local best,dist=nil,_G.AIM_FOV
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and isEnemy(p) then
            local char = p.Character
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health>0 then
                if _G.AIM_VISIBLE and not isVisible(head,char) then continue end
                local pos,on = Camera:WorldToViewportPoint(head.Position)
                if on then
                    local d = (Vector2.new(pos.X,pos.Y) - Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)).Magnitude
                    if d<dist then dist=d best=head end
                end
            end
        end
    end
    return best
end

-- Anti-Cheat Bypass Movement (Counter Blox'ta Çalışır)
local WalkSpeedConnection
local function toggleWalkSpeed()
    if WalkSpeedConnection then WalkSpeedConnection:Disconnect() end
    if _G.WalkSpeedEnabled then
        local speed = (_G.WalkSpeedValue - 16) * 0.7  -- Normal hissettir (16 = 0, 100 = yüksek)
        WalkSpeedConnection = RunService.Stepped:Connect(function(_, dt)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local move = LocalPlayer:GetMouse().Hit.LookVector * speed * dt * 50
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then hrp.CFrame = hrp.CFrame + move end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then hrp.CFrame = hrp.CFrame - move end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then hrp.CFrame = hrp.CFrame - hrp.CFrame.RightVector * speed * dt * 50 end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then hrp.CFrame = hrp.CFrame + hrp.CFrame.RightVector * speed * dt * 50 end
            end
        end)
    end
end

-- Noclip
RunService.Stepped:Connect(function()
    if _G.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Infinite Jump (Velocity ile - Bug Yok, Mobile Uyumlu)
UserInputService.JumpRequest:Connect(function()
    if _G.InfJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
            end
        end
    end
end)

-- Toggle Bağlantıları
Movement_Tab:FindFirstChild("Walkspeed").Callback = toggleWalkSpeed  -- Toggle değişince çalıştır

RunService.RenderStepped:Connect(function()
    -- AIM FOV
    FOV.Visible = _G.SILENT_AIM
    FOV.Radius = _G.AIM_FOV
    FOV.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    if _G.SILENT_AIM then
        local t = getTarget()
        if t then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
        end
    end

    -- ESP (Sabit Box & HealthBar)
    for plr,data in pairs(ESP) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not head or not hum or hum.Health<=0 or not isEnemy(plr) then
            for _,v in pairs(data) do
                if typeof(v)~="Instance" then v.Visible=false end
            end
            if data.Highlight then data.Highlight.Enabled=false end
            continue
        end

        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
        local hrpPos, hrpOnScreen = Camera:WorldToViewportPoint(hrp.Position)
        local onScreen = headOnScreen and hrpOnScreen
        local visible = isVisible(head, char)

        local BOX_WIDTH = 30
        local BOX_HEIGHT = 48
        local HEALTH_HEIGHT = 38

        -- LINE
        data.Line.Visible = _G.ESP_LINE and onScreen
        if data.Line.Visible then
            data.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
            data.Line.To = Vector2.new(hrpPos.X, hrpPos.Y)
        end

        -- BOX
        data.Box.Visible = _G.ESP_BOX and onScreen
        if data.Box.Visible then
            data.Box.Size = Vector2.new(BOX_WIDTH, BOX_HEIGHT)
            data.Box.Position = Vector2.new(hrpPos.X - BOX_WIDTH/2, hrpPos.Y - BOX_HEIGHT/2)
        end

        -- NAME
        data.Name.Visible = _G.ESP_NAME and onScreen
        if data.Name.Visible then
            data.Name.Text = plr.Name
            data.Name.Position = Vector2.new(hrpPos.X, hrpPos.Y - BOX_HEIGHT/2 - 14)
        end

        -- HEALTH
        data.HealthBar.Visible = _G.ESP_HEALTH and onScreen
        if data.HealthBar.Visible then
            local hp = hum.Health / hum.MaxHealth
            data.HealthBar.Color = getHealthColor(hp)
            data.HealthBar.From = Vector2.new(hrpPos.X - BOX_WIDTH/2 - 6, hrpPos.Y + BOX_HEIGHT/2)
            data.HealthBar.To = Vector2.new(hrpPos.X - BOX_WIDTH/2 - 6, hrpPos.Y + BOX_HEIGHT/2 - HEALTH_HEIGHT * hp)
        end

        -- HIGHLIGHT
        if data.Highlight then
            if _G.ESP_HIGHLIGHT then
                data.Highlight.FillColor = visible and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
                data.Highlight.Enabled = true
            else
                data.Highlight.Enabled = false
            end
        end
    end
end)
