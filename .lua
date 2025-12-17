local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

if not WindUI then warn("WindUI yüklenemedi!"); return end

WindUI:Notify({Title="Tamir Edildi!", Content="Role Detection Anında + Doğru!", Duration=5, Icon="check"})

local Window = WindUI:CreateWindow({
    Title = "MM2 ESP (Role Fix)",
    Author = "x.v3gas.x / Grok",
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

EspTab:Toggle({Title="Box ESP (Role Renkli)", Default=false, Callback=function(v) BoxEnabled=v end})
EspTab:Toggle({Title="Line ESP (Role Renkli)", Default=false, Callback=function(v) LineEnabled=v end})
EspTab:Toggle({Title="Nametag ESP (Role Renkli)", Default=false, Callback=function(v) NameEnabled=v end})
EspTab:Toggle({Title="Gun ESP (Rainbow Box/Line + Mavi GUN)", Default=false, Callback=function(v) GunEnabled=v end})
EspTab:Toggle({Title="Highlight ESP (Role Renkli)", Default=false, Callback=function(v) HighlightEnabled=v; for _,hl in pairs(HighlightCache) do if hl then hl.Enabled=v end end end})

local function w2s(pos)
    local ok, vec, on = pcall(Camera.WorldToViewportPoint, Camera, pos)
    return ok and Vector2.new(vec.X, vec.Y) or Vector2.new(), on or false
end

local function safeDraw(class, props)
    local ok, obj = pcall(Drawing.new, class)
    if ok and obj and props then for k,v in pairs(props) do pcall(function() obj[k]=v end) end end
    return obj
end

-- **YENİ & ANINDA Role Detection (Tool Bazlı)**
local function detectRole(p)
    local role = "Innocent"
    pcall(function()
        local backpack = p:FindFirstChild("Backpack")
        local char = p.Character
        -- Knife öncelikli (Murderer)
        if (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
            role = "Murderer"
            return
        end
        -- Gun (Sheriff)
        if (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
            role = "Sheriff"
        end
    end)
    RoleCache[p] = role
    return role
end

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
        hl.FillColor = ROLE_COLORS[RoleCache[p] or detectRole(p)]
        hl.Enabled = HighlightEnabled
        HighlightCache[p] = hl
    end)
end

-- **Event Bazlı İzleme (Anında Update)**
local function watchPlayer(p)
    createESP(p)
    detectRole(p)  -- Initial
    updateHighlight(p)

    p.CharacterAdded:Connect(function()
        task.wait(0.05)
        detectRole(p)
        updateHighlight(p)
    end)

    -- Backpack Events
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

    -- Character Events
    p.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then
                RoleCache[p] = nil
                detectRole(p)
                updateHighlight(p)
            end
        end)
        char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then
                RoleCache[p] = nil
                detectRole(p)
                updateHighlight(p)
            end
        end)
    end)
end

local function cleanup(p)
    pcall(function()
        if BoxESP[p] and BoxESP[p].box then BoxESP[p].box:Remove() end
        if LineESP[p] and LineESP[p].line then LineESP[p].line:
