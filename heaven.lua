-- // BLOX Gank Server Monitor //
-- Discord @bloxgank
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // CONFIGURATION //
local WEBHOOK_URL = "https://discord.com/api/webhooks/1480464995517988886/nXpR2uPBu2JWc-2ej08WTVYEEZ549xwaQck8Zgk6W7BuDv764krF5ddXBpVcO9zEmJYE"
local PROXY = "https://square-haze-a007.remediashop.workers.dev"
local SCRIPT_ACTIVE = true

-- // DATABASE NAMA SECRET FISH //
local SecretFishList = {
    "Crystal Crab", "Orca", "Zombie Shark", "Zombie Megalodon", "Dead Zombie Shark",
    "Blob Shark", "Ghost Shark", "Skeleton Narwhal", "Ghost Worm Fish", "Worm Fish",
    "Megalodon", "1x1x1x1 Comet Shark", "Bloodmoon Whale", "Lochness Monster",
    "Monster Shark", "Eerie Shark", "Great Whale", "Frostborn Shark", "Armored Shark",
    "Scare", "Queen Crab", "King Crab", "Cryoshade Glider", "Panther Eel",
    "Giant Squid", "Depthseeker Ray", "Robot Kraken", "Mosasaur Shark", "King Jelly",
    "Bone Whale", "Elshark Gran Maja", "Elpirate Gran Maja", "Ancient Whale",
    "Gladiator Shark", "Ancient Lochness Monster", "Talon Serpent", "Hacker Shark",
    "ElRetro Gran Maja", "Strawberry Choc Megalodon", "Krampus Shark",
    "Emerald Winter Whale", "Winter Frost Shark", "Icebreaker Whale", "Leviathan",
    "Pirate Megalodon", "Viridis Lurker", "Cursed Kraken", "Ancient Magma Whale",
    "Rainbow Comet Shark", "Love Nessie", "Broken Heart Nessie"
}

-- // CACHE: simpan imageId dari backpack monitor //
-- key = nama ikan base, value = imageId dari tool
local FishImageCache = {}

-- // WEBHOOK SENDER //
local function SendWebhook(title, description, color, fields, imageUrl, thumbUrl)
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not requestFunc then return end
    local embed = {
        ["title"] = title,
        ["description"] = description,
        ["color"] = color,
        ["fields"] = fields,
        ["footer"] = {["text"] = "BLOX Gank Webhook | " .. os.date("%X")},
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    if imageUrl then embed["image"] = {["url"] = imageUrl} end
    if thumbUrl then embed["thumbnail"] = {["url"] = thumbUrl} end
    task.spawn(function()
        pcall(function()
            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({["embeds"] = {embed}})
            })
        end)
    end)
end

-- // STRIP HTML TAGS //
local function StripTags(str)
    return string.gsub(str, "<[^>]+>", "")
end

-- // CEK SECRET FISH + SUPPORT MUTASI //
local function FindSecretFish(fishName)
    local lower = string.lower(fishName)
    for _, baseName in ipairs(SecretFishList) do
        if string.find(lower, string.lower(baseName), 1, true) then
            local s = string.find(lower, string.lower(baseName), 1, true)
            local mutasi = nil
            if s and s > 1 then
                mutasi = fishName:sub(1, s - 1):match("^%s*(.-)%s*$")
                if mutasi == "" then mutasi = nil end
            end
            return baseName, mutasi
        end
    end
    return nil, nil
end

-- // AMBIL IMAGE DARI TOOL DI BACKPACK //
local function GetFishImageId(item)
    -- Cari TextureId atau ImageId dari descendants tool
    for _, desc in ipairs(item:GetDescendants()) do
        local ok, val = pcall(function()
            if desc:IsA("SpecialMesh") then return desc.TextureId
            elseif desc:IsA("Decal") or desc:IsA("Texture") then return desc.Texture
            elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then return desc.Image
            end
            return nil
        end)
        if ok and val and val ~= "" and val ~= "rbxasset://" then
            -- Ambil angkanya saja
            local id = tostring(val):match("%d+")
            if id then return id end
        end
    end
    return nil
end

-- // PARSE CHAT SERVER //
local function ParseChat(rawMsg)
    local msg = StripTags(rawMsg)
    msg = string.gsub(msg, "^%[Server%]:%s*", "")

    local playerName, fishFull, weight = string.match(msg, "^(.-) obtained an? (.-) %(([%d%.%a]+ ?kg)%)")
    if not playerName then
        playerName, fishFull = string.match(msg, "^(.-) obtained an? (.+)")
        weight = "N/A"
    end
    if not playerName or not fishFull then return nil end

    -- Hapus prefix [Global]: [Local]: dll
    playerName = playerName:match("%[%a+%]:%s*(.+)") or playerName
    playerName = playerName:match("^%s*(.-)%s*$") or playerName

    -- Normalize weight
    weight = weight:match("^%s*(.-)%s*$") or weight

    -- Bersihkan nama ikan
    fishFull = fishFull:match("^(.-)%s+with a 1 in") or fishFull
    fishFull = fishFull:match("^(.-)%s*[!%.]?$") or fishFull
    fishFull = fishFull:match("^%s*(.-)%s*$") or fishFull

    return { player = playerName, fish = fishFull, weight = weight }
