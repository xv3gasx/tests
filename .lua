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
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    Enabled = true,
    Draggable = true,
})

-- 4. Tabs
local EspTab = Window:Tab({Title="ESP", Icon="app-window"})

-- 5. Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 6. Globals
_G.BoxESPEnabled = false
_G.GunESP = false
_G.HighlightESP = false
_G.LineESPEnabled = false
_G.NametagESPEnabled = false
_G.HighlightCache = {}

local currentGun = nil

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,255,0)
}

-- 7. Toggles
EspTab:Toggle({Title="Box ESP", Callback=function(v) _G.BoxESPEnabled=v end})
EspTab:Toggle({Title="Gun ESP", Callback=function(v) _G.GunESP=v end})
EspTab:Toggle({Title="Highlight ESP", Callback=function(v)
    _G.HighlightESP=v
    for _,hl in pairs(_G.HighlightCache) do
        if hl then hl.Enabled=v end
    end
end})
EspTab:Toggle({Title="Line ESP", Callback=function(v) _G.LineESPEnabled=v end})
EspTab:Toggle({Title="Nametag ESP", Callback=function(v) _G.NametagESPEnabled=v end})

-- 8. Utility
local function detectRole(player)
    local role = "Innocent"

    local function scan(container)
        if not container then return end
        for _,v in pairs(container:GetChildren()) do
            if v:IsA("Tool") then
                if v.Name=="Knife" then role="Murderer" end
                if v.Name=="Gun" then role="Sheriff" end
            end
        end
    end

    scan(player:FindFirstChild("Backpack"))
    scan(player.Character)

    return role
end

local function safeDraw(class, props)
    local ok,obj = pcall(function()
        return Drawing.new(class)
    end)
    if not ok or not obj then return nil end
    for k,v in pairs(props or {}) do
        pcall(function() obj[k]=v end)
    end
    return obj
end

local function w2s(pos)
    local v,ons = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X,v.Y), ons
end

-- ESP TABLES
local BoxESP, LineESP, NametagESP = {}, {}, {}

-- BOX
local function createBox(plr)
    if plr==LocalPlayer or BoxESP[plr] then return end
    BoxESP[plr] = {
        box = safeDraw("Square",{Thickness=1,Filled=false,Visible=false})
    }
end

local function destroyBox(plr)
    if BoxESP[plr] and BoxESP[plr].box then
        BoxESP[plr].box:Remove()
    end
    BoxESP[plr]=nil
end

-- LINE
local function createLine(plr)
    if plr==LocalPlayer or LineESP[plr] then return end
    LineESP[plr] = {
        line = safeDraw("Line",{Thickness=2,Visible=false})
    }
end

local function destroyLine(plr)
    if LineESP[plr] and LineESP[plr].line then
        LineESP[plr].line:Remove()
    end
    LineESP[plr]=nil
end

-- NAMETAG
local function createTag(plr)
    if NametagESP[plr] then return end
    NametagESP[plr] = {
        text = safeDraw("Text",{
            Text=plr.Name,
            Size=14,
            Center=true,
            Outline=true,
            Visible=false
        })
    }
end

local function destroyTag(plr)
    if NametagESP[plr] and NametagESP[plr].text then
        NametagESP[plr].text:Remove()
    end
    NametagESP[plr]=nil
end

-- HIGHLIGHT
local function applyHighlight(plr)
    if plr==LocalPlayer then return end
    local char = plr.Character
    if not char then return end

    if _G.HighlightCache[plr] then
        _G.HighlightCache[plr]:Destroy()
    end

    local hl = Instance.new("Highlight")
    hl.Parent = char
    hl.Adornee = char
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0
    hl.OutlineTransparency = 0.4
    hl.FillColor = ROLE_COLORS[detectRole(plr)]
    hl.Enabled = _G.HighlightESP

    _G.HighlightCache[plr] = hl
end

-- ROLE FIX (Tool takibi)
local function watchTools(plr)
    local function hook(char)
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then applyHighlight(plr) end
        end)
        char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then applyHighlight(plr) end
        end)
    end
    if plr.Character then hook(plr.Character) end
    plr.CharacterAdded:Connect(hook)
end

-- PLAYERS
local function setup(plr)
    createBox(plr)
    createLine(plr)
    createTag(plr)
    watchTools(plr)

    if plr.Character then
        task.delay(0.1,function()
            applyHighlight(plr)
        end)
    end

    plr.CharacterAdded:Connect(function()
        task.delay(0.1,function()
            applyHighlight(plr)
        end)
    end)
end

for _,p in pairs(Players:GetPlayers()) do
    setup(p)
end

Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(p)
    destroyBox(p)
    destroyLine(p)
    destroyTag(p)
    if _G.HighlightCache[p] then
        _G.HighlightCache[p]:Destroy()
    end
end)

-- RENDER LOOP
RunService.RenderStepped:Connect(function()

    -- BOX
    for plr,d in pairs(BoxESP) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if _G.BoxESPEnabled and d.box and hrp and head then
            local t,on1 = w2s(head.Position+Vector3.new(0,0.5,0))
            local b,on2 = w2s(hrp.Position-Vector3.new(0,2.5,0))
            if on1 and on2 then
                local h = math.abs(t.Y-b.Y)
                local w = h/2
                d.box.Position = Vector2.new(t.X-w/2,t.Y)
                d.box.Size = Vector2.new(w,h)
                d.box.Color = ROLE_COLORS[detectRole(plr)]
                d.box.Visible = true
            else
                d.box.Visible=false
            end
        elseif d.box then
            d.box.Visible=false
        end
    end

    -- LINE (ÜST ORTA FIX)
    for plr,d in pairs(LineESP) do
        local line = d.line
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if _G.LineESPEnabled and line and hrp then
            local pos,on = w2s(hrp.Position)
            if on then
                line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
                line.To = pos
                line.Color = ROLE_COLORS[detectRole(plr)]
                line.Visible = true
            else
                line.Visible = false
            end
        elseif line then
            line.Visible = false
        end
    end

    -- HIGHLIGHT UPDATE
    if _G.HighlightESP then
        for plr,hl in pairs(_G.HighlightCache) do
            if hl then
                hl.FillColor = ROLE_COLORS[detectRole(plr)]
            end
        end
    end
end)