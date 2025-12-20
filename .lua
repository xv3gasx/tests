local ALLOWED_PLACEID = 12137249458 -- Gun Grounds FFA PlaceId

if game.PlaceId ~= ALLOWED_PLACEID then
    game:GetService("Players").LocalPlayer:Kick(
        "Unsupported game. If you think this is a mistake, contact us: discord.gg/foxname"
    )
    return
end

--========================================================
-- 1) WIND UI LOADER
--========================================================
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
    Title = "Loaded",
    Content = "Join our Discord for more Scripts/Updates",
    Duration = 3,
    Icon = "check"
})

--========================================================
-- 2) WINDOW
--========================================================
local Window = WindUI:CreateWindow({
    Title = "discord.gg/foxname",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 420),
    Folder = "discord.gg/foxname",
    AutoScale = true
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Draggable = true
})

--========================================================
-- 3) TABS
--========================================================
local ESP_Tab   = Window:Tab({ Title = "ESP", Icon = "app-window" })
local Aim_Tab   = Window:Tab({ Title = "Aim", Icon = "target" })
local Local_Tab = Window:Tab({ Title = "Local Player", Icon = "user" })
local Crosshair_Tab = Window:Tab({ Title = "Crosshair", Icon = "crosshair" })
local Keybind   = Window:Tab({ Title = "Keybind", Icon = "keyboard" })

--========================================================
-- 4) SERVICES + GLOBALS
--========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Globals
_G.HighlightESP = false
_G.LineESP = false
_G.SilentAim = false
_G.AimFOV = 150
_G.WalkSpeed = 16
_G.Noclip = false
_G.InfiniteJump = false

-- Crosshair globals
_G.CustomCrosshair = false
_G.CrosshairColor = Color3.fromRGB(255,0,0)
_G.CrosshairSize = 25
_G.RGBCrosshair = false

--========================================================
-- 5) SAFE DRAWING
--========================================================
local function newDraw(class, props)
    if not Drawing then return nil end
    local obj = Drawing.new(class)
    for k,v in pairs(props or {}) do obj[k] = v end
    return obj
end

--========================================================
-- 6) REMOVE GAME CROSSHAIR
--========================================================
local function removeGameCrosshair()
    UserInputService.MouseIconEnabled = false
    local function hideCrosshairUI()
        for _,v in pairs(PlayerGui:GetDescendants()) do
            if v:IsA("ImageLabel") or v:IsA("Frame") then
                local name = v.Name:lower()
                if name:find("cross") or name:find("reticle") or name:find("aim") then
                    v.Visible = false
                end
            end
        end
    end
    hideCrosshairUI()
    PlayerGui.DescendantAdded:Connect(function(v)
        if v:IsA("ImageLabel") or v:IsA("Frame") then
            local name = v.Name:lower()
            if name:find("cross") or name:find("reticle") or name:find("aim") then
                task.wait()
                v.Visible = false
            end
        end
    end)
end

--========================================================
-- 7) UI ELEMENTS
--========================================================
Crosshair_Tab:Toggle({Title="Custom Crosshair", Callback=function(v) _G.CustomCrosshair=v end})
Crosshair_Tab:Toggle({Title="RGB Crosshair", Callback=function(v) _G.RGBCrosshair=v end})
Crosshair_Tab:Colorpicker({Title="Crosshair Color", Default=_G.CrosshairColor, Callback=function(c) _G.CrosshairColor=c end})
Crosshair_Tab:Button({Title="Remove Game Crosshair", Callback=removeGameCrosshair})

ESP_Tab:Toggle({Title="Highlight ESP", Callback=function(v) _G.HighlightESP=v end})
ESP_Tab:Toggle({Title="Line ESP", Callback=function(v) _G.LineESP=v end})

Aim_Tab:Toggle({Title="Silent Aim", Callback=function(v) _G.SilentAim=v end})
Aim_Tab:Slider({
    Title="Aim FOV",
    Step=5,
    Value={Min=50,Max=500,Default=150},
    Callback=function(v) _G.AimFOV=v end
})

Local_Tab:Slider({
    Title="WalkSpeed",
    Step=1,
    Value={Min=16,Max=100,Default=16},
    Callback=function(v) _G.WalkSpeed=v
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = _G.WalkSpeed end
    end
})
Local_Tab:Toggle({Title="Noclip", Callback=function(v) _G.Noclip=v end})
Local_Tab:Toggle({Title="Infinite Jump", Callback=function(v) _G.InfiniteJump=v end})

