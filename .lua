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

-- Open Menu Button + Keybind
local MenuOpen = false
Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
    Callback = function()
        MenuOpen = not MenuOpen
        Window:SetVisible(MenuOpen)
    end
})

-- Keybind: RightShift
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        MenuOpen = not MenuOpen
        Window:SetVisible(MenuOpen)
    end
end)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Globals
_G.ESPEnabled = false
_G.GunESPEnabled = false
_G.WalkSpeedValue = 16
_G.InfiniteJumpEnabled = false
_G.NoclipEnabled = false

-- Highlight Utility
local ESP = {}
local function AddESP(player)
    if player==LocalPlayer or ESP[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    ESP[player] = highlight

    local function attachChar(char)
        highlight.Parent = char
        highlight.Adornee = char
    end

    player.CharacterAdded:Connect(attachChar)
    if player.Character then
        attachChar(player.Character)
    end
end

local function RemoveESP(player)
    if ESP[player] then
        pcall(function() ESP[player]:Destroy() end)
        ESP[player] = nil
    end
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _,p in pairs(Players:GetPlayers()) do AddESP(p) end

-- Colors
local colors = {Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0)}

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

-- Gun TP
local currentGun = nil
task.spawn(function()
    while true do
        currentGun = nil
        for _,obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                currentGun = obj
                break
            end
        end
        task.wait(0.5)
    end
end)

local function teleportToGun()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and currentGun then
        hrp.CFrame = currentGun.CFrame + Vector3.new(0,3,0)
    end
end

-- TP to Murderer / Sheriff
local function getMurderer()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and ((p.Backpack:FindFirstChild("Knife")) or (p.Character and p.Character:FindFirstChild("Knife"))) then return p end
    end
end

local function getSheriff()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and ((p.Backpack:FindFirstChild("Gun")) or (p.Character and p.Character:FindFirstChild("Gun"))) then return p end
    end
end

local function teleportBehind(target)
    local hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and myHRP then
        local backPos = hrp.Position - (hrp.CFrame.LookVector * 8)
        myHRP.CFrame = CFrame.new(backPos, hrp.Position)
    end
end

-- WalkSpeed
local function setWalkSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed ~= _G.WalkSpeedValue then
        hum.WalkSpeed = _G.WalkSpeedValue
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
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- TP Tab
local TP_Tab = Window:Tab({ Title = "TP", Icon = "zap" })
TP_Tab:Button({Title="Gun TP",Callback=teleportToGun})
TP_Tab:Button({Title="Teleport to Murderer",Callback=function()
    local m = getMurderer()
    if m then teleportBehind(m) else WindUI:Notify({Title="Murderer Not Found", Content="Wait for match.", Duration=3, Icon="x"}) end
end})
TP_Tab:Button({Title="Teleport to Sheriff",Callback=function()
    local s = getSheriff()
    if s then teleportBehind(s) else WindUI:Notify({Title="Sheriff Not Found", Content="Wait for match.", Duration=3, Icon="x"}) end
end})

-- ESP Tab
local ESP_Tab = Window:Tab({ Title = "ESP", Icon = "app-window" })
ESP_Tab:Toggle({Title="Player ESP",Default=false,Callback=function(state)
    _G.ESPEnabled=state
    for player,highlight in pairs(ESP) do
        highlight.Enabled = state
        highlight.FillColor = colors[detectRole(player)]
    end
end})
ESP_Tab:Toggle({Title="Gun ESP",Default=false,Callback=function(state) _G.GunESPEnabled=state end})

-- Local Player Tab
local Local_Tab = Window:Tab({ Title = "Local Player", Icon = "user" })
Local_Tab:Slider({Title="WalkSpeed",Step=1,Value={Min=16,Max=100,Default=16},Callback=function(val) _G.WalkSpeedValue=val setWalkSpeed() end})
Local_Tab:Toggle({Title="Infinite Jump",Default=false,Callback=function(state) _G.InfiniteJumpEnabled=state end})
Local_Tab:Toggle({Title="Noclip",Default=false,Callback=function(state) _G.NoclipEnabled=state end})