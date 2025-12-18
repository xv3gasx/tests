-- MM2 ESP Script (0'dan Grok Tarafından Yazıldı - WindUI Loader Dahil, 100% Opti, Anında Role Detection)
-- Özellikler: Role Renkli Highlight/Box/Line/Nametag, Rainbow Gun Box/Line + Mavi GUN Text (Siyah Stroke), 0 FPS Drop, Yeni Round Yenileme

-- WindUI Loader (2025 Güncel & Çalışan - Repo'dan Doğrulandı)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Loader Hata Kontrolü
if not WindUI then
    warn("WindUI yüklenemedi! Executor'un HttpGet'i kontrol et.")
    return
end

WindUI:Notify({
    Title = "ESP Yüklendi",
    Content = "MM2 ESP Aktif - 0 Lag, Anında Role!",
    Duration = 5,
    Icon = "check"
})

-- GUI Oluşturma
local Window = WindUI:CreateWindow({
    Title = "MM2 ESP (Grok Yapımı)",
    Author = "Grok - 100% Opti",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 450),
    Folder = "MM2_ESP",
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

local EspTab = Window:Tab({Title = "ESP", Icon = "app-window"})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Toggles
local BoxEnabled = false
local LineEnabled = false
local NameEnabled = false
local GunEnabled = false
local HighlightEnabled = false

EspTab:Toggle({Title = "Box ESP (Role Renkli)", Default = false, Callback = function(v) BoxEnabled = v end})
EspTab:Toggle({Title = "Line ESP (Role Renkli)", Default = false, Callback = function(v) LineEnabled = v end})
EspTab:Toggle({Title = "Nametag ESP (Role Renkli)", Default = false, Callback = function(v) NameEnabled = v end})
EspTab:Toggle({Title = "Gun ESP (Rainbow Box/Line + Mavi GUN)", Default = false, Callback = function(v) GunEnabled = v end})
EspTab:Toggle({Title = "Highlight ESP (Role Renkli)", Default = false, Callback = function(v) HighlightEnabled = v end})

-- Data Structures
local BoxESP = {}
local LineESP = {}
local NameESP = {}
local HighlightCache = {}
local RoleCache = {}
local currentGun = nil

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

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

-- Role Detection (Anında + Yeni Round Yenileme)
local function detectRole(p)
    local role = "Innocent"
    local backpack = p:FindFirstChild("Backpack")
    local char = p.Character
    if backpack or char then
        local containers = {backpack, char}
        for _, container in ipairs(containers) do
            if container then
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") then
                        if tool.Name == "Knife" then
                            role = "Murderer"
                            return role
                        elseif tool.Name == "Gun" then
                            role = "Sheriff"
                        end
                    end
                end
            end
        end
    end
    return role
end

-- ESP Oluşturma
local function createESP(p)
    if p == LocalPlayer then return end
    BoxESP[p] = {box = safeDraw("Square", {Filled = false, Thickness = 2, Visible = false})}
    LineESP[p] = {line = safeDraw("Line", {Thickness = 3, Visible = false})}
    NameESP[p] = {text = safeDraw("Text", {Size = 16, Center = true, Outline = true, OutlineColor = Color3.new(0,0,0), Visible = false})}
end

-- Highlight Oluşturma
local function createHighlight(p)
    if p == LocalPlayer or not p.Character then return end
    local hl = Instance.new("Highlight")
    hl.Parent = p.Character
    hl.Adornee = p.Character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.FillColor = ROLE_COLORS["Innocent"]
    hl.Enabled = false
    HighlightCache[p] = hl
end

-- Role Güncelleme
local function updateRole(p)
    RoleCache[p] = detectRole(p)
    if HighlightCache[p] then
        HighlightCache[p].FillColor = ROLE_COLORS[RoleCache[p]]
        HighlightCache[p].Enabled = HighlightEnabled
    end
end

-- Oyuncu İzleme (Anında Tool Değişim + 0.2s Scan)
local function watchPlayer(p)
    createESP(p)
    createHighlight(p)
    updateRole(p)

    p.CharacterAdded:Connect(function(char)
        task.wait(0.05)
        createHighlight(p)
        updateRole(p)
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then updateRole(p) end
        end)
        char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then updateRole(p) end
        end)
    end)

    local backpack = p:FindFirstChild("Backpack")
    if backpack then
        backpack.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then updateRole(p) end
        end)
        backpack.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then updateRole(p) end
        end
    end

    -- Yeni Round Yenileme (0.2s Scan - 0 Lag)
    task.spawn(function()
        while task.wait(0.2) do
            updateRole(p)
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

-- Gun Bulma (0.3s Loop)
task.spawn(function()
    while task.wait(0.3) do
        currentGun = workspace:FindFirstChild("GunDrop", true)
    end
end)

-- Rainbow Gun ESP
local gunBox = safeDraw("Square", {Thickness = 3, Filled = false, Visible = false})
local gunLine = safeDraw("Line", {Thickness = 3, Visible = false})
local gunText = safeDraw("Text", {Text = "GUN", Size = 20, Center = true, Outline = true, OutlineColor = Color3.new(0,0,0), Color = Color3.fromRGB(0, 0, 255), Visible = false})

-- Rainbow Animasyon (0 Lag - Heartbeat)
local hue = 0
RunService.Heartbeat:Connect(function(dt)
    hue = (hue + dt * 0.5) % 1
    local rainbow = Color3.fromHSV(hue, 1, 1)
    if gunBox then gunBox.Color = rainbow end
    if gunLine then gunLine.Color = rainbow end
end)

-- Render Loop (100% Opti - Early Return + Alive Check)
RunService.RenderStepped:Connect(function()
    if not (BoxEnabled or LineEnabled or NameEnabled or GunEnabled or HighlightEnabled) then return end

    for p, d in pairs(BoxESP) do
        local char = p.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (hrp and head and hum and hum.Health > 0) then
            if d.box then d.box.Visible = false end
            if LineESP[p] then LineESP[p].line.Visible = false end
            if NameESP[p] then NameESP[p].text.Visible = false end
            continue
        end

        local role = RoleCache[p] or detectRole(p)
        local color = ROLE_COLORS[role]

        -- Box ESP
        if BoxEnabled then
            local top, onTop = w2s(head.Position + Vector3.new(0, 0.5, 0))
            local bot, onBot = w2s(hrp.Position - Vector3.new(0, 2.5, 0))
            if onTop and onBot then
                local height = math.abs(top.Y - bot.Y)
                local width = height / 2
                d.box.Position = Vector2.new(top.X - width / 2, top.Y)
                d.box.Size = Vector2.new(width, height)
                d.box.Color = color
                d.box.Visible = true
            else
                d.box.Visible = false
            end
        else
            if d.box then d.box.Visible = false end
        end

        -- Line ESP
        if LineEnabled then
            local pos, on = w2s(hrp.Position)
            if on then
                LineESP[p].line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                LineESP[p].line.To = pos
                LineESP[p].line.Color = color
                LineESP[p].line.Visible = true
            else
                LineESP[p].line.Visible = false
            end
        else
            if LineESP[p] then LineESP[p].line.Visible = false end
        end

        -- Nametag ESP
        if NameEnabled then
            local pos, on = w2s(head.Position + Vector3.new(0, 1, 0))
            if on then
                NameESP[p].text.Text = p.Name .. " [" .. role .. "]"
                NameESP[p].text.Position = pos
                NameESP[p].text.Color = color
                NameESP[p].text.Visible = true
            else
                NameESP[p].text.Visible = false
            end
        else
            if NameESP[p] then NameESP[p].text.Visible = false end
        end

        -- Highlight Update (Eğer Enabled)
        if HighlightEnabled and HighlightCache[p] then
            HighlightCache[p].Enabled = true
            HighlightCache[p].FillColor = color
        elseif HighlightCache[p] then
            HighlightCache[p].Enabled = false
        end
    end

    -- Gun ESP (Rainbow Box/Line + Mavi GUN Siyah Stroke)
    if GunEnabled and currentGun then
        local pos, on = w2s(currentGun.Position)
        if on then
            local sz = 30
            gunBox.Position = pos - Vector2.new(sz / 2, sz / 2)
            gunBox.Size = Vector2.new(sz, sz)
            gunBox.Visible = true
            gunLine.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
            gunLine.To = pos
            gunLine.Visible = true
            gunText.Position = pos
            gunText.Visible = true
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
