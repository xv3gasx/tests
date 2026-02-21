print("AAA")
local src = game:HttpGet("https://raw.githubusercontent.com/H3xad3cimalDev/imgui_library/master/imgui.lib.lua")
src = src:gsub("script%.Parent = imgui", "-- patched: script.Parent = imgui")
src = src:gsub("local Prefabs = script%.Parent:WaitForChild%(%\"Prefabs%\"%)", "local Prefabs = imgui:WaitForChild(\"Prefabs\")")
src = src:gsub("local Windows = script%.Parent:FindFirstChild%(%\"Windows%\"%)", "local Windows = imgui:FindFirstChild(\"Windows\")")
src = src:gsub("if script%.Parent then", "if imgui then")
src = src:gsub("script%.Parent%.Enabled = not script%.Parent%.Enabled", "imgui.Enabled = not imgui.Enabled")

local library = loadstring(src)()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:FindFirstChild("TextChatService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VoiceChatService = game:FindFirstChild("VoiceChatService")
local LocalPlayer = Players.LocalPlayer
local state = {
    antiLag = false,
    autoThank = true,
    autoBeg = false,
    anonymousMode = false,
    jumpOnDonated = true,
    spinPerRobux = false,
    helicopterSpin = false,
    serverHopToggle = false,
    serverHopDelay = 15,
    vcServer = false,
    alternativeHop = false,
    serverHopAfterDonation = false,
    friendHop = false,
    goalServerhopSwitch = false,
    goalServerhopGoal = 0,
    antiBotServers = false,
    minimumDonated = 0,
    taggedBoothHop = false,
    webhookAfterSH = false,
    fpsLimit = 60,

    autoEditBoothText = false,
    boothDelay = 12,
    boothColorHex = "FFFFFF",
    boothFont = "Gotham",

    webhookNotify = false,
    pingEveryone = false,
    webhookUrl = "",
}

local begMessages = {
    "Hi! Any donation helps me a lot, thank you!",
    "Trying to reach my goal, support is appreciated!",
    "Even 1 Robux helps, thank you so much!",
    "Saving up for my goal, any support means a lot!",
    "If you enjoy my stand, a small donation helps!",
    "Appreciate every donation, thank you for stopping by!",
}

local begIndex = 0
local boothIndex = 0
local spinBusy = false
local spinLoopConn
local donationSpinMultiplier = 0
local SPIN_SPEED_PER_LEVEL = 120
local JUMP_BURST_DURATION = 5
local JUMP_BURST_INTERVAL = 0.06
local jumpBurstId = 0
local boothRemoteCache

local donationStat
local donationStatConn
local leaderstatsConn
local leaderstatsChildConn
local lastRaised = 0
local lastDonorName = "Unknown"

local donationStatusLabel
local boothStatusLabel
local notifyStatusLabel
local colorStatusLabel
local fontStatusLabel
local boothTextsConsole
local boothTextsInput
local BOOTH_MIN_DELAY = 10
local lastBoothSentText = ""

local serverHopStatusLabel
local serverHopTimerTask
local serverHopBusy = false
local serverHopGoalRaised = 0
local voiceEligible = false
local teleportRetryPending = false
local requestServerHop
local resetServerHopTimer

local SERVER_HOP_PLACE_ID = 8737602449
local SERVER_HOP_VOICE_PLACE_ID = 8943844393
local SERVER_HOP_MIN_DELAY_MINUTES = 1
local BOOTH_BOT_FLAG_WORDS = {
    "spin",
    "jump",
    "helicopter",
    "+1 speed",
    "gifting donations",
    "goal",
}


local SETTINGS_FILE = "pls_donate_helper_settings.json"
local DEFAULT_BOOTH_TEXTS = "Support me if you want! <3\nThank you for visiting my stand!"
local persistenceAvailable = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local persistedBoothTexts = DEFAULT_BOOTH_TEXTS
local queueonteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) or nil

-- If you run from URL, keep this set so teleport always re-runs from same URL.
local AUTOEXEC_HTTP_URL = "https://raw.githubusercontent.com/xv3gasx/tests/refs/heads/main/.lua"

local function queueCurrentScriptOnTeleport()
    if queueonteleport then
        local ok, err = pcall(function()
            queueonteleport("loadstring(game:HttpGet('" .. AUTOEXEC_HTTP_URL .. "'))()")
        end)

        if ok then
            return true
        end

        return false, tostring(err)
    end

    return false, "queue_on_teleport unavailable"
end

local function setLabel(label, text)
    if label then
        label.Text = tostring(text)
    end
end

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$")
end

local function splitLines(text)
    local lines = {}
    text = tostring(text or "")
    text = text:gsub("\\n", "\n")
    text = text:gsub("|", "\n")

    for line in text:gmatch("[^\r\n]+") do
        line = trim(line)
        if line ~= "" then
            table.insert(lines, line)
        end
    end

    return lines
end
local function strictNumber(text)
    text = tostring(text or "")
    if not text:match("^%d+$") then
        return nil
    end
    return tonumber(text)
end

local function parseNumberFromLabeledText(text)
    return tonumber(tostring(text or ""):match("%d+"))
end

local function color3ToHex(color)
    local r = math.floor(math.clamp(color.R, 0, 1) * 255)
    local g = math.floor(math.clamp(color.G, 0, 1) * 255)
    local b = math.floor(math.clamp(color.B, 0, 1) * 255)
    return string.format("%02X%02X%02X", r, g, b)
end

local function normalizeHex(hex)
    hex = trim(hex):gsub("#", ""):upper()
    if hex:match("^[0-9A-F][0-9A-F][0-9A-F]$") then
        hex = hex:sub(1, 1) .. hex:sub(1, 1) .. hex:sub(2, 2) .. hex:sub(2, 2) .. hex:sub(3, 3) .. hex:sub(3, 3)
    end
    if hex:match("^[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$") then
        return hex
    end
    return nil
end

local function parseHexFromLabeledText(text)
    local direct = normalizeHex(text)
    if direct then
        return direct
    end

    local extracted = tostring(text or ""):match("#?([0-9a-fA-F]+)%s*$")
    if extracted then
        return normalizeHex(extracted)
    end

    return nil
end

local function parseWebhookUrlText(text)
    local cleaned = tostring(text or "")
    cleaned = cleaned:gsub("^%s*[Ww]ebhook%s*[Uu][Rr][Ll]%s*:%s*", "", 1)
    return trim(cleaned)
end

local function formatFpsLimitText(value)
    return "FPS Limit: " .. tostring(math.floor(tonumber(value) or 60))
end

local function formatBoothDelayText(seconds)
    return "Text Update Delay: " .. tostring(math.floor(tonumber(seconds) or BOOTH_MIN_DELAY)) .. "s"
end

local function formatBoothColorHexText(hex)
    return "Text Color HEX: " .. tostring(normalizeHex(hex) or "FFFFFF")
end

local function formatWebhookUrlText(url)
    return "Webhook URL: " .. tostring(trim(url))
end

local function formatBoothTextsInputText(text)
    return "Booth Texts: " .. tostring(text or ""):gsub("\n", "|")
end

local function parseBoothTextsInputText(text)
    local cleaned = tostring(text or "")
    cleaned = cleaned:gsub("^%s*[Bb]ooth%s*[Tt]exts%s*:%s*", "", 1)
    return cleaned
end

local function sanitizeLoadedState()
    state.fpsLimit = math.floor(math.clamp(tonumber(state.fpsLimit) or 60, 30, 360))
    state.boothDelay = math.floor(math.clamp(tonumber(state.boothDelay) or 12, BOOTH_MIN_DELAY, 300))
    state.boothColorHex = normalizeHex(state.boothColorHex) or "FFFFFF"
    if type(state.boothFont) ~= "string" or not Enum.Font[state.boothFont] then
        state.boothFont = "Gotham"
    end
    state.webhookUrl = trim(state.webhookUrl)
    state.serverHopDelay = math.floor(math.clamp(tonumber(state.serverHopDelay) or 15, SERVER_HOP_MIN_DELAY_MINUTES, 300))
    state.goalServerhopSwitch = false
    state.goalServerhopGoal = 0
    state.taggedBoothHop = false
    state.minimumDonated = 0
