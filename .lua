local HttpService = game:GetService("HttpService")

InfoTab:Divider()
InfoTab:Section({ 
    Title = "Developer",
    TextXAlignment = "Center",
    TextSize = 17,
})
InfoTab:Divider()

local Owner = InfoTab:Paragraph({
    Title = "CÃ¡o Mod",
    Desc = "Dex and owner script",
    Image = "rbxassetid://113523692909987",
    ImageSize = 30,
    Thumbnail = "",
    ThumbnailSize = 0,
    Locked = false,
})

InfoTab:Divider()
InfoTab:Section({ 
    Title = "Source - Most of the script is based on his script",
    TextXAlignment = "Center",
    TextSize = 17,
})
InfoTab:Divider()

local Source = InfoTab:Paragraph({
    Title = "Nova Hoang (Nguyá»…n NgÃ´ Táº¥n HoÃ ng)",
    Desc = "Owner Of Article Hub and Nihahaha Hub ",
    Image = "rbxassetid://77933782593847",
    ImageSize = 30,
    Thumbnail = "",
    ThumbnailSize = 0,
    Locked = false,
})

InfoTab:Divider()
InfoTab:Section({ 
    Title = "Discord",
    TextXAlignment = "Center",
    TextSize = 17,
})
InfoTab:Divider()

local InviteCode = "mSrMzVuc3h"
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

local function LoadDiscordInfo()
    local success, result = pcall(function()
        return HttpService:JSONDecode(WindUI.Creator.Request({
            Url = DiscordAPI,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "RobloxBot/1.0",
                ["Accept"] = "application/json"
            }
        }).Body)
    end)

    if success and result and result.guild then
        local DiscordInfo = InfoTab:Paragraph({
            Title = result.guild.name,
            Desc = ' <font color="#52525b">â€¢</font> Member Count : ' .. tostring(result.approximate_member_count) ..
                '\n <font color="#16a34a">â€¢</font> Online Count : ' .. tostring(result.approximate_presence_count),
            Image = "https://cdn.discordapp.com/icons/" .. result.guild.id .. "/" .. result.guild.icon .. ".png?size=1024",
            ImageSize = 42,
        })

        InfoTab:Button({
            Title = "Update Info",
            Callback = function()
                local updated, updatedResult = pcall(function()
                    return HttpService:JSONDecode(WindUI.Creator.Request({
                        Url = DiscordAPI,
                        Method = "GET",
                    }).Body)
                end)

                if updated and updatedResult and updatedResult.guild then
                    DiscordInfo:SetDesc(
                        ' <font color="#52525b">â€¢</font> Member Count : ' .. tostring(updatedResult.approximate_member_count) ..
                        '\n <font color="#16a34a">â€¢</font> Online Count : ' .. tostring(updatedResult.approximate_presence_count)
                    )
                end
            end
        })

        InfoTab:Button({
            Title = "Copy Discord Invite",
            Callback = function()
                setclipboard("https://discord.gg/" .. InviteCode)
            end
        })
    else
        InfoTab:Paragraph({
            Title = "Error fetching Discord Info",
            Desc = HttpService:JSONEncode(result),
            Image = "triangle-alert",
            ImageSize = 26,
            Color = "Red",
        })
    end
end

LoadDiscordInfo()