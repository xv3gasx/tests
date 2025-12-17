-- FPS OPTIMIZED ESP SCRIPT (v2 - Drops Fixed)
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI load failed") end
WindUI:Notify({Title="Loaded", Content="FPS Optimized ESP!", Duration=3, Icon="check"})

local Window = WindUI:CreateWindow({
    Title = "ESP Script (FPS Opti)",
    Author = "by: x.v3gas.x (FPS Fix: Grok)",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 450),
    Folder = "GUI",
    AutoScale = false
})
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
local EspTab = Window:Tab({Title="ESP", Icon="app-window"})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Globals & Cache (FPS Fix 1: Role Cache)
_G.BoxESPEnabled = false
_G.LineESPEnabled = false
_G.NametagESPEnabled = false
_G.GunESP = false
_G.HighlightESP = false
local HighlightCache = {}
local RoleCache = {}  -- FPS Fix: Cache roles, no scan every frame
local BoxESP, LineESP, NametagESP = {}, {}, {}
local currentGun = nil
local ROLE_COLORS = {Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0)}

-- Toggles
EspTab:Toggle({Title="Box ESP", Default=false, Callback=function(v) _G.BoxESPEnabled=v end})
EspTab:Toggle({Title="Line ESP", Default=false, Callback=function(v) _G.LineESPEnabled=v end})
EspTab:Toggle({Title="Nametag ESP", Default=false, Callback=function(v) _G.NametagESPEnabled=v end})
EspTab:Toggle({Title="Gun ESP", Default=false, Callback=function(v) _G.GunESP=v end})
EspTab:Toggle({Title="Highlight ESP", Default=false, Callback=function(v)
    _G.HighlightESP=v
    for _,hl in pairs(HighlightCache) do if hl then hl.Enabled=v end end
end})

-- Utils (FPS Fix 2: pcall w2s)
local function w2s(pos)
    local ok, v, on = pcall(Camera.WorldToViewportPoint, Camera, pos)
    return ok and Vector2.new(v.X, v.Y) or Vector2.new(), on or false
end
local function draw(class, props)
    local ok, d = pcall(Drawing.new, class)
    if ok and d then for k,v in pairs(props or {}) do pcall(function() d[k]=v end) end end
    return d or nil
end
local function detectRole(p)
    local role = "Innocent"
    local function scan(c) if c then for _,v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") and (v.Name=="Knife" or v.Name=="Gun") then role = v.Name=="Knife" and "Murderer" or "Sheriff" return role end
    end end end
    scan(p.Backpack); scan(p.Character)
    RoleCache[p] = role
    return role
end

-- ESP Creators
local function createBox(p) if p~=LocalPlayer then BoxESP[p]={box=draw("Square",{Filled=false,Thickness=1,Visible=false})} end end
local function createLine(p) if p~=LocalPlayer then LineESP[p]={line=draw("Line",{Thickness=2,Visible=false})} end end
local function createTag(p) if p~=LocalPlayer then NametagESP[p]={text=draw("Text",{Size=14,Center=true,Outline=true,Visible=false})} end end
local function applyHighlight(p)
    local hl = HighlightCache[p]
    if hl then hl:Destroy() end
    if p.Character then
        hl = Instance.new("Highlight")
        hl.Parent = p.Character; hl.Adornee = p.Character
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency=0; hl.OutlineTransparency=0.4
        hl.FillColor = ROLE_COLORS[RoleCache[p] or detectRole(p)]
        hl.Enabled = _G.HighlightESP
        HighlightCache[p] = hl
    end
end

-- Tool Watch (FPS Fix 3: Only on change)
local function watchTools(p)
    local function hook(char)
        char.ChildAdded:Connect(function(c) if c:IsA("Tool") then RoleCache[p]=nil; detectRole(p); applyHighlight(p) end end)
        char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then RoleCache[p]=nil; detectRole(p); applyHighlight(p) end end)
    end
    if p.Character then hook(p.Character) end
    p.CharacterAdded:Connect(hook)
end

-- Gun Finder (FPS Fix 4: 0.5s loop, no events)
task.spawn(function()
    while true do currentGun = workspace:FindFirstChild("GunDrop", true) task.wait(0.5) end
end)
local gunBox = draw("Square",{Thickness=2,Filled=false,Visible=false,Color=Color3.fromRGB(255,255,0)})
local gunText = draw("Text",{Text="GUN",Size=16,Center=true,Outline=true,Visible=false,Color=Color3.fromRGB(255,255,0)})

