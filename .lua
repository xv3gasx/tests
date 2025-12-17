local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI load failed") end
WindUI:Notify({
    Title = "Load Successful (Optimized v2)",
    Content = "by: x.v3gas.x | Optimized by Grok",
    Duration = 4,
    Icon = "swords",
})

local Window = WindUI:CreateWindow({
    Title = "Murder Mystery 2 Script (Opti v2)",
    Author = "x.v3gas.x / Grok",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 420),
    Folder = "MM2_Opti",
    AutoScale = false
})
Window:EditOpenButton({
    Title = "Open MM2 Hub",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })
local Main_Tab = Window:Tab({ Title = "Main", Icon = "target" })
local ESP_Tab = Window:Tab({ Title = "ESP", Icon = "app-window" })
local TP_Tab = Window:Tab({ Title = "TP", Icon = "zap" })
local Local_Tab = Window:Tab({ Title = "Local", Icon = "user" })

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Globals
_G.ESPEnabled = false
_G.GunESPEnabled = false
_G.WalkSpeedValue = 16
_G.InfiniteJumpEnabled = false
_G.NoclipEnabled = false
_G.KillMurdererEnabled = false
_G.KnifeAuraEnabled = false
_G.KnifeAuraRange = 50  -- Optimized default
_G.KnifeAuraDelay = 0.3

-- Utils
local function safeNewDrawing(class, props)
    local ok, obj = pcall(Drawing.new, class)
    if not ok or not obj then return nil end
    if props then for k,v in pairs(props) do pcall(function() obj[k] = v end) end end
    return obj
end

local function worldToScreen(pos)
    local ok, sp, onScreen = pcall(Camera.WorldToViewportPoint, Camera, pos)
    return ok and sp or Vector2.new(), onScreen or false
end

local ROLE_COLORS = { Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0) }

local function detectRole(player)
    local role = "Innocent"
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        if backpack:FindFirstChild("Knife") then return "Murderer" end
        if backpack:FindFirstChild("Gun") then return "Sheriff" end
    end
    local char = player.Character
    if char then for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name == "Knife" and role=="Murderer" or tool.Name == "Gun" and role=="Sheriff") then
            role = tool.Name == "Knife" and "Murderer" or "Sheriff"
        end
    end end
    return role
end

-- ESP System
local ESP = {}
local function createPlayerESP(player)
    if player == LocalPlayer or ESP[player] then return end
    local line = safeNewDrawing("Line", {Thickness=3, Visible=false, Color=ROLE_COLORS.Innocent})
    local box = safeNewDrawing("Square", {Thickness=1, Filled=false, Visible=false, Color=ROLE_COLORS.Innocent})
    local nameTag = safeNewDrawing("Text", {Size=16, Center=true, Outline=true, Visible=false, Text=player.Name})
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"; highlight.FillTransparency=0; highlight.OutlineTransparency=0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; highlight.Enabled=false
    ESP[player] = {Line=line, Box=box, NameTag=nameTag, Highlight=highlight}
    local function onCharAdded(char)
        if highlight then highlight.Parent=char; highlight.Adornee=char end
    end
    player.CharacterAdded:Connect(onCharAdded)
    if player.Character then onCharAdded(player.Character) end
end
local function destroyPlayerESP(player)
    local data = ESP[player]
    if data then
        pcall(data.Line.Remove, data.Line); pcall(data.Box.Remove, data.Box)
        pcall(data.NameTag.Remove, data.NameTag); pcall(data.Highlight.Destroy, data.Highlight)
        ESP[player] = nil
    end
end
Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(destroyPlayerESP)
for _,p in pairs(Players:GetPlayers()) do createPlayerESP(p) end

-- Gun ESP
local gunLine = safeNewDrawing("Line", {Thickness=3, Visible=false, Color=Color3.fromRGB(255,255,0)})
local gunBox = safeNewDrawing("Square", {Thickness=1, Filled=false, Visible=false, Color=Color3.fromRGB(255,255,0)})
local currentGun = nil
task.spawn(function()
    while true do
        currentGun = workspace:FindFirstChild("GunDrop", true)  -- Optimized!
        task.wait(0.5)
    end
end)

