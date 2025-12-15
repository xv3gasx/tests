-- 1. WindUI Loader
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI load failed") end

-- 2. Window Oluşturma
local Window = WindUI:CreateWindow({
    Title = "ESP Script",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 450),
    Folder = "GUI",
    AutoScale = true
})

-- 3. Edit Open Button
Window:EditOpenButton({
    Title = "Open ESP Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
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
local ESP = {}
local currentGun = nil
_G.BoxESPEnabled = false
_G.GunESP = false
_G.HighlightESP = false
_G.LineESPEnabled = false
_G.NametagESPEnabled = false
_G.HighlightCache = {}

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,255,0)
}

-- 7. Toggles
EspTab:Toggle({Title="Box ESP", Default=false, Callback=function(state) _G.BoxESPEnabled=state end})
EspTab:Toggle({Title="Gun ESP", Default=false, Callback=function(state) _G.GunESP=state end})
EspTab:Toggle({Title="Highlight ESP", Default=false, Callback=function(state) 
    _G.HighlightESP=state 
    for _, hl in pairs(_G.HighlightCache) do
        if hl then hl.Enabled = state end
    end
end})
EspTab:Toggle({Title="Line ESP", Default=false, Callback=function(state) _G.LineESPEnabled=state end})
EspTab:Toggle({Title="Nametag ESP", Default=false, Callback=function(state) _G.NametagESPEnabled=state end})

-- 8. Functions
local function detectRole(player)
    local role = "Innocent"
    local bp = player:FindFirstChild("Backpack")
    if bp then
        if bp:FindFirstChild("Knife") then role="Murderer"
        elseif bp:FindFirstChild("Gun") then role="Sheriff" end
    end
    local char = player.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name=="Knife" then role="Murderer"
                elseif tool.Name=="Gun" then role="Sheriff" end
            end
        end
    end
    return role
end

local function safeNewDrawing(class, props)
    local ok, obj = pcall(function() return Drawing and Drawing.new(class) end)
    if not ok or not obj then return nil end
    if props then
        for k,v in pairs(props) do pcall(function() obj[k]=v end) end
    end
    return obj
end

local function worldToScreen(pos)
    local ok, sp, onScreen = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if not ok or not sp then return Vector2.new(0,0), false end
    return Vector2.new(sp.X, sp.Y), onScreen
end

local function rgb(t) return Color3.fromHSV((tick()*t)%1,1,1) end

-- Box ESP
local BoxESP = {}
local function createPlayerBox(player)
    if player==LocalPlayer or BoxESP[player] then return end
    BoxESP[player] = {Box=safeNewDrawing("Square",{Thickness=1,Filled=false,Visible=false})}
    player.CharacterAdded:Connect(function() task.wait(0.1) end)
end

local function destroyPlayerBox(player)
    local data = BoxESP[player]
    if not data then return end
    if data.Box then pcall(function() data.Box:Remove() end) end
    BoxESP[player] = nil
end

-- Gun ESP
local gunBox = safeNewDrawing("Square",{Filled=false,Visible=false,Thickness=2,Color=Color3.fromRGB(0,150,255)})
local gunLine = safeNewDrawing("Line",{Visible=false,Thickness=2,Color=Color3.fromRGB(0,150,255)})
local gunText = safeNewDrawing("Text",{Visible=false,Text="GUN",Size=16,Center=true,Outline=true,Color=Color3.fromRGB(0,150,255)})

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and obj.Name=="GunDrop" then currentGun=obj end
end)
workspace.DescendantRemoving:Connect(function(obj) if obj==currentGun then currentGun=nil end end)

-- Highlight ESP
local function applyHighlight(player)
    if player==LocalPlayer then return end
    local char = player.Character
    if not char then return end
    if _G.HighlightCache[player] then _G.HighlightCache[player]:Destroy() _G.HighlightCache[player]=nil end
    local hl = Instance.new("Highlight")
    hl.Name="RoleHighlightESP"
    hl.Parent=char
    hl.Adornee=char
    hl.FillTransparency=0
    hl.OutlineTransparency=0.4
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor=ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
    hl.Enabled=_G.HighlightESP
    _G.HighlightCache[player]=hl
end

local function removeHighlight(player)
    if _G.HighlightCache[player] then _G.HighlightCache[player]:Destroy() _G.HighlightCache[player]=nil end
end

-- Line ESP
local LineESP = {}
local function createLineESP(player)
    if player==LocalPlayer or LineESP[player] then
        return
    end
    LineESP[player]={Line=safeNewDrawing("Line",{Thickness=2,Visible=false})}
