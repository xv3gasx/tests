--========================================================
-- WIND UI LOADER
--========================================================
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)
if not ok or not WindUI then return end

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
    local o = Drawing.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    return o
end

--========================================================
-- UI
--========================================================
ESP_Tab:Toggle({Title="Team Check", Callback=function(v) _G.TEAM_CHECK=v end})
ESP_Tab:Toggle({Title="Line ESP", Callback=function(v) _G.ESP_LINE=v end})
ESP_Tab:Toggle({Title="Box ESP", Callback=function(v) _G.ESP_BOX=v end})
ESP_Tab:Toggle({Title="Name ESP", Callback=function(v) _G.ESP_NAME=v end})
ESP_Tab:Toggle({Title="Health ESP", Callback=function(v) _G.ESP_HEALTH=v end})
ESP_Tab:Toggle({Title="Highlight ESP", Callback=function(v) _G.ESP_HIGHLIGHT=v end})

Aim_Tab:Toggle({Title="Silent Aim", Callback=function(v) _G.SILENT_AIM=v end})
Aim_Tab:Slider({
    Title="Aim FOV",
    Step=5,
    Value={Min=50,Max=500,Default=150},
    Callback=function(v) _G.AIM_FOV=v end
})
Aim_Tab:Toggle({
    Title="Visibility Check",
    Default=true,
    Callback=function(v) _G.AIM_VISIBLE=v end
})

--========================================================
-- TEAM CHECK HELPER
--========================================================
local function isEnemy(p)
    if not _G.TEAM_CHECK then return true end
    if not LocalPlayer.Team or not p.Team then return true end
    return p.Team ~= LocalPlayer.Team
end

--========================================================
-- VISIBILITY CHECK
--========================================================
local function isVisible(part, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
    return not workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
end

--========================================================
-- HEALTH COLOR
--========================================================
local function healthColor(hp)
    if hp > 0.66 then return Color3.fromRGB(0,255,0)
    elseif hp > 0.33 then return Color3.fromRGB(255,255,0)
    else return Color3.fromRGB(255,0,0)
    end
end

--========================================================
-- ESP STORAGE
--========================================================
local ESP = {}

local function createESP(p)
    if p == LocalPlayer then return end
    ESP[p] = {
        Line = dnew("Line",{Thickness=1.5,Visible=false}),
        Box = dnew("Square",{Thickness=1,Filled=false,Visible=false}),
        Name = dnew("Text",{Size=13,Center=true,Outline=true,Visible=false}),
        Health = dnew("Line",{Thickness=2,Visible=false}),
        Highlight = nil
    }

    local function applyHighlight(char)
        if ESP[p].Highlight then ESP[p].Highlight:Destroy() end
        local h = Instance.new("Highlight")
        h.FillTransparency = 0.6
        h.OutlineTransparency = 1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = false
        h.Parent = char
        h.Adornee = char
        ESP[p].Highlight = h
    end

    p.CharacterAdded:Connect(function(c)
        task.wait(0.2)
        applyHighlight(c)
    end)
    if p.Character then applyHighlight(p.Character) end
end

for _,p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    if ESP[p] then
        for _,v in pairs(ESP[p]) do
            pcall(function() if typeof(v)=="Instance" then v:Destroy() else v:Remove() end end)
        end
        ESP[p]=nil
    end
end)

--========================================================
-- AIM FOV CIRCLE
--========================================================
local FOV = dnew("Circle",{Thickness=2,NumSides=64,Filled=false,Color=Color3.fromRGB(255,255,255),Visible=false})

local function getTarget()
    local best,dist=nil,_G.AIM_FOV
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and isEnemy(p) then
            local c=p.Character
            local h=c and c:FindFirstChild("Head")
            local hum=c and c:FindFirstChildOfClass("Humanoid")
            if h and hum and hum.Health>0 then
                if _G.AIM_VISIBLE and not isVisible(h,c) then continue end
                local pos,on=Camera:WorldToViewportPoint(h.Position)
                if on then
                    local d=(Vector2.new(pos.X,pos.Y)-Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)).Magnitude
                    if d<dist then dist=d best=h end
                end
            end
        end
    end
    return best
end

--========================================================
-- RENDER LOOP (ESP + AIM + EKRAN DIŞI KONTROL)
--========================================================
RunService.RenderStepped:Connect(function()
    FOV.Visible = _G.SILENT_AIM
    FOV.Radius = _G.AIM_FOV
    FOV.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    if _G.SILENT_AIM then
        local t = getTarget()
        if t then Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position) end
    end

    for p,d in pairs(ESP) do
        local c = p.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local head = c and c:FindFirstChild("Head")
        local hum = c and c:FindFirstChildOfClass("Humanoid")

        if not hrp or not head or not hum or hum.Health <= 0 or not isEnemy(p) then
            for _,v in pairs(d) do if typeof(v)~="Instance" then v.Visible=false end end
            if d.Highlight then d.Highlight.Enabled=false end
            continue
        end

        local hpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position)
        local visible = isVisible(head,c)

        -- Ekran dışındaysa gizle, ekrana gelince tekrar aç
        local espVisible = onScreen
        for _,v in pairs(d) do
            if typeof(v)~="Instance" then
                v.Visible = espVisible
            end
        end

        if d.Highlight then
            if _G.ESP_HIGHLIGHT then
                d.Highlight.FillColor = visible and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
                d.Highlight.Enabled = espVisible
            else
                d.Highlight.Enabled = false
            end
        end

        if not espVisible then continue end

        local h = math.abs(headPos.Y - hpPos.Y)*2
        local w = h/2

        -- LINE
        d.Line.Visible = _G.ESP_LINE and visible
        if _G.ESP_LINE then d.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0); d.Line.To = Vector2.new(hpPos.X, hpPos.Y) end

        -- BOX
        d.Box.Visible = _G.ESP_BOX and visible
        if _G.ESP_BOX then d.Box.Size = Vector2.new(w,h); d.Box.Position = Vector2.new(hpPos.X-w/2,hpPos.Y-h/2) end

        -- NAME
        d.Name.Visible = _G.ESP_NAME and visible
        if _G.ESP_NAME then d.Name.Text = p.Name; d.Name.Position = Vector2.new(hpPos.X,hpPos.Y-h/2-14) end

        -- HEALTH
        d.Health.Visible = _G.ESP_HEALTH and visible
        if _G.ESP_HEALTH then
            local hp = hum.Health / hum.MaxHealth
            d.Health.Color = healthColor(hp)
            d.Health.From = Vector2.new(hpPos.X-w/2-6,hpPos.Y+h/2)
            d.Health.To = Vector2.new(hpPos.X-w/2-6,hpPos.Y+h/2-h*hp)
        end
    end
end)