-- TP Functions
local function teleportToGun()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and currentGun then
        local pos = currentGun.Position
        if not pos and currentGun.PrimaryPart then pos = currentGun.PrimaryPart.Position end
        if pos then hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
    else
        WindUI:Notify({Title="Error", Content="No gun found!", Duration=2, Icon="x"})
    end
end

local function teleportBehind(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and myHRP then myHRP.CFrame = CFrame.new(hrp.Position - hrp.CFrame.LookVector * 8, hrp.Position) end
end

local function getMurderer() for _,p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then local hasKnife = (p.Backpack:FindFirstChild("Knife")) or (p.Character and p.Character:FindFirstChild("Knife"))
        if hasKnife then return p end
    end end return nil
end

local function getSheriff() for _,p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then local hasGun = (p.Backpack:FindFirstChild("Gun")) or (p.Character and p.Character:FindFirstChild("Gun"))
        if hasGun then return p end
    end end return nil
end

-- Local Features
local function setWalkSpeed()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= _G.WalkSpeedValue then hum.WalkSpeed = _G.WalkSpeedValue end
    end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); setWalkSpeed() end)
if LocalPlayer.Character then setWalkSpeed() end
RunService.Heartbeat:Connect(function()
    setWalkSpeed()  -- Anti-reset loop
end)

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if _G.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then for _,part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end end
    end
end)

-- UI Elements
TP_Tab:Button({Title="Gun TP", Callback=teleportToGun})
TP_Tab:Button({Title="TP to Murderer", Callback=function()
    local m = getMurderer(); if m then teleportBehind(m) else WindUI:Notify({Title="Error",Content="No murderer!",Duration=2,Icon="x"}) end
end})
TP_Tab:Button({Title="TP to Sheriff", Callback=function()
    local s = getSheriff(); if s then teleportBehind(s) else WindUI:Notify({Title="Error",Content="No sheriff!",Duration=2,Icon="x"}) end
end})
TP_Tab:Button({Title="Kill All (Aura ON)", Callback=function() _G.KnifeAuraEnabled=true end})  -- Quick

ESP_Tab:Toggle({Title="Player ESP", Default=false, Callback=function(state) _G.ESPEnabled=state end})
ESP_Tab:Toggle({Title="Gun ESP", Default=false, Callback=function(state) _G.GunESPEnabled=state end})

Local_Tab:Slider({Title="WalkSpeed", Step=1, Value={Min=16,Max=200,Default=16}, Callback=function(val) _G.WalkSpeedValue=val end})
Local_Tab:Toggle({Title="Infinite Jump", Default=false, Callback=function(state) _G.InfiniteJumpEnabled=state end})
Local_Tab:Toggle({Title="Noclip", Default=false, Callback=function(state) _G.NoclipEnabled=state end})

-- Main Tab
Main_Tab:Toggle({Title="Kill Murderer (Gun Needed)", Default=false, Callback=function(state)
    _G.KillMurdererEnabled = state
    if state then task.spawn(function()
        while _G.KillMurdererEnabled do
            task.wait(0.1)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Gun") then
                local murderer = getMurderer()
                if murderer and murderer.Character and murderer.Character:FindFirstChild("Head") then
                    local headPos = murderer.Character.Head.Position
                    local gun = char.Gun
                    local rf = gun:FindFirstChild("KnifeLocal", true) and gun.KnifeLocal:FindFirstChild("CreateBeam", true) and gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
                    if rf then pcall(rf.InvokeServer, rf, 1, headPos, "AH2") end
                end
            end
        end
    end) end
end})

-- Aura Sliders
Main_Tab:Slider({Title="Aura Range", Step=1, Value={Min=10,Max=200,Default=50}, Callback=function(val) _G.KnifeAuraRange=val end})
Main_Tab:Slider({Title="Aura Delay", Step=0.1, Value={Min=0.1,Max=1,Default=0.3}, Callback=function(val) _G.KnifeAuraDelay=val end})

