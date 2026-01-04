local Players = game:GetService("Players")
local player = Players.LocalPlayer

local currentPlaceId = game.PlaceId

local PlaceLoadstrings = {

    
    [301549746] = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oldd4rkback/Counter-Blox/refs/heads/main/main.lua"))()
    ]],

    [12137249458] = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oldd4rkback/Gun-Grounds-FFA/refs/heads/main/main.lua"))()
    ]],
    
    [142823291] = [[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oldd4rkback/Murder-Mystery-2/refs/heads/main/Open-Source.lua"))()
    ]],
}

local source = PlaceLoadstrings[currentPlaceId]

if source then
    local fn, err = loadstring(source)
    if not fn then
        player:Kick("Script error while loading this game.")
        return
    end

    local ok, runtimeErr = pcall(fn)
    if not ok then
        player:Kick("Runtime error in game script.")
    end
else
 
    player:Kick("Unsupported game. If you think this is a mistake, contact us: discord.gg/kxYEUeARvA")
end