end

local function applyLoadedState(decoded)
    if type(decoded) ~= "table" then
        return
    end

    local loadedState = decoded.state
    if type(loadedState) == "table" then
        for key, defaultValue in pairs(state) do
            local loadedValue = loadedState[key]
            if type(loadedValue) == type(defaultValue) then
                state[key] = loadedValue
            end
        end
    end

    if type(decoded.boothTexts) == "string" and trim(decoded.boothTexts) ~= "" then
        persistedBoothTexts = decoded.boothTexts
    end
end

local function getBoothTextsRaw()
    if boothTextsConsole and boothTextsConsole.Get then
        return tostring(boothTextsConsole:Get() or "")
    end
    if boothTextsInput and boothTextsInput:IsA("TextBox") then
        return parseBoothTextsInputText(boothTextsInput.Text or "")
    end
    return tostring(persistedBoothTexts or "")
end

local function saveSettings()
    if not persistenceAvailable then
        return false, "file api unavailable"
    end

    local payload = {
        state = state,
        boothTexts = getBoothTextsRaw(),
    }

    local ok, err = pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode(payload))
    end)

    if ok then
        persistedBoothTexts = payload.boothTexts
        return true
    end

    return false, tostring(err)
end

local function loadSettings()
    if not persistenceAvailable then
        sanitizeLoadedState()
        return false, "file api unavailable"
    end

    if not isfile(SETTINGS_FILE) then
        sanitizeLoadedState()
        return false, "settings file missing"
    end

    local ok, decoded = pcall(function()
        local raw = readfile(SETTINGS_FILE)
        return HttpService:JSONDecode(raw)
    end)

    if ok and type(decoded) == "table" then
        applyLoadedState(decoded)
        sanitizeLoadedState()
        return true
    end

    sanitizeLoadedState()
    return false, "invalid settings file"
end

local function formatNumber(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local k
    repeat
        s, k = s:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return s
end

local function escapeRichText(text)
    text = tostring(text or "")
    text = text:gsub("&", "&amp;")
    text = text:gsub("<", "&lt;")
    text = text:gsub(">", "&gt;")
    return text
end

local function unescapeRichEntities(text)
    text = tostring(text or "")
    text = text:gsub("&lt;", "<")
    text = text:gsub("&gt;", ">")
    text = text:gsub("&amp;", "&")
    return text
end

local function stripRichTags(text)
    text = unescapeRichEntities(text)
    text = text:gsub("<br%s*/?>", " ")
    text = text:gsub("<.->", " ")
    text = text:gsub("[%c]", " ")
    text = text:gsub("%s+", " ")
    return trim(text)
end

local function sanitizeDonorName(name)
    name = stripRichTags(name)
    name = name:gsub("^@", "")
    name = trim(name)
    if name == "" then
        return "Unknown"
    end
    if #name > 40 then
        name = trim(name:sub(1, 40))
    end
    return name
end

local function normalizeCompareText(text)
    text = stripRichTags(text)
    text = text:gsub("%s+", " ")
    return trim(text):lower()
end

local function getOwnedBoothSignLabel()
    local mapUI
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local container = playerGui:FindFirstChild("MapUIContainer")
        mapUI = container and container:FindFirstChild("MapUI")
    end

    if not mapUI then
        mapUI = workspace:FindFirstChild("MapUI")
    end

    local boothUI = mapUI and mapUI:FindFirstChild("BoothUI")
    if not boothUI then
        return nil
    end

    local myName = tostring(LocalPlayer.Name or ""):lower()
    local myDisplay = tostring(LocalPlayer.DisplayName or LocalPlayer.Name or ""):lower()

    for _, booth in ipairs(boothUI:GetChildren()) do
        local details = booth:FindFirstChild("Details")
        local ownerLabel = details and details:FindFirstChild("Owner")
        local ownerText = ownerLabel and ownerLabel:IsA("TextLabel") and normalizeCompareText(ownerLabel.Text) or ""
        if ownerText ~= "" and (ownerText:find(myName, 1, true) or ownerText:find(myDisplay, 1, true)) then
            local sign = booth:FindFirstChild("Sign")
            local signLabel = sign and sign:FindFirstChild("TextLabel")
            if signLabel and signLabel:IsA("TextLabel") then
                return signLabel
            end
        end
    end

    return nil
end
local function getRequestFunction()
    if type(request) == "function" then
        return request
    end
    if type(http_request) == "function" then
        return http_request
    end
    if syn and type(syn.request) == "function" then
        return syn.request
    end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then
        return fluxus.request
    end
    return nil
end

local function detectVoiceEnabledForLocalPlayer()
    if not VoiceChatService or not VoiceChatService.IsVoiceEnabledForUserIdAsync then
        return false
    end

    local ok, enabled = pcall(function()
        return VoiceChatService:IsVoiceEnabledForUserIdAsync(LocalPlayer.UserId)
    end)

    return ok and enabled == true
end

local function chooseServerHopPlaceId()
    if voiceEligible and state.vcServer then
        return SERVER_HOP_VOICE_PLACE_ID
    end

    if voiceEligible and state.alternativeHop and math.random() < 0.5 then
        return SERVER_HOP_VOICE_PLACE_ID
    end

    return SERVER_HOP_PLACE_ID
end

local function getLocalAvatarImageUrl()
    local userId = tonumber(LocalPlayer and LocalPlayer.UserId)
    if not userId or userId <= 0 then
        return nil
    end

    local req = getRequestFunction()
    if req then
        local okReq, response = pcall(req, {
            Url = string.format(
                "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=420x420&format=Png&isCircular=false",
                userId
            ),
            Method = "GET",
        })

        if okReq and response and type(response.Body) == "string" then
            local okDecode, body = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if okDecode and type(body) == "table" and type(body.data) == "table" then
                local entry = body.data[1]
                local imageUrl = entry and entry.imageUrl
                if type(imageUrl) == "string" and imageUrl ~= "" then
                    return imageUrl
                end
            end
        end
    end

    return string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png",
        userId
    )
end

local function getLocalDisplayName()
    return tostring(LocalPlayer.DisplayName or LocalPlayer.Name or "Unknown")
end

local function mapServerHopReasonType(reasonText)
    local reasonLower = string.lower(trim(reasonText))
    if reasonLower == "auto timer" then
        return "time delay"
    end
    if reasonLower == "friend joined" or reasonLower == "friend in server" then
        return "friend joined"
    end
    if reasonLower == "anti-bot server" then
        return "bot server"
    end
    return "manual"
end

local function getLocalTimeWithUtcOffset()
    local localClock = os.date("%H:%M:%S")
    local rawOffset = tostring(os.date("%z") or "")
    local sign, hh, mm = rawOffset:match("([%+%-])(%d%d)(%d%d)")

    local utcLabel = "UTC"
    if sign and hh and mm then
        utcLabel = "UTC " .. sign .. hh .. ":" .. mm
    end

    return tostring(localClock or "00:00:00") .. " (" .. utcLabel .. ")"
end