-- Knife Aura (Optimized)
do
    local function ensureKnifeEquipped()
        local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local tool = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if tool then pcall(hum.EquipTool, hum, tool) return true end
        return false
    end
    local function smoothMoveToPosition(targetPos, stopDist)
        stopDist = stopDist or 1.5
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        for i=1,30 do  -- Reduced steps
            if not _G.KnifeAuraEnabled then return false end
            local dist = (hrp.Position - targetPos).Magnitude
            if dist <= stopDist then return true end
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos + Vector3.new(0,1,0)), 0.3)
            task.wait(0.03)
        end
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,1,0))
        return true
    end
    Main_Tab:Toggle({Title="Knife Aura (Murderer)", Default=false, Callback=function(state)
        _G.KnifeAuraEnabled = state
        if state then task.spawn(function()
            if not ensureKnifeEquipped() then
                WindUI:Notify({Title="Aura Error", Content="Knife missing!", Duration=3, Icon="x"})
                _G.KnifeAuraEnabled = false; return
            end
            while _G.KnifeAuraEnabled do
                task.wait(0.05)
                local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                local targets = {}
                for _,p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                        local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                        if tHRP and tHum and tHum.Health > 0 then
                            local dist = (hrp.Position - tHRP.Position).Magnitude
                            if dist <= _G.KnifeAuraRange then table.insert(targets, {player=p, dist=dist, hrp=tHRP}) end
                        end
                    end
                end
                if #targets == 0 then task.wait(0.5); continue end
                table.sort(targets, function(a,b) return a.dist < b.dist end)
                for _,t in ipairs(targets) do
                    if not _G.KnifeAuraEnabled then break end
                    local tgtHRP = t.hrp; local tgtHum = t.player.Character:FindFirstChildOfClass("Humanoid")
                    if not (tgtHRP and tgtHum and tgtHum.Health > 0) then continue end
                    if not ensureKnifeEquipped() then
                        WindUI:Notify({Title="Aura Stop", Content="Knife lost!", Duration=3, Icon="x"})
                        _G.KnifeAuraEnabled = false; break
                    end
                    smoothMoveToPosition(tgtHRP.Position)
                    local startT = tick()
                    while _G.KnifeAuraEnabled and tgtHum.Health > 0 and (tick() - startT) < 5 do  -- Reduced timeout
                        pcall(function() 
                            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if myHRP then myHRP.CFrame = CFrame.new(tgtHRP.Position) end
                        end)
                        task.wait(0.06)
                    end
                    task.wait(_G.KnifeAuraDelay)
                end
                task.wait(0.2)
            end
        end) end
    end})
end

-- Aim System
local AimConfig = {Murderer=false, Sheriff=false, FOV=150}
local fovCircle = safeNewDrawing("Circle", {Thickness=2, NumSides=64, Radius=AimConfig.FOV, Filled=false, Color=Color3.fromRGB(255,50,50), Visible=false})
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end)

