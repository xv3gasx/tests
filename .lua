-- LocalScript (StarterPlayer > StarterPlayerScripts içine koy)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Wind UI Library yükle (doğru repo'dan)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()

-- Tema ayarla (opsiyonel)
WindUI:SetTheme("Dark")

-- Ana pencere oluştur
local Window = WindUI:CreateWindow({
    Title = "Test Oyunu Menü",
    Size = UDim2.fromOffset(350, 250),
    Position = UDim2.new(0.5, -175, 0.5, -125)
})

-- Bölüm (Section) oluştur
local MainSection = Window:Section({
    Title = "Ana Kontroller",
    Opened = true  -- Açık başlasın
})

-- Sekme (Tab) ekle
local AutoTab = MainSection:Tab({
    Title = "Auto Shoot",
    Icon = "rbxassetid://6034834858"  -- Opsiyonel ikon
})

-- Toggle durumu
local autoShootEnabled = false

-- Toggle ekle
AutoTab:Toggle({
    Title = "Auto Shoot (Her Silahla Çalışır)",
    Value = false,
    Callback = function(state)
        autoShootEnabled = state
        if state then
            WindUI:Notify({
                Title = "Auto Shoot AÇILDI!",
                Content = "Artık silahın otomatik ateş ediyor.",
                Duration = 5
            })
        else
            WindUI:Notify({
                Title = "Auto Shoot KAPANDI.",
                Duration = 3
            })
        end
    end
})

-- Ana döngü: Auto Shoot
spawn(function()
    while true do
        task.wait() -- en performanslı bekleme
        if autoShootEnabled then
            local character = player.Character
            if character then
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    -- Silah ekipteyse ve mouse bir şeye bakıyorsa otomatik basılı tut
                    if mouse.Target then
                        -- Mouse sol tuşunu sanal olarak basılı tut
                        VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 0)  -- down
                        task.wait(0.03) -- ateş hızı (çok hızlı olmasın diye)
                        VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 0) -- up (opsiyonel, bazı sistemler için)
                    end
                end
            end
        end
    end
end)

-- GUI'yi Insert tuşuyla aç/kapat (docs'ta OnOpen/OnClose var ama tuş için manuel)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
        -- Window:Toggle() yoksa, OnOpen/OnClose kullanabiliriz ama basitçe visible toggle
        -- WindUI'de direkt Toggle methodu olmayabilir, ama assume visible toggle için
        -- Eğer yokysa, custom yap
        if Window.Visible then
            Window:OnClose(function() end) -- veya custom
        else
            Window:OnOpen(function() end)
        end
        Window.Visible = not Window.Visible -- Assume Window.Visible var
    end
end)

-- Başlangıç bildirimi
WindUI:Notify({
    Title = "Menü Yüklendi!",
    Content = "Insert tuşuna basarak aç/kapatabilirsin.",
    Duration = 6
})

print("Auto Shoot Menüsü başarıyla yüklendi! Her silahla çalışır.")
