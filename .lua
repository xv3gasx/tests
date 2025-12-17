local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

if not WindUI then warn("WindUI yüklenemedi!"); return end

WindUI:Notify({Title="ESP Yüklendi (Yeni Role Detect)", Content="Anında Role + 0 FPS Drop!", Duration=5, Icon="check"})

local Window = WindUI:CreateWindow({
    Title = "MM2 ESP (Ultra Fast Role)",
    Author = "Grok",
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

local EspTab = Window:Tab({Title="ESP", Icon="app-window"})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local BoxEnabled = false; LineEnabled = false; NameEnabled = false; GunEnabled = false; HighlightEnabled = false

local BoxESP, LineESP, NameESP, HighlightCache, RoleCache = {}, {}, {}, {}, {}
local currentGun = nil

local ROLE_COLORS = {Murderer = Color3.fromRGB(255,0,0), Sheriff = Color3.fromRGB(0,0,255), Innocent = Color3.fromRGB(0,255,0)}

EspTab:Toggle({Title="Box ESP (Role Renkli)", Default=false, Callback=function(v) BoxEnabled=v end})
EspTab:Toggle({Title="Line ESP (Role Renkli)", Default=false, Callback=function(v) LineEnabled=v end})
EspTab:Toggle({Title="Nametag ESP (Role Renkli)", Default=false, Callback=function(v) NameEnabled=v end})
EspTab:Toggle({Title="Gun ESP (Rainbow Box/Line + Mavi GUN)", Default=false, Callback=function(v) GunEnabled=v end})
EspTab:Toggle({Title="Highlight ESP (Role Renkli)", Default=false, Callback=function(v) HighlightEnabled=v; for _,hl in pairs(HighlightCache) do if hl then hl.Enabled=v end end end})

local function w2s(pos) local ok,v,on=pcall(Camera.WorldToViewportPoint,Camera,pos); return ok and Vector2.new(v.X,v.Y) or Vector2.new(),on or false end
local function safeDraw(class,props) local ok,obj=pcall(Drawing.new,class); if ok and obj and props then for k,v in pairs(props) do pcall(function() obj[k]=v end) end end; return obj end

-- YENİ: Anında Role Detection (Ignored.Roles)
local function setupRoles()
    local ignored = workspace:FindFirstChild("Ignored")
    if not ignored then return end
    local roles = ignored:FindFirstChild("Roles")
    if not roles then return end

    -- Initial scan
    for _,roleObj in ipairs(roles:GetChildren()) do
        local player = roleObj.Value
        if player and RoleCache[player] ~= roleObj.Name then
            RoleCache[player] = roleObj.Name
        end
    end

    -- Anında update (0 delay!)
    roles.ChildAdded:Connect(function(roleObj)
        local player = roleObj.Value
        if player then RoleCache[player] = roleObj.Name end
    end)
    roles.ChildRemoved:Connect(function(roleObj)
        local player = roleObj.Value
        if player then RoleCache[player] = "Innocent" end
    end)

    -- Fallback: 1s scan (round reset garanti)
    spawn(function()
        while task.wait(1) do
            for _,roleObj in ipairs(roles:GetChildren()) do
                local player = roleObj.Value
                if player then RoleCache[player] = roleObj.Name end
            end
        end
    end)
end

local function getRole(p) return RoleCache[p] or "Innocent" end

local function createESP(p)
    if p==LocalPlayer then return end
    BoxESP[p]={box=safeDraw("Square",{Filled=false,Thickness=2,Visible=false})}
    LineESP[p]={line=safeDraw("Line",{Thickness=3,Visible=false})}
    NameESP[p]={text=safeDraw("Text",{Size=16,Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Visible=false})}
end

local function updateHighlight(p)
    pcall(function()
        local hl=HighlightCache[p]; if hl then hl:Destroy() end
        if not p.Character then return end
        hl=Instance.new("Highlight")
        hl.Parent=p.Character; hl.Adornee=p.Character
        hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency=0.5; hl.OutlineTransparency=0
        hl.FillColor=ROLE_COLORS[getRole(p)]; hl.Enabled=HighlightEnabled
        HighlightCache[p]=hl
    end)
end

local function watchPlayer(p)
    createESP(p)
    updateHighlight(p)
    p.CharacterAdded:Connect(function() task.wait(0.05); updateHighlight(p) end)
end

local function cleanup(p)
    if BoxESP[p]?.box then BoxESP[p].box:Remove() end; BoxESP[p]=nil
    if LineESP[p]?.line then LineESP[p].line:Remove() end; LineESP[p]=nil
    if NameESP[p]?.text then NameESP[p].text:Remove() end; NameESP[p]=nil
    if HighlightCache[p] then HighlightCache[p]:Destroy() end; HighlightCache[p]=nil
end

for _,p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer); Players.PlayerRemoving:Connect(cleanup)

-- Gun Loop
task.spawn(function() while task.wait(0.3) do currentGun=workspace:FindFirstChild("GunDrop",true) end end)

-- Rainbow Gun ESP
local gunBox=safeDraw("Square",{Thickness=3,Filled=false,Visible=false})
local gunLine=safeDraw("Line",{Thickness=3,Visible=false})
local gunText=safeDraw("Text",{Text="GUN",Size=20,Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Color=Color3.new(0,162,255),Visible=false})

local rainbow=0; RunService.Heartbeat:Connect(function(dt) rainbow=(rainbow+dt*2)%6.28; local c=Color3.fromHSV(rainbow/6.28,1,1); if gunBox then gunBox.Color=c end; if gunLine then gunLine.Color=c end end)

-- Ultra Opti Render (Early Return + Per-Feature)
RunService.RenderStepped:Connect(function()
    if not (BoxEnabled or LineEnabled or NameEnabled or GunEnabled or HighlightEnabled) then return end

    for p,d in pairs(BoxESP) do
        local char=p.Character; if not char then continue end
        local hrp=char:FindFirstChild("HumanoidRootPart"); local head=char.Head; local hum=char:FindFirstChildOfClass("Humanoid")
        if not (hrp and head and hum and hum.Health>0) then
            if d.box then d.box.Visible=false end
            if LineESP[p]?.line then LineESP[p].line.Visible=false end
            if NameESP[p]?.text then NameESP[p].text.Visible=false end
            continue
        end
        local role=getRole(p); local color=ROLE_COLORS[role]

        -- Box
        if BoxEnabled then
            local top,onTop=w2s(head.Position+Vector3.new(0,0.5,0))
            local bot,onBot=w2s(hrp.Position-Vector3.new(0,2.5,0))
            if onTop and onBot then
                local h=math.abs(top.Y-bot.Y); local w=h/2
                d.box.Position=Vector2.new(top.X-w/2,top.Y); d.box.Size=Vector2.new(w,h); d.box.Color=color; d.box.Visible=true
            else d.box.Visible=false end
        else d.box.Visible=false end

        -- Line
        if LineEnabled then
            local pos,on=w2s(hrp.Position)
            if on then
                LineESP[p].line.From=Vector2.new(Camera.ViewportSize.X/2,0); LineESP[p].line.To=pos
                LineESP[p].line.Color=color; LineESP[p].line.Visible=true
            else LineESP[p].line.Visible=false end
        else if LineESP[p] then LineESP[p].line.Visible=false end end

        -- Nametag
        if NameEnabled then
            local pos,on=w2s(head.Position+Vector3.new(0,1,0))
            if on then
                NameESP[p].text.Text=p.Name.." ["..role.."]"; NameESP[p].text.Position=pos; NameESP[p].text.Color=color; NameESP[p].text.Visible=true
            else NameESP[p].text.Visible=false end
        else if NameESP[p] then NameESP[p].text.Visible=false end end
    end

    -- Gun ESP (Rainbow + Mavi GUN)
    if GunEnabled and currentGun then
        local pos,on=w2s(currentGun.Position)
        if on then
            local sz=35
            gunBox.Position=pos-Vector2.new(sz/2,sz/2); gunBox.Size=Vector2.new(sz,sz); gunBox.Visible=true
            gunLine.From=Vector2.new(Camera.ViewportSize.X/2,0); gunLine.To=pos; gunLine.Visible=true
            gunText.Position=pos; gunText.Visible=true
        else
            gunBox.Visible=gunLine.Visible=gunText.Visible=false
        end
    else
        gunBox.Visible=gunLine.Visible=gunText.Visible=false
    end
end)

-- Roles Setup (Anında!)
setupRoles()

print("MM2 ESP - Anında Role Detection Aktif!")