local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local rayResult = workspace:Raycast(origin, direction, rayParams)
    return not rayResult or rayResult.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosest(roleName)
    local closest, minDist = nil, math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and detectRole(p) == roleName then
            local char = p.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and isVisible(hrp) then
                local pos, onScreen = worldToScreen(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < AimConfig.FOV and dist < minDist then minDist=dist; closest=hrp end
                end
            end
        end
    end
    return closest
end

Main_Tab:Slider({Title="Aim FOV", Step=10, Value={Min=50,Max=500,Default=150}, Callback=function(val)
    AimConfig.FOV = val; fovCircle.Radius = val
end})
Main_Tab:Toggle({Title="Aim Murderer", Default=false, Callback=function(state)
    if state and AimConfig.Sheriff then WindUI:Notify({Title="Warn",Content="Disable Sheriff aim!",Duration=3,Icon="alert-circle"}) end
    AimConfig.Murderer = state; if state then AimConfig.Sheriff=false end
    fovCircle.Visible = (AimConfig.Murderer or AimConfig.Sheriff)
end})
Main_Tab:Toggle({Title="Aim Sheriff", Default=false, Callback=function(state)
    if state and AimConfig.Murderer then WindUI:Notify({Title="Warn",Content="Disable Murderer aim!",Duration=3,Icon="alert-circle"}) end
    AimConfig.Sheriff = state; if state then AimConfig.Murderer=false end
    fovCircle.Visible = (AimConfig.Murderer or AimConfig.Sheriff)
end})

-- Main Render Loop (Optimized)
RunService.RenderStepped:Connect(function()
    -- ESP Players
    if not _G.ESPEnabled then
        for player,data in pairs(ESP) do
            if data.Box then data.Box.Visible=false end
            if data.Line then data.Line.Visible=false end
            if data.NameTag then data.NameTag.Visible=false end
            if data.Highlight then data.Highlight.Enabled=false end
        end
    else
        for player,data in pairs(ESP) do
            local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid"); local head = char and char:FindFirstChild("Head")
            if not (char and hrp and hum and hum.Health > 0 and head) then
                if data.Box then data.Box.Visible=false end
                if data.Line then data.Line.Visible=false end
                if data.NameTag then data.NameTag.Visible=false end
                if data.Highlight then data.Highlight.Enabled=false end
            else
                local role = detectRole(player)
                local color = ROLE_COLORS[role] or ROLE_COLORS.Innocent
                if data.Highlight then data.Highlight.FillColor=color; data.Highlight.Enabled=true end
                local top2D, onTop = worldToScreen(head.Position + Vector3.new(0,0.5,0))
                local bottom2D, onBottom = worldToScreen(hrp.Position - Vector3.new(0,2.5,0))
                if onTop and onBottom then
                    local height = math.abs(top2D.Y - bottom2D.Y); local width = height / 2
                    if data.Box then
                        data.Box.Position = Vector2.new(top2D.X - width/2, top2D.Y)
                        data.Box.Size = Vector2.new(width, height); data.Box.Color = color; data.Box.Visible=true
                    end
                    if data.NameTag then
                        data.NameTag.Position = top2D - Vector2.new(0,15)
                        data.NameTag.Color = color; data.NameTag.Text = player.Name .. " [" .. role .. "]"
                        data.NameTag.Visible = true  -- All visible now
                    end
                    if data.Line then
                        data.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0)
                        data.Line.To = Vector2.new(top2D.X, top2D.Y); data.Line.Color = color; data.Line.Visible=true
                    end
                else
                    if data.Box then data.Box.Visible=false end
                    if data.NameTag then data.NameTag.Visible=false end
                    if data.Line then data.Line.Visible=false end
                end
            end
        end
    end

    -- Gun ESP
    if _G.GunESPEnabled and currentGun then
        local pos = currentGun.Position or (currentGun.PrimaryPart and currentGun.PrimaryPart.Position)
        if pos then
            local vec, vis = worldToScreen(pos)
            if vis then
                if gunBox then gunBox.Position=Vector2.new(vec.X-12,vec.Y-12); gunBox.Size=Vector2.new(24,24); gunBox.Visible=true end
                if gunLine then gunLine.From=Vector2.new(Camera.ViewportSize.X/2,0); gunLine.To=Vector2.new(vec.X,vec.Y); gunLine.Visible=true end
            else
                if gunBox then gunBox.Visible=false end; if gunLine then gunLine.Visible=false end
            end
        end
    else
        if gunBox then gunBox.Visible=false end; if gunLine then gunLine.Visible=false end
    end

    -- Aim
    if not (AimConfig.Murderer or AimConfig.Sheriff) then return end
    fovCircle.Visible = true
    local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local target = AimConfig.Murderer and getClosest("Murderer") or AimConfig.Sheriff and getClosest("Sheriff")
    if target then
        local newCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.22)
        hrp.CFrame = CFrame.new(hrp.Position, target.Position)
    end
end)

-- Info Tab
InfoTab:Button({Title="Copy Discord (Updates)", Callback=function()
    setclipboard("https://discord.gg/ftgs-development-hub-1300692552005189632")  -- WindUI Discord
    WindUI:Notify({Title="Copied!", Content="Paste to join!", Duration=3, Icon="copy"})
end})
InfoTab:Label({Title="Credits: x.v3gas.x | Opti: Grok", Color=Color3.fromRGB(255,255,255)})  -- Assuming Label support
InfoTab:Label({Title="Use Alt Acc | No Malware", Color=Color3.fromRGB(0,255,0)})

print("MM2 Opti Script Loaded! 🎉")
