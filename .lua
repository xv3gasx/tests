--========================================================
-- WIND UI LOADER
--========================================================
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
    Content = "Blox Strike ESP + Aim",
    Duration = 3,
    Icon = "check"
})

--========================================================
-- WINDOW
--========================================================
local Window = WindUI:CreateWindow({
    Title = "Blox Strike",
    Author = "by x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(520, 380),
    Folder = "BloxStrike",
    AutoScale = true
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Draggable = true
})

--========================================================
-- TABS
--========================================================
local ESP_Tab = Window:Tab({Title="ESP", Icon="eye"})
local Aim_Tab = Window:Tab({Title="Aim", Icon="target"})

--========================================================
-- SERVICES
--========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--========================================================
-- GLOBALS
--========================================================
_G.TEAM_CHECK    = false
_G.ESP_LINE      = false
_G.ESP_BOX       = false
_G.ESP_NAME      = false
_G.ESP_HEALTH    = false
_G.ESP_HIGHLIGHT = false

_G.SILENT_AIM  = false
_G.AIM_FOV     = 150
_G.AIM_VISIBLE = true

--========================================================
-- DRAWING SAFE
--========================================================
local function dnew(class, props)
    local obj = Drawing.new(class)
    for k,v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

--========================================================
-- UI
--========================================================
ESP_Tab:Toggle({Title="Team Check", Callback=function(v) _G.TEAM_CHECK = v end})
ESP_Tab:Toggle({Title="Line ESP", Callback=function(v) _G.ESP_LINE=v end})
ESP_Tab:Toggle({Title="Box ESP", Callback=function(v) _G.ESP_BOX=v end})
ESP_Tab:Toggle({Title="NameTag ESP", Callback=function(v) _G.ESP_NAME=v end})
ESP_Tab:Toggle({Title="Health ESP", Callback=function(v) _G.ESP_HEALTH=v end})
ESP_Tab:Toggle({Title="Highlight ESP", Callback=function(v) _G.ESP_HIGHLIGHT=v end})

Aim_Tab:Toggle({Title="Silent Aim", Callback=function(v) _G.SILENT_AIM=v end})
Aim_Tab:Slider({
    Title="Aim FOV",
    Step=5,
    Value={Min=50,Max=500,Default=150},
    Callback=function(v) _G.AIM_FOV=v end
})
Aim_Tab:Toggle({Title="Visibility Check", Default=true, Callback=function(v) _G.AIM_VISIBLE=v end})

--========================================================
-- TEAM CHECK HELPER
--========================================================
local function isEnemy(plr)
    if not _G.TEAM_CHECK then return true end
    if LocalPlayer.Team == nil or plr.Team == nil then return true end
    return plr.Team ~= LocalPlayer.Team
end

--========================================================
-- VISIBILITY CHECK
--========================================================
local function isVisible(part, character)
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, character}

    return workspace:Raycast(origin, direction, params) == nil
end

--========================================================
-- ESP STORAGE
--========================================================
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

--========================================================
-- HEALTH COLOR
--========================================================
local function getHealthColor(hp)
    if hp > 0.66 then return Color3.fromRGB(0,255,0)
    elseif hp > 0.33 then return Color3.fromRGB(255,255,0)
    else return Color3.fromRGB(255,0,0)
    end
end

--========================================================
-- AIM FOV CIRCLE
--========================================================
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

--========================================================
-- RENDER LOOP
--========================================================
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

    -- ESP
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

        local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position)
        local visible = isVisible(head,char)

        local height = math.abs(headPos.Y-hrpPos.Y)*2
        local width = height/2

        -- LINE (DUVAR ARKASI DA GÖRÜNÜR)
        data.Line.Visible = _G.ESP_LINE
        if _G.ESP_LINE then
            data.Line.From = Vector2.new(Camera.ViewportSize.X/2,0)
            data.Line.To = Vector2.new(hrpPos.X,hrpPos.Y)
        end

        -- BOX (DUVAR ARKASI DA GÖRÜNÜR)
        data.Box.Visible = _G.ESP_BOX
        if _G.ESP_BOX then
            data.Box.Size = Vector2.new(width,height)
            data.Box.Position = Vector2.new(hrpPos.X-width/2,hrpPos.Y-height/2)
        end

        -- NAME (DUVAR ARKASI DA GÖRÜNÜR)
        data.Name.Visible = _G.ESP_NAME
        if _G.ESP_NAME then
            data.Name.Text = plr.Name
            data.Name.Position = Vector2.new(hrpPos.X,hrpPos.Y-height/2-14)
        end

        -- HEALTH (DUVAR ARKASI DA GÖRÜNÜR)
        data.HealthBar.Visible = _G.ESP_HEALTH
        if _G.ESP_HEALTH then
            local hp = hum.Health/hum.MaxHealth
            data.HealthBar.Color = getHealthColor(hp)
            data.HealthBar.From = Vector2.new(hrpPos.X-width/2-6, hrpPos.Y+height/2)
            data.HealthBar.To = Vector2.new(hrpPos.X-width/2-6, hrpPos.Y+height/2-height*hp)
        end

        -- HIGHLIGHT (DUVAR ARKASI RENGİ KIRMIZI)
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