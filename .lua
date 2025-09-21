local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Murderer Mystery 2 Script",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(660, 430),
    Folder = "GUÄ°",
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local Tab = Window:Tab({
    Title = "Esp",
    Icon = "app-window",
    Locked = false,
})

_G.ESPEnabled = false  

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local function NewDrawing(class, props)
    local obj = Drawing.new(class)
    for i,v in pairs(props) do obj[i] = v end
    return obj
end

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local ESP = {}

local colors = {
    Murderer = Color3.fromRGB(200,0,0),
    Sheriff = Color3.fromRGB(0,0,200),
    Innocent = Color3.fromRGB(0,150,0)
}
local lineColors = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,255,0)
}
local highlightColors = {
    Murderer = Color3.fromRGB(255,100,100),
    Sheriff = Color3.fromRGB(100,100,255),
    Innocent = Color3.fromRGB(0,255,0)
}
local nameColors = {
    Murderer = Color3.fromRGB(150,0,0),
    Sheriff = Color3.fromRGB(0,0,150),
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

    local line = NewDrawing("Line",{Thickness=2,Visible=false})
    local box = NewDrawing("Square",{Thickness=2,Filled=false,Visible=false})
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
        ESP[player].Line:Remove()
        ESP[player].Box:Remove()
        ESP[player].NameTag:Remove()
        if ESP[player].Highlight then ESP[player].Highlight:Destroy() end
        ESP[player] = nil
    end
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _,plr in pairs(Players:GetPlayers()) do AddESP(plr) end

RunService.RenderStepped:Connect(function()
    for player,data in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")
        if not (char and hrp and hum and hum.Health > 0) then
            data.Line.Visible = false
            data.Box.Visible = false
            data.NameTag.Visible = false
            if data.Highlight then data.Highlight.Enabled = false end
            continue
        end

        if _G.ESPEnabled then
            local role = detectRole(player)
            if data.Highlight then
                data.Highlight.FillColor = highlightColors[role]
                data.Highlight.Enabled = true
            end

            if head and hrp then
                local r6Height = 5
                local topPos = hrp.Position + Vector3.new(0,r6Height/2,0)
                local bottomPos = hrp.Position - Vector3.new(0,r6Height/2,0)
                local top2D,onTop,_ = WorldToScreen(topPos)
                local bottom2D,onBottom,_ = WorldToScreen(bottomPos)
                if onTop and onBottom then
                    local height = math.abs(top2D.Y - bottom2D.Y)
                    local width = height/2

                    data.Box.Position = Vector2.new(top2D.X - width/2, top2D.Y)
                    data.Box.Size = Vector2.new(width,height)
                    data.Box.Color = colors[role]
                    data.Box.Visible = true

                    local root2D,_ = WorldToScreen(hrp.Position)
                    data.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
                    data.Line.To = root2D
                    data.Line.Color = lineColors[role]
                    data.Line.Visible = true

                    data.NameTag.Position = top2D - Vector2.new(0,15)
                    data.NameTag.Color = nameColors[role]
                    data.NameTag.Visible = role ~= "Innocent"
                else
                    data.Box.Visible = false
                    data.Line.Visible = false
                    data.NameTag.Visible = false
                end
            end
        else
            
            data.Line.Visible = false
            data.Box.Visible = false
            data.NameTag.Visible = false
            if data.Highlight then data.Highlight.Enabled = false end
        end
    end
end)

local Toggle = Tab:Toggle({
    Title = "ESP",
    Default = false,
    Callback = function(state) 
        print("ESP Toggle: " .. tostring(state))
        _G.ESPEnabled = state
    end
})