local function sendServerHopWebhook(reason)
    if not state.webhookAfterSH then
        return
    end

    local url = trim(state.webhookUrl)
    if url == "" then
        return
    end

    local req = getRequestFunction()
    if not req then
        return
    end

    local reasonText = trim(reason)
    local hopType = mapServerHopReasonType(reasonText)
    local userName = tostring(LocalPlayer.Name)
    local displayName = getLocalDisplayName()
    local avatarUrl = getLocalAvatarImageUrl()

    local description = table.concat({
        "type: " .. tostring(hopType),
        "user: " .. tostring(userName),
        "time: " .. getLocalTimeWithUtcOffset(),
    }, "\n")

    local payload = {
        content = state.pingEveryone and "@everyone" or nil,
        username = "PLS DONATE Helper",
        embeds = {
            {
                title = tostring(displayName) .. " serverhopped",
                description = description,
                color = tonumber("3498DB", 16),
                author = avatarUrl and {name = "@" .. tostring(userName), icon_url = avatarUrl} or nil,
                thumbnail = avatarUrl and {url = avatarUrl} or nil,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }
        }
    }

    pcall(req, {
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    })
end

local function fetchHopServerId(placeId)
    local req = getRequestFunction()
    if not req then
        return nil, "request() function not found"
    end

    local okReq, response = pcall(req, {
        Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", placeId),
        Method = "GET",
    })

    if not okReq then
        return nil, tostring(response)
    end

    local okDecode, body = pcall(function()
        return HttpService:JSONDecode(response and response.Body or "")
    end)

    if not okDecode or type(body) ~= "table" or type(body.data) ~= "table" then
        return nil, "invalid server list"
    end

    local currentJobId = tostring(game.JobId or "")
    local servers = {}

    for _, server in ipairs(body.data) do
        local sid = tostring(server.id or "")
        local playing = tonumber(server.playing)
        if sid ~= "" and sid ~= currentJobId and playing and playing > 12 and playing < 25 then
            table.insert(servers, sid)
        end
    end

    if #servers == 0 then
        return nil, "no suitable servers found"
    end

    return servers[math.random(1, #servers)]
end

requestServerHop = function(reason)
    if serverHopBusy then
        return false, "server hop already in progress"
    end

    local placeId = chooseServerHopPlaceId()
    local serverId, err = fetchHopServerId(placeId)
    if not serverId then
        setLabel(serverHopStatusLabel, "Server hop failed: " .. tostring(err))
        return false, err
    end

    serverHopBusy = true

    local reasonText = trim(reason)
    if reasonText ~= "" then
        setLabel(serverHopStatusLabel, "Server hopping: " .. reasonText)
    else
        setLabel(serverHopStatusLabel, "Server hopping...")
    end

    local queuedOk, queuedErr = queueCurrentScriptOnTeleport()
    if not queuedOk then
        warn("[PLS DONATE Helper] Autoexecute queue failed before hop: " .. tostring(queuedErr))
    end

    sendServerHopWebhook(reasonText)

    local okTp, tpErr = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, serverId, LocalPlayer)
    end)

    if not okTp then
        serverHopBusy = false
        setLabel(serverHopStatusLabel, "Server hop failed: " .. tostring(tpErr))
        return false, tostring(tpErr)
    end

    task.delay(12, function()
        serverHopBusy = false
    end)

    return true
end

TeleportService.TeleportInitFailed:Connect(function(player)
    if player ~= LocalPlayer then
        return
    end

    serverHopBusy = false
    setLabel(serverHopStatusLabel, "Teleport failed, retrying...")

    if teleportRetryPending then
        return
    end

    teleportRetryPending = true
    task.delay(1, function()
        teleportRetryPending = false
        if requestServerHop then
            requestServerHop("retry")
        end
    end)
end)

resetServerHopTimer = function()
    if serverHopTimerTask then
        task.cancel(serverHopTimerTask)
        serverHopTimerTask = nil
    end

    if not state.serverHopToggle then
        return
    end

    local delayMinutes = math.floor(math.clamp(tonumber(state.serverHopDelay) or 15, SERVER_HOP_MIN_DELAY_MINUTES, 300))
    state.serverHopDelay = delayMinutes

    serverHopTimerTask = task.delay(delayMinutes * 60, function()
        serverHopTimerTask = nil
        if state.serverHopToggle and requestServerHop then
            requestServerHop("auto timer")
            resetServerHopTimer()
        end
    end)

    setLabel(serverHopStatusLabel, "Auto hop in " .. tostring(delayMinutes) .. "m")
end

local function isFriendPlayer(player)
    if not player or player == LocalPlayer then
        return false
    end

    local ok, result = pcall(function()
        return player:IsFriendsWith(LocalPlayer.UserId)
    end)

    return ok and result == true
end

local function hopIfFriendPresent(reason)
    if not state.friendHop then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if isFriendPlayer(player) then
            if requestServerHop then
                requestServerHop(reason or "friend in server")
            end
            return
        end
    end
end

local function getBoothUIRoot()
    local mapUI
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local container = playerGui:FindFirstChild("MapUIContainer")
        mapUI = container and container:FindFirstChild("MapUI")
    end

    if not mapUI then
        mapUI = workspace:FindFirstChild("MapUI")
    end

    return mapUI and mapUI:FindFirstChild("BoothUI")
end

local function findNearestUnclaimedBoothInteraction()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local boothUI = getBoothUIRoot()
    local interactions = workspace:FindFirstChild("BoothInteractions")
    if not hrp or not boothUI or not interactions then
        return nil
    end

    local nearestInteraction
    local shortestDistance = math.huge

    for _, uiFrame in ipairs(boothUI:GetChildren()) do
        local details = uiFrame:FindFirstChild("Details")
        local ownerLabel = details and details:FindFirstChild("Owner")
        local ownerText = ownerLabel and ownerLabel:IsA("TextLabel") and normalizeCompareText(ownerLabel.Text) or ""

        if ownerText == "unclaimed" then
            local boothSlot = tonumber(tostring(uiFrame.Name):match("(%d+)$"))
            if boothSlot then
                for _, booth in ipairs(interactions:GetChildren()) do
                    if booth:GetAttribute("BoothSlot") == boothSlot then
                        local distance = (hrp.Position - booth.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            nearestInteraction = booth
                        end
                        break
                    end
                end
            end
        end
    end

    return nearestInteraction
end

local function claimNearestUnclaimedBooth()
    local player = Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")

    local targetBooth = findNearestUnclaimedBoothInteraction()
    if not targetBooth then
        setLabel(boothStatusLabel, "No empty booth found")
        return false
    end

    local boothSlot = tonumber(targetBooth:GetAttribute("BoothSlot"))

    local function isOwnedByMe(slot)
        if not slot then
            return false
        end

        local boothUI = getBoothUIRoot()
        local boothFrame = boothUI and boothUI:FindFirstChild("BoothUI" .. tostring(slot))
        local details = boothFrame and boothFrame:FindFirstChild("Details")
        local ownerLabel = details and details:FindFirstChild("Owner")
        local ownerText = ownerLabel and ownerLabel:IsA("TextLabel") and normalizeCompareText(ownerLabel.Text) or ""

        local myName = tostring(LocalPlayer.Name or ""):lower()
        local myDisplay = tostring(LocalPlayer.DisplayName or LocalPlayer.Name or ""):lower()
        return ownerText:find(myName, 1, true) ~= nil or ownerText:find(myDisplay, 1, true) ~= nil
    end

    local function hasOwnedBooth()
        if boothSlot and isOwnedByMe(boothSlot) then
            return true
        end
        return getOwnedBoothSignLabel() ~= nil
    end

    local function waitForOwnership(timeoutSeconds)
        local timeoutAt = tick() + (tonumber(timeoutSeconds) or 1.2)
        repeat
            if hasOwnedBooth() then
                return true
            end
            task.wait(0.1)
        until tick() >= timeoutAt

        return hasOwnedBooth()
    end

    local function findClaimPrompt(booth)
        local prompt = booth:FindFirstChild("Claim")
        if prompt and prompt:IsA("ProximityPrompt") then
            return prompt
        end

        for _, obj in ipairs(booth:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                return obj
            end
        end

        return nil
    end

    local claimPrompt = findClaimPrompt(targetBooth)
    if not claimPrompt then
        setLabel(boothStatusLabel, "Claim prompt not found")
        return false
    end

    if hasOwnedBooth() then
        setLabel(boothStatusLabel, "Booth already claimed")
        return true
    end

    local function focusCameraToTarget()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local lookPart = claimPrompt.Parent
        if lookPart and lookPart:IsA("BasePart") then
            camera.CFrame = CFrame.new(camera.CFrame.Position, lookPart.Position)
        else
            camera.CFrame = CFrame.new(camera.CFrame.Position, targetBooth.Position)
        end
    end

    local function moveBehindBoothAndFaceOpposite()
        -- Same behavior as ornek.txt "Behind" option: boothPosition = -5.5 (local Z axis).
        local boothCFrame = targetBooth.CFrame
        local standPos = (boothCFrame * CFrame.new(0, 2.45, -5.5)).Position
        local lookTarget = boothCFrame.Position + (boothCFrame.LookVector * 8)

        hrp.CFrame = CFrame.new(standPos, Vector3.new(lookTarget.X, standPos.Y, lookTarget.Z))
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180), 0)

        local camera = workspace.CurrentCamera
        if camera then
            local camPos = camera.CFrame.Position
            local faceDir = hrp.CFrame.LookVector
            camera.CFrame = CFrame.new(camPos, camPos + Vector3.new(faceDir.X, 0, faceDir.Z))
        end
    end
    local function fireClaimPrompt()
        local holdDuration = tonumber(claimPrompt.HoldDuration) or 0
        local fired = false

        if type(fireproximityprompt) == "function" then
            fired = pcall(function()
                fireproximityprompt(claimPrompt, holdDuration)
            end)
        end

        if not fired then
            local began = pcall(function()
                claimPrompt:InputHoldBegin()
            end)
            if began then
                task.wait(holdDuration + 0.1)
                pcall(function()
                    claimPrompt:InputHoldEnd()
                end)
                fired = true
            end
        end

        task.wait(math.max(0.35, holdDuration + 0.15))
        return fired
    end

    local function attemptClaim(tpCFrame)
        hrp.CFrame = tpCFrame
        task.wait(0.2)
        focusCameraToTarget()

        local fired = fireClaimPrompt()
        focusCameraToTarget()
        local claimed = waitForOwnership(1.25)
        return claimed, fired
    end

    local firstClaimed, firstFired = attemptClaim(targetBooth.CFrame + Vector3.new(0, 2.5, 0))
    if firstClaimed then
        moveBehindBoothAndFaceOpposite()
        setLabel(boothStatusLabel, "Booth claimed")
        return true
    end

    local secondClaimed, secondFired = attemptClaim(targetBooth.CFrame * CFrame.new(0, 2.5, -3))
    if secondClaimed then
        moveBehindBoothAndFaceOpposite()
        setLabel(boothStatusLabel, "Booth claimed (retry)")
        return true
    end

    local anyFired = firstFired or secondFired
    setLabel(boothStatusLabel, anyFired and "Claim sent twice, still not owned" or "Claim failed")
    return false
