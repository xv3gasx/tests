-- WIND UI LOADER
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)

if not ok or not WindUI then
    warn("WindUI load failed")
    return
end

WindUI:Notify({
    Title = "Auto Shoot Loaded",
    Content = "FireServer / unpack(args) Method",
    Duration = 3,
    Icon = "check"
})

-- WINDOW
local Window = WindUI:CreateWindow({
    Title = "Auto Shoot",
    Author = "by x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(420, 260),
    Folder = "AutoShoot_Remote",
    AutoScale = true
})

Window:EditOpenButton({
    Title = "Open Auto Shoot",
    Icon = "crosshair",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Draggable = true
})

-- TAB
local Auto_Tab = Window:Tab({
    Title = "Auto Shoot",
    Icon = "target"
})

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- GLOBALS
_G.AUTO_SHOOT = false
_G.SHOT_DELAY = 0.15

-- UI
Auto_Tab:Toggle({
    Title = "Enable Auto Shoot",
    Callback = function(v)
        _G.AUTO_SHOOT = v
    end
})

Auto_Tab:Slider({
    Title = "Shot Delay",
    Step = 0.01,
    Value = {Min = 0.05, Max = 0.5, Default = 0.15},
    Callback = function(v)
        _G.SHOT_DELAY = v
    end
})

-- INTERNALS
local savedRemote = nil
local savedArgs = nil
local lastShot = 0

-- FIND GUN
local function getTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _,v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            return v
        end
    end
end

-- HOOK REMOTES (CAPTURE ARGS ON MANUAL FIRE)
local function hookTool(tool)
    for _,obj in pairs(tool:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...) end)
        end
    end
end

-- METAMETHOD HOOK (ARGS YAKALAMA)
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt,false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "FireServer" and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
        local tool = getTool()
        if tool and self:IsDescendantOf(tool) then
            savedRemote = self
            savedArgs = args
        end
    end

    return old(self, ...)
end)

setreadonly(mt,true)

-- AUTO SHOOT LOOP
RunService.Heartbeat:Connect(function()
    if not _G.AUTO_SHOOT then return end
    if not savedRemote or not savedArgs then return end
    if tick() - lastShot < _G.SHOT_DELAY then return end

    lastShot = tick()
    pcall(function()
        savedRemote:FireServer(unpack(savedArgs))
    end)
end)