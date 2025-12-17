-- 1. WindUI Loader
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)
if not ok or not WindUI then return warn("WindUI load failed") end

-- 2. Window
local Window = WindUI:CreateWindow({
    Title = "ESP Script",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 450),
    Folder = "GUI",
    AutoScale = true
})

-- 3. Open Button
Window:EditOpenButton({
    Title = "Open ESP Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    Enabled = true,
    Draggable = true
})

-- 4. Tab
local EspTab = Window:Tab({Title="ESP", Icon="app-window"})

-- 5. Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 6. Globals
_G.BoxESPEnabled = false
_G.LineESPEnabled = false
_G.NametagESPEnabled = false
_G.GunESP = false
_G.HighlightESP = false
_G.HighlightCache = {}

local currentGun = nil

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,255,0)
}

-- 7. Toggles
EspTab:Toggle({Title="Box ESP", Callback=function(v) _G.BoxESPEnabled=v end})
EspTab:Toggle({Title="Line ESP", Callback=function(v) _G.LineESPEnabled=v end})
EspTab:Toggle({Title="Nametag ESP", Callback=function(v) _G.NametagESPEnabled=v end})
EspTab:Toggle({Title="Gun ESP", Callback=function(v) _G.GunESP=v end})
EspTab:Toggle({Title="Highlight ESP", Callback=function(v)
    _G.HighlightESP=v
    for _,hl in pairs(_G.HighlightCache) do
        if hl then hl.Enabled=v end
    end
end})

-- 8. Utils
local function detectRole(plr)
    local role = "Innocent"

    local function scan(c)
        if not c then return end
        for _,v in pairs(c:GetChildren()) do
            if v:IsA("Tool") then
                if v.Name=="Knife" then role="Murderer" end
                if v.Name=="Gun" then role="Sheriff" end
            end
        end
    end

    scan(plr:FindFirstChild("Backpack"))
    scan(plr.Character)
    return role
end

local function w2s(pos)
    local v,ons = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X,v.Y), ons
end

local function draw(class, props)
    local d = Drawing.new(class)
    for k,v in pairs(props or {}) do d[k]=v end
    return d
end

-- ESP TABLES
local BoxESP, LineESP, NametagESP = {}, {}, {}

-- BOX
local function createBox(p)
    if p==LocalPlayer then return end
    BoxESP[p] = {box = draw("Square",{Filled=false,Thickness=1,Visible=false})}
end

-- LINE
local function createLine(p)
    if p==LocalPlayer then return end
    LineESP[p] = {line = draw("Line",{Thickness=2,Visible=false})}
end

-- NAMETAG
local function createTag(p)
    if p==LocalPlayer then return end
    NametagESP[p] = {text = draw("Text",{Text=p.Name,Size=14,Center=true,Outline=true,Visible=false})}
end

-- HIGHLIGHT
local function applyHighlight(p)
    if p==LocalPlayer or not p.Character then return end
    if _G.HighlightCache[p] then _G.HighlightCache[p]:Destroy() end

    local hl = Instance.new("Highlight")
    hl.Parent = p.Character
    hl.Adornee = p.Character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0
    hl.OutlineTransparency = 0.4
    hl.FillColor = ROLE_COLORS[detectRole(p)]
    hl.Enabled = _G.HighlightESP

    _G.HighlightCache[p] = hl
end

-- TOOL WATCH (ROL FIX)
local function watchTools(p)
    local function hook(char)
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then applyHighlight(p) end
        end)
        char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then applyHighlight(p) end
        end)
    end
    if p.Character then hook(p.Character) end
    p.CharacterAdded:Connect(hook)
end

-- GUN ESP OBJECTS
local gunBox  = draw("Square",{Thickness=2,Filled=false,Visible=false})
local gunText = draw("Text",{Text="GUN",Size=16,Center=true,Outline=true,Visible=false})

workspace.DescendantAdded:Connect(function(o)
    if o:IsA("BasePart") and o.Name=="GunDrop" then
        currentGun=o
    end
end)
workspace.DescendantRemoving:Connect(function(o)
    if o==currentGun then currentGun=nil end
end)

-- PLAYERS
local function setup(p)
    createBox(p)
    createLine(p)
    createTag(p)
    watchTools(p)

    if p.Character then task.delay(0.1,function() applyHighlight(p) end) end
    p.CharacterAdded:Connect(function()
        task.delay(0.1,function() applyHighlight(p) end)
    end)
end

for _,p in pairs(Players:GetPlayers()) do setup(p) end
Players.PlayerAdded:Connect(setup)

-- RENDER LOOP
RunService.RenderStepped:Connect(function()
    -- BOX
    for p,d in pairs(BoxESP) do
        local c=p.Character
        local hrp=c and c:FindFirstChild("HumanoidRootPart")
        local head=c and c:FindFirstChild("Head")
        if _G.BoxESPEnabled and hrp and head then
            local t,a=w2s(head.Position+Vector3.new(0,0.5,0))
            local b,b2=w2s(hrp.Position-Vector3.new(0,2.5,0))
            if a and b2 then
                local h=math.abs(t.Y-b.Y)
                local w=h/2
                d.box.Position=Vector2.new(t.X-w/2,t.Y)
                d.box.Size=Vector2.new(w,h)
                d.box.Color=ROLE_COLORS[detectRole(p)]
                d.box.Visible=true
            else d.box.Visible=false end
        else d.box.Visible=false end
    end

    -- LINE (ÜST ORTA)
    for p,d in pairs(LineESP) do
        local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if _G.LineESPEnabled and hrp then
            local pos,on=w2s(hrp.Position)
            if on then
                d.line.From=Vector2.new(Camera.ViewportSize.X/2,0)
                d.line.To=pos
                d.line.Color=ROLE_COLORS[detectRole(p)]
                d.line.Visible=true
            else d.line.Visible=false end
        else d.line.Visible=false end
    end

    -- NAMETAG
    for p,d in pairs(NametagESP) do
        local head=p.Character and p.Character:FindFirstChild("Head")
        if _G.NametagESPEnabled and head then
            local pos,on=w2s(head.Position+Vector3.new(0,1,0))
            if on then
                d.text.Position=pos
                d.text.Color=ROLE_COLORS[detectRole(p)]
                d.text.Visible=true
            else d.text.Visible=false end
        else d.text.Visible=false end
    end

    -- GUN ESP
    if _G.GunESP and currentGun then
        local pos,on=w2s(currentGun.Position)
        if on then
            gunBox.Position=pos-Vector2.new(15,15)
            gunBox.Size=Vector2.new(30,30)
            gunBox.Color=Color3.fromRGB(255,255,0)
            gunBox.Visible=true

            gunText.Position=pos+Vector2.new(0,-20)
            gunText.Color=Color3.fromRGB(255,255,0)
            gunText.Visible=true
        else
            gunBox.Visible=false
            gunText.Visible=false
        end
    else
        gunBox.Visible=false
        gunText.Visible=false
    end

    -- HIGHLIGHT COLOR UPDATE
    if _G.HighlightESP then
        for p,hl in pairs(_G.HighlightCache) do
            if hl then hl.FillColor=ROLE_COLORS[detectRole(p)] end
        end
    end
end)
