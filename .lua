-- 1. WindUI Loader
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI load failed") end

-- 2. Window Oluşturma
local Window = WindUI:CreateWindow({
    Title = "Box ESP Script",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 390),
    Folder = "GUI",
    AutoScale = false
})

-- 3. Edit Open Button
Window:EditOpenButton({
    Title = "Open Menu",
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
_G.BoxESPEnabled = false
local ESP = {}
local ROLE_COLORS = { Murderer=Color3.fromRGB(200,0,0), Sheriff=Color3.fromRGB(0,0,200), Innocent=Color3.fromRGB(0,200,0) }
local currentGun = nil
_G.HighlightESP = false

_G.HighlightCache = {}

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff  = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

_G.LineESPEnabled = false
local ESP = {}
local RoleCache = {}

-- 7. Toggles
EspTab:Toggle({Title="Box ESP", Default=false, Callback=function(state) _G.BoxESPEnabled=state end})

_G.GunESP = false
EspTab:Toggle({
    Title="Enable Gun ESP",
    Default=false,
    Callback=function(s)
        _G.GunESP = s
    end
})

EspTab:Toggle({
    Title = "Highlight ESP",
    Default = false,
    Callback = function(state)
        _G.HighlightESP = state
        for _, hl in pairs(_G.HighlightCache) do
            if hl then hl.Enabled = state end
        end
    end
})

EspTab:Toggle({
    Title="Player Line ESP", 
    Default=false, 
    Callback=function(state) _G.LineESPEnabled = state end
})

-- 8. Functions
local function detectRole(player) -- Rol tespiti
    local role = "Innocent"
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        if backpack:FindFirstChild("Knife") then role="Murderer"
        elseif backpack:FindFirstChild("Gun") then role="Sheriff" end
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

local function safeNewDrawing(class, props) -- Drawing objesi oluşturma
    local ok, obj = pcall(function() return Drawing and Drawing.new(class) end)
    if not ok or not obj then return nil end
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k]=v end)
        end
    end
    return obj
end

local function worldToScreen(pos) -- 3D -> 2D
    local ok, sp, onScreen = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if not ok or not sp then return Vector2.new(0,0), false end
    return Vector2.new(sp.X, sp.Y), onScreen
end

local function createPlayerBox(player) -- Player için Box ESP oluşturma
    if player==LocalPlayer or ESP[player] then return end
    local box = safeNewDrawing("Square",{Thickness=1,Filled=false,Visible=false})
    ESP[player] = {Box=box}

    local function setupCharacter(char)
        if box then
            box.Visible = _G.BoxESPEnabled
        end
    end

    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then
        setupCharacter(player.Character)
    end
end

local function destroyPlayerBox(player) -- Player Box ESP yok etme
    local data = ESP[player]
    if not data then return end
    if data.Box then pcall(function() data.Box:Remove() end) end
    ESP[player] = nil
end

-- 9. Connections
Players.PlayerAdded:Connect(createPlayerBox)
Players.PlayerRemoving:Connect(destroyPlayerBox)
for _,p in pairs(Players:GetPlayers()) do createPlayerBox(p) end

-- 10. Render Loop
RunService.RenderStepped:Connect(function()
    for player,data in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if not _G.BoxESPEnabled or not (char and hrp) then
            if data.Box then data.Box.Visible=false end
        else
            if head and hrp then
                local top2D, onTop = worldToScreen(head.Position+Vector3.new(0,0.5,0))
                local bottom2D, onBottom = worldToScreen(hrp.Position-Vector3.new(0,2.5,0))
                if onTop and onBottom then
                    local height = math.abs(top2D.Y-bottom2D.Y)
                    local width = height/2
                    if data.Box then
                        data.Box.Position = Vector2.new(top2D.X-width/2, top2D.Y)
                        data.Box.Size = Vector2.new(width, height)
                        data.Box.Color = ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
                        data.Box.Visible = true
                    end
                else
                    if data.Box then data.Box.Visible=false end
                end
            end
        end
    end
end)

local gunBox = Drawing.new("Square")
gunBox.Visible = false
gunBox.Filled = false
gunBox.Thickness = 2
gunBox.Color = Color3.fromRGB(0, 150, 255)

local gunLine = Drawing.new("Line")
gunLine.Visible = false
gunLine.Thickness = 2
gunLine.Color = Color3.fromRGB(0, 150, 255)

local gunText = Drawing.new("Text")
gunText.Visible = false
gunText.Size = 16
gunText.Center = true
gunText.Outline = true
gunText.Text = "GUN"
gunText.Color = Color3.fromRGB(0, 150, 255)

-- GunDrop event tabanlı tespiti
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and obj.Name == "GunDrop" then
        currentGun = obj
    end
end)

workspace.DescendantRemoving:Connect(function(obj)
    if obj == currentGun then
        currentGun = nil
    end
end)

-- RGB fonksiyonu
local function rgb(t)
    return Color3.fromHSV((tick() * t) % 1, 1, 1)
end

