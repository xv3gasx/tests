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

-- LINE
local function createLine(plr)
    if plr==LocalPlayer or LineESP[plr] then return end
    LineESP[plr] = {
        line = safeDraw("Line",{Thickness=2,Visible=false})
    }
end

-- NAMETAG
local function createTag(plr)
    if plr==LocalPlayer or NametagESP[plr] then return end
    NametagESP[plr] = {
        text = safeDraw("Text",{
            Text = plr.Name,
            Size = 14,
            Center = true,
            Outline = true,
            Visible = false
        })
    }
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

-- GUN ESP OBJECTS
local gunBox  = safeDraw("Square",{Thickness=2,Filled=false,Visible=false})
local gunText = safeDraw("Text",{Text="GUN",Size=16,Center=true,Outline=true,Visible=false})

workspace.DescendantAdded:Connect(function(o)
    if o:IsA("BasePart") and o.Name == "GunDrop" then
        currentGun = o
    end
end)

workspace.DescendantRemoving:Connect(function(o)
    if o == currentGun then
        currentGun = nil
    end
end)

-- PLAYERS
local function setup(plr)
    createBox(plr)
    createLine(plr)
    createTag(plr)

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

for _,p in pairs(Players:GetPlayers()) do setup(p) end
Players.PlayerAdded:Connect(setup)

-- RENDER LOOP
RunService.RenderStepped:Connect(function()

    -- NAMETAG FIX
    for plr,d in pairs(NametagESP) do
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        if _G.NametagESPEnabled and d.text and head then
            local pos,on = w2s(head.Position + Vector3.new(0,1,0))
            if on then
                d.text.Position = pos
                d.text.Color = ROLE_COLORS[detectRole(plr)]
                d.text.Visible = true
            else
                d.text.Visible = false
            end
        elseif d.text then
            d.text.Visible = false
        end
    end

    -- GUN ESP FIX
    if _G.GunESP and currentGun then
        local pos,on = w2s(currentGun.Position)
        if on then
            gunBox.Position = pos - Vector2.new(15,15)
            gunBox.Size = Vector2.new(30,30)
            gunBox.Color = Color3.fromRGB(255,255,0)
            gunBox.Visible = true

            gunText.Position = pos + Vector2.new(0,-20)
            gunText.Color = Color3.fromRGB(255,255,0)
            gunText.Visible = true
        else
            gunBox.Visible = false
            gunText.Visible = false
        end
    else
        gunBox.Visible = false
        gunText.Visible = false
    end
end)