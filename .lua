-- WindUI Loader
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI yüklenemedi!") end

WindUI:Notify({Title="Line ESP", Content="Yüklendi!", Duration=3, Icon="check"})


-- WindUI Window
local Window = WindUI:CreateWindow({
    Title = "ESP Menu",
    Author = "x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(400, 300),
    Folder = "ESP_GUI"
})

-- WindUI Open Button
Window:EditOpenButton({
    Title = "Open ESP Menu",
    Icon = "eye",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Tabs
local ESP_Tab = Window:Tab({Title="ESP", Icon="eye"})
local TP_Tab = Window:Tab({Title="Teleport", Icon="zap"})

-- Globals
_G.HighlightESP = false
_G.BoxESP = false
_G.LineESP    = false
_G.NameTagESP = false
_G.GunESP = false
local currentGun = nil
local gunBox = Drawing.new("Square")
local gunLine = Drawing.new("Line")
local gunText = Drawing.new("Text")
_G.TP_DISTANCE = 5

-- Toggles/Buttons
ESP_Tab:Toggle({Title="Enable Highlight", Default=false, Callback=function(s) _G.HighlightESP = s end})
ESP_Tab:Toggle({Title="Enable Box", Default=false, Callback=function(s) _G.BoxESP = s end})
ESP_Tab:Toggle({Title="Enable Line", Default=false, Callback=function(s)_G.LineESP=s end})
ESP_Tab:Toggle({Title="Enable NameTag", Default=false, Callback=function(s)_G.NameTagESP=s end})
ESP_Tab:Toggle({Title="Enable Gun ESP", Default=false, Callback=function(s)_G.GunESP = s end})
TP_Tab:Button({Title="TP to Murderer", Callback=function() TPToMurderer() end})
TP_Tab:Button({Title="TP to Sheriff", Callback=function() TPToSheriff() end})
TP_Tab:Button({Title="TP to Gun", Callback=function() TPToGun() end})

-- Functions
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,150,255),
    Innocent = Color3.fromRGB(0,255,0)
}

local function safeNewDrawing(class, props)
    local obj = Drawing.new(class)
    for i,v in pairs(props or {}) do obj[i]=v end
    return obj
end

local function worldToScreen(pos)
    local vec, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), vis
end

local function detectRole(player)
    local role = "Innocent"
    local bp = player:FindFirstChild("Backpack")
    if bp then
        if bp:FindFirstChild("Knife") then role = "Murderer"
        elseif bp:FindFirstChild("Gun") then role = "Sheriff" end
    end
    local char = player.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name == "Knife" then role = "Murderer"
                elseif tool.Name == "Gun" then role = "Sheriff" end
            end
        end
    end
    return role
end

-- ESP table
local ESP = {}
local function createESP(player)
    if player == LocalPlayer or ESP[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0
    highlight.OutlineTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false

    local box = safeNewDrawing("Square",{Thickness=1,Filled=false,Visible=false})

    ESP[player] = {Highlight=highlight, Box=box}

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

for _,p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    local d = ESP[p]
    if d then
        pcall(function()
            if d.Highlight then d.Highlight:Destroy() end
            if d.Box then d.Box:Remove() end
        end)
    end
    ESP[p] = nil
end)

-- Render Loop
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            if data.Box then data.Box.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            continue
        end

        local role = detectRole(player)
        local color = ROLE_COLORS[role]

        -- Highlight
        if _G.HighlightESP and data.Highlight and char then
            data.Highlight.Enabled = true
            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color
        else
            data.Highlight.Enabled = false
        end

        -- Box
        local hrp = char.HumanoidRootPart
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not head or not humanoid or not data.Box then
            if data.Box then data.Box.Visible = false end
            continue
        end

        local pos, vis = worldToScreen(hrp.Position)
        if not vis then
            data.Box.Visible = false
            continue
        end

        local headPos, feetPos = worldToScreen(head.Position + Vector3.new(0,0.3,0)), worldToScreen(hrp.Position - Vector3.new(0,2.5,0))
        local height = math.abs(headPos.Y - feetPos.Y)
        local width = height / 2.3
        local size = Vector2.new(width*1.1, height*1.1)
        local topLeft = Vector2.new(headPos.X - size.X/2, headPos.Y)

        if _G.BoxESP then
            data.Box.Visible = true
            data.Box.Position = topLeft
            data.Box.Size = size
            data.Box.Color = color:lerp(Color3.new(0,0,0),0.25)
        else
            data.Box.Visible = false
        end
    end
