local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Murder Mystery 2 Script",
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

local Tab = Window:Tab({ Title = "Esp", Icon = "app-window", Locked = false })

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.ESPEnabled = false
_G.GunESPEnabled = false

local function NewDrawing(class, props)
    local obj = Drawing.new(class)
    for i,v in pairs(props) do obj[i] = v end
    return obj
end

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local Section = Tab:Section({ 
    Title = "Player ESP",
    TextXAlignment = "Left",
    TextSize = 35, -- Default Size
})

local ESP = {}

local colors = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,255,0)
}

local lineColors = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,255,0)
}

local highlightColors = {
    Murderer = Color3.fromRGB(255,100,100),
    Sheriff   = Color3.fromRGB(100,100,255),
    Innocent  = Color3.fromRGB(0,255,0)
}

local nameColors = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,0,0)
}

local function detectRole(player)
    if not player or not player.Character then return "Innocent" end
    local role = "Innocent"
    if player:FindFirstChild("Backpack") then
        if player.Backpack:FindFirstChild("Knife") then
            role = "Murderer"
        elseif player.Backpack:FindFirstChild("Gun") then
            role = "Sheriff"
        end
    end
    for _,tool in pairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name == "Knife" then role = "Murderer"
            elseif tool.Name == "Gun" then role = "Sheriff" end
        end
    end
    return role
end

local function AddESP(player)
    if player == LocalPlayer or ESP[player] then return end
    local line = NewDrawing("Line",{Thickness=3,Visible=false})
    local box  = NewDrawing("Square",{Thickness=1,Filled=false,Visible=false})
    local nameTag = NewDrawing("Text",{Size=16,Center=true,Outline=true,Visible=false,Text=player.Name})
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    ESP[player] = {Line=line, Box=box, Highlight=highlight, NameTag=nameTag}
    player.CharacterAdded:Connect(function(char)
        highlight.Parent = char
        highlight.Adornee = char
    end)
    if player.Character then
        highlight.Parent = player.Character
        highlight.Adornee = player.Character
    end
end

local function RemoveESP(player)
    if ESP[player] then
        pcall(function() ESP[player].Line:Remove() end)
        pcall(function() ESP[player].Box:Remove() end)
        pcall(function() ESP[player].NameTag:Remove() end)
        if ESP[player].Highlight then pcall(function() ESP[player].Highlight:Destroy() end) end
        ESP[player] = nil
    end
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _,p in pairs(Players:GetPlayers()) do AddESP(p) end

local gunLine = NewDrawing("Line",{Thickness=3,Visible=false})
local gunBox  = NewDrawing("Square",{Thickness=1,Filled=false,Visible=false})

local currentGun = nil
local function findGunDrop()
    for _,obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

task.spawn(function()
    while true do
        currentGun = findGunDrop()
        task.wait(0.3)
    end
end)

local function getRainbowColor()
    local t = tick() % 5
    return Color3.fromHSV((t/5)%1,1,1)
end

local function teleportToGun()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local gun = currentGun or findGunDrop()
    if gun and gun:IsA("BasePart") then
        hrp.CFrame = gun.CFrame + Vector3.new(0,3,0)
    end
end

local function drawPlayerESP(player, data)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local head = char and char:FindFirstChild("Head")
    if not (char and hrp and hum and hum.Health > 0) then
        data.Line.Visible = false
        data.Box.Visible = false
        data.NameTag.Visible = false
        if data.Highlight then data.Highlight.Enabled = false end
        return
    end
    if not _G.ESPEnabled then
        data.Line.Visible = false
        data.Box.Visible = false
        data.NameTag.Visible = false
        if data.Highlight then data.Highlight.Enabled = false end
        return
    end
    local role = detectRole(player)
    if data.Highlight then
        data.Highlight.FillColor = highlightColors[role]
        data.Highlight.Enabled = true
    end
    local topPos = head and (head.Position + Vector3.new(0,0.5,0)) or (hrp.Position + Vector3.new(0,2.5,0))
    local bottomPos = hrp.Position - Vector3.new(0,2.5,0)
    local top2D,onTop = WorldToScreen(topPos)
    local bottom2D,onBottom = WorldToScreen(bottomPos)
    if onTop and onBottom then
        local height = math.abs(top2D.Y - bottom2D.Y)
        local width = height/2
        data.Box.Position = Vector2.new(top2D.X - width/2, top2D.Y)
        data.Box.Size = Vector2.new(width, height)
        data.Box.Color = colors[role]
        data.Box.Visible = true
        local root2D, rootOn = WorldToScreen(hrp.Position)
        if rootOn then
            data.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
            data.Line.To = root2D
            data.Line.Color = lineColors[role]
            data.Line.Thickness = 3
            data.Line.Visible = true
        else
            data.Line.Visible = false
        end
        data.NameTag.Position = top2D - Vector2.new(0,15)
        data.NameTag.Color = nameColors[role]
        data.NameTag.Visible = role ~= "Innocent"
    else
        data.Box.Visible = false
        data.Line.Visible = false
        data.NameTag.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if _G.GunESPEnabled and currentGun and currentGun:IsA("BasePart") then
        local gunPos, onScreen = Camera:WorldToViewportPoint(currentGun.Position)
        if onScreen then
            local rgb = getRainbowColor()
            gunLine.From = Vector2.new(Camera.ViewportSize.X/2, 0)
            gunLine.To = Vector2.new(gunPos.X, gunPos.Y)
            gunLine.Color = rgb
            gunLine.Visible = true
            gunBox.Position = Vector2.new(gunPos.X - 12, gunPos.Y - 12)
            gunBox.Size = Vector2.new(24,24)
            gunBox.Color = rgb
            gunBox.Visible = true
        else
            gunLine.Visible = false
            gunBox.Visible = false
        end
    else
        gunLine.Visible = false
        gunBox.Visible = false
    end

    for player,data in pairs(ESP) do
        drawPlayerESP(player, data)
    end
end)

local Toggle = Tab:Toggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(state)
        _G.ESPEnabled = state
    end
})
local Section = Tab:Section({ 
    Title = "Gun ESP",
    TextXAlignment = "Left",
    TextSize = 35, -- Default Size
})

local GunToggle = Tab:Toggle({
    Title = "Gun ESP",
    Default = false,
    Callback = function(state)
        _G.GunESPEnabled = state
    end
})

local TPBtn = Tab:Button({
    Title = "Gun TP",
    Callback = function()
        teleportToGun()
    end
})

local Tab = Window:Tab({ Title = "TP", Icon = "zap", Locked = false })

local Section = Tab:Section({ 
    Title = "TP",
    TextXAlignment = "Left",
    TextSize = 35, -- Default Size
})

local Button = Tab:Button({
    Title = "Tp To Sherrif",
    Locked = false,
    Callback = function()
    end
})

local Button = Tab:Button({
    Title = "Tp To Murderer",
    Locked = false,
    Callback = function()
    end
})