end

local function checkAntiBotServers()
    if not state.antiBotServers then
        return
    end

    local boothUI = getBoothUIRoot()
    if not boothUI then
        return
    end

    local flaggedCount = 0
    for _, obj in ipairs(boothUI:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local text = string.lower(tostring(obj.Text or ""))
            for _, flag in ipairs(BOOTH_BOT_FLAG_WORDS) do
                if text:find(flag, 1, true) then
                    flaggedCount = flaggedCount + 1
                    break
                end
            end
        end
    end

    if flaggedCount > 6 and requestServerHop then
        requestServerHop("anti-bot server")
    end
end

local function checkMinimumDonated()
    local minimum = math.floor(math.max(0, tonumber(state.minimumDonated) or 0))
    if minimum <= 0 then
        return
    end

    local highestRaised = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                for _, stat in ipairs(leaderstats:GetChildren()) do
                    if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                        local name = string.lower(stat.Name)
                        if name:find("raised", 1, true) or name:find("robux", 1, true) then
                            local value = tonumber(stat.Value) or 0
                            if value > highestRaised then
                                highestRaised = value
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    if highestRaised < minimum and requestServerHop then
        requestServerHop("minimum donated")
    end
end
local function setFpsLimit(value)
    local cap = tonumber(value) or 60
    cap = math.floor(math.clamp(cap, 30, 360))
    state.fpsLimit = cap
    if type(setfpscap) == "function" then
        pcall(setfpscap, cap)
    end
end

local function sendChat(message)
    message = trim(message)
    if message == "" then
        return
    end

    local general = TextChatService and TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if general and general.SendAsync then
        local ok = pcall(function()
            general:SendAsync(message)
        end)
        if ok then
            return
        end
    end

    local legacy = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local say = legacy and legacy:FindFirstChild("SayMessageRequest")
    if say then
        pcall(function()
            say:FireServer(message, "All")
        end)
    end
end

local function getTotalRaised()
    if donationStat then
        return tonumber(donationStat.Value) or 0
    end
    return 0
end

local function getAfterTax(amount)
    return math.floor((tonumber(amount) or 0) * 0.6 + 0.5)
end

local function postWebhook(title, donorName, amount, isTest)
    if not isTest and not state.webhookNotify then
        return false, "Webhook notify disabled"
    end

    local url = trim(state.webhookUrl)
    if url == "" then
        return false, "Webhook URL empty"
    end

    local req = getRequestFunction()
    if not req then
        return false, "request() function not found"
    end

    title = stripRichTags(title)
    donorName = sanitizeDonorName(donorName)

    local avatarUrl = getLocalAvatarImageUrl()
    local totalRaised = getTotalRaised()
    local payload = {
        content = state.pingEveryone and "@everyone" or nil,
        username = "PLS DONATE Helper",
        embeds = {
            {
                title = tostring(title),
                color = tonumber("2ECC71", 16),
                author = avatarUrl and {name = "@" .. tostring(LocalPlayer.Name), icon_url = avatarUrl} or nil,
                thumbnail = avatarUrl and {url = avatarUrl} or nil,
                fields = {
                    {name = "Username", value = tostring(donorName), inline = true},
                    {name = "A/T", value = tostring(getAfterTax(amount)), inline = true},
                    {name = "Total Raised", value = formatNumber(totalRaised), inline = true},
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }
        }
    }

    local ok, res = pcall(req, {
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    })

    if not ok then
        return false, tostring(res)
    end

    local code = tonumber(res and (res.StatusCode or res.Status)) or 0
    if code == 200 or code == 201 or code == 204 then
        return true, "OK"
    end

    return false, "HTTP " .. tostring(code)
end

local function getBoothTextPool()
    local raw = ""
    if boothTextsConsole and boothTextsConsole.Get then
        raw = boothTextsConsole:Get()
    elseif boothTextsInput and boothTextsInput:IsA("TextBox") then
        raw = tostring(boothTextsInput.Text or "")
    else
        raw = persistedBoothTexts
    end

    local lines = splitLines(raw)
    if #lines == 0 then
        lines = splitLines(persistedBoothTexts)
    end
    if #lines == 0 then
        lines = splitLines(DEFAULT_BOOTH_TEXTS)
    end

    return lines
end
local function formatBoothText(raw)
    return tostring(raw or "")
end

local function resolveBoothFont()
    local name = trim(state.boothFont)
    if name ~= "" and Enum.Font[name] then
        return Enum.Font[name]
    end
    return Enum.Font.Gotham
end

local function hexToColor3(hex)
    local normalized = normalizeHex(hex) or "FFFFFF"
    local ok, color = pcall(function()
        return Color3.fromHex("#" .. normalized)
    end)
    if ok and color then
        return color
    end
    return Color3.new(1, 1, 1)
end

local function getRemotesProxy()
    if type(Remotes) == "table" and type(Remotes.Event) == "function" then
        return Remotes
    end

    local env = getgenv and getgenv() or nil
    if type(env) == "table" and type(env.Remotes) == "table" and type(env.Remotes.Event) == "function" then
        return env.Remotes
    end

    local function requireRemotesModule(moduleScript)
        local ok, mod = pcall(require, moduleScript)
        if ok and type(mod) == "table" and type(mod.Event) == "function" then
            return mod
        end
        return nil
    end

    local remotesRoot = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesRoot then
        if remotesRoot:IsA("ModuleScript") then
            local mod = requireRemotesModule(remotesRoot)
            if mod then
                return mod
            end
        elseif remotesRoot:IsA("Folder") then
            for _, child in ipairs(remotesRoot:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local mod = requireRemotesModule(child)
                    if mod then
                        return mod
                    end
                end
            end
        end
    end

    local searchRoots = {
        ReplicatedStorage:FindFirstChild("Modules"),
        ReplicatedStorage:FindFirstChild("ClientModules"),
        ReplicatedStorage,
    }

    for _, root in ipairs(searchRoots) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("ModuleScript") and string.lower(obj.Name) == "remotes" then
                    local mod = requireRemotesModule(obj)
                    if mod then
                        return mod
                    end
                end
            end
        end
    end

    return nil
end
local function getOwnedBoothButtonStyle()
    local boothUI = getBoothUIRoot()
    if not boothUI then
        return nil
    end

    local myName = tostring(LocalPlayer.Name or ""):lower()
    local myDisplay = tostring(LocalPlayer.DisplayName or LocalPlayer.Name or ""):lower()

    for _, booth in ipairs(boothUI:GetChildren()) do
        local details = booth:FindFirstChild("Details")
        local ownerLabel = details and details:FindFirstChild("Owner")
        local ownerText = ownerLabel and ownerLabel:IsA("TextLabel") and normalizeCompareText(ownerLabel.Text) or ""

        if ownerText ~= "" and (ownerText:find(myName, 1, true) or ownerText:find(myDisplay, 1, true)) then
            local style = {}

            for attrName, attrValue in pairs(booth:GetAttributes()) do
                local lowerName = string.lower(tostring(attrName))
                if lowerName:find("layout", 1, true) then
                    if type(attrValue) == "string" and trim(attrValue) ~= "" then
                        style.buttonLayout = attrValue
                        break
                    elseif type(attrValue) == "number" then
                        style.buttonLayout = attrValue
                        break
                    end
                end
            end

            if style.buttonLayout == nil then
                local layoutCandidates = {
                    booth:GetAttribute("ButtonLayout"),
                    booth:GetAttribute("buttonLayout"),
                    booth:GetAttribute("Layout"),
                    booth:GetAttribute("layout"),
                }
                for _, layout in ipairs(layoutCandidates) do
                    if type(layout) == "string" and trim(layout) ~= "" then
                        style.buttonLayout = layout
                        break
                    elseif type(layout) == "number" then
                        style.buttonLayout = layout
                        break
                    end
                end
            end

            local chosenButton
            for _, obj in ipairs(booth:GetDescendants()) do
                if obj:IsA("TextButton") then
                    if not chosenButton then
                        chosenButton = obj
                    end

                    local buttonText = trim(stripRichTags(obj.Text))
                    if buttonText ~= "" and buttonText ~= "+" then
                        chosenButton = obj
                        break
                    end
                end
            end

            if chosenButton then
                style.buttonColor = chosenButton.BackgroundColor3
                style.buttonTextColor = chosenButton.TextColor3

                local stroke = chosenButton:FindFirstChildOfClass("UIStroke")
                if stroke then
                    style.buttonStrokeColor = stroke.Color
                end
            end

            return style
        end
    end

    return nil
end

local function fireSetCustomization(plainText)
    local boothStyle = getOwnedBoothButtonStyle() or {}
    local buttonColor = boothStyle.buttonColor or Color3.fromRGB(56, 183, 255)
    local buttonHoverColor = buttonColor:Lerp(Color3.new(1, 1, 1), 0.1)

    local payload = {
        text = tostring(plainText or ""),
        textFont = resolveBoothFont(),
        richText = true,
        strokeColor = Color3.new(0, 0, 0),
        strokeOpacity = 0,
        textColor = hexToColor3(state.boothColorHex),
        buttonTextFont = resolveBoothFont(),
        buttonStrokeColor = boothStyle.buttonStrokeColor or Color3.new(0, 0, 0),
        buttonTextColor = boothStyle.buttonTextColor or Color3.new(1, 1, 1),
        buttonColor = buttonColor,
        buttonHoverColor = buttonHoverColor,
    }

    if type(boothStyle.buttonLayout) == "string" and trim(boothStyle.buttonLayout) ~= "" then
        payload.buttonLayout = boothStyle.buttonLayout
    elseif type(boothStyle.buttonLayout) == "number" then
        payload.buttonLayout = boothStyle.buttonLayout
    end

    local remotesProxy = getRemotesProxy()
    if remotesProxy then
        local okEvent, remoteObj = pcall(function()
            return remotesProxy.Event("SetCustomization")
        end)

        if okEvent and remoteObj then
            local attempts = {
                function()
                    if remoteObj:IsA("RemoteEvent") then
                        remoteObj:FireServer(payload, "booth")
                    else
                        remoteObj:InvokeServer(payload, "booth")
                    end
                end,
                function()
                    if remoteObj:IsA("RemoteEvent") then
                        remoteObj:FireServer("booth", payload)
                    else
                        remoteObj:InvokeServer("booth", payload)
                    end
                end,
            }

            for _, call in ipairs(attempts) do
                if pcall(call) then
                    return true
                end
            end
        end
    end

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and string.lower(obj.Name) == "setcustomization" then
            local attempts = {
                function()
                    if obj:IsA("RemoteEvent") then
                        obj:FireServer(payload, "booth")
                    else
                        obj:InvokeServer(payload, "booth")
                    end
                end,
                function()
                    if obj:IsA("RemoteEvent") then
                        obj:FireServer("booth", payload)
                    else
                        obj:InvokeServer("booth", payload)
                    end
                end,
            }

            for _, call in ipairs(attempts) do
                if pcall(call) then
                    return true
                end
            end
        end
    end

    return false
end

local function applyBoothText(rawText)
    local plainText = formatBoothText(rawText)
    local targetText = normalizeCompareText(plainText)
    if targetText == "" then
        return false
    end

    local signLabel = getOwnedBoothSignLabel()
    if signLabel and normalizeCompareText(signLabel.Text) == targetText then
        lastBoothSentText = plainText
        return true
    end

    local dispatched = fireSetCustomization(plainText)
    if not dispatched then
        return false
    end

    task.wait(0.35)

    signLabel = signLabel or getOwnedBoothSignLabel()
    if signLabel and normalizeCompareText(signLabel.Text) == targetText then
        lastBoothSentText = plainText
        return true
    end

    lastBoothSentText = plainText
    return true
end
local function jumpNow()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function stopJumpBurst()
    jumpBurstId = jumpBurstId + 1
end

local function isGroundedHumanoid(humanoid)
    if not humanoid then
        return false
    end

    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed then
        return true
    end

    return humanoid.FloorMaterial ~= Enum.Material.Air
end

local function startJumpBurst(durationSeconds)
    local duration = math.max(0.5, tonumber(durationSeconds) or JUMP_BURST_DURATION)
    stopJumpBurst()
    local myBurstId = jumpBurstId

    task.spawn(function()
        local started = tick()
        while jumpBurstId == myBurstId and (tick() - started) < duration do
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if humanoid and isGroundedHumanoid(humanoid) then
                jumpNow()

                local leaveTimeout = tick() + 1
                while jumpBurstId == myBurstId and tick() < leaveTimeout do
                    character = LocalPlayer.Character
                    humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if not humanoid or not isGroundedHumanoid(humanoid) then
                        break
                    end
                    task.wait(JUMP_BURST_INTERVAL)
                end

                local landTimeout = tick() + 3
                while jumpBurstId == myBurstId and tick() < landTimeout do
                    character = LocalPlayer.Character
                    humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid and isGroundedHumanoid(humanoid) then
                        break
                    end
                    task.wait(JUMP_BURST_INTERVAL)
                end
            else
                task.wait(JUMP_BURST_INTERVAL)
            end
        end
    end)
end


local function shouldRunPersistentSpin()
    return state.helicopterSpin and state.spinPerRobux and donationSpinMultiplier > 0
end

local function stopPersistentSpin()
    if spinLoopConn then
        spinLoopConn:Disconnect()
        spinLoopConn = nil
    end
end

local function updatePersistentSpin()
    if not shouldRunPersistentSpin() then
        stopPersistentSpin()
        return
    end

    if spinLoopConn then
        return
    end

    spinLoopConn = RunService.RenderStepped:Connect(function(dt)
        if not shouldRunPersistentSpin() then
            stopPersistentSpin()
            return
        end

        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return
        end

        local speed = math.max(1, donationSpinMultiplier) * SPIN_SPEED_PER_LEVEL
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(speed * dt), 0)
    end)
end

local function helicopterSpin(multiplier)
    if state.spinPerRobux then
        return
    end

    if spinBusy then
        return
    end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    spinBusy = true
    local power = math.max(1, tonumber(multiplier) or 1)
    local duration = 0.8 + math.min(power, 30) * 0.08
    local speed = 360 * power
    local started = tick()

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not hrp.Parent or tick() - started >= duration then
            conn:Disconnect()
            spinBusy = false
            return
        end

        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(speed * dt), 0)
    end)
