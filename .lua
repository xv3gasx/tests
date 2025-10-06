-- // Wind UI yükle
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- // Ana pencere oluştur
local Window = WindUI:Window("Vegaz ESP Panel")
local Tab = Window:Tab("ESP")

-- // Değişkenler
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local ESP_Enabled = false
local ESP_Objects = {}

-- // ESP oluşturma fonksiyonu
local function createESP(player)
	if player == LocalPlayer then return end
	if not player.Character then return end
	if ESP_Objects[player] then return end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.Parent = player.Character

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 100, 0, 20)
	billboard.AlwaysOnTop = true
	billboard.Parent = player.Character:WaitForChild("Head", 3)

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Text = player.Name
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0
	text.Font = Enum.Font.SourceSansBold
	text.TextScaled = true
	text.Parent = billboard

	ESP_Objects[player] = {highlight = highlight, billboard = billboard}
end

-- // ESP temizleme fonksiyonu
local function removeESP(player)
	if ESP_Objects[player] then
		for _, v in pairs(ESP_Objects[player]) do
			if v and v.Parent then
				v:Destroy()
			end
		end
		ESP_Objects[player] = nil
	end
end

-- // ESP toggle işlemi
Tab:Toggle("ESP Aktif", ESP_Enabled, function(state)
	ESP_Enabled = state

	if ESP_Enabled then
		-- Açıldığında aktif et
		for _, player in pairs(Players:GetPlayers()) do
			createESP(player)
		end
	else
		-- Kapatıldığında temizle
		for _, player in pairs(Players:GetPlayers()) do
			removeESP(player)
		end
	end
end)

-- // Oyuncu join/leave takibi
Players.PlayerAdded:Connect(function(player)
	if ESP_Enabled then
		player.CharacterAdded:Connect(function()
			task.wait(1)
			createESP(player)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
end)

-- // Karakter yeniden doğarsa ESP yenile
RunService.RenderStepped:Connect(function()
	if ESP_Enabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and not ESP_Objects[player] then
				createESP(player)
			end
		end
	end
end)
