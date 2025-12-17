-- ULTRA DEBUG FPS ESP (Error Logs Dahil)
print("=== MM2 ESP DEBUG START ===")
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not ok or not WindUI then 
    warn("WindUI FAILED!"); return 
end
print("WindUI OK")

WindUI:Notify({Title="Debug ESP Loaded", Content="Check Console!", Duration=5, Icon="bug"})

local Window = WindUI:CreateWindow({Title="ESP Debug (FPS Fix)", Author="x.v3gas.x", Theme="Dark", Size=UDim2.fromOffset(540,450), Folder="GUI", AutoScale=false})
Window:EditOpenButton({Title="ESP Debug", Icon="eye", CornerRadius=UDim.new(0,16), StrokeThickness=2, Color=ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")), Enabled=true, Draggable=true})

local EspTab = Window:Tab({Title="ESP", Icon="app-window"})
local DebugTab = Window:Tab({Title="Debug", Icon="bug"})  -- New tab for logs

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Globals
local BoxESPEnabled, LineESPEnabled, NametagESPEnabled, GunESP, HighlightESP = false, false, false, false, false  -- Local vars, no _G spam
local HighlightCache, RoleCache, BoxESP, LineESP, NametagESP = {}, {}, {}, {}, {}
local currentGun = nil
local ROLE_COLORS = {Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0)}

-- Toggles (Local vars)
EspTab:Toggle({Title="Box ESP", Default=false, Callback=function(v) BoxESPEnabled=v; print("Box:", v) end})
EspTab:Toggle({Title="Line ESP", Default=false, Callback=function(v) LineESPEnabled=v; print("Line:", v) end})
EspTab:Toggle({Title="Nametag ESP", Default=false, Callback=function(v) NametagESPEnabled=v; print("Nametag:", v) end})
EspTab:Toggle({Title="Gun ESP", Default=false, Callback=function(v) GunESP=v; print("Gun:", v) end})
EspTab:Toggle({Title="Highlight ESP", Default=false, Callback=function(v) 
    HighlightESP=v; print("Highlight:", v)
    for p,hl in pairs(HighlightCache) do if hl then hl.Enabled=v end end
end})

-- Utils w/ Debug
local function w2s(pos)
    local ok, v, on = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if not ok then print("w2s ERROR:", pos) end
    return ok and Vector2.new(v.X, v.Y) or Vector2.new(0,0), on or false
end

local function safeDraw(class, props)
    local ok, d = pcall(Drawing.new, class)
    if not ok then print("Drawing.new FAILED:", class); return nil end
    if props then for k,v in pairs(props) do pcall(function() d[k]=v end) end end
    return d
end

local function detectRole(p)
    local role = "Innocent"
    pcall(function()
        local function scan(c) 
            if c then for _,v in ipairs(c:GetChildren()) do
                if v:IsA("Tool") then
                    if v.Name=="Knife" then role="Murderer" return role end
                    if v.Name=="Gun" then role="Sheriff" return role end
                end
            end end 
        end
        scan(p:FindFirstChild("Backpack"))
        scan(p.Character)
    end)
    RoleCache[p] = role
    print(p.Name .. " Role:", role)  -- Debug print
    return role
end

-- Creators
local function createBox(p) 
    if p==LocalPlayer then return end
    local box = safeDraw("Square", {Filled=false, Thickness=1, Visible=false})
    if box then BoxESP[p] = {box=box} else print("Box create FAIL:", p.Name) end
end

local function createLine(p) 
    if p==LocalPlayer then return end
    local line = safeDraw("Line", {Thickness=2, Visible=false})
    if line then LineESP[p] = {line=line} else print("Line create FAIL:", p.Name) end
end

local function createTag(p) 
    if p==LocalPlayer then return end
    local text = safeDraw("Text", {Size=14, Center=true, Outline=true, Visible=false})
    if text then NametagESP[p] = {text=text} else print("Tag create FAIL:", p.Name) end
    text.Text = p.Name  -- Initial
end

local function applyHighlight(p)
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
        hl.Enabled = HighlightESP
        HighlightCache[p] = hl
        print("Highlight OK:", p.Name)
    end)
end

-- Watch Tools
local function watchTools(p)
    pcall(function()
        local function hook(char)
            char.ChildAdded:Connect(function(c) 
                if c:IsA("Tool") then 
                    RoleCache[p] = nil 
                    detectRole(p) 
                    applyHighlight(p) 
                end 
            end)
            char.ChildRemoved:Connect(function(c) 
                if c:IsA("Tool") then 
                    RoleCache[p] = nil 
                    detectRole(p) 
                    applyHighlight(p) 
                end 
            end)
        end
        if p.Character then hook(p.Character) end
        p.CharacterAdded:Connect(hook)
    end)
