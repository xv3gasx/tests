local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI load failed") end

local Window = WindUI:CreateWindow({
    Title = "Box ESP Script",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 390),
    Folder = "GUI",
    AutoScale = false
})

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

local BoxTab = Window:Tab({Title="Box ESP", Icon="app-window"})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.BoxESPEnabled = false
local ESP = {}
local ROLE_COLORS = { Murderer=Color3.fromRGB(200,0,0), Sheriff=Color3.fromRGB(0,0,200), Innocent=Color3.fromRGB(0,200,0) } -- koyu renkler

local function detectRole(player)
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

local function safeNewDrawing(class, props)
    local ok, obj = pcall(function() return Drawing and Drawing.new(class) end)
    if not ok or not obj then return nil end
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k]=v end)
        end
    end
    return obj
end

local function worldToScreen(pos)
    local ok, sp, onScreen = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if not ok or not sp then return Vector2.new(0,0), false end
    return Vector2.new(sp.X, sp.Y), onScreen
end

local function createPlayerBox(player)
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

local function destroyPlayerBox(player)
    local data = ESP[player]
    if not data then return end
    if data.Box then pcall(function() data.Box:Remove() end) end
    ESP[player] = nil
end

Players.PlayerAdded:Connect(createPlayerBox)
Players.PlayerRemoving:Connect(destroyPlayerBox)
for _,p in pairs(Players:GetPlayers()) do createPlayerBox(p) end

BoxTab:Toggle({Title="Enable Box ESP", Default=false, Callback=function(state) _G.BoxESPEnabled=state end})

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