--========================================================
-- 8) CUSTOM CROSSHAIR RENDER
--========================================================
local crosshairLines = {}
for i=1,2 do
    crosshairLines[i] = newDraw("Line", {Visible=false, Color=_G.CrosshairColor, Thickness=2})
end

local function getRainbowColor(t)
    local r = math.sin(t*13)*127+128
    local g = math.sin(t*13 + 2)*127+128
    local b = math.sin(t*13 + 4)*127+128
    return Color3.fromRGB(r,g,b)
end

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local color = _G.CrosshairColor
    if _G.RGBCrosshair then color = getRainbowColor(tick()) end

    for i=1,2 do
        crosshairLines[i].Color = color
        crosshairLines[i].Thickness = 2
    end

    if _G.CustomCrosshair then
        local s = _G.CrosshairSize
        crosshairLines[1].From = center - Vector2.new(s/2,0)
        crosshairLines[1].To   = center + Vector2.new(s/2,0)
        crosshairLines[2].From = center - Vector2.new(0,s/2)
        crosshairLines[2].To   = center + Vector2.new(0,s/2)
        crosshairLines[1].Visible = true
        crosshairLines[2].Visible = true
    else
        crosshairLines[1].Visible = false
        crosshairLines[2].Visible = false
    end
end)

--========================================================
-- 9) ESP / AIM / LOCAL PLAYER LOGIC
--========================================================
local ESP = {}
local function addESP(plr)
    if plr == LocalPlayer then return end
    local line = newDraw("Line",{Thickness=1.5, Color=Color3.fromRGB(255,255,255), Visible=false})
    ESP[plr] = {Line=line, Highlight=nil}

    local function createHighlight(char)
        if ESP[plr].Highlight then pcall(function() ESP[plr].Highlight:Destroy() end) end
        local hl = Instance.new("Highlight")
        hl.Enabled = false
        hl.FillColor = Color3.fromRGB(255,0,0)
        hl.FillTransparency = 0
        hl.OutlineTransparency = 0.6
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        hl.Adornee = char
        ESP[plr].Highlight = hl
        if _G.HighlightESP then hl.Enabled = true end
    end

    plr.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        createHighlight(char)
    end)

    if plr.Character then createHighlight(plr.Character) end
end

for _,p in pairs(Players:GetPlayers()) do addESP(p) end
Players.PlayerAdded:Connect(addESP)
Players.PlayerRemoving:Connect(function(p)
    if ESP[p] then
        if ESP[p].Line then ESP[p].Line:Remove() end
        if ESP[p].Highlight then ESP[p].Highlight:Destroy() end
        ESP[p] = nil
    end
end)

local fovCircle = newDraw("Circle", {
    Thickness = 2,
    NumSides = 64,
    Radius = _G.AimFOV,
    Color = Color3.fromRGB(255,0,0),
    Filled = false,
    Visible = false
})

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Radius = _G.AimFOV
end)

local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local ray = workspace:Raycast(origin, dir, params)
    return not ray or ray.Instance:IsDescendantOf(part.Parent)
end

local function getClosestTarget()
    local closest, best = nil, _G.AimFOV
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and isVisible(hrp) then
                local pos, onscreen = Camera:WorldToViewportPoint(hrp.Position)
                if onscreen then
                    local dist = (Vector2.new(pos.X,pos.Y)
                        - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < best then
                        best = dist
                        closest = hrp
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    for plr,data in pairs(ESP) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not (_G.HighlightESP or _G.LineESP) then
            if data.Line then data.Line.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
        else
            if _G.HighlightESP and data.Highlight then data.Highlight.Enabled = true end
            if _G.LineESP and data.Line then
                local pos, onscreen = Camera:WorldToViewportPoint(hrp.Position)
                if onscreen then
                    data.Line.From = Vector2.new(Camera.ViewportSize.X/2,0)
                    data.Line.To = Vector2.new(pos.X,pos.Y)
                    data.Line.Visible = true
                else
                    data.Line.Visible = false
                end
            end
        end
    end

    if _G.SilentAim then
        fovCircle.Visible = true
        local target = getClosestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    else
        fovCircle.Visible = false
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = _G.WalkSpeed end
end)

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if _G.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _,v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

