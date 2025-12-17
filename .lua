-- GÜVENLİ WINDUI LOADER (Hata Önleyici)
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not WindUI then
    warn("WindUI yüklenemedi! Farklı link dene.")
    -- Alternatif dene
    success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
    end)
    
    if not success or not WindUI then
        error("WindUI tamamen yüklenemedi. Executor'un HttpGet engellenmiş olabilir.")
        return
    end
end

WindUI:Notify({Title="Başarılı!", Content="ESP Script Yüklendi", Duration=5, Icon="check-circle"})

-- Burdan sonrası senin ESP scriptin (FPS optimized hali)
local Window = WindUI:CreateWindow({
    Title = "MM2 ESP (Fixed)",
    Author = "x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 450),
    Folder = "MM2ESP",
    AutoScale = false
})

Window:EditOpenButton({
    Title = "ESP Menu",
    Icon = "eye",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("#FF0F7B"), Color3.fromHex("#F89B29")),
    Enabled = true,
    Draggable = true
})

local EspTab = Window:Tab({Title="ESP", Icon="app-window"})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local BoxESPEnabled = false
local LineESPEnabled = false
local NametagESPEnabled = false
local GunESPEnabled = false
local HighlightESPEnabled = false

local BoxESP, LineESP, NametagESP = {}, {}, {}
local HighlightCache = {}
local RoleCache = {}
local currentGun = nil

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,255,0)
}

-- Toggles
EspTab:Toggle({Title="Box ESP", Default=false, Callback=function(v) BoxESPEnabled = v end})
EspTab:Toggle({Title="Line ESP", Default=false, Callback=function(v) LineESPEnabled = v end})
EspTab:Toggle({Title="Nametag ESP", Default=false, Callback=function(v) NametagESPEnabled = v end})
EspTab:Toggle({Title="Gun ESP", Default=false, Callback=function(v) GunESPEnabled = v end})
EspTab:Toggle({Title="Highlight ESP", Default=false, Callback=function(v)
    HighlightESPEnabled = v
    for _, hl in pairs(HighlightCache) do if hl then hl.Enabled = v end end
end})

-- Utils
local function safeW2S(pos)
    local success, vec, onScreen = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if success then return Vector2.new(vec.X, vec.Y), onScreen end
    return Vector2.new(0,0), false
end

local function safeDraw(class, props)
    local success, obj = pcall(Drawing.new, class)
    if success and obj then
        for k, v in pairs(props or {}) do
            pcall(function() obj[k] = v end)
        end
        return obj
    end
    return nil
end

local function detectRole(player)
    local role = "Innocent"
    pcall(function()
        local function check(container)
            if container then
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") then
                        if tool.Name == "Knife" then role = "Murderer" return end
                        if tool.Name == "Gun" then role = "Sheriff" return end
                    end
                end
            end
        end
        check(player:FindFirstChild("Backpack"))
        check(player.Character)
    end)
    RoleCache[player] = role
    return role
end

-- Create ESP Objects
local function createESP(player)
    if player == LocalPlayer then return end
    BoxESP[player] = { box = safeDraw("Square", {Thickness = 1, Filled = false, Visible = false}) }
    LineESP[player] = { line = safeDraw("Line", {Thickness = 2, Visible = false}) }
    NametagESP[player] = { text = safeDraw("Text", {Size = 14, Center = true, Outline = true, Visible = false}) }
    detectRole(player)
end

-- Highlight
local function updateHighlight(player)
    pcall(function()
        if player == LocalPlayer or not player.Character then return end
        local hl = HighlightCache[player]
        if hl then hl:Destroy() end
        hl = Instance.new("Highlight")
        hl.Parent = player.Character
        hl.Adornee = player.Character
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0
        hl.OutlineTransparency = 0.4
        hl.FillColor = ROLE_COLORS[RoleCache[player] or detectRole(player)]
        hl.Enabled = HighlightESPEnabled
        HighlightCache[player] = hl
    end)
end

