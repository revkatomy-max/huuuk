-- // BLOX Gank Server Monitor - Clean Edition //
-- Discord @bloxgank
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- // CONFIGURATION //
local WEBHOOK_URL = "https://discord.com/api/webhooks/1466426909507452952/w-q6Wgvm3l2ByDuwDR1Qy30QgEYdf8HpwpIgeWCY1Em5iCtSVeSd4DAdPEy27OwOVLQv"
local SCRIPT_ACTIVE = true

-- Database Ikan Secret
local SecretFishData = {
    ["Crystal Crab"] = 18335072046, ["Orca"] = 18335061483, ["Zombie Shark"] = 18335056722,
    ["Zombie Megalodon"] = 18335056551, ["Dead Zombie Shark"] = 18335056722, ["Blob Shark"] = 18335068212,
    ["Ghost Shark"] = 18335059639, ["Skeleton Narwhal"] = 18335057177, ["Ghost Worm Fish"] = 18335059511,
    ["Worm Fish"] = 18335057406, ["Megalodon"] = 18335063073, ["1x1x1x1 Comet Shark"] = 18335068832,
    ["Bloodmoon Whale"] = 18335067980, ["Lochness Monster"] = 18335063708, ["Monster Shark"] = 18335062145,
    ["Eerie Shark"] = 18335060416, ["Great Whale"] = 18335058867, ["Frostborn Shark"] = 18335059957,
    ["Armored Shark"] = 18335068417, ["Scare"] = 18335058097, ["Queen Crab"] = 18335058252,
    ["King Crab"] = 18335064431, ["Cryoshade Glider"] = 18335066928, ["Panther Eel"] = 18335060799,
    ["Giant Squid"] = 18335059345, ["Depthseeker Ray"] = 18335066551, ["Robot Kraken"] = 18335058448,
    ["Mosasaur Shark"] = 18335061981, ["King Jelly"] = 18335064243, ["Bone Whale"] = 18335067645,
    ["Elshark Gran Maja"] = 18335060241, ["Elpirate Gran Maja"] = 18335060241, ["Ancient Whale"] = 18335068612,
    ["Gladiator Shark"] = 18335059068, ["Ancient Lochness Monster"] = 18335063708, ["Talon Serpent"] = 18335057777,
    ["Hacker Shark"] = 18335059223, ["ElRetro Gran Maja"] = 18335060241, ["Strawberry Choc Megalodon"] = 18335063073,
    ["Krampus Shark"] = 18335062145, ["Emerald Winter Whale"] = 18335058867, ["Winter Frost Shark"] = 18335059957,
    ["Icebreaker Whale"] = 18335067645, ["Leviathan"] = 18335063983, ["Pirate Megalodon"] = 18335063073,
    ["Viridis Lurker"] = 18335060799, ["Cursed Kraken"] = 18335058448, ["Ancient Magma Whale"] = 18335068612,
    ["Rainbow Comet Shark"] = 18335118712, ["Love Nessie"] = 18335063708, ["Broken Heart Nessie"] = 18335063708
}

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

-- // CEK ITEM DI BACKPACK //
local function CheckItem(player, item)
    local fishId = SecretFishData[item.Name]
    if fishId then
        local fishImg = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. tostring(fishId) .. "&width=420&height=420&format=png"
        local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(player.UserId) .. "&width=420&height=420&format=png"
        SendWebhook("🚨 SECRET FISH DETECTED!", nil, 16768768, {
            {["name"] = "Pemain", ["value"] = "**" .. player.Name .. "**", ["inline"] = true},
            {["name"] = "Ikan",   ["value"] = "**" .. item.Name .. "**",   ["inline"] = true}
        }, fishImg, avatarUrl)
    end
end

-- // WATCH BACKPACK PLAYER //
local function WatchBackpack(player, bp)
    -- Cek item yang SUDAH ada di backpack saat script jalan
    for _, item in ipairs(bp:GetChildren()) do
        CheckItem(player, item)
    end
    -- Monitor item baru yang masuk
    bp.ChildAdded:Connect(function(item)
        CheckItem(player, item)
    end)
end

-- // WATCH PLAYER (karakter + backpack) //
local function WatchForFish(player)
    -- FIX: Langsung cek backpack yang sudah ada (player sudah spawn sebelum script jalan)
    local bp = player:FindFirstChild("Backpack")
    if bp then
        WatchBackpack(player, bp)
    end

    -- Tetap listen CharacterAdded untuk respawn berikutnya
    player.CharacterAdded:Connect(function()
        local newBp = player:WaitForChild("Backpack", 15)
        if newBp then
            WatchBackpack(player, newBp)
        end
    end)
end

-- // PLAYER JOIN //
Players.PlayerAdded:Connect(function(player)
    if not SCRIPT_ACTIVE then return end
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(player.UserId) .. "&width=420&height=420&format=png"
    SendWebhook("✅ PLAYER JOINED SERVER", nil, 65280, {
        {["name"] = "Username", ["value"] = "**" .. player.Name .. "**", ["inline"] = true}
    }, nil, avatarUrl)
end)

-- // PLAYER LEAVE //
Players.PlayerRemoving:Connect(function(player)
    if not SCRIPT_ACTIVE then return end
    local pName = player.Name
    local pId = player.UserId
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(pId) .. "&width=420&height=420&format=png"
    SendWebhook("👋 PLAYER LEFT SERVER", nil, 16729344, {
        {["name"] = "Username", ["value"] = "**" .. pName .. "**", ["inline"] = true}
    }, nil, avatarUrl)
end)

-- // STARTUP //
local function Startup()
    local allPlayers = Players:GetPlayers()
    local names = {}
    for _, p in ipairs(allPlayers) do table.insert(names, p.Name) end
    SendWebhook("🚀 WEBHOOK STARTED", nil, 65280, {
        {["name"] = "Host",          ["value"] = "👤 " .. Players.LocalPlayer.Name, ["inline"] = true},
        {["name"] = "Total Player",  ["value"] = "👥 " .. tostring(#allPlayers),    ["inline"] = true},
        {["name"] = "Daftar Player", ["value"] = "```\n" .. table.concat(names, ", ") .. "```", ["inline"] = false}
    })
    StarterGui:SetCore("SendNotification", {Title = "BLOX Gank Webhook Active", Text = "Monitoring Secret Fish & Player Activity", Duration = 5})
end

-- // INITIALIZE //
Startup()
for _, p in ipairs(Players:GetPlayers()) do WatchForFish(p) end
Players.PlayerAdded:Connect(WatchForFish)
