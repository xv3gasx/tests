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
    Content = "Blox Strike ESP",
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
-- TAB
--========================================================
local ESP_Tab = Window:Tab({Title="ESP", Icon="eye"})

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
-- UI (TEAM CHECK EN ÜSTE)
--========================================================
ESP_Tab:Toggle({
    Title="Team Check",
    Callback=function(v) _G.TEAM_CHECK = v end
})

ESP_Tab:Toggle({Title="Line ESP", Callback=function(v) _G.ESP_LINE=v end})
ESP_Tab:Toggle({Title="Box ESP", Callback=function(v) _G.ESP_BOX=v end})
ESP_Tab:Toggle({Title="NameTag ESP", Callback=function(v) _G.ESP_NAME=v end})
ESP_Tab:Toggle({Title="Health ESP", Callback=function(v) _G.ESP_HEALTH=v end})
ESP_Tab:Toggle({Title="Highlight ESP", Callback=function(v) _G.ESP_HIGHLIGHT=v end})

--========================================================
-- TEAM CHECK HELPER
--========================================================
local function isEnemy(plr)
    if not _G.TEAM_CHECK then
        return true
    end
    if LocalPlayer.Team == nil or plr.Team == nil then
        return true
    end
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

    local ray = workspace:Raycast(origin, direction, params)
    return ray == nil
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
-- HEALTH COLOR (GREEN / YELLOW / RED)
--========================================================
local function getHealthColor(hp)
    if hp > 0.66 then
        return Color3.fromRGB(0,255,0)      -- green
    elseif hp > 0.33 then
        return Color3.fromRGB(255,255,0)    -- yellow
    else
        return Color3.fromRGB(255,0,0)      -- red
    end
end

--========================================================
-- RENDER LOOP
--========================================================
RunService.RenderStepped:Connect(function()
    for plr,data in pairs(ESP) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not hrp or not head or not hum or hum.Health <= 0 or not isEnemy(plr) then
            for _,v in pairs(data) do
                if typeof(v) ~= "Instance" then v.Visible = false end
            end
            if data.Highlight then data.Highlight.Enabled = false end
            continue
        end

        local hrpPos, onscreen = Camera:WorldToViewportPoint(hrp.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position)

        if not onscreen then
            for _,v in pairs(data) do
                if typeof(v) ~= "Instance" then v.Visible = false end
            end
            if data.Highlight then data.Highlight.Enabled = false end
            continue
        end

        local height = math.abs(headPos.Y - hrpPos.Y) * 2
        local width = height / 2

        -- LINE (TOP)
        data.Line.Visible = _G.ESP_LINE
        if _G.ESP_LINE then
            data.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
            data.Line.To = Vector2.new(hrpPos.X, hrpPos.Y)
        end

        -- BOX
        data.Box.Visible = _G.ESP_BOX
        if _G.ESP_BOX then
            data.Box.Size = Vector2.new(width, height)
            data.Box.Position = Vector2.new(hrpPos.X - width/2, hrpPos.Y - height/2)
        end

        -- NAME
        data.Name.Visible = _G.ESP_NAME
        if _G.ESP_NAME then
            data.Name.Text = plr.Name
            data.Name.Position = Vector2.new(hrpPos.X, hrpPos.Y - height/2 - 14)
        end

        -- HEALTH (THRESHOLD COLORS)
        data.HealthBar.Visible = _G.ESP_HEALTH
        if _G.ESP_HEALTH then
            local hp = hum.Health / hum.MaxHealth
            data.HealthBar.Color = getHealthColor(hp)
            data.HealthBar.From = Vector2.new(hrpPos.X - width/2 - 6, hrpPos.Y + height/2)
            data.HealthBar.To = Vector2.new(
                hrpPos.X - width/2 - 6,
                hrpPos.Y + height/2 - height*hp
            )
        end

        -- HIGHLIGHT (VISIBILITY BASED)
        if data.Highlight then
            if _G.ESP_HIGHLIGHT then
                local visible = isVisible(head, char)
                data.Highlight.FillColor = visible
                    and Color3.fromRGB(0,255,0)
                    or Color3.fromRGB(255,0,0)
                data.Highlight.Enabled = true
            else
                data.Highlight.Enabled = false
            end
        end
    end
end)