-- RenderStepped Loop
RunService.RenderStepped:Connect(function()
    if _G.GunESP and currentGun then
        local pos, vis = Camera:WorldToViewportPoint(currentGun.Position)
        if vis then
            local screenPos = Vector2.new(pos.X, pos.Y)
            gunBox.Visible = true
            gunLine.Visible = true
            gunText.Visible = true

            gunBox.Position = screenPos - Vector2.new(30, 30)
            gunBox.Size = Vector2.new(60, 60)

            gunLine.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
            gunLine.To = screenPos

            gunText.Position = screenPos
            gunText.Color = rgb(0.5)
        else
            gunBox.Visible = false
            gunLine.Visible = false
            gunText.Visible = false
        end
    else
        gunBox.Visible = false
        gunLine.Visible = false
        gunText.Visible = false
    end
end)

-- Role detection (MM2 uyumlu)
local function detectRole(player)
    local role = "Innocent"

    local function check(container)
        if not container then return end
        if container:FindFirstChild("Knife") then
            role = "Murderer"
        elseif container:FindFirstChild("Gun") then
            role = "Sheriff"
        end
    end

    check(player:FindFirstChild("Backpack"))
    if player.Character then
        check(player.Character)
    end

    return role
end


-- Highlight uygula (RESET FIX BURADA)
local function applyHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    -- eskisini temizle
    if _G.HighlightCache[player] then
        _G.HighlightCache[player]:Destroy()
        _G.HighlightCache[player] = nil
    end

    local hl = Instance.new("Highlight")
    hl.Name = "RoleHighlightESP"
    hl.Parent = char
    hl.Adornee = char

    hl.FillTransparency = 0                 -- TAM DOLU
    hl.OutlineTransparency = 0.4             -- BEYAZ OUTLINE
   
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    hl.FillColor = ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
    hl.Enabled = _G.HighlightESP

    _G.HighlightCache[player] = hl
end


local function removeHighlight(player)
    if _G.HighlightCache[player] then
        _G.HighlightCache[player]:Destroy()
        _G.HighlightCache[player] = nil
    end
end


-- Player bağlantıları
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.15)
        applyHighlight(player)
    end)
end)

Players.PlayerRemoving:Connect(removeHighlight)


-- Mevcut oyuncular
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then
            applyHighlight(player)
        end
        player.CharacterAdded:Connect(function()
            task.wait(0.15)
            applyHighlight(player)
        end)
    end
end


-- Role değişimini hafif loop ile güncelle (optimize)
task.spawn(function()
    while true do
        task.wait(0.4)
        if not _G.HighlightESP then continue end

        for player, hl in pairs(_G.HighlightCache) do
            if hl and hl.Parent then
                hl.FillColor = ROLE_COLORS[detectRole(player)] or ROLE_COLORS.Innocent
            end
        end
    end
end)
local function detectRole(player)
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    local role = "Innocent"

    if bp and bp:FindFirstChild("Knife") then
        role = "Murderer"
    elseif bp and bp:FindFirstChild("Gun") then
        role = "Sheriff"
    elseif char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name == "Knife" then
                    role = "Murderer"
                    break
                elseif tool.Name == "Gun" then
                    role = "Sheriff"
                    break
                end
            end
        end
    end

    -- Cache güncelle
    if RoleCache[player] ~= role then
        RoleCache[player] = role
    end
    return role
end

local function safeNewDrawing(class, props)
    local ok, obj = pcall(function() return Drawing and Drawing.new(class) end)
    if not ok or not obj then return nil end
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

local function worldToScreen(pos)
    local ok, sp, onScreen = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if not ok or not sp then return Vector2.new(0,0), false end
    return Vector2.new(sp.X, sp.Y), onScreen
end

-- Player Line ESP yaratma
local function createLineESP(player)
    if player == LocalPlayer or ESP[player] then return end
    local line = safeNewDrawing("Line", {Thickness=2, Visible=false})
    ESP[player] = {Line=line}

    local function onCharacterAdded(char)
        task.wait(0.1)
        if ESP[player] and ESP[player].Line then
            ESP[player].Line.Visible = _G.LineESPEnabled
        end
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then onCharacterAdded(player.Character) end
end

local function destroyLineESP(player)
    local data = ESP[player]
    if not data then return end
    if data.Line then pcall(function() data.Line:Remove() end) end
    ESP[player] = nil
    RoleCache[player] = nil
end

Players.PlayerAdded:Connect(createLineESP)
Players.PlayerRemoving:Connect(destroyLineESP)
for _, p in pairs(Players:GetPlayers()) do createLineESP(p) end

-- RenderStepped Loop
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if not _G.LineESPEnabled or not (char and hrp and head) then
            if data.Line then data.Line.Visible=false end
        else
            local role = detectRole(player)
            local top2D, onTop = worldToScreen(head.Position + Vector3.new(0,0.5,0))
            if onTop then
                data.Line.From = Vector2.new(Camera.ViewportSize.X/2,0)
                data.Line.To = top2D
                data.Line.Color = ROLE_COLORS[role] or ROLE_COLORS.Innocent
                data.Line.Visible = true
            else
                data.Line.Visible = false
            end
        end
    end
end)