-- Tool Watch
local function watchPlayer(player)
    createESP(player)
    updateHighlight(player)
    player.CharacterAdded:Connect(function() updateHighlight(player) end)
    if player.Character then
        player.Character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                RoleCache[player] = nil
                detectRole(player)
                updateHighlight(player)
            end
        end)
        player.Character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                RoleCache[player] = nil
                detectRole(player)
                updateHighlight(player)
            end
        end)
    end
end

-- Cleanup
local function cleanup(player)
    if BoxESP[player] and BoxESP[player].box then BoxESP[player].box:Remove() end
    if LineESP[player] and LineESP[player].line then LineESP[player].line:Remove() end
    if NametagESP[player] and NametagESP[player].text then NametagESP[player].text:Remove() end
    if HighlightCache[player] then HighlightCache[player]:Destroy() end
    BoxESP[player], LineESP[player], NametagESP[player], HighlightCache[player], RoleCache[player] = nil, nil, nil, nil, nil
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(cleanup)

-- Gun Finder
task.spawn(function()
    while task.wait(0.5) do
        currentGun = workspace:FindFirstChild("GunDrop", true)
    end
end)

local gunBox = safeDraw("Square", {Thickness=2, Filled=false, Visible=false, Color=Color3.fromRGB(255,255,0)})
local gunText = safeDraw("Text", {Text="GUN", Size=16, Center=true, Outline=true, Visible=false, Color=Color3.fromRGB(255,255,0)})

-- Render Loop
RunService.RenderStepped:Connect(function()
    if not (BoxESPEnabled or LineESPEnabled or NametagESPEnabled or GunESPEnabled) then return end

    for player, data in pairs(BoxESP) do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") or char:FindFirstChildOfClass("Humanoid").Health <= 0 then
            if data.box then data.box.Visible = false end
            if LineESP[player] then LineESP[player].line.Visible = false end
            if NametagESP[player] then NametagESP[player].text.Visible = false end
            continue
        end

        local role = RoleCache[player] or detectRole(player)
        local headPos = char.Head.Position + Vector3.new(0, 0.5, 0)
        local rootPos = char.HumanoidRootPart.Position - Vector3.new(0, 2.5, 0)

        local head2D, headOn = safeW2S(headPos)
        local root2D, rootOn = safeW2S(rootPos)

        if headOn and rootOn and BoxESPEnabled then
            local height = math.abs(head2D.Y - root2D.Y)
            local width = height / 2
            data.box.Position = Vector2.new(head2D.X - width/2, head2D.Y)
            data.box.Size = Vector2.new(width, height)
            data.box.Color = ROLE_COLORS[role]
            data.box.Visible = true
        elseif data.box then
            data.box.Visible = false
        end

        if LineESPEnabled then
            local root2D, on = safeW2S(char.HumanoidRootPart.Position)
            if on then
                LineESP[player].line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
                LineESP[player].line.To = root2D
                LineESP[player].line.Color = ROLE_COLORS[role]
                LineESP[player].line.Visible = true
            elseif LineESP[player] then
                LineESP[player].line.Visible = false
            end
        end

        if NametagESPEnabled then
            local head2D, on = safeW2S(char.Head.Position + Vector3.new(0,1,0))
            if on then
                NametagESP[player].text.Text = player.Name .. " [" .. role .. "]"
                NametagESP[player].text.Position = head2D
                NametagESP[player].text.Color = ROLE_COLORS[role]
                NametagESP[player].text.Visible = true
            elseif NametagESP[player] then
                NametagESP[player].text.Visible = false
            end
        end
    end

    if GunESPEnabled and currentGun then
        local pos, on = safeW2S(currentGun.Position)
        if on then
            local size = 30
            gunBox.Position = pos - Vector2.new(size/2, size/2)
            gunBox.Size = Vector2.new(size, size)
            gunBox.Visible = true
            gunText.Position = pos + Vector2.new(0, -20)
            gunText.Visible = true
        else
            gunBox.Visible = false
            gunText.Visible = false
        end
    else
        if gunBox then gunBox.Visible = false end
        if gunText then gunText.Visible = false end
    end
end)

print("MM2 ESP Script Başarıyla Yüklendi!")