end
local function destroyLineESP(player)
    if LineESP[player] then
        pcall(function() LineESP[player].Line:Remove() end)
        LineESP[player]=nil
    end
end

-- Nametag ESP
local NametagESP = {}
local function createPlayerNametag(player)
    if not NametagESP[player] then NametagESP[player]={} end
    if not NametagESP[player].NameTag then
        NametagESP[player].NameTag = safeNewDrawing("Text",{
            Text=player.Name,Size=14,Center=true,Outline=true,
            Color=ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent,Visible=false
        })
    end
end
local function destroyPlayerNametag(player)
    if NametagESP[player] and NametagESP[player].NameTag then
        pcall(function() NametagESP[player].NameTag:Remove() end)
        NametagESP[player].NameTag=nil
    end
end

-- Player Connections
Players.PlayerAdded:Connect(function(player)
    createPlayerBox(player)
    createLineESP(player)
    createPlayerNametag(player)
    player.CharacterAdded:Connect(function() task.wait(0.15) applyHighlight(player) end)
end)
Players.PlayerRemoving:Connect(function(player)
    destroyPlayerBox(player)
    destroyLineESP(player)
    destroyPlayerNametag(player)
    removeHighlight(player)
end)
for _,p in pairs(Players:GetPlayers()) do
    createPlayerBox(p)
    createLineESP(p)
    createPlayerNametag(p)
    if p.Character then applyHighlight(p) end
end

-- 9. RenderStepped Loop
RunService.RenderStepped:Connect(function()
    local hrp, head, top2D, bottom2D, onTop, onBottom, height, width
    for player, data in pairs(BoxESP) do
        local char = player.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        head = char and char:FindFirstChild("Head")
        if _G.BoxESPEnabled and char and hrp and head then
            top2D, onTop = worldToScreen(head.Position+Vector3.new(0,0.5,0))
            bottom2D, onBottom = worldToScreen(hrp.Position-Vector3.new(0,2.5,0))
            if onTop and onBottom then
                height = math.abs(top2D.Y-bottom2D.Y)
                width = height/2
                data.Box.Position=Vector2.new(top2D.X-width/2, top2D.Y)
                data.Box.Size=Vector2.new(width,height)
                data.Box.Color=ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
                data.Box.Visible=true
            else data.Box.Visible=false end
        else data.Box.Visible=false end
    end

    -- Gun ESP
    if _G.GunESP and currentGun then
        local pos, vis = Camera:WorldToViewportPoint(currentGun.Position)
        if vis then
            local screenPos = Vector2.new(pos.X,pos.Y)
            gunBox.Position=screenPos-Vector2.new(30,30)
            gunBox.Size=Vector2.new(60,60)
            gunBox.Visible=true
            gunLine.From=Vector2.new(Camera.ViewportSize.X/2,0)
            gunLine.To=screenPos
            gunLine.Visible=true
            gunText.Position=screenPos
            gunText.Color=rgb(0.5)
            gunText.Visible=true
        else
            gunBox.Visible=false
            gunLine.Visible=false
            gunText.Visible=false
        end
    else
        gunBox.Visible=false
        gunLine.Visible=false
        gunText.Visible=false
    end

    -- Line ESP
    for player, data in pairs(LineESP) do
        local char = player.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        head = char and char:FindFirstChild("Head")
        if _G.LineESPEnabled and char and hrp and head then
            top2D, onTop = worldToScreen(head.Position+Vector3.new(0,0.5,0))
            if onTop then
                data.Line.From=Vector2.new(Camera.ViewportSize.X/2,0)
                data.Line.To=top2D
                data.Line.Color=ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
                data.Line.Visible=true
            else data.Line.Visible=false end
        else data.Line.Visible=false end
    end

    -- Nametag ESP
    for player,data in pairs(NametagESP) do
        local char = player.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        head = char and char:FindFirstChild("Head")
        if _G.NametagESPEnabled and char and hrp and head then
            top2D, onTop = worldToScreen(head.Position+Vector3.new(0,0.5,0))
            if onTop then
                data.NameTag.Position = top2D - Vector2.new(0,15)
                data.NameTag.Color = ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
                data.NameTag.OutlineColor = Color3.fromRGB(0,0,0)
                data.NameTag.Size = 14
                data.NameTag.Visible = true
            else
                data.NameTag.Visible=false
            end
        else
            data.NameTag.Visible=false
        end
    end

    -- Highlight ESP
    if _G.HighlightESP then
        for player, hl in pairs(_G.HighlightCache) do
            if hl and hl.Parent then
                hl.FillColor = ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
            end
        end
    end
end)