-- Setup & Cleanup (FPS Fix 5: PlayerRemoving destroy)
local function setup(p)
    createBox(p); createLine(p); createTag(p); watchTools(p); detectRole(p)
    if p.Character then task.delay(0.1, applyHighlight, p) end
    p.CharacterAdded:Connect(function() task.delay(0.1, applyHighlight, p) end)
end
local function destroyESP(p)
    if BoxESP[p]?.box then BoxESP[p].box:Remove() end; BoxESP[p]=nil
    if LineESP[p]?.line then LineESP[p].line:Remove() end; LineESP[p]=nil
    if NametagESP[p]?.text then NametagESP[p].text:Remove() end; NametagESP[p]=nil
    if HighlightCache[p] then HighlightCache[p]:Destroy() end; HighlightCache[p]=nil
    RoleCache[p]=nil
end
for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(destroyESP)

-- Render Loop (FPS Fix 6: Early return + per-feature if + cache + alive check)
RunService.RenderStepped:Connect(function()
    local anyActive = _G.BoxESPEnabled or _G.LineESPEnabled or _G.NametagESPEnabled or _G.GunESP or _G.HighlightESP
    if not anyActive then return end  -- #1 FPS Killer Fixed

    -- Box (only if enabled + alive)
    if _G.BoxESPEnabled then
        for p,d in pairs(BoxESP) do
            local c = p.Character; if not c then d.box.Visible=false continue end
            local hrp = c:FindFirstChild("HumanoidRootPart"); local head = c.Head; local hum = c:FindFirstChildOfClass("Humanoid")
            if not (hrp and head and hum and hum.Health>0) then d.box.Visible=false continue end  -- Alive check
            local t,a = w2s(head.Position + Vector3.new(0,0.5,0))
            local b,b2 = w2s(hrp.Position - Vector3.new(0,2.5,0))
            if a and b2 then
                local h=math.abs(t.Y-b.Y); local w=h/2
                d.box.Position=Vector2.new(t.X-w/2,t.Y); d.box.Size=Vector2.new(w,h)
                d.box.Color=ROLE_COLORS[RoleCache[p] or detectRole(p)]; d.box.Visible=true  -- Cache!
            else d.box.Visible=false end
        end
    end

    -- Line
    if _G.LineESPEnabled then
        for p,d in pairs(LineESP) do
            local c = p.Character; if not c then d.line.Visible=false continue end
            local hrp = c:FindFirstChild("HumanoidRootPart"); local hum = c:FindFirstChildOfClass("Humanoid")
            if not (hrp and hum and hum.Health>0) then d.line.Visible=false continue end
            local pos,on = w2s(hrp.Position)
            if on then
                d.line.From=Vector2.new(Camera.ViewportSize.X/2,0); d.line.To=pos
                d.line.Color=ROLE_COLORS[RoleCache[p] or detectRole(p)]; d.line.Visible=true
            else d.line.Visible=false end
        end
    end

    -- Nametag
    if _G.NametagESPEnabled then
        for p,d in pairs(NametagESP) do
            local c = p.Character; if not c then d.text.Visible=false continue end
            local head = c.Head; local hum = c:FindFirstChildOfClass("Humanoid")
            if not (head and hum and hum.Health>0) then d.text.Visible=false continue end
            local pos,on = w2s(head.Position + Vector3.new(0,1,0))
            if on then
                local role = RoleCache[p] or detectRole(p)
                d.text.Text = p.Name .. " [" .. role .. "]"
                d.text.Position=pos; d.text.Color=ROLE_COLORS[role]; d.text.Visible=true
            else d.text.Visible=false end
        end
    end

    -- Gun
    if _G.GunESP and currentGun then
        local pos,on = w2s(currentGun.Position)
        if on then
            local sz=30
            gunBox.Position=pos-Vector2.new(sz/2,sz/2); gunBox.Size=Vector2.new(sz,sz); gunBox.Visible=true
            gunText.Position=pos+Vector2.new(0,-sz/2-10); gunText.Visible=true
        else
            gunBox.Visible=false; gunText.Visible=false
        end
    else
        gunBox.Visible=false; gunText.Visible=false
    end

    -- Highlight: NO LOOP UPDATE (FPS Fix 7: Only on tool change)
end)
