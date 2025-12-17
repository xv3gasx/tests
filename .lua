local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

if not WindUI then
    warn("WindUI yüklenemedi! Link çalışmıyor olabilir, alternatif dene.")
    return
end

WindUI:Notify({Title="Başarılı!", Content="MM2 ESP Aktif!", Duration=5, Icon="check"})

local Window = WindUI:CreateWindow({
    Title = "MM2 ESP",
    Author = "x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 450),
    Folder = "MM2ESP",
    AutoScale = false
})

Window:EditOpenButton({
    Title = "ESP Aç",
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

local ROLE_COLORS = {Murderer = Color3.fromRGB(255,0,0), Sheriff = Color3.fromRGB(0,0,255), Innocent = Color3.fromRGB(0,255,0)}

EspTab:Toggle({Title="Box ESP", Default=false, Callback=function(v) BoxEnabled=v end})
EspTab:Toggle({Title="Line ESP", Default=false, Callback=function(v) LineEnabled=v end})
EspTab:Toggle({Title="Nametag ESP", Default=false, Callback=function(v) NameEnabled=v end})
EspTab:Toggle({Title="Gun ESP (Rainbow)", Default=false, Callback=function(v) GunEnabled=v end})
EspTab:Toggle({Title="Highlight ESP", Default=false, Callback=function(v) HighlightEnabled=v; for _,hl in pairs(HighlightCache) do if hl then hl.Enabled=v end end end})

local function w2s(pos)
    local ok, vec, on = pcall(Camera.WorldToViewportPoint, Camera, pos)
    return ok and Vector2.new(vec.X, vec.Y) or Vector2.new(), on or false
end

local function safeDraw(class, props)
    local ok, obj = pcall(Drawing.new, class)
    if ok and obj and props then for k,v in pairs(props) do pcall(function() obj[k]=v end) end end
    return obj
end

local rolesFolder = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Roles")
if rolesFolder then
    for _, obj in ipairs(rolesFolder:GetChildren()) do
        if obj:IsA("ObjectValue") and obj.Value then RoleCache[obj.Value] = obj.Name end
    end
    rolesFolder.ChildAdded:Connect(function(obj)
        if obj:IsA("ObjectValue") and obj.Value then RoleCache[obj.Value] = obj.Name end
    end)
    rolesFolder.ChildRemoved:Connect(function(obj)
        if obj:IsA("ObjectValue") and obj.Value then RoleCache[obj.Value] = "Innocent" end
    end)
end

local function getRole(p) return RoleCache[p] or "Innocent" end

local function createESP(p)
    if p == LocalPlayer then return end
    BoxESP[p] = {box = safeDraw("Square", {Filled=false, Thickness=2, Visible=false})}
    LineESP[p] = {line = safeDraw("Line", {Thickness=3, Visible=false})}
    NameESP[p] = {text = safeDraw("Text", {Size=16, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Visible=false})}
end

local function updateHighlight(p)
    pcall(function()
        local hl = HighlightCache[p]
        if hl then hl:Destroy() end
        if not p.Character then return end
        hl = Instance.new("Highlight")
        hl.Parent = p.Character
        hl.Adornee = p.Character
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.FillColor = ROLE_COLORS[getRole(p)]
        hl.Enabled = HighlightEnabled
        HighlightCache[p] = hl
    end)
end

local function watchPlayer(p)
    createESP(p)
    updateHighlight(p)
    p.CharacterAdded:Connect(function() task.wait(0.05); updateHighlight(p) end)
end

local function cleanup(p)
    pcall(function()
        if BoxESP[p] and BoxESP[p].box then BoxESP[p].box:Remove() end
        if LineESP[p] and LineESP[p].line then LineESP[p].line:Remove() end
        if NameESP[p] and NameESP[p].text then NameESP[p].text:Remove() end
        if HighlightCache[p] then HighlightCache[p]:Destroy() end
    end)
    BoxESP[p] = nil; LineESP[p] = nil; NameESP[p] = nil; HighlightCache[p] = nil; RoleCache[p] = nil
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(cleanup)

task.spawn(function()
    while task.wait(0.3) do
        currentGun = workspace:FindFirstChild("GunDrop", true)
    end
end)

local gunBox = safeDraw("Square", {Thickness=3, Filled=false, Visible=false})
local gunLine = safeDraw("Line", {Thickness=3, Visible=false})
local gunText = safeDraw("Text", {Text="GUN", Size=20, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Color=Color3.new(0,0,255), Visible=false})

local hue = 0
RunService.Heartbeat:Connect(function(dt)
    hue = (hue + dt * 200) % 360
    local rainbow = Color3.fromHSV(hue / 360, 1, 1)
    gunBox.Color = rainbow
    gunLine.Color = rainbow
end)

RunService.RenderStepped:Connect(function()
    if not (BoxEnabled or LineEnabled or NameEnabled or GunEnabled) then return end

    for p, d in pairs(BoxESP) do
        local char = p.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (hrp and head and hum and hum.Health > 0) then
            d.box.Visible = false
            if LineESP[p] then LineESP[p].line.Visible = false end
            if NameESP[p] then NameESP[p].text.Visible = false end
            continue
        end

        local role = getRole(p)
        local color = ROLE_COLORS[role]

        if BoxEnabled then
            local top, on1 = w2s(head.Position + Vector3.new(0,0.5,0))
            local bot, on2 = w2s(hrp.Position - Vector3.new(0,2.5,0))
            if on1 and on2 then
                local h = math.abs(top.Y - bot.Y)
                local w = h / 2
                d.box.Position = Vector2.new(top.X - w/2, top.Y)
                d.box.Size = Vector2.new(w, h)
                d.box.Color = color
                d.box.Visible = true
            else d.box.Visible = false end
        else d.box.Visible = false end

        if LineEnabled then
            local pos, on = w2s(hrp.Position)
            if on then
                LineESP[p].line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
                LineESP[p].line.To = pos
                LineESP[p].line.Color = color
                LineESP[p].line.Visible = true
            else LineESP[p].line.Visible = false end
        else if LineESP[p] then LineESP[p].line.Visible = false end end

        if NameEnabled then
            local pos, on = w2s(head.Position + Vector3.new(0,1,0))
            if on then
                NameESP[p].text.Text = p.Name.." ["..role.."]"
                NameESP[p].text.Position = pos
                NameESP[p].text.Color = color
                NameESP[p].text.Visible = true
            else NameESP[p].text.Visible = false end
        else if NameESP[p] then NameESP[p].text.Visible = false end end
    end

    if GunEnabled and currentGun then
        local pos, on = w2s(currentGun.Position)
        if on then
            local sz = 35
            gunBox.Position = pos - Vector2.new(sz/2, sz/2)
            gunBox.Size = Vector2.new(sz, sz)
            gunBox.Visible = true
            gunLine.From = Vector2.new(Camera.ViewportSize.X/2, 0)
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