end

-- // PROSES PESAN CHAT SERVER //
local function CheckAndSend(rawMsg)
    if not SCRIPT_ACTIVE then return end
    if not string.find(string.lower(rawMsg), "obtained") then return end

    local data = ParseChat(rawMsg)
    if not data then return end

    local baseName, mutasi = FindSecretFish(data.fish)
    if not baseName then return end

    -- Avatar player
    local targetPlayer = Players:FindFirstChild(data.player)
    local avatarUrl = targetPlayer and (PROXY .. "/avatar/" .. tostring(targetPlayer.UserId)) or nil

    -- Cek cache imageId dari backpack monitor
    local imageUrl = nil
    local cachedId = FishImageCache[baseName]
    if cachedId then
        imageUrl = PROXY .. "/asset/" .. cachedId
    end

    -- Label ikan
    local fishLabel = "**" .. data.fish .. "**"
    if mutasi then
        fishLabel = "**" .. data.fish .. "** *(mutasi: " .. baseName .. ")*"
    end

    SendWebhook("🚨 SECRET FISH DETECTED!", nil, 1752220, {
        {["name"] = "Pemain", ["value"] = "**" .. data.player .. "**", ["inline"] = true},
        {["name"] = "Ikan",   ["value"] = fishLabel,                   ["inline"] = true},
        {["name"] = "Berat",  ["value"] = data.weight,                 ["inline"] = true},
    }, imageUrl, avatarUrl)
end

-- // BACKPACK MONITOR — ambil imageId dari tool //
local function WatchBackpack(player, bp)
    bp.ChildAdded:Connect(function(item)
        task.wait(0.1) -- tunggu item fully loaded
        local baseName, _ = FindSecretFish(item.Name)
        if baseName and not FishImageCache[baseName] then
            local imgId = GetFishImageId(item)
            if imgId then
                FishImageCache[baseName] = imgId
                print("BLOX Gank: Cached image for " .. baseName .. " = " .. imgId)
            end
        end
    end)
end

local function WatchForFish(player)
    -- Cek backpack yang sudah ada
    local bp = player:FindFirstChild("Backpack")
    if bp then WatchBackpack(player, bp) end
    -- Listen respawn
    player.CharacterAdded:Connect(function()
        local newBp = player:WaitForChild("Backpack", 15)
        if newBp then WatchBackpack(player, newBp) end
    end)
end

-- // HOOK CHAT SERVER //
local function HookChat()
    if TextChatService then
        TextChatService.MessageReceived:Connect(function(msg)
            if msg.TextSource == nil then
                CheckAndSend(msg.Text or "")
            end
        end)
    end
    -- Fallback sistem chat lama
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents then
        local onMessage = chatEvents:FindFirstChild("OnMessageDoneFiltering")
        if onMessage then
            onMessage.OnClientEvent:Connect(function(d)
                if d and d.Message then CheckAndSend(d.Message) end
            end)
        end
    end
end

-- // PLAYER JOIN //
Players.PlayerAdded:Connect(function(player)
    if not SCRIPT_ACTIVE then return end
    task.spawn(function()
        task.wait(1)
        local avatarUrl = PROXY .. "/avatar/" .. tostring(player.UserId)
        SendWebhook("✅ PLAYER JOINED SERVER", nil, 65280, {
            {["name"] = "Username", ["value"] = "**" .. player.Name .. "**",              ["inline"] = true},
            {["name"] = "Total",    ["value"] = "👥 " .. tostring(#Players:GetPlayers()), ["inline"] = true}
        }, nil, avatarUrl)
    end)
    WatchForFish(player)
end)

-- // PLAYER LEAVE //
Players.PlayerRemoving:Connect(function(player)
    if not SCRIPT_ACTIVE then return end
    task.spawn(function()
        local pName = player.Name
        local pId = player.UserId
        local avatarUrl = PROXY .. "/avatar/" .. tostring(pId)
        SendWebhook("👋 PLAYER LEFT SERVER", nil, 16729344, {
            {["name"] = "Username", ["value"] = "**" .. pName .. "**",                        ["inline"] = true},
            {["name"] = "Total",    ["value"] = "👥 " .. tostring(#Players:GetPlayers() - 1), ["inline"] = true}
        }, nil, avatarUrl)
    end)
end)

-- // STARTUP //
local function Startup()
    local allPlayers = Players:GetPlayers()
    local names = {}
    for _, p in ipairs(allPlayers) do table.insert(names, p.Name) end
    SendWebhook("🚀 WEBHOOK STARTED", nil, 65280, {
        {["name"] = "Host",          ["value"] = "👤 " .. Players.LocalPlayer.Name,            ["inline"] = true},
        {["name"] = "Total Player",  ["value"] = "👥 " .. tostring(#allPlayers),                ["inline"] = true},
        {["name"] = "Daftar Player", ["value"] = "```\n" .. table.concat(names, ", ") .. "```", ["inline"] = false}
    })
    StarterGui:SetCore("SendNotification", {Title = "BLOX Gank Webhook Active", Text = "Monitoring Secret Fish & Player Activity", Duration = 5})
end

-- // INITIALIZE //
Startup()
HookChat()
for _, p in ipairs(Players:GetPlayers()) do WatchForFish(p) end