end)


local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff  = Color3.fromRGB(0,150,255),
    Innocent = Color3.fromRGB(0,255,0)
}

local function safeNewDrawing(class, props)
    local obj = Drawing.new(class)
    for i,v in pairs(props or {}) do obj[i]=v end
    return obj
end

local function worldToScreen(pos)
    local vec, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), vis
end

local function detectRole(player)
    local role="Innocent"
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

-- ESP Creating
local ESP = {}

local function createESP(player)
    if player == LocalPlayer or ESP[player] then return end

    local line = safeNewDrawing("Line",{Thickness=2, Visible=false})
    local text = safeNewDrawing("Text",{Size=15, Center=true, Outline=true, Visible=false})

    ESP[player] = {
        Line = line,
        Text = text
    }
end

for _,p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    local d = ESP[p]
    if d then
        pcall(function()
            d.Line:Remove()
            d.Text:Remove()
        end)
    end
    ESP[p] = nil
end)

-- Render Loop
RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        local role = detectRole(player)
        local color = ROLE_COLORS[role]

        -- Line 
        RunService.RenderStepped:Connect(function()
	for player, data in pairs(ESP) do
		local char = player.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then
			data.Line.Visible = false
			continue
		end

		local hrp = char.HumanoidRootPart
		local role = detectRole(player)
		local color = ROLE_COLORS[role]

		if _G.LineESP then
			local pos, vis = worldToScreen(hrp.Position)
			data.Line.Visible = vis
			if vis then
				data.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
				data.Line.To = pos
				data.Line.Color = color
			end
		else
			data.Line.Visible = false
		end
	end
end)

        -- NameTag 
        RunService.RenderStepped:Connect(function()
	for player, data in pairs(ESP) do
		local char = player.Character
		if not char or not char:FindFirstChild("Head") then
			data.Text.Visible = false
			continue
		end

		local head = char.Head
		local role = detectRole(player)
		local color = ROLE_COLORS[role]

		if _G.NameTagESP then
			local pos, vis = worldToScreen(head.Position + Vector3.new(0, 0.3, 0))
			data.Text.Visible = vis
			if vis then
				data.Text.Text = player.Name
				data.Text.Position = pos - Vector2.new(0, 15)
				data.Text.Color = color
			end
		else
			data.Text.Visible = false
		end
	end
end)

-- GunBox
gunBox.Visible = false
gunBox.Filled = false
gunBox.Thickness = 2
gunBox.Color = Color3.fromRGB(0, 150, 255)
-- GunLine
gunLine.Visible = false
gunLine.Thickness = 2
gunLine.Color = Color3.fromRGB(0, 150, 255)
-- GunText
gunText.Visible = false
gunText.Size = 16
gunText.Center = true
gunText.Outline = true
gunText.Text = "GUN"
gunText.Color = Color3.fromRGB(0, 150, 255)

-- GunDrop find
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

-- RGB function
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

-- Gun Tp
local function getRole(player)
    local role = "Innocent"
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name == "Knife" then role = "Murderer"
                elseif tool.Name == "Gun" then role = "Sheriff" end
            end
        end
    end
    local char = player.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name == "Knife" then role = "Murderer"
                elseif tool.Name == "Gun" then role = "Sheriff" end
            end
        end
    end
    return role
end

function TPToMurderer()
    local target = nil
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            target = plr
            break
        end
    end
    if target then
        LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,0,_G.TP_DISTANCE)
    else
        WindUI:Notify({Title="TP Error", Content="Can't find Murderer!", Duration=3, Icon="triangle-alert"})
    end
end

function TPToSheriff()
    local target = nil
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and getRole(plr) == "Sheriff" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            target = plr
            break
        end
    end
    if target then
        LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,0,_G.TP_DISTANCE)
    else
        WindUI:Notify({Title="TP Error", Content="Can't find Sheriff!", Duration=3, Icon="triangle-alert"})
    end
end

-- Gun Finder
local currentGun = nil
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

function TPToGun()
    if currentGun then
        LocalPlayer.Character.HumanoidRootPart.CFrame = currentGun.CFrame + Vector3.new(0,0,_G.TP_DISTANCE)
    else
        WindUI:Notify({Title="TP Error", Content="Can't find Gun!", Duration=3, Icon="triangle-alert"})
    end
end
