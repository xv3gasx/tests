-- 1. WindUI Loader
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not ok or not WindUI then
    return warn("WindUI load failed")
end
WindUI:Notify({Title="Loaded", Content="ESP Script Active!", Duration=3, Icon="check"})

-- 2. Window
local Window = WindUI:CreateWindow({
    Title = "ESP Script",
    Author = "by: x.v3gas.x (Opti by Grok)",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 450),
    Folder = "GUI",
    AutoScale = false  -- Fixed
})

-- 3. Open Button
Window:EditOpenButton({
    Title = "Open ESP Menu",
    Icon = "eye",  -- Better icon
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true
})

-- 4. Tab
local EspTab = Window:Tab({Title="ESP", Icon="app-window"})

-- 5. Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 6. Globals
_G.BoxESPEnabled = false
_G.LineESPEnabled = false
_G.NametagESPEnabled = false
_G.GunESP = false
_G.HighlightESP = false
_G.HighlightCache = {}
_G.RoleCache = {}  -- New: Role cache for perf
local currentGun = nil
local ROLE_COLORS = { Murderer = Color3.fromRGB(255,0,0), Sheriff = Color3.fromRGB(0,0,255), Innocent = Color3.fromRGB(0,255,0) }

-- 7. Toggles
EspTab:Toggle({Title="Box ESP", Default=false, Callback=function(v) _G.BoxESPEnabled=v end})
EspTab:Toggle({Title="Line ESP", Default=false, Callback=function(v) _G.LineESPEnabled=v end})
EspTab:Toggle({Title="Nametag ESP", Default=false, Callback=function(v) _G.NametagESPEnabled=v end})
EspTab:Toggle({Title="Gun ESP", Default=false, Callback=function(v) _G.GunESP=v end})
EspTab:Toggle({Title="Highlight ESP", Default=false, Callback=function(v)
    _G.HighlightESP=v
    for _,hl in pairs(_G.HighlightCache) do if hl then hl.Enabled=v end end
end})

-- 8. Utils
local function detectRole(plr)
    local role = "Innocent"
    local function scan(c)
        if not c then return end
        for _,v in ipairs(c:GetChildren()) do  -- ipairs for perf
            if v:IsA("Tool") then
                if v.Name=="Knife" then role="Murderer" end
                if v.Name=="Gun" then role="Sheriff" end
            end
        end
    end
    scan(plr:FindFirstChild("Backpack"))
    scan(plr.Character)
    _G.RoleCache[plr] = role  -- Cache
    return role
end

local function w2s(pos)
    local ok, v, ons = pcall(Camera.WorldToViewportPoint, Camera, pos)
    return ok and Vector2.new(v.X, v.Y) or Vector2.new(), ons or false
end

local function draw(class, props)
    local ok, d = pcall(Drawing.new, class)
    if not ok or not d then return nil end
    for k,v in pairs(props or {}) do pcall(function() d[k]=v end) end
    return d
end

-- ESP TABLES
local BoxESP, LineESP, NametagESP = {}, {}, {}

-- BOX
local function createBox(p)
    if p==LocalPlayer then return end
    BoxESP[p] = {box = draw("Square",{Filled=false,Thickness=1,Visible=false})}
end

-- LINE
local function createLine(p)
    if p==LocalPlayer then return end
    LineESP[p] = {line = draw("Line",{Thickness=2,Visible=false})}
end

-- NAMETAG
local function createTag(p)
    if p==LocalPlayer then return end
    NametagESP[p] = {text = draw("Text",{Text=p.Name,Size=14,Center=true,Outline=true,Visible=false})}
end

-- HIGHLIGHT
local function applyHighlight(p)
    if p==LocalPlayer or not p.Character then return end
    local hl = _G.HighlightCache[p]
    if hl then hl:Destroy() end
    hl = Instance.new("Highlight")
    hl.Parent = p.Character
    hl.Adornee = p.Character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0
    hl.OutlineTransparency = 0.4
    hl.FillColor = ROLE_COLORS[_G.RoleCache[p] or detectRole(p)]
    hl.Enabled = _G.HighlightESP
    _G.HighlightCache[p] = hl
end

-- TOOL WATCH (ROL FIX)
local function watchTools(p)
    local function hook(char)
        local con1 = char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then
                detectRole(p)  -- Update cache
                applyHighlight(p)
            end
        end)
        local con2 = char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then
                detectRole(p)
                applyHighlight(p)
            end
        end)
        return con1, con2  -- For disconnect if needed
    end
    if p.Character then hook(p.Character) end
    p.CharacterAdded:Connect(hook)
