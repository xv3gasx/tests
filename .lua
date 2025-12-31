local NoSpreadEnabled = true
local WeaponsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")

local function noSpread(weapon)
	if NoSpreadEnabled then
		local spread = weapon:FindFirstChild("Spread")
		if spread then
			for _, v in ipairs(spread:GetDescendants()) do
				if v:IsA("NumberValue") then
					v.Value = 0
				end
			end
		end
	end
end

if WeaponsFolder then
	for _, weapon in ipairs(WeaponsFolder:GetChildren()) do
		noSpread(weapon)
	end
end
print("a")
