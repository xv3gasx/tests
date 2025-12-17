-- WindUI Loadstring (En Güncel & Çalışan Versiyon - 17 Aralık 2025)
loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- MM2 ESP Script (Tamamen Fixed - Toggle OFF = Anında Gizlenir + Role Detection Doğru)
local Window = WindUI:CreateWindow({
    Title = "MM2 ESP (Final Fixed)",
    Author = "x.v3gas.x / Grok Fix",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 450),
    Folder = "MM2_ESP_Final",
    AutoScale = false
})

Window:EditOpenButton({
    Title = "ESP Menu",
    Icon = "eye",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    Enabled = true,
    Draggable = true
})

local EspTab = Window:Tab({Title="ESP", Icon="app-window"})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Toggles (Local değişkenler - FPS dostu)
local BoxEnabled = false
local LineEnabled = false
local NameEnabled = false
local GunEnabled = false
local HighlightEnabled = false

local BoxESP = {}
local LineESP = {}
local NameESP = {}
local HighlightCache = {}
local RoleCache = {}
local currentGun = nil

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255,0,0),
    Sheriff = Color3.fromRGB(0,0,255),
    Innocent = Color3.fromRGB(0,255,0)
}

-- Toggles
EspTab:Toggle({Title="Box ESP", Default=false, Callback=function(v) BoxEnabled=v end})
EspTab:Toggle({Title="Line ESP", Default=false, Callback=function(v) LineEnabled=v end})
EspTab:Toggle({Title="Nametag ESP", Default=false, Callback=function(v) NameEnabled=v end})
EspTab:Toggle({Title="Gun ESP", Default=false, Callback=function(v) GunEnabled=v end})
EspTab:Toggle({Title="Highlight ESP", Default=false, Callback=function(v)
    HighlightEnabled = v
    for _, hl in pairs(HighlightCache) do
        if hl then hl.Enabled = v end
    end
end})

-- Utils
local function w2s(pos)
    local ok, vec, on = pcall(Camera.WorldToViewportPoint, Camera, pos)
    return ok and Vector2.new(vec.X, vec.Y) or Vector2.new(), on or false
end

local function safeDraw(class, props)
    local ok, obj = pcall(Drawing.new, class)
    if ok and obj and props then
        for k, v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

