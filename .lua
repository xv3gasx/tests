-- PLACEID BASED LOADER (UNSUPPORTED GAME = KICK)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local currentPlaceId = game.PlaceId

-- PlaceId => loadstring eşleşmeleri
local PlaceLoadstrings = {

    -- ÖRNEKLER
    [1234567890] = [[
        print("Bu oyun destekleniyor (1234567890)")
        -- buraya o oyuna özel script
    ]],

    [9876543210] = [[
        print("Bu oyun destekleniyor (9876543210)")
        -- başka oyuna özel script
    ]],
}

-- Kontrol
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
    -- EŞLEŞME YOK → KICK
    player:Kick("Unsupported game.")
end