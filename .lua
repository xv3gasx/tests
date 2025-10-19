--// 1. WindUI Loader
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI yüklenemedi!") end

WindUI:Notify({Title="Highlight ESP", Content="Yüklendi!", Duration=3, Icon="check"})

--// 2. UI Window
local Window = WindUI:CreateWindow({
    Title = "Highlight ESP",
    Author = "x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(300,200)
})

--// 3. Edit Open Button
Window:EditOpenButton({
    Title = "Open Highlight ESP",
    Icon = "eye",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true
})

--// 4. Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

--// 5. Tabs
local ESP_Tab = Window:Tab({Title="Highlight", Icon="eye"})
local TP_Tab = Window:Tab({
    Title = "Teleport",
    Icon = "navigation"
})

--// 6. Toggles/Buttons
ESP_Tab:Toggle({Title="Enable Highlight", Default=false, Callback=function(s)_G.HighlightESP = s end})
ESP_Tab:Toggle({Title="Enable Box ESP", Default=false, Callback=function(s)_G.BoxESP = s end})
ESP_Tab:Toggle({Title="Enable Line ESP", Default=false, Callback=function(s)_G.LineESP = s end})
ESP_Tab:Toggle({Title="Enable NameTag ESP", Default=false, Callback=function(s)_G.NameTagESP = s end})
ESP_Tab:Toggle({Title="Enable Gun ESP", Default=false, callback=function(s)_G.GunESP = s end})
TP_Tab:Button({
    Title = "Teleport to Murderer",
    Callback = function()
        TeleportToMurderer()
    end
})
TP_Tab:Button({
    Title = "Teleport to Sheriff",
    Callback = function()
        TeleportToSheriff()
    end
})
TP_Tab:Button({
    Title = "Teleport to Gun",
    Callback = function()
        TeleportToGun()
    end
})

--// 7. Globals
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,150,255),
    Innocent = Color3.fromRGB(0,255,0)
}
_G.HighlightESP = false
_G.BoxESP = false
_G.LineESP = false
_G.NameTagESP = false
_G.GunESP = false
_G.TeleportDistance = 5
_G.GunName = "GunDrop"

--// Functions
local ESP = {}

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

local function createESP(player)
    if player == LocalPlayer or ESP[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0
    highlight.OutlineTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false

    ESP[player] = {Highlight = highlight}

    player.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        highlight.Parent = char
        highlight.Adornee = char
    end)

    if player.Character then
        highlight.Parent = player.Character
        highlight.Adornee = player.Character
    end
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    local d = ESP[p]
    if d then pcall(function() d.Highlight:Destroy() end) end
    ESP[p] = nil
end)

--// Render Loop
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        local color = ROLE_COLORS[detectRole(player)]
        if _G.HighlightESP and char then
            data.Highlight.Enabled = true
            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color
        else
            data.Highlight.Enabled = false
        end
    end
end)

--// Box
local ESP = {}

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

local function worldToScreen(pos)
    local vec, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), vis
end

local function createESP(player)
    if player == LocalPlayer or ESP[player] then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Visible = false

    ESP[player] = {Box = box}

    player.CharacterAdded:Connect(function(char)
        task.wait(0.3)
    end)
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    local d = ESP[p]
    if d then pcall(function() d.Box:Remove() end) end
    ESP[p] = nil
end)

--// Render Loop
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then
            data.Box.Visible = false
            continue
        end

        local hrp = char.HumanoidRootPart
        local head = char.Head
        local topPos, topVis = worldToScreen(head.Position + Vector3.new(0,0.5,0))
        local bottomPos, bottomVis = worldToScreen(hrp.Position - Vector3.new(0,2.5,0))

        if not topVis or not bottomVis then
            data.Box.Visible = false
            continue
        end

        local height = math.abs(topPos.Y - bottomPos.Y)
        local width = height / 2.3
        local topLeft = Vector2.new(topPos.X - width/2, topPos.Y)

        if _G.BoxESP then
            data.Box.Visible = true
            data.Box.Position = topLeft
            data.Box.Size = Vector2.new(width, height)
            data.Box.Color = ROLE_COLORS[detectRole(player)]:lerp(Color3.new(0,0,0),0.2)
        else
            data.Box.Visible = false
        end
    end