-- Role Detection (Knife > Gun önceliği - MM2 standart)
local function detectRole(p)
    local role = "Innocent"
    pcall(function()
        local backpack = p:FindFirstChild("Backpack")
        local char = p.Character
        if (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
            role = "Murderer"
        elseif (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
            role = "Sheriff"
        end
    end)
    RoleCache[p] = role
    return role
end

-- ESP Nesneleri Oluştur
local function createESP(p)
    if p == LocalPlayer then return end
    BoxESP[p] = {box = safeDraw("Square", {Filled=false, Thickness=1, Visible=false})}
    LineESP[p] = {line = safeDraw("Line", {Thickness=2, Visible=false})}
    NameESP[p] = {text = safeDraw("Text", {Size=14, Center=true, Outline=true, Visible=false})}
end

-- Highlight Güncelle
local function updateHighlight(p)
    pcall(function()
        local hl = HighlightCache[p]
        if hl then hl:Destroy() end
        if not p.Character then return end
        hl = Instance.new("Highlight")
        hl.Parent = p.Character
        hl.Adornee = p.Character
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0
        hl.OutlineTransparency = 0.4
        hl.FillColor = ROLE_COLORS[RoleCache[p] or detectRole(p)]
        hl.Enabled = HighlightEnabled
        HighlightCache[p] = hl
    end)
end

-- Oyuncu İzleme (Backpack + Character + Tool değişiklikleri)
local function watchPlayer(p)
    createESP(p)
    detectRole(p)
    updateHighlight(p)

    p.CharacterAdded:Connect(function()
        task.wait(0.1)
        detectRole(p)
        updateHighlight(p)
    end)

    -- Character'daki tool değişiklikleri
    task.spawn(function()
        if p.Character then
            p.Character.ChildAdded:Connect(function(c)
                if c:IsA("Tool") then
                    RoleCache[p] = nil
                    detectRole(p)
                    updateHighlight(p)
                end
            end)
            p.Character.ChildRemoved:Connect(function(c)
                if c:IsA("Tool") then
                    RoleCache[p] = nil
                    detectRole(p)
                    updateHighlight(p)
                end
            end)
        end
    end)

    -- Backpack'teki tool değişiklikleri (önemli!)
    p.Backpack.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then
            RoleCache[p] = nil
            detectRole(p)
            updateHighlight(p)
        end
    end)
    p.Backpack.ChildRemoved:Connect(function(c)
        if c:IsA("Tool") then
            RoleCache[p] = nil
            detectRole(p)
            updateHighlight(p)
        end
    end)
end

-- Temizlik
local function cleanup(p)
    if BoxESP[p] and BoxESP[p].box then BoxESP[p].box:Remove() end
    BoxESP[p] = nil
    if LineESP[p] and LineESP[p].line then LineESP[p].line:Remove() end
    LineESP[p] = nil
    if NameESP[p] and NameESP[p].text then NameESP[p].text:Remove() end
    NameESP[p] = nil
    if HighlightCache[p] then HighlightCache[p]:Destroy() end
    HighlightCache[p] = nil
    RoleCache[p] = nil
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(cleanup)

-- Gun Bulma
task.spawn(function()
    while task.wait(0.5) do
        currentGun = workspace:FindFirstChild("GunDrop", true)
    end
end)

local gunBox = safeDraw("Square", {Thickness=2, Filled=false, Visible=false, Color=Color3.fromRGB(255,255,0)})
local gunText = safeDraw("Text", {Text="GUN", Size=16, Center=true, Outline=true, Visible=false, Color=Color3.fromRGB(255,255,0)})

-- Render Loop (Toggle OFF = Anında Gizlenir!)
RunService.RenderStepped:Connect(function()
    -- Box ESP
    for p, d in pairs(BoxESP) do
        local char = p.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not BoxEnabled or not (hrp and head and hum and hum.Health > 0) then
            d.box.Visible = false
        else
            local top, onTop = w2s(head.Position + Vector3.new(0, 0.5, 0))
            local bot, onBot = w2s(hrp.Position - Vector3.new(0, 2.5, 0))
            if onTop and onBot then
                local height = math.abs(top.Y - bot.Y)
                local width = height / 2
                d.box.Position = Vector2.new(top.X - width / 2, top.Y)
                d.box.Size = Vector2.new(width, height)
                d.box.Color = ROLE_COLORS[RoleCache[p] or detectRole(p)]
                d.box.Visible = true
            else
                d.box.Visible = false
            end
        end
    end

    -- Line ESP
    for p, d in pairs(LineESP) do
        local char = p.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not LineEnabled or not (hrp and hum and hum.Health > 0) then
            d.line.Visible = false
        else
            local pos, on = w2s(hrp.Position)
            if on then
                d.line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                d.line.To = pos
                d.line.Color = ROLE_COLORS[RoleCache[p] or detectRole(p)]
                d.line.Visible = true
            else
                d.line.Visible = false
            end
        end
    end

    -- Nametag ESP
    for p, d in pairs(NameESP) do
        local char = p.Character
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not NameEnabled or not (head and hum and hum.Health > 0) then
            d.text.Visible = false
        else
            local pos, on = w2s(head.Position + Vector3.new(0, 1, 0))
            if on then
                local role = RoleCache[p] or detectRole(p)
                d.text.Text = p.Name .. " [" .. role .. "]"
                d.text.Position = pos
                d.text.Color = ROLE_COLORS[role]
                d.text.Visible = true
            else
                d.text.Visible = false
            end
        end
    end

    -- Gun ESP
    if GunEnabled and currentGun then
        local pos, on = w2s(currentGun.Position)
        if on then
            local sz = 30
            gunBox.Position = pos - Vector2.new(sz/2, sz/2)
            gunBox.Size = Vector2.new(sz, sz)
            gunBox.Visible = true
            gunText.Position = pos + Vector2.new(0, -sz/2 - 10)
            gunText.Visible = true
        else
            gunBox.Visible = false
            gunText.Visible = false
        end
    else
        gunBox.Visible = false
        gunText.Visible = false
    end
end)

WindUI:Notify({
    Title = "Başarılı!",
    Content = "ESP Yüklendi - Toggle OFF = Anında Gizlenir",
    Duration = 6,
    Icon = "check"
})