end

-- Gun
task.spawn(function()
    while task.wait(0.5) do
        currentGun = workspace:FindFirstChild("GunDrop", true)
    end
end)
local gunBox = safeDraw("Square", {Thickness=2, Filled=false, Visible=false, Color=Color3.fromRGB(255,255,0)})
local gunText = safeDraw("Text", {Text="GUN", Size=16, Center=true, Outline=true, Visible=false, Color=Color3.fromRGB(255,255,0)})

-- Setup/Destroy
local function setup(p)
    print("Setup:", p.Name)
    createBox(p); createLine(p); createTag(p); watchTools(p); detectRole(p)
    if p.Character then task.delay(0.1, applyHighlight, p) end
    p.CharacterAdded:Connect(function() task.delay(0.1, applyHighlight, p) end)
end

local function destroyESP(p)
    print("Destroy:", p.Name)
    pcall(function()
        if BoxESP[p] and BoxESP[p].box then BoxESP[p].box:Remove() end; BoxESP[p]=nil
        if LineESP[p] and LineESP[p].line then LineESP[p].line:Remove() end; LineESP[p]=nil
        if NametagESP[p] and NametagESP[p].text then NametagESP[p].text:Remove() end; NametagESP[p]=nil
        if HighlightCache[p] then HighlightCache[p]:Destroy() end; HighlightCache[p]=nil
        RoleCache[p]=nil
    end)
end

for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(destroyESP)

-- Render (FPS Safe)
local conn = RunService.RenderStepped:Connect(function()
    if not (BoxESPEnabled or LineESPEnabled or NametagESPEnabled or GunESP or HighlightESP) then return end

    -- Box
    if BoxESPEnabled then
        for p,d in pairs(BoxESP) do
            local c = p.Character
            if not c or not c:FindFirstChild("HumanoidRootPart") or not c.Head or not c:FindFirstChildOfClass("Humanoid") or c:FindFirstChildOfClass("Humanoid").Health <= 0 then
                if d.box then d.box.Visible = false end
                continue
            end
            local t,a = w2s(c.Head.Position + Vector3.new(0,0.5,0))
            local b,b2 = w2s(c.HumanoidRootPart.Position - Vector3.new(0,2.5,0))
            if a and b2 then
                local h = math.abs(t.Y - b.Y); local w = h / 2
                d.box.Position = Vector2.new(t.X - w/2, t.Y)
                d.box.Size = Vector2.new(w, h)
                d.box.Color = ROLE_COLORS[RoleCache[p] or detectRole(p)]
                d.box.Visible = true
            else
                d.box.Visible = false
            end
        end
    end

    -- Line (kısaltılmış, benzer)
    if LineESPEnabled then
        for p,d in pairs(LineESP) do
            local c = p.Character
            if not c or not c:FindFirstChild("HumanoidRootPart") or not c:FindFirstChildOfClass("Humanoid") or c:FindFirstChildOfClass("Humanoid").Health <= 0 then
                if d.line then d.line.Visible = false end
                continue
            end
            local pos,on = w2s(c.HumanoidRootPart.Position)
            if on then
                d.line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
                d.line.To = pos
                d.line.Color = ROLE_COLORS[RoleCache[p] or detectRole(p)]
                d.line.Visible = true
            else
                d.line.Visible = false
            end
        end
    end

    -- Nametag (kısaltılmış)
    if NametagESPEnabled then
        for p,d in pairs(NametagESP) do
            local c = p.Character
            if not c or not c.Head or not c:FindFirstChildOfClass("Humanoid") or c:FindFirstChildOfClass("Humanoid").Health <= 0 then
                if d.text then d.text.Visible = false end
                continue
            end
            local pos,on = w2s(c.Head.Position + Vector3.new(0,1,0))
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

    -- Gun
    if GunESP and currentGun then
        local pos,on = w2s(currentGun.Position)
        if on then
            local sz = 30
            gunBox.Position = pos - Vector2.new(sz/2, sz/2)
            gunBox.Size = Vector2.new(sz, sz)
            gunBox.Visible = true
            gunText.Position = pos + Vector2.new(0, -sz/2 - 10)
            gunText.Visible =