end

-- GUN ESP OBJECTS
local gunBox = draw("Square",{Thickness=2,Filled=false,Visible=false, Color=Color3.fromRGB(255,255,0)})
local gunText = draw("Text",{Text="GUN",Size=16,Center=true,Outline=true,Visible=false, Color=Color3.fromRGB(255,255,0)})

-- Gun Finder Loop (Optimized)
task.spawn(function()
    while true do
        currentGun = workspace:FindFirstChild("GunDrop", true)  -- Faster than descendants
        task.wait(0.5)
    end
end)

-- PLAYERS SETUP
local function setup(p)
    createBox(p)
    createLine(p)
    createTag(p)
    watchTools(p)
    detectRole(p)  -- Initial cache
    if p.Character then task.delay(0.1, applyHighlight, p) end
    p.CharacterAdded:Connect(function() task.delay(0.1, applyHighlight, p) end)
end

local function destroyESP(p)
    if BoxESP[p] and BoxESP[p].box then pcall(BoxESP[p].box.Remove, BoxESP[p].box) BoxESP[p]=nil end
    if LineESP[p] and LineESP[p].line then pcall(LineESP[p].line.Remove, LineESP[p].line) LineESP[p]=nil end
    if NametagESP[p] and NametagESP[p].text then pcall(NametagESP[p].text.Remove, NametagESP[p].text) NametagESP[p]=nil end
    if _G.HighlightCache[p] then pcall(_G.HighlightCache[p].Destroy, _G.HighlightCache[p]) _G.HighlightCache[p]=nil end
    _G.RoleCache[p] = nil
end

for _,p in pairs(Players:GetPlayers()) do setup(p) end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(destroyESP)

-- RENDER LOOP
RunService.RenderStepped:Connect(function()
    if not (_G.BoxESPEnabled or _G.LineESPEnabled or _G.NametagESPEnabled or _G.GunESP or _G.HighlightESP) then return end  -- Early return perf

    -- BOX
    if _G.BoxESPEnabled then
        for p,d in pairs(BoxESP) do
            local c = p.Character local hrp = c and c:FindFirstChild("HumanoidRootPart") local head = c and c:FindFirstChild("Head")
            if hrp and head then
                local t, a = w2s(head.Position + Vector3.new(0,0.5,0))
                local b, b2 = w2s(hrp.Position - Vector3.new(0,2.5,0))
                if a and b2 then
                    local h = math.abs(t.Y - b.Y) local w = h / 2
                    d.box.Position = Vector2.new(t.X - w/2, t.Y)
                    d.box.Size = Vector2.new(w, h)
                    d.box.Color = ROLE_COLORS[_G.RoleCache[p] or detectRole(p)]
                    d.box.Visible = true
                else d.box.Visible = false end
            else d.box.Visible = false end
        end
    end

    -- LINE (ÜST ORTA)
    if _G.LineESPEnabled then
        for p,d in pairs(LineESP) do
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos, on = w2s(hrp.Position)
                if on then
                    d.line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
                    d.line.To = pos
                    d.line.Color = ROLE_COLORS[_G.RoleCache[p] or detectRole(p)]
                    d.line.Visible = true
                else d.line.Visible = false end
            else d.line.Visible = false end
        end
    end

    -- NAMETAG
    if _G.NametagESPEnabled then
        for p,d in pairs(NametagESP) do
            local head = p.Character and p.Character:FindFirstChild("Head")
            if head then
                local pos, on = w2s(head.Position + Vector3.new(0,1,0))
                if on then
                    d.text.Text = p.Name .. " [" .. (_G.RoleCache[p] or detectRole(p)) .. "]"  -- Added role
                    d.text.Position = pos
                    d.text.Color = ROLE_COLORS[_G.RoleCache[p] or detectRole(p)]
                    d.text.Visible = true
                else d.text.Visible = false end
            else d.text.Visible = false end
        end
    end

    -- GUN ESP
    if _G.GunESP and currentGun then
        local pos, on = w2s(currentGun.Position)
        if on then
            local size = 30  -- Dynamic if needed
            gunBox.Position = pos - Vector2.new(size/2, size/2)
            gunBox.Size = Vector2.new(size, size)
            gunBox.Visible = true
            gunText.Position = pos + Vector2.new(0, -size/2 - 10)
            gunText.Visible = true
        else
            gunBox.Visible = false gunText.Visible = false