end)

--// Line
local ESP = {}

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

local function worldToScreen(pos)
    local vec, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), vis
end

local function createESP(player)
    if player == LocalPlayer or ESP[player] then return end

    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Visible = false

    ESP[player] = {Line = line}
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    local d = ESP[p]
    if d then pcall(function() d.Line:Remove() end) end
    ESP[p] = nil
end)

--// Render Loop
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            data.Line.Visible = false
            continue
        end

        local hrp = char.HumanoidRootPart
        local screenPos, vis = worldToScreen(hrp.Position)
        if not vis then
            data.Line.Visible = false
            continue
        end

        if _G.LineESP then
            data.Line.Visible = true
            data.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0) -- üst ortadan çiz
            data.Line.To = screenPos
            data.Line.Color = ROLE_COLORS[detectRole(player)]
        else
            data.Line.Visible = false
        end
    end
end)

--// Nametag
local ESP = {}

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

local function worldToScreen(pos)
    local vec, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), vis
end

local function createESP(player)
    if player == LocalPlayer or ESP[player] then return end

    local text = Drawing.new("Text")
    text.Size = 16
    text.Center = true
    text.Outline = true
    text.Visible = false

    ESP[player] = {Text = text}
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    local d = ESP[p]
    if d then pcall(function() d.Text:Remove() end) end
    ESP[p] = nil
end)

--// Render Loop
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        if not head then
            data.Text.Visible = false
            continue
        end

        local screenPos, vis = worldToScreen(head.Position + Vector3.new(0,0.3,0))
        if not vis or not _G.NameTagESP then
            data.Text.Visible = false
            continue
        end

        data.Text.Visible = true
        data.Text.Text = player.Name
        data.Text.Position = screenPos - Vector2.new(0,15)
        data.Text.Color = ROLE_COLORS[detectRole(player)]
    end
end)

--// Gun ESP

local currentGun = nil
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

--// Tp to Murderer

function FindMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local bp = player:FindFirstChild("Backpack")
            local char = player.Character

            if bp and bp:FindFirstChild("Knife") then
                return player
            elseif char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == "Knife" then
                        return player
                    end
                end
            end
        end
    end
    return nil
end

function TeleportToMurderer()
    local murderer = FindMurderer()
    if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = murderer.Character.HumanoidRootPart
        LocalPlayer.Character:PivotTo(hrp.CFrame + hrp.CFrame.LookVector * -_G.TeleportDistance)
    else
        WindUI:Notify({
            Title = "Teleport",
            Content = "Murderer bulunamadı!",
            Duration = 3,
            Icon = "x"
        })
    end
end

--// Tp to Sheriff

function FindSheriff()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local bp = player:FindFirstChild("Backpack")
            local char = player.Character

            if bp and bp:FindFirstChild("Gun") then
                return player
            elseif char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == "Gun" then
                        return player
                    end
                end
            end
        end
    end
    return nil
end

function TeleportToSheriff()
    local sheriff = FindSheriff()
    if sheriff and sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = sheriff.Character.HumanoidRootPart
        LocalPlayer.Character:PivotTo(hrp.CFrame + hrp.CFrame.LookVector * -_G.TeleportDistance)
    else
        WindUI:Notify({
            Title = "Teleport",
            Content = "Sheriff bulunamadı!",
            Duration = 3,
            Icon = "x"
        })
    end
end

--// Tp to Gun

function FindGun()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == _G.GunName then
            return obj
        end
    end
    return nil
end

function TeleportToGun()
    local gun = FindGun()
    if gun then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = gun.CFrame + Vector3.new(0, 3, 0)
        end
    else
        WindUI:Notify({
            Title = "Teleport",
            Content = "Gun bulunamadı!",
            Duration = 3,
            Icon = "x"
        })
    end
end
