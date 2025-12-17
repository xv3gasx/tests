local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then
warn("WindUI yüklenemedi!")
return
end
WindUI:Notify({
Title = "ESP Yüklendi",
Content = "MM2 ESP Hazır - 100% Optimize!",
Duration = 5,
Icon = "check"
})
local Window = WindUI:CreateWindow({
Title = "MM2 ESP (0 FPS Drop)",
Author = "Grok - 100% Opti",
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
local ROLE_COLORS = {
Murderer = Color3.fromRGB(255, 0, 0),
Sheriff = Color3.fromRGB(0, 0, 255),
Innocent = Color3.fromRGB(0, 255, 0)
}
EspTab:Toggle({Title="Box ESP (Role Renkli)", Default=false, Callback=function(v) BoxEnabled = v end})
EspTab:Toggle({Title="Line ESP (Role Renkli)", Default=false, Callback=function(v) LineEnabled = v end})
EspTab:Toggle({Title="Nametag ESP (Role Renkli)", Default=false, Callback=function(v) NameEnabled = v end})
EspTab:Toggle({Title="Gun ESP (Rainbow Box/Line + Mavi GUN Text)", Default=false, Callback=function(v) GunEnabled = v end})
EspTab:Toggle({Title="Highlight ESP (Role Renkli)", Default=false, Callback=function(v)
HighlightEnabled = v
for _, hl in pairs(HighlightCache) do if hl then hl.Enabled = v end end
end})
local function w2s(pos)
local ok, vec, on = pcall(Camera.WorldToViewportPoint, Camera, pos)
return ok and Vector2.new(vec.X, vec.Y) or Vector2.new(), on or false
end
local function safeDraw(class, props)
local ok, obj = pcall(Drawing.new, class)
if ok and obj and props then
for k, v in pairs(props) do pcall(function() obj[k] = v end) end
end
return obj
end
local function detectRole(p)
local role = "Innocent"
pcall(function()
local backpack = p:FindFirstChild("Backpack")
local char = p.Character
if (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
role = "Murderer"
elseif (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
role = "Sheriff"
end
end)
RoleCache[p] = role
return role
end
local function createESP(p)
if p == LocalPlayer then return end
BoxESP[p] = {box = safeDraw("Square", {Filled=false, Thickness=1, Visible=false})}
LineESP[p] = {line = safeDraw("Line", {Thickness=2, Visible=false})}
NameESP[p] = {text = safeDraw("Text", {Size=14, Center=true, Outline=true, Visible=false, OutlineColor=Color3.fromRGB(0,0,0)})}
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
hl.FillTransparency = 0
hl.OutlineTransparency = 0.4
hl.FillColor = ROLE_COLORS[RoleCache[p] or detectRole(p)]
hl.Enabled = HighlightEnabled
HighlightCache[p] = hl
end)
end
local function watchPlayer(p)
createESP(p)
detectRole(p)
updateHighlight(p)
p.CharacterAdded:Connect(function(char)
task.wait(0.1)
detectRole(p)
updateHighlight(p)
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
local backpack = p:FindFirstChild("Backpack")
if backpack then
backpack.ChildAdded:Connect(function(c)
if c:IsA("Tool") then
RoleCache[p] = nil
detectRole(p)
updateHighlight(p)
end
end)
backpack.ChildRemoved:Connect(function(c)
if c:IsA("Tool") then
RoleCache[p] = nil
detectRole(p)
updateHighlight(p)
end
end)
end
end
local function cleanup(p)
if BoxESP[p] and BoxESP[p].box then BoxESP[p].box:Remove() end BoxESP[p] = nil
if LineESP[p] and LineESP[p].line then LineESP[p].line:Remove() end LineESP[p] = nil
if NameESP[p] and NameESP[p].text then NameESP[p].text:Remove() end NameESP[p] = nil
if HighlightCache[p] then HighlightCache[p]:Destroy() end HighlightCache[p] = nil
RoleCache[p] = nil
end
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(cleanup)
task.spawn(function()
while task.wait(0.5) do
currentGun = workspace:FindFirstChild("GunDrop", true)
end
end)
local gunBox = safeDraw("Square", {Thickness=2, Filled=false, Visible=false})
local gunLine = safeDraw("Line", {Thickness=2, Visible=false})
local gunText = safeDraw("Text", {Text="GUN", Size=16, Center=true, Outline=true, Visible=false, OutlineColor=Color3.fromRGB(0,0,0), Color=Color3.fromRGB(0,0,255)})
local rainbowHue = 0
RunService.Heartbeat:Connect(function(delta)
rainbowHue = (rainbowHue + delta * 0.5) % 1
local rainbowColor = Color3.fromHSV(rainbowHue, 1, 1)
if gunBox then gunBox.Color = rainbowColor end
if gunLine then gunLine.Color = rainbowColor end
end)
RunService.RenderStepped:Connect(function()
if not (BoxEnabled or LineEnabled or NameEnabled or GunEnabled or HighlightEnabled) then return end
for p, d in pairs(BoxESP) do
local char = p.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
local head = char and char:FindFirstChild("Head")
local hum = char and char:FindFirstChildOfClass("Humanoid")
if not char or not hrp or not head or not hum or hum.Health <= 0 then
if d.box then d.box.Visible = false end
if LineESP[p] and LineESP[p].line then LineESP[p].line.Visible = false end
if NameESP[p] and NameESP[p].text then NameESP[p].text.Visible = false end
continue
end
local role = RoleCache[p] or detectRole(p)
if BoxEnabled then
local top, onTop = w2s(head.Position + Vector3.new(0, 0.5, 0))
local bot, onBot = w2s(hrp.Position - Vector3.new(0, 2.5, 0))
if onTop and onBot then
local height = math.abs(top.Y - bot.Y)
local width = height / 2
d.box.Position = Vector2.new(top.X - width / 2, top.Y)
d.box.Size = Vector2.new(width, height)
d.box.Color = ROLE_COLORS[role]
d.box.Visible = true
else
d.box.Visible = false
end
else
d.box.Visible = false
end
if LineEnabled then
local pos, on = w2s(hrp.Position)
if on then
LineESP[p].line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
LineESP[p].line.To = pos
LineESP[p].line.Color = ROLE_COLORS[role]
LineESP[p].line.Visible = true
else
LineESP[p].line.Visible = false
end
else
if LineESP[p] then LineESP[p].line.Visible = false end
end
if NameEnabled then
local pos, on = w2s(head.Position + Vector3.new(0, 1, 0))
if on then
NameESP[p].text.Text = p.Name .. " [" .. role .. "]"
NameESP[p].text.Position = pos
NameESP[p].text.Color = ROLE_COLORS[role]
NameESP[p].text.Visible = true
else
NameESP[p].text.Visible = false
end
else
if NameESP[p] then NameESP[p].text.Visible = false end
end
end
if GunEnabled and currentGun then
local pos, on = w2s(currentGun.Position)
if on then
local sz = 30
gunBox.Position = pos - Vector2.new(sz/2, sz/2)
gunBox.Size = Vector2.new(sz, sz)
gunBox.Visible = true
gunLine.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
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