end

local function handleDonation(amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return
    end

    local donorName = state.anonymousMode and "Anonymous" or sanitizeDonorName(lastDonorName)

    if state.autoThank then
        if state.anonymousMode then
            sendChat("Thanks for donating " .. tostring(amount) .. " Robux! <3")
        else
            sendChat("Thanks " .. tostring(donorName) .. " for donating " .. tostring(amount) .. " Robux! <3")
        end
    end

    if state.serverHopToggle and resetServerHopTimer then
        resetServerHopTimer()
    end

    if state.spinPerRobux then
        donationSpinMultiplier = math.clamp(donationSpinMultiplier + amount, 0, 200)
        updatePersistentSpin()
    elseif state.helicopterSpin then
        helicopterSpin(1)
    end
    if state.jumpOnDonated then
        startJumpBurst(JUMP_BURST_DURATION)
    end

    if state.serverHopAfterDonation and requestServerHop then
        task.spawn(requestServerHop, "after donation")
    end

    if state.webhookNotify then
        local title = getLocalDisplayName() .. " donated by " .. tostring(donorName)
        local ok, msg = postWebhook(title, donorName, amount, false)
        if not ok then
            setLabel(notifyStatusLabel, "Webhook error: " .. tostring(msg))
        end
    end
end
local function pickDonationStat()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if not leaderstats then
        return nil
    end

    local preferred = {
        "Raised",
        "raised",
        "RobuxRaised",
        "RaisedAmount",
        "R$ Raised",
    }

    for _, name in ipairs(preferred) do
        local v = leaderstats:FindFirstChild(name)
        if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v
        end
    end

    local fallback
    for _, v in ipairs(leaderstats:GetChildren()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            local n = string.lower(v.Name)
            if n:find("raised") or n:find("robux") then
                return v
            end
            if not fallback and n:find("donat") then
                fallback = v
            end
        end
    end

    return fallback
end

local function bindDonationStat(stat)
    if donationStatConn then
        donationStatConn:Disconnect()
        donationStatConn = nil
    end

    donationStat = stat
    lastRaised = tonumber(stat.Value) or 0
    setLabel(donationStatusLabel, "Donation stat: " .. stat.Name)

    donationStatConn = stat:GetPropertyChangedSignal("Value"):Connect(function()
        local current = tonumber(stat.Value) or lastRaised
        if current > lastRaised then
            handleDonation(current - lastRaised)
        end
        lastRaised = current
    end)
end

local function refreshDonationStat()
    local stat = pickDonationStat()
    if stat and stat ~= donationStat then
        bindDonationStat(stat)
    elseif not stat then
        setLabel(donationStatusLabel, "Donation stat: not found")
    end
end

local function parseDonorFromText(text)
    local plain = stripRichTags(text)
    if plain == "" then
        return nil
    end

    local lower = plain:lower()
    local myName = tostring(LocalPlayer.Name or ""):lower()
    local myDisplay = tostring(LocalPlayer.DisplayName or LocalPlayer.Name or ""):lower()

    if not lower:find("donat", 1, true) then
        return nil
    end

    local mentionsMe =
        lower:find(myName, 1, true) or
        lower:find(myDisplay, 1, true) or
        lower:find(" you", 1, true) or
        lower:find("you ", 1, true)

    if not mentionsMe then
        return nil
    end

    local donor =
        plain:match("[Dd]onated%s+[Bb]y%s+(.+)$") or
        plain:match("[Dd]onated%s+[Ff]rom%s+(.+)$") or
        plain:match("^(.-)%s+[Jj]ust%s+[Dd]onated") or
        plain:match("^(.-)%s+[Dd]onated%s+[%d,]+") or
        plain:match("^(.-)%s+[Dd]onated")

    if not donor or donor == "" then
        return nil
    end

    donor = donor:gsub("^to%s+", "")
    donor = donor:gsub("%s+[!%.]+$", "")
    donor = sanitizeDonorName(donor)

    local donorLower = donor:lower()
    if donorLower == myName or donorLower == myDisplay or donorLower == "you" then
        return nil
    end

    return donor
end
local function setupDonorDetection()
    local function messageLooksLikeDonationForMe(rawText)
        local plain = stripRichTags(rawText):lower()
        if not plain:find("donat", 1, true) then
            return false
        end

        local myName = LocalPlayer.Name:lower()
        local myDisplay = tostring(LocalPlayer.DisplayName or LocalPlayer.Name):lower()
        return plain:find(myName, 1, true) or plain:find(myDisplay, 1, true) or plain:find("you", 1, true)
    end

    local legacy = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local legacyMsg = legacy and legacy:FindFirstChild("OnMessageDoneFiltering")
    if legacyMsg and legacyMsg.OnClientEvent then
        legacyMsg.OnClientEvent:Connect(function(data)
            local text = data and data.Message or ""
            local donor = parseDonorFromText(text)
            if donor then
                lastDonorName = donor
                return
            end

            if data and data.FromSpeaker and messageLooksLikeDonationForMe(text) then
                local speaker = sanitizeDonorName(data.FromSpeaker)
                local sLower = speaker:lower()
                if sLower ~= "system" and sLower ~= "roblox" and sLower ~= "pls donate" then
                    lastDonorName = speaker
                end
            end
        end)
    end

    local general = TextChatService and TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if general and general.MessageReceived then
        general.MessageReceived:Connect(function(message)
            local text = message and message.Text or ""
            local donor = parseDonorFromText(text)
            if donor then
                lastDonorName = donor
                return
            end

            if message and message.TextSource and messageLooksLikeDonationForMe(text) then
                local plr = Players:GetPlayerByUserId(message.TextSource.UserId)
                if plr then
                    lastDonorName = sanitizeDonorName(plr.Name)
                end
            end
        end)
    end
end

local function setupDonationStatWatcher()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        if leaderstatsChildConn then
            leaderstatsChildConn:Disconnect()
        end
        leaderstatsChildConn = leaderstats.ChildAdded:Connect(function()
            task.wait(0.1)
            refreshDonationStat()
        end)
        refreshDonationStat()
    end

    if leaderstatsConn then
        leaderstatsConn:Disconnect()
    end

    leaderstatsConn = LocalPlayer.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            task.wait(0.2)
            setupDonationStatWatcher()
        end
    end)
end

loadSettings()
voiceEligible = detectVoiceEnabledForLocalPlayer()
local queuedAutoExec, autoExecErr = queueCurrentScriptOnTeleport()
if not queuedAutoExec then
    warn("[PLS DONATE Helper] Autoexecute queue failed: " .. tostring(autoExecErr))
end

Players.PlayerAdded:Connect(function(player)
    if state.friendHop and isFriendPlayer(player) and requestServerHop then
        requestServerHop("friend joined")
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    updatePersistentSpin()
end)

local window = library:AddWindow("PLS DONATE Helper", {
    main_color = Color3.fromRGB(41, 74, 122),
    min_size = Vector2.new(520, 420),
    toggle_key = Enum.KeyCode.RightShift,
    can_resize = true,
})

local mainTab = window:AddTab("Main")
mainTab:Show()

mainTab:AddLabel("Main Features")

local antiLagSwitch = select(1, mainTab:AddSwitch("Anti Lag (Render Disable)", function(v)
    state.antiLag = v
    pcall(function()
        RunService:Set3dRenderingEnabled(not v)
    end)
    saveSettings()
end))
antiLagSwitch:Set(state.antiLag)

local autoThankSwitch = select(1, mainTab:AddSwitch("Auto Thank User When Donated", function(v)
    state.autoThank = v
    saveSettings()
end))
autoThankSwitch:Set(state.autoThank)

local autoBegSwitch = select(1, mainTab:AddSwitch("Auto Beg", function(v)
    state.autoBeg = v
    saveSettings()
end))
autoBegSwitch:Set(state.autoBeg)

local anonymousSwitch = select(1, mainTab:AddSwitch("Anonymous Mode", function(v)
    state.anonymousMode = v
    saveSettings()
end))
anonymousSwitch:Set(state.anonymousMode)

local jumpDonatedSwitch = select(1, mainTab:AddSwitch("Jump When Donated", function(v)
    state.jumpOnDonated = v
    if not v then
        stopJumpBurst()
    end
    saveSettings()
end))
jumpDonatedSwitch:Set(state.jumpOnDonated)

local spinPerSwitch = select(1, mainTab:AddSwitch("1R$ = +1 Spin Multiplier", function(v)
    state.spinPerRobux = v
    if not v then
        donationSpinMultiplier = 0
        stopPersistentSpin()
    else
        updatePersistentSpin()
    end
    saveSettings()
end))
spinPerSwitch:Set(state.spinPerRobux)

local heliSpinSwitch = select(1, mainTab:AddSwitch("Helicopter Spin When Donation", function(v)
    state.helicopterSpin = v
    if v then
        updatePersistentSpin()
    else
        stopPersistentSpin()
    end
    saveSettings()
end))
heliSpinSwitch:Set(state.helicopterSpin)

local fpsLimitBox
fpsLimitBox = mainTab:AddTextBox("FPS Limit (default 60)", function(text)
    local n = strictNumber(text) or parseNumberFromLabeledText(text)
    if not n then
        setFpsLimit(60)
        if fpsLimitBox then
            fpsLimitBox.Text = formatFpsLimitText(state.fpsLimit)
        end
        saveSettings()
        return
    end

    setFpsLimit(n)
    if fpsLimitBox then
        fpsLimitBox.Text = formatFpsLimitText(state.fpsLimit)
    end
    saveSettings()
end, {clear = false})
if fpsLimitBox and fpsLimitBox:IsA("TextBox") then
    fpsLimitBox.Text = formatFpsLimitText(state.fpsLimit)
end

mainTab:AddButton("Apply FPS 60", function()
    setFpsLimit(60)
    if fpsLimitBox and fpsLimitBox:IsA("TextBox") then
        fpsLimitBox.Text = formatFpsLimitText(state.fpsLimit)
    end
    saveSettings()
end)

mainTab:AddButton("Re-scan Donation Stat", function()
    refreshDonationStat()
end)

donationStatusLabel = mainTab:AddLabel("Donation stat: scanning...")
local serverHopTab = window:AddTab("Server Hop")
serverHopTab:AddLabel("Server Hop Settings")

local autoServerHopSwitch = select(1, serverHopTab:AddSwitch("Auto Server Hop", function(v)
    state.serverHopToggle = v
    if resetServerHopTimer then
        resetServerHopTimer()
    end
    saveSettings()
end))
autoServerHopSwitch:Set(state.serverHopToggle)

local serverHopDelayBox
local function formatServerHopDelayText(minutes)
    return "ServerHop Delay: " .. tostring(minutes) .. "M"
end
serverHopDelayBox = serverHopTab:AddTextBox("ServerHop Delay", function(text)
    local n = tonumber(tostring(text or ""):match("%d+"))
    if not n then
        if serverHopDelayBox and serverHopDelayBox:IsA("TextBox") then
            serverHopDelayBox.Text = formatServerHopDelayText(state.serverHopDelay)
        end
        return
    end

    state.serverHopDelay = math.floor(math.clamp(n, SERVER_HOP_MIN_DELAY_MINUTES, 300))
    if serverHopDelayBox and serverHopDelayBox:IsA("TextBox") then
        serverHopDelayBox.Text = formatServerHopDelayText(state.serverHopDelay)
    end

    if resetServerHopTimer then
        resetServerHopTimer()
    end
    saveSettings()
end, {clear = false})
if serverHopDelayBox and serverHopDelayBox:IsA("TextBox") then
    serverHopDelayBox.Text = formatServerHopDelayText(state.serverHopDelay)
end
serverHopTab:AddLabel("Server hop timer resets after donation")

if voiceEligible then
    local voiceServerSwitch = select(1, serverHopTab:AddSwitch("Voice Chat Servers", function(v)
        state.vcServer = v
        saveSettings()
    end))
    voiceServerSwitch:Set(state.vcServer)

    local alternativeSwitch = select(1, serverHopTab:AddSwitch("Random between normal/voice", function(v)
        state.alternativeHop = v
        saveSettings()
    end))
    alternativeSwitch:Set(state.alternativeHop)
else
    serverHopTab:AddLabel("Voice chat place hopping unavailable for this account")
end

local serverHopAfterDonationSwitch = select(1, serverHopTab:AddSwitch("Server Hop after donation", function(v)
    state.serverHopAfterDonation = v
    saveSettings()
end))
serverHopAfterDonationSwitch:Set(state.serverHopAfterDonation)

local friendHopSwitch = select(1, serverHopTab:AddSwitch("Server Hop if friend joined", function(v)
    state.friendHop = v
    if v then
        hopIfFriendPresent("friend in server")
    end
    saveSettings()
end))
friendHopSwitch:Set(state.friendHop)


local antiBotServersSwitch = select(1, serverHopTab:AddSwitch("[BETA] Anti Bot Servers", function(v)
    state.antiBotServers = v
    if v then
        checkAntiBotServers()
    end
    saveSettings()
end))
antiBotServersSwitch:Set(state.antiBotServers)



serverHopTab:AddButton("Server Hop", function()
    if requestServerHop then
        requestServerHop("manual")
    end
end)

serverHopStatusLabel = serverHopTab:AddLabel("Server hop status: idle")

local boothTab = window:AddTab("Booth")
boothTab:AddLabel("Booth Settings")

local autoBoothSwitch = select(1, boothTab:AddSwitch("Auto Edit Booth Text", function(v)
    state.autoEditBoothText = v
    saveSettings()
end))
autoBoothSwitch:Set(state.autoEditBoothText)

local boothDelayBox
boothDelayBox = boothTab:AddTextBox("Text Update Delay (sec)", function(text)
    local n = parseNumberFromLabeledText(text)
    if not n then
        if boothDelayBox and boothDelayBox:IsA("TextBox") then
            boothDelayBox.Text = formatBoothDelayText(state.boothDelay)
        end
        return
    end

    state.boothDelay = math.floor(math.clamp(n, BOOTH_MIN_DELAY, 300))
    if n < BOOTH_MIN_DELAY then
        setLabel(boothStatusLabel, "Delay too low, using " .. tostring(BOOTH_MIN_DELAY) .. "s")
    end

    if boothDelayBox and boothDelayBox:IsA("TextBox") then
        boothDelayBox.Text = formatBoothDelayText(state.boothDelay)
    end
    saveSettings()
end, {clear = false})
if boothDelayBox and boothDelayBox:IsA("TextBox") then
    boothDelayBox.Text = formatBoothDelayText(state.boothDelay)
end

local colorPickerData
local boothColorHexBox
boothColorHexBox = boothTab:AddTextBox("Text Color HEX (FFFFFF)", function(text)
    local hex = parseHexFromLabeledText(text)
    if not hex then
        if boothColorHexBox and boothColorHexBox:IsA("TextBox") then
            boothColorHexBox.Text = formatBoothColorHexText(state.boothColorHex)
        end
        return
    end

    state.boothColorHex = hex
    setLabel(colorStatusLabel, "Text Color: #" .. state.boothColorHex)
    if boothColorHexBox and boothColorHexBox:IsA("TextBox") then
        boothColorHexBox.Text = formatBoothColorHexText(state.boothColorHex)
    end
    saveSettings()
end, {clear = false})
if boothColorHexBox and boothColorHexBox:IsA("TextBox") then
    boothColorHexBox.Text = formatBoothColorHexText(state.boothColorHex)
end

colorPickerData = select(1, boothTab:AddColorPicker(function(color)
    state.boothColorHex = color3ToHex(color)
    setLabel(colorStatusLabel, "Text Color: #" .. state.boothColorHex)
    if boothColorHexBox and boothColorHexBox:IsA("TextBox") then
        boothColorHexBox.Text = formatBoothColorHexText(state.boothColorHex)
    end
    saveSettings()
end))
do
    local ok, color = pcall(function()
        return Color3.fromHex("#" .. state.boothColorHex)
    end)
    if ok and color then
        colorPickerData:Set(color)
    else
        colorPickerData:Set(Color3.fromRGB(255, 255, 255))
    end
end
colorStatusLabel = boothTab:AddLabel("Text Color: #" .. state.boothColorHex)

local fontDropdown, fontDropdownObject = boothTab:AddDropdown("Text Font", function(selected)
    state.boothFont = selected
    setLabel(fontStatusLabel, "Font: " .. tostring(selected))
    saveSettings()
end)
for _, f in ipairs(Enum.Font:GetEnumItems()) do
    fontDropdown:Add(f.Name)
end
if fontDropdownObject then
    fontDropdownObject.Text = "      [ " .. state.boothFont .. " ]"
end
fontStatusLabel = boothTab:AddLabel("Font: " .. state.boothFont)

boothTab:AddLabel("Booth Texts (one per line):")
local okConsole, consoleOrErr = pcall(function()
    return select(1, boothTab:AddConsole({
        source = "Lua",
        readonly = false,
        full = false,
        y = 140,
    }))
end)
if okConsole and consoleOrErr and type(consoleOrErr.Set) == "function" then
    boothTextsConsole = consoleOrErr
    boothTextsConsole:Set(persistedBoothTexts)
else
    boothTextsInput = boothTab:AddTextBox("Booth Texts (use | as line break)", function(text)
    persistedBoothTexts = parseBoothTextsInputText(text)
    if boothTextsInput and boothTextsInput:IsA("TextBox") then
        boothTextsInput.Text = formatBoothTextsInputText(persistedBoothTexts)
    end
    saveSettings()
end, {clear = false})
    if boothTextsInput and boothTextsInput:IsA("TextBox") then
        boothTextsInput.Text = formatBoothTextsInputText(persistedBoothTexts)
    end
end

boothTab:AddButton("Update", function()
    persistedBoothTexts = getBoothTextsRaw()
    saveSettings()

    local pool = getBoothTextPool()
    if #pool == 0 then
        setLabel(boothStatusLabel, "Booth update failed: no text")
        return
    end

    local ok = applyBoothText(pool[1])
    if ok then
        setLabel(boothStatusLabel, "Booth update applied")
    else
        setLabel(boothStatusLabel, "Booth update failed: remote not found")
    end
end)

boothStatusLabel = boothTab:AddLabel("Booth status: idle")

local notifyTab = window:AddTab("Notify")
notifyTab:AddLabel("Webhook Notify")

local webhookSwitch = select(1, notifyTab:AddSwitch("Discord Webhook Notify", function(v)
    state.webhookNotify = v
    saveSettings()
end))
webhookSwitch:Set(state.webhookNotify)

local pingSwitch = select(1, notifyTab:AddSwitch("Ping Everyone", function(v)
    state.pingEveryone = v
    saveSettings()
end))
pingSwitch:Set(state.pingEveryone)

local webhookAfterServerHopSwitch = select(1, notifyTab:AddSwitch("Webhook after server hop", function(v)
    state.webhookAfterSH = v
    saveSettings()
end))
webhookAfterServerHopSwitch:Set(state.webhookAfterSH)

local webhookUrlBox
webhookUrlBox = notifyTab:AddTextBox("Webhook URL", function(text)
    state.webhookUrl = parseWebhookUrlText(text)
    if webhookUrlBox and webhookUrlBox:IsA("TextBox") then
        webhookUrlBox.Text = formatWebhookUrlText(state.webhookUrl)
    end
    saveSettings()
end, {clear = false})
if webhookUrlBox and webhookUrlBox:IsA("TextBox") then
    webhookUrlBox.Text = formatWebhookUrlText(state.webhookUrl)
end

notifyTab:AddButton("Test Webhook", function()
    local title = getLocalDisplayName() .. " donated by WebhookTest"
    local ok, msg = postWebhook(title, LocalPlayer.Name, 100, true)
    if ok then
        setLabel(notifyStatusLabel, "Webhook test sent")
    else
        setLabel(notifyStatusLabel, "Webhook test failed: " .. tostring(msg))
    end
end)

notifyStatusLabel = notifyTab:AddLabel("Webhook status: idle")

setFpsLimit(state.fpsLimit)
setupDonorDetection()
setupDonationStatWatcher()
if resetServerHopTimer then
    resetServerHopTimer()
end
if state.friendHop then
    hopIfFriendPresent("friend in server")
end
checkAntiBotServers()
task.spawn(function()
    task.wait(1)
    claimNearestUnclaimedBooth()
end)
saveSettings()

local function nextBegText()
    begIndex = begIndex + 1
    if begIndex > #begMessages then
        begIndex = 1
    end
    return begMessages[begIndex]
end

task.spawn(function()
    while true do
        if state.autoBeg then
            sendChat(nextBegText())
            task.wait(25)
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do
        if state.autoEditBoothText then
            persistedBoothTexts = getBoothTextsRaw()
            saveSettings()
            local pool = getBoothTextPool()
            if #pool > 0 then
                boothIndex = boothIndex + 1
                if boothIndex > #pool then
                    boothIndex = 1
                end

                local candidate = pool[boothIndex]
                if #pool > 1 and normalizeCompareText(candidate) == normalizeCompareText(lastBoothSentText) then
                    boothIndex = (boothIndex % #pool) + 1
                    candidate = pool[boothIndex]
                end

                local ok = applyBoothText(candidate)
                if ok then
                    setLabel(boothStatusLabel, "Booth updated (" .. tostring(boothIndex) .. "/" .. tostring(#pool) .. ")")
                else
                    setLabel(boothStatusLabel, "Booth update failed: remote not found")
                end
            end
            task.wait(math.max(BOOTH_MIN_DELAY, tonumber(state.boothDelay) or BOOTH_MIN_DELAY))
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while true do
        if state.antiBotServers then
            checkAntiBotServers()
        end
        task.wait(15)
    end
end)

if library and library.FormatWindows then
    pcall(function()
        library:FormatWindows()
    end)
end















