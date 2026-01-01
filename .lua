--// ================================
--// PLACE CHECK
--// ================================
local ALLOWED_PLACEID = 301549746
if game.PlaceId ~= ALLOWED_PLACEID then
    game:GetService("Players").LocalPlayer:Kick(
        "Unsupported game. discord.gg/kxYEUeARvA"
    )
    return
end

--// ================================
--// WIND UI LOADER
--// ================================
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
    Content = "Visual module ready",
    Duration = 3,
    Icon = "check"
})

--// ================================
--// WINDOW
--// ================================
local Window = WindUI:CreateWindow({
    Title = "BloxStrike",
    Author = "by x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(520, 380),
    Folder = "BloxStrike",
    AutoScale = true
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Draggable = true
})

--// ================================
--// VISUAL TAB
--// ================================
local Visual_Tab = Window:Tab({
    Title = "Visual",
    Icon = "eye"
})

--// ================================
--// SERVICES
--// ================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// ================================
--// GLOBAL STATES
--// ================================
_G.REMOVE_SMOKE = false
_G.ANTI_FLASH = false

--// ================================
--// NO SMOKE (OPTIMIZED)
--// ================================
local smokeConn
local particleConn

local function disableParticle(obj)
    if obj:IsA("ParticleEmitter") then
        obj.Enabled = false
        obj.Rate = 0
    elseif obj.Name == "Smoke" or obj.Name == "Fire" then
        pcall(function() obj:Destroy() end)
    end
end

local function enableNoSmoke()
    local rayIgnore = Workspace:FindFirstChild("Ray_Ignore")
    if rayIgnore then
        local smokes = rayIgnore:FindFirstChild("Smokes")
        if smokes then
            -- mevcutları TEK SEFER sil
            for _, v in pairs(smokes:GetChildren()) do
                v:Destroy()
            end

            smokeConn = smokes.ChildAdded:Connect(function(child)
                if _G.REMOVE_SMOKE then
                    task.wait()
                    child:Destroy()
                end
            end)
        end
    end

    -- SADECE spawn edilen particle'lar
    particleConn = Workspace.DescendantAdded:Connect(function(obj)
        if _G.REMOVE_SMOKE then
            disableParticle(obj)
        end
    end)
end

local function disableNoSmoke()
    if smokeConn then smokeConn:Disconnect() smokeConn = nil end
    if particleConn then particleConn:Disconnect() particleConn = nil end
end

--// ================================
--// ANTI FLASHBANG (SAFE)
--// ================================
local blindConn

local function enableAntiFlash()
    local blnd = PlayerGui:FindFirstChild("Blnd")
    if blnd then
        blnd.Enabled = false

        local blindFrame = blnd:FindFirstChild("Blind")
        if blindFrame then
            blindConn = blindFrame.Changed:Connect(function()
                if _G.ANTI_FLASH then
                    blnd.Enabled = false
                end
            end)
        end
    end
end

local function disableAntiFlash()
    if blindConn then blindConn:Disconnect() blindConn = nil end
end

--// ================================
--// TOGGLES
--// ================================
Visual_Tab:Toggle({
    Title = "Remove Smoke",
    Callback = function(v)
        _G.REMOVE_SMOKE = v
        if v then
            enableNoSmoke()
        else
            disableNoSmoke()
        end
    end
})

Visual_Tab:Toggle({
    Title = "Anti Flashbang",
    Callback = function(v)
        _G.ANTI_FLASH = v
        if v then
            enableAntiFlash()
        else
            disableAntiFlash()
        end
    end
})

print("✅ Visual module loaded | FPS SAFE | Event-driven")
