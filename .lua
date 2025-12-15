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