-- WindUI Loader
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
WindUI:Notify({
    Title = "Load Successful",
    Content = "MM2 Script Loaded",
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
_G.WalkSpeedValue = 16
_G.InfiniteJumpEnabled = false
_G.NoclipEnabled = false

-- Utility
local function NewDrawing(class, props)
    local obj = Drawing.new(class)
    for i,v in pairs(props) do obj[i]=v end
    return obj
end

local function WorldToScreen(pos)
    local screenPos,onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- Colors
local colors = {Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0)}

-- Detect Role
local function detectRole(player)
    local role = "Innocent"
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        if backpack:FindFirstChild("Knife") then role="Murderer"
        elseif backpack:FindFirstChild("Gun") then role="Sheriff" end
    end
    local char = player.Character
    if char then
        for _,tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name=="Knife" then role="Murderer"
                elseif tool.Name=="Gun" then role="Sheriff" end
            end
        end
    end
    return role
end

-- ESP (Highlight + Box + Line)
local ESP = {}
local function AddESP(player)
    if player == LocalPlayer or ESP[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false

    local box = NewDrawing("Square",{Thickness=1,Filled=false,Visible=false})
    local line = NewDrawing("Line",{Thickness=3,Visible=false})

    ESP[player] = {Highlight=highlight, Box=box, Line=line}

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
        pcall(function() if ESP[player].Highlight then ESP[player].Highlight:Destroy() end end)
        pcall(function() if ESP[player].Box then ESP[player].Box:Remove() end end)
        pcall(function() if ESP[player].Line then ESP[player].Line:Remove() end end)
        ESP[player] = nil
    end
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _,p in pairs(Players:GetPlayers()) do AddESP(p) end

-- Teleports
local function teleportBehind(target)
    local hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and myHRP then
        myHRP.CFrame = CFrame.new(hrp.Position - hrp.CFrame.LookVector*8, hrp.Position)
    end
end

local function getSheriff()
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and ((p.Backpack:FindFirstChild("Gun")) or (p.Character and p.Character:FindFirstChild("Gun"))) then return p end
    end
end

local function getMurderer()
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and ((p.Backpack:FindFirstChild("Knife")) or (p.Character and p.Character:FindFirstChild("Knife"))) then return p end
    end
end

-- WalkSpeed
local function setWalkSpeed()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= _G.WalkSpeedValue then
            hum.WalkSpeed = _G.WalkSpeedValue
        end
    end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5) setWalkSpeed() end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if _G.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _,part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide=false end
            end
        end
    end
end)

-- TP Buttons
TP_Tab:Button({Title="Teleport to Murderer", Callback=function()
    local m = getMurderer()
    if m then teleportBehind(m)
    else WindUI:Notify({Title="Murderer Not Found", Content="No murderer detected yet.", Duration=3, Icon="x"}) end
end})

TP_Tab:Button({Title="Teleport to Sheriff", Callback=function()
    local s = getSheriff()
    if s then teleportBehind(s)
    else WindUI:Notify({Title="Sheriff Not Found", Content="No sheriff detected yet.", Duration=3, Icon="x"}) end
end})

-- ESP Toggle
ESP_Tab:Toggle({Title="Player ESP", Default=false, Callback=function(state)
    _G.ESPEnabled = state
end})

-- RenderLoop (Highlight + Box + Line)
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not _G.ESPEnabled or not (char and hrp and hum and hum.Health>0) then
            if data.Highlight then data.Highlight.Enabled=false end
            if data.Box then data.Box.Visible=false end
            if data.Line then data.Line.Visible=false end
        else
            local role = detectRole(player)
            if data.Highlight then
                data.Highlight.FillColor = colors[role]
                data.Highlight.Enabled = true
            end
            if head and hrp then
                local top2D, onTop = WorldToScreen(head.Position + Vector3.new(0,0.5,0))
                local bottom2D, onBottom = WorldToScreen(hrp.Position - Vector3.new(0,2.5,0))
                if onTop and onBottom then
                    local height = math.abs(top2D.Y - bottom2D.Y)
                    local width = height/2
                    if data.Box then
                        data.Box.Position = Vector2.new(top2D.X - width/2, top2D.Y)
                        data.Box.Size = Vector2.new(width, height)
                        data.Box.Color = colors[role]
                        data.Box.Visible = true
                    end
                    if data.Line then
                        data.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
                        data.Line.To = Vector2.new(top2D.X, top2D.Y)
                        data.Line.Color = colors[role]
                        data.Line.Visible = true
                    end
                else
                    if data.Box then data.Box.Visible=false end
                    if data.Line then data.Line.Visible=false end
                end
            end
        end
    end
end)

-- Local Player Controls
Local_Tab:Slider({Title="WalkSpeed", Step=1, Value={Min=16, Max=100, Default=16}, Callback=function(val)
    _G.WalkSpeedValue = val
    setWalkSpeed()
end})
Local_Tab:Toggle({Title="Infinite Jump", Default=false, Callback=function(state) _G.InfiniteJumpEnabled = state end})
Local_Tab:Toggle({Title="Noclip", Default=false, Callback=function(state) _G.NoclipEnabled = state end})