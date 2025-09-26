-- WindUI Loader
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:Notify({
    Title = "Load Successful ^^",
    Content = "Join Discord For More Scripts/Updates",
    Duration = 3,
    Icon = "swords",
})

-- Window
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

-- Tabs
local ESP_Tab = Window:Tab({ Title = "ESP", Icon = "app-window" })
local TP_Tab = Window:Tab({ Title = "TP", Icon = "zap" })
local Local_Tab = Window:Tab({ Title = "Local Player", Icon = "user" })

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Globals
_G.ESPEnabled = false
_G.GunESPEnabled = false
_G.WalkSpeedValue = 16
_G.InfiniteJumpEnabled = false
_G.NoclipEnabled = false

-- Utils
local function NewDrawing(class, props)
    local obj = Drawing.new(class)
    for i,v in pairs(props) do obj[i]=v end
    return obj
end

local function WorldToScreen(pos)
    local screenPos,onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local colors = {Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0)}

-- Role Detect
local function detectRole(player)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        if backpack:FindFirstChild("Knife") then return "Murderer"
        elseif backpack:FindFirstChild("Gun") then return "Sheriff" end
    end
    local char = player.Character
    if char then
        for _,tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name=="Knife" then return "Murderer"
                elseif tool.Name=="Gun" then return "Sheriff" end
            end
        end
    end
    return "Innocent"
end

-- ESP
local ESP = {}
local function AddESP(player)
    if player == LocalPlayer or ESP[player] then return end
    local line = NewDrawing("Line",{Thickness=2,Visible=false})
    local box  = NewDrawing("Square",{Thickness=1,Filled=false,Visible=false})
    local nameTag = NewDrawing("Text",{Size=15,Center=true,Outline=true,Visible=false,Text=player.Name})
    local highlight = Instance.new("Highlight")
    highlight.Name="ESP_Highlight"
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled=false

    ESP[player] = {Line=line, Box=box, NameTag=nameTag, Highlight=highlight}

    player.CharacterAdded:Connect(function(char)
        highlight.Parent=char
        highlight.Adornee=char
    end)

    if player.Character then
        highlight.Parent=player.Character
        highlight.Adornee=player.Character
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
for _,p in pairs(Players:GetPlayers()) do AddESP(p) end

-- Gun ESP (Event-based, no loop scanning!)
local gunBox, gunLine = NewDrawing("Square",{Visible=false}), NewDrawing("Line",{Visible=false})
local currentGun = nil

workspace.DescendantAdded:Connect(function(obj)
    if obj.Name=="GunDrop" and obj:IsA("BasePart") then currentGun=obj end
end)
workspace.DescendantRemoving:Connect(function(obj)
    if obj == currentGun then currentGun=nil gunBox.Visible=false gunLine.Visible=false end
end)

-- WalkSpeed
local function setWalkSpeed()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed ~= _G.WalkSpeedValue then hum.WalkSpeed=_G.WalkSpeedValue end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.3) setWalkSpeed() end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip (optimize: only parts of character, not every frame heavy loop)
RunService.Stepped:Connect(function()
    if _G.NoclipEnabled then
        local char=LocalPlayer.Character
        if char then
            for _,part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide=false end
            end
        end
    end
end)

-- Render Loop
RunService.RenderStepped:Connect(function()
    for player,data in pairs(ESP) do
        local char=player.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local head=char and char:FindFirstChild("Head")

        if not _G.ESPEnabled or not (char and hrp and hum and hum.Health>0) then
            data.Box.Visible=false data.Line.Visible=false data.NameTag.Visible=false
            if data.Highlight then data.Highlight.Enabled=false end
        else
            local role=detectRole(player)
            if data.Highlight then data.Highlight.FillColor=colors[role]; data.Highlight.Enabled=true end

            local top2D,onTop=WorldToScreen(head.Position+Vector3.new(0,0.5,0))
            local bottom2D,onBottom=WorldToScreen(hrp.Position-Vector3.new(0,2.5,0))
            if onTop and onBottom then
                local height=math.abs(top2D.Y-bottom2D.Y)
                local width=height/2
                data.Box.Position=Vector2.new(top2D.X-width/2,top2D.Y)
                data.Box.Size=Vector2.new(width,height)
                data.Box.Color=colors[role]
                data.Box.Visible=true

                data.NameTag.Position=top2D-Vector2.new(0,15)
                data.NameTag.Color=role=="Innocent" and Color3.fromRGB(0,0,0) or colors[role]
                data.NameTag.Visible=role~="Innocent"

                data.Line.From=Vector2.new(Camera.ViewportSize.X/2,0)
                data.Line.To=Vector2.new(top2D.X,top2D.Y)
                data.Line.Color=colors[role]
                data.Line.Visible=true
            else
                data.Box.Visible=false data.NameTag.Visible=false data.Line.Visible=false
            end
        end
    end

    if _G.GunESPEnabled and currentGun then
        local pos,onScreen=Camera:WorldToViewportPoint(currentGun.Position)
        if onScreen then
            gunBox.Position=Vector2.new(pos.X-10,pos.Y-10)
            gunBox.Size=Vector2.new(20,20)
            gunBox.Color=Color3.fromRGB(255,255,0)
            gunBox.Visible=true
            gunLine.From=Vector2.new(Camera.ViewportSize.X/2,0)
            gunLine.To=Vector2.new(pos.X,pos.Y)
            gunLine.Color=Color3.fromRGB(255,255,0)
            gunLine.Visible=true
        else
            gunBox.Visible=false gunLine.Visible=false
        end
    else
        gunBox.Visible=false gunLine.Visible=false
    end
end)

-- UI Toggles
ESP_Tab:Toggle({Title="Player ESP",Default=false,Callback=function(state) _G.ESPEnabled=state end})
ESP_Tab:Toggle({Title="Gun ESP",Default=false,Callback=function(state) _G.GunESPEnabled=state end})
Local_Tab:Slider({Title="WalkSpeed",Step=1,Value={Min=16,Max=100,Default=16},Callback=function(val) _G.WalkSpeedValue=val setWalkSpeed() end})
Local_Tab:Toggle({Title="Infinite Jump",Default=false,Callback=function(state) _G.InfiniteJumpEnabled=state end})
Local_Tab:Toggle({Title="Noclip",Default=false,Callback=function(state) _G.NoclipEnabled=state end})