-- OPTIMIZED ANTI FLASHBANG (FPS DROP YOK - Event Based)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local antiFlashEnabled = true  -- Ana script'teki toggle'ına bağla (örneğin if enabled then ... end)

if antiFlashEnabled then
    -- Blnd GUI spawn bekle (ilk sefer)
    local blndConnection
    local function disableBlnd()
        local blnd = playerGui:FindFirstChild("Blnd")
        if blnd then
            blnd.Enabled = false
            -- Sürekli flash engelle (Blind değişince anında reset)
            if blndConnection then blndConnection:Disconnect() end
            blndConnection = blnd.ChildAdded:Connect(function(child)
                if child.Name == "Blind" then
                    child.BackgroundTransparency = 1
                    child.ImageTransparency = 1
                    child.Visible = false
                end
            end)
            -- Ekstra: Enabled değişimini yakala
            blnd:GetPropertyChangedSignal("Enabled"):Connect(function()
                blnd.Enabled = false
            end)
        end
    end
    
    -- İlk disable
    disableBlnd()
    
    -- Yeni Blnd spawn olursa (reset/spawn)
    playerGui.ChildAdded:Connect(function(child)
        if child.Name == "Blnd" then
            task.wait(0.1)  -- Tam yüklenmesini bekle
            disableBlnd()
        end
    end)
end
