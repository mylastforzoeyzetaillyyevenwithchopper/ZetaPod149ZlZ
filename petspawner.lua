local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local ContextActionService = game:GetService('ContextActionService')

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local PREPPY_PRIMARY_COLOR = Color3.fromRGB(0, 200, 220)
local PREPPY_SECONDARY_COLOR = Color3.fromRGB(120, 90, 255)
local PREPPY_BACKGROUND = Color3.fromRGB(25, 30, 45)
local PREPPY_TEXT_COLOR = Color3.fromRGB(230, 230, 230)
local PREPPY_HOVER_COLOR = Color3.fromRGB(50, 55, 70)

local function setThreadIdentity(identity)
    pcall(function()
        setthreadidentity(identity)
    end)
end
setThreadIdentity(2)

local function _util_generate_id()
    return HttpService:GenerateGUID(false)
end

local function _util_clone_table(tbl)
    local newTable = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            newTable[k] = _util_clone_table(v)
        else
            newTable[k] = v
        end
    end
    return newTable
end

local function _util_find_in_table(array, predicate)
    for i, v in pairs(array) do
        if predicate(v, i) then
            return i
        end
    end
    return nil
end

local SimulatedFsys = {}
SimulatedFsys.load = function(moduleName)
    if moduleName == "ClientData" then
        return {
            get = function(key)
                if key == "inventory" then
                    return { pets = {}, toys = {} }
                elseif key == "pet_char_wrappers" then
                    return {}
                elseif key == "pet_state_managers" then
                    return {}
                end
                return {}
            end,
            predict = function(key, value)
            end
        }
    elseif moduleName == "KindDB" then
        return {
            pets = {
                ["Shadow Dragon"] = { name = "Shadow Dragon", kind = "pet", id = "Shadow Dragon" },
                ["Bat Dragon"] = { name = "Bat Dragon", kind = "pet", id = "Bat Dragon" },
                ["Frost Dragon"] = { name = "Frost Dragon", kind = "pet", id = "Frost Dragon" },
                ["Giraffe"] = { name = "Giraffe", kind = "pet", id = "Giraffe" },
                ["Owl"] = { name = "Owl", kind = "pet", id = "Owl" },
                ["Parrot"] = { name = "Parrot", kind = "pet", id = "Parrot" },
                ["Turtle"] = { name = "Turtle", kind = "pet", id = "Turtle" },
                ["Kangaroo"] = { name = "Kangaroo", kind = "pet", id = "Kangaroo" },
                ["Lion"] = { name = "Lion", kind = "pet", id = "Lion" },
                ["Elephant"] = { name = "Elephant", kind = "pet", id = "Elephant" },
            },
            toys = {
                ["Squeaky Toy"] = { name = "Squeaky Toy", kind = "toy", id = "Squeaky Toy" }
            }
        }
    elseif moduleName == "UIManager" then
        return {
            apps = {
                BackpackApp = {
                    refresh_rendered_items = function()
                    end
                }
            }
        }
    elseif moduleName == "RouterClient" then
        return {
            get = function(endpoint)
                return {
                    InvokeServer = function(...)
                        return true
                    end,
                    FireServer = function(...)
                        return true
                    end
                }
            end
        }
    elseif moduleName == "AnimationManager" then
         return {
             get_track = function(trackName)
                 return Instance.new("Animation")
             end
         }
    elseif moduleName == "DownloadClient" then
        return {
            promise_download_copy = function(storage, name)
                return {
                    expect = function()
                        local model = Instance.new("Model")
                        model.Name = name .. "Model"
                        return model
                    end
                }
            end
        }
     elseif moduleName == "PetRigs" then
         return {
             get = function(model)
                 return {
                     get_geo_part = function(model, partName)
                         local part = model:FindFirstChild(partName)
                         if not part then
                             part = Instance.new("Part")
                             part.Name = partName
                             part.Parent = model
                         end
                         return part
                     end
                 }
             end
         }
     elseif moduleName == "AilmentsClient" then
         return {
             on_ailments_changed = function(player)
             end
         }
     elseif moduleName == "AilmentsDB" then
         return {
             at_work = {}, mystery = {}, walking = {}
         }
    end
    return {}
end

local ClientData = SimulatedFsys.load("ClientData")
local KindDB = SimulatedFsys.load("KindDB")
local UIManager = SimulatedFsys.load("UIManager")
local RouterClient = SimulatedFsys.load("RouterClient")
local AnimationManager = SimulatedFsys.load("AnimationManager")
local DownloadClient = SimulatedFsys.load("DownloadClient")
local PetRigs = SimulatedFsys.load("PetRigs")
local AilmentsClient = SimulatedFsys.load("AilmentsClient")
local AilmentsDB = SimulatedFsys.load("AilmentsDB")

local SpawnedObjects = {}
local ObjectModelCache = {}

local function GenerateUniquePetName()
    local prefixes = {"☆", "✨", "☁️", "💖", "🌸", "🍓", "🌙", "🌈", "💫"}
    local names = {"Sparkle", "Glimmer", "Dream", "Star", "Moonbeam", "Cloud", "Petal", "Berry", "Rainbow", "Shimmer", "Aurora", "Nova", "Cosmo"}
    
    local usePrefix = math.random(1, 2) == 1
    local name = names[math.random(1, #names)]
    
    if usePrefix then
        return prefixes[math.random(1, #prefixes)] .. " " .. name
    else
        return name .. " " .. prefixes[math.random(1, #prefixes)]
    end
end

local NewnessGroups = {
    mega_neon_flyable_rideable = 990000, mega_neon_flyable = 980000, mega_neon_rideable = 970000, mega_neon = 960000,
    neon_flyable_rideable = 950000, neon_flyable = 940000, neon_rideable = 930000, neon = 920000,
    flyable_rideable = 910000, flyable = 900000, rideable = 890000, regular = 880000
}

local function GetPropertyGroup(properties)
    local isMega = properties.mega_neon or false
    local isNeon = properties.neon or false
    local canFly = properties.flyable or false
    local canRide = properties.rideable or false

    if isMega then
        if canFly and canRide then return "mega_neon_flyable_rideable"
        elseif canFly then return "mega_neon_flyable"
        elseif canRide then return "mega_neon_rideable"
        else return "mega_neon" end
    elseif isNeon then
        if canFly and canRide then return "neon_flyable_rideable"
        elseif canFly then return "neon_flyable"
        elseif canRide then return "neon_rideable"
        else return "neon" end
    else
        if canFly and canRide then return "flyable_rideable"
        elseif canFly then return "flyable"
        elseif canRide then return "rideable"
        else return "regular" end
    end
end

local nextToyOrder = 60000

local function CreateInventoryItem(itemId, category, properties)
    local uniqueId = _util_generate_id()
    local itemKindData = KindDB[category] and KindDB[category][itemId] or KindDB[itemId]
    
    if not itemKindData then
        warn("Item kind not found in simulated DB: " .. itemId)
        return nil
    end

    properties = properties or {}
    local newnessValue = nextToyOrder

    if category == "pets" then
        local groupKey = GetPropertyGroup(properties)
        NewnessGroups[groupKey] = (NewnessGroups[groupKey] or 0) - 1
        newnessValue = NewnessGroups[groupKey]

        properties.ailments_completed = properties.ailments_completed or 0
        if not properties.rp_name or properties.rp_name == "" then
            properties.rp_name = GenerateUniquePetName()
        end
    else
        nextToyOrder = nextToyOrder - 1
        newnessValue = nextToyOrder
    end

    local itemData = {
        unique = uniqueId,
        category = category,
        id = itemId,
        kind = itemKindData.kind or "unknown",
        newness_order = newnessValue,
        properties = properties,
        _source = "ZetaScripts" 
    }

    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local clientData = ClientData.get("inventory") or {}
    clientData[category] = clientData[category] or {}
    clientData[category][uniqueId] = itemData
    ClientData.predict("inventory", clientData)
    set_thread_identity(identity)

    SpawnedObjects[uniqueId] = { data = itemData, model = nil, category = category }

    task.defer(function()
        if UIManager and UIManager.apps and UIManager.apps.BackpackApp then
            UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)
    
    print("Creato item: " .. itemId .. " (Unique: " .. uniqueId .. ")")
    return itemData
end

local function DeleteAllSpawnedObjects()
    local deletedCount = 0
    local inventory = ClientData.get("inventory") or {}
    
    for uniqueId, obj in pairs(SpawnedObjects) do
        if obj.model then
            obj.model:Destroy()
        end
        
        if inventory[obj.category] and inventory[obj.category][uniqueId] and inventory[obj.category][uniqueId]._source == "ZetaScripts" then
            inventory[obj.category][uniqueId] = nil
            deletedCount = deletedCount + 1
        end
    end
    
    SpawnedObjects = {}
    
    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    ClientData.predict("inventory", inventory)
    set_thread_identity(identity)
    
    task.defer(function()
        if UIManager and UIManager.apps and UIManager.apps.BackpackApp then
            UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)
    
    print("Eliminati " .. deletedCount .. " oggetti spawnati da ZetaScripts.")
    return deletedCount
end

local function FindPetId(petName)
    for id, info in pairs(KindDB.pets) do
        if info.name:lower() == petName:lower() then
            return id
        end
    end
    return nil
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZetaScriptsUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 380)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -190)
mainFrame.BackgroundColor3 = PREPPY_BACKGROUND
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2.5
uiStroke.Color = PREPPY_PRIMARY_COLOR
uiStroke.Transparency = 0.3
uiStroke.Parent = mainFrame

local strokeColorSequence = {
    PREPPY_PRIMARY_COLOR,
    PREPPY_SECONDARY_COLOR,
    Color3.fromRGB(255, 90, 180),
    Color3.fromRGB(255, 170, 0)
}
local colorIdx = 1
task.spawn(function()
    while true do
        colorIdx = colorIdx % #strokeColorSequence + 1
        TweenService:Create(uiStroke, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Color = strokeColorSequence[colorIdx] }):Play()
        task.wait(5)
    end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextColor3 = PREPPY_TEXT_COLOR
titleLabel.Parent = mainFrame
titleLabel.Text = "✨ ZetaScripts(last4zeta on tt) ✨" 

local tabContainer = Instance.new('Frame')
tabContainer.Size = UDim2.new(0.92, 0, 0, 28)
tabContainer.Position = UDim2.new(0.04, 0, 0, 45)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabs = {
    { key = 'Spawn', label = 'Spawn Pet', icon = '🐾' },
    { key = 'Settings', label = 'Settings', icon = '⚙️' }
}

local activeTab = 'Spawn'
local tabButtons = {}

local function SwitchTab(tabName)
    activeTab = tabName
    for key, button in pairs(tabButtons) do
        local isActive = (key == tabName)
        button.BackgroundColor3 = isActive and PREPPY_HOVER_COLOR or Color3.fromRGB(40, 44, 60)
        button.UIStroke.Color = isActive and PREPPY_PRIMARY_COLOR or Color3.fromRGB(80, 85, 100)
        button.UIStroke.Thickness = isActive and 1.5 or 0.8
        button.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 220)
        
        if key == 'Spawn' then spawnPanel.Visible = isActive end
        if key == 'Settings' then settingsPanel.Visible = isActive end
    end
end

for i, tab in ipairs(tabs) do
    local tabButton = Instance.new('TextButton')
    tabButton.Size = UDim2.new(1 / #tabs - 0.02, 0, 1, 0)
    tabButton.Position = UDim2.new((i - 1) * (1 / #tabs), (i == 1) and 0 or 4, 0, 0)
    tabButton.BackgroundColor3 = i == 1 and PREPPY_HOVER_COLOR or Color3.fromRGB(40, 44, 60)
    tabButton.BackgroundTransparency = 0.1
    tabButton.Text = tab.icon .. " " .. tab.label
    tabButton.Font = Enum.Font.GothamBold
    tabButton.TextSize = 10
    tabButton.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 220)
    tabButton.Parent = tabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tabButton
    
    local stroke = Instance.new('UIStroke')
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = i == 1 and PREPPY_PRIMARY_COLOR or Color3.fromRGB(80, 85, 100)
    stroke.Thickness = i == 1 and 1.5 or 0.8
    stroke.Transparency = 0.4
    stroke.Parent = tabButton
    
    tabButtons[tab.key] = tabButton
    tabButton.UIStroke = stroke
    
    tabButton.MouseButton1Click:Connect(function()
        SwitchTab(tab.key)
    end)
end

local spawnPanel = Instance.new("Frame")
spawnPanel.Size = UDim2.new(0.92, 0, 1, -75)
spawnPanel.Position = UDim2.new(0.04, 0, 0, 75)
spawnPanel.BackgroundTransparency = 1
spawnPanel.Parent = mainFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 12)
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "🐾 Pet Name"
nameLabel.Font = Enum.Font.Gotham
nameLabel.TextSize = 8
nameLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = spawnPanel

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, 0, 0, 24)
nameInput.Position = UDim2.new(0, 0, 0, 12)
nameInput.BackgroundColor3 = Color3.fromRGB(32, 36, 58)
nameInput.TextColor3 = PREPPY_TEXT_COLOR
nameInput.TextSize = 11
nameInput.Font = Enum.Font.Gotham
nameInput.PlaceholderText = "e.g., Shadow Dragon"
nameInput.PlaceholderColor3 = Color3.fromRGB(140, 150, 180)
nameInput.ClearTextOnFocus = false
nameInput.Text = "Shadow Dragon"
nameInput.Parent = spawnPanel

local nameInputCorner = Instance.new("UICorner")
nameInputCorner.CornerRadius = UDim.new(0, 7)
nameInputCorner.Parent = nameInput

local inputGlow = Instance.new("UIStroke")
inputGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inputGlow.Color = Color3.fromRGB(220, 220, 220)
inputGlow.Thickness = 1.8
inputGlow.Transparency = 0.5
inputGlow.Parent = nameInput

local ageLabel = Instance.new("TextLabel")
ageLabel.Size = UDim2.new(1, 0, 0, 12)
ageLabel.Position = UDim2.new(0, 0, 0, 42)
ageLabel.BackgroundTransparency = 1
ageLabel.Text = "📅 Age"
ageLabel.Font = Enum.Font.Gotham
ageLabel.TextSize = 8
ageLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
ageLabel.TextXAlignment = Enum.TextXAlignment.Left
ageLabel.Parent = spawnPanel

local ageGrid = Instance.new("Frame")
ageGrid.Size = UDim2.new(1, 0, 0, 26)
ageGrid.Position = UDim2.new(0, 0, 0, 55)
ageGrid.BackgroundTransparency = 1
ageGrid.Parent = spawnPanel

local ageCodes = {"N", "J", "PT", "T", "PG", "FG"}
local ageDescriptions = {"Newborn", "Junior", "Pre-Teen", "Teen", "Post-Teen", "Full Grown"}
local currentAgeIndex = 1

for i, code in ipairs(ageCodes) do
    local ageButton = Instance.new("TextButton")
    ageButton.Size = UDim2.new(1/6 - 0.01, 0, 1, 0)
    ageButton.Position = UDim2.new((i-1) * (1/6), (i > 1) and 2 or 0, 0, 0)
    ageButton.Text = code
    ageButton.BackgroundColor3 = i == currentAgeIndex and Color3.fromRGB(80, 85, 100) or Color3.fromRGB(40, 44, 60)
    ageButton.Font = Enum.Font.GothamBold
    ageButton.TextColor3 = PREPPY_TEXT_COLOR
    ageButton.TextSize = 11
    ageButton.Parent = ageGrid
    
    local ageCorner = Instance.new("UICorner")
    ageCorner.CornerRadius = UDim.new(0, 6)
    ageCorner.Parent = ageButton
    
    local hintBox = Instance.new("TextLabel")
    hintBox.Text = ageDescriptions[i]
    hintBox.BackgroundColor3 = PREPPY_BACKGROUND
    hintBox.TextColor3 = PREPPY_TEXT_COLOR
    hintBox.TextSize = 7
    hintBox.Font = Enum.Font.Gotham
    hintBox.Size = UDim2.new(0, 0, 0, 0)
    hintBox.Visible = false
    hintBox.Parent = ageButton
    Instance.new("UICorner", hintBox).CornerRadius = UDim.new(0, 4)
    
    ageButton.MouseEnter:Connect(function()
        hintBox.Size = UDim2.new(0, hintBox.TextBounds.X + 10, 0, hintBox.TextBounds.Y + 6)
        hintBox.Position = UDim2.new(0.5, -hintBox.Size.X.Offset/2, -1.2, 0)
        hintBox.Visible = true
    end)
    
    ageButton.MouseLeave:Connect(function()
        hintBox.Visible = false
    end)
    
    ageButton.MouseButton1Click:Connect(function()
        currentAgeIndex = i
        for _, btn in pairs(ageGrid:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
            end
        end
        ageButton.BackgroundColor3 = Color3.fromRGB(80, 85, 100)
    end)
end

local flagLabel = Instance.new("TextLabel")
flagLabel.Size = UDim2.new(1, 0, 0, 12)
flagLabel.Position = UDim2.new(0, 0, 0, 85)
flagLabel.BackgroundTransparency = 1
flagLabel.Text = "✨ Pet Flags"
flagLabel.Font = Enum.Font.Gotham
flagLabel.TextSize = 8
flagLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
flagLabel.TextXAlignment = Enum.TextXAlignment.Left
flagLabel.Parent = spawnPanel

local flagGrid = Instance.new("Frame")
flagGrid.Size = UDim2.new(1, 0, 0, 30)
flagGrid.Position = UDim2.new(0, 0, 0, 98)
flagGrid.BackgroundTransparency = 1
flagGrid.Parent = spawnPanel

local flagConfig = {
    M = { name = "Mega Neon", color = Color3.fromRGB(170, 0, 255), defaultValue = false },
    N = { name = "Neon", color = Color3.fromRGB(0, 255, 100), defaultValue = true },
    F = { name = "Flyable", color = Color3.fromRGB(0, 200, 255), defaultValue = true },
    R = { name = "Rideable", color = Color3.fromRGB(255, 50, 150), defaultValue = true }
}

local flagState = {}
local flagButtons = {}

for i, flagKey in ipairs({"M", "N", "F", "R"}) do
    local config = flagConfig[flagKey]
    flagState[flagKey] = config.defaultValue

    local flagButton = Instance.new("TextButton")
    flagButton.Size = UDim2.new(0.23, -2, 1, 0)
    flagButton.Position = UDim2.new((i-1) * 0.25, (i > 1) and 3 or 0, 0, 0)
    flagButton.Text = flagKey
    flagButton.BackgroundColor3 = flagState[flagKey] and config.color or Color3.fromRGB(40, 44, 60)
    flagButton.Font = Enum.Font.GothamBold
    flagButton.TextColor3 = PREPPY_TEXT_COLOR
    flagButton.TextSize = 12
    flagButton.Parent = flagGrid
    
    local flagCorner = Instance.new("UICorner")
    flagCorner.CornerRadius = UDim.new(0, 8)
    flagCorner.Parent = flagButton
    
    local flagStroke = Instance.new("UIStroke")
    flagStroke.Color = config.color
    flagStroke.Thickness = flagState[flagKey] and 2.5 or 1.5
    flagStroke.Transparency = flagState[flagKey] and 0.2 or 0.5
    flagStroke.Parent = flagButton
    
    flagButton.MouseButton1Click:Connect(function()
        if (flagKey == "M" and flagState["N"]) or (flagKey == "N" and flagState["M"]) then
            warn("Non puoi selezionare sia Mega Neon che Neon contemporaneamente.")
            return
        end

        flagState[flagKey] = not flagState[flagKey]
        
        if flagState[flagKey] then
            flagButton.BackgroundColor3 = config.color
            TweenService:Create(flagStroke, TweenInfo.new(0.2), {
                Thickness = 2.5,
                Transparency = 0.2
            }):Play()
        else
            flagButton.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
            TweenService:Create(flagStroke, TweenInfo.new(0.2), {
                Thickness = 1.5,
                Transparency = 0.5
            }):Play()
        end
    end)
    flagButtons[flagKey] = flagButton
end

local quickLabel = Instance.new("TextLabel")
quickLabel.Size = UDim2.new(1, 0, 0, 12)
quickLabel.Position = UDim2.new(0, 0, 0, 130)
quickLabel.BackgroundTransparency = 1
quickLabel.Text = "⚡ Quick Select"
quickLabel.Font = Enum.Font.Gotham
quickLabel.TextSize = 8
quickLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
quickLabel.TextXAlignment = Enum.TextXAlignment.Left
quickLabel.Parent = spawnPanel

local quickGrid = Instance.new("Frame")
quickGrid.Size = UDim2.new(1, 0, 0, 50)
quickGrid.Position = UDim2.new(0, 0, 0, 142)
quickGrid.BackgroundTransparency = 1
quickGrid.Parent = spawnPanel

local quickPetsData = {
    {name = "Shadow Dragon", color = Color3.fromRGB(70, 30, 90)},
    {name = "Frost Dragon", color = Color3.fromRGB(100, 180, 220)},
    {name = "Bat Dragon", color = Color3.fromRGB(180, 50, 50)},
    {name = "Giraffe", color = Color3.fromRGB(200, 150, 0)},
    {name = "Owl", color = Color3.fromRGB(150, 100, 50)},
    {name = "Parrot", color = Color3.fromRGB(255, 100, 0)}
}

for i, petInfo in ipairs(quickPetsData) do
    local row = math.floor((i-1) / 3)
    local col = (i-1) % 3
    
    local quickButton = Instance.new("TextButton")
    quickButton.Size = UDim2.new(0.31, -2, 0.48, 0)
    quickButton.Position = UDim2.new(col * 0.33, (col > 0) and 3 or 0, row * 0.5, (row > 0) and 3 or 0)
    
    quickButton.Text = petInfo.name:match("^(%w+)") or petInfo.name
    quickButton.BackgroundColor3 = petInfo.color
    quickButton.Font = Enum.Font.GothamBold
    quickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickButton.TextSize = 8
    quickButton.Parent = quickGrid
    
    local quickCorner = Instance.new("UICorner")
    quickCorner.CornerRadius = UDim.new(0, 6)
    quickCorner.Parent = quickButton
    
    quickButton.MouseButton1Click:Connect(function()
        nameInput.Text = petInfo.name
        
        if petInfo.name == "Shadow Dragon" then
            flagState.M = true; flagState.N = false; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Frost Dragon" then
            flagState.M = false; flagState.N = true; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Bat Dragon" then
            flagState.M = false; flagState.N = true; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Giraffe" then
             flagState.M = false; flagState.N = false; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Owl" then
             flagState.M = false; flagState.N = false; flagState.F = true; flagState.R = true
        elseif petInfo.name == "Parrot" then
             flagState.M = false; flagState.N = false; flagState.F = true; flagState.R = true
        else
            flagState.M = false; flagState.N = false; flagState.F = true; flagState.R = true
        end
        for key, button in pairs(flagButtons) do
            local config = flagConfig[key]
            button.BackgroundColor3 = flagState[key] and config.color or Color3.fromRGB(40, 44, 60)
            local stroke = button.UIStroke
            TweenService:Create(stroke, TweenInfo.new(0.2), {
                Thickness = flagState[key] and 2.5 or 1.5,
                Transparency = flagState[key] and 0.2 or 0.5
            }):Play()
        end
    end)
end

local spawnButton = Instance.new("TextButton")
spawnButton.Size = UDim2.new(0.92, 0, 0, 30)
spawnButton.Position = UDim2.new(0.04, 0, 1, -38)
spawnButton.Text = "✨ Spawn Pet"
spawnButton.Font = Enum.Font.GothamBold
spawnButton.TextSize = 13
spawnButton.BackgroundColor3 = PREPPY_PRIMARY_COLOR
spawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnButton.Parent = mainFrame

local spawnCorner = Instance.new("UICorner")
spawnCorner.CornerRadius = UDim.new(0, 10)
spawnCorner.Parent = spawnButton

local spawnStroke = Instance.new("UIStroke")
spawnStroke.Color = Color3.fromRGB(0, 255, 255)
spawnStroke.Thickness = 2
spawnStroke.Transparency = 0.4
spawnStroke.Parent = spawnButton

spawnButton.MouseButton1Click:Connect(function()
    local petName = nameInput.Text
    if petName == "" then return end
    
    local petId = FindPetId(petName)
    if not petId then
        TweenService:Create(inputGlow, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 80, 80) }):Play()
        spawnButton.Text = "Pet Not Found!"
        task.wait(1)
        spawnButton.Text = "✨ Spawn Pet"
        return
    end
    
    TweenService:Create(inputGlow, TweenInfo.new(0.2), { Color = Color3.fromRGB(80, 255, 120) }):Play()

    local options = {
        mega_neon = flagState["M"],
        neon = flagState["N"],
        flyable = flagState["F"],
        rideable = flagState["R"],
        age = currentAgeIndex,
        trick_level = 5,
        ailments_completed = 0,
        rp_name = GenerateUniquePetName()
    }
    
    local item = CreateInventoryItem(petId, "pets", options)
    if item then
        spawnButton.Text = "✓ Spawned!"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(50, 200, 50) }):Play()
        task.wait(1.2)
        spawnButton.Text = "✨ Spawn Pet"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), { BackgroundColor3 = PREPPY_PRIMARY_COLOR }):Play()
    else
        spawnButton.Text = "Spawn Failed!"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }):Play()
        task.wait(1)
        spawnButton.Text = "✨ Spawn Pet"
        TweenService:Create(spawnButton, TweenInfo.new(0.3), { BackgroundColor3 = PREPPY_PRIMARY_COLOR }):Play()
    end
end)

local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(0.92, 0, 1, -75)
settingsPanel.Position = UDim2.new(0.04, 0, 0, 75)
settingsPanel.BackgroundTransparency = 1
settingsPanel.Visible = false
settingsPanel.Parent = mainFrame

local deleteAllButton = Instance.new("TextButton")
deleteAllButton.Size = UDim2.new(1, 0, 0, 30)
deleteAllButton.Position = UDim2.new(0, 0, 0, 10)
deleteAllButton.Text = "🗑️ Delete All Spawned Pets"
deleteAllButton.Font = Enum.Font.GothamBold
deleteAllButton.TextSize = 11
deleteAllButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
deleteAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteAllButton.Parent = settingsPanel

local deleteAllCorner = Instance.new("UICorner")
deleteAllCorner.CornerRadius = UDim.new(0, 8)
deleteAllCorner.Parent = deleteAllButton

deleteAllButton.MouseButton1Click:Connect(function()
    local count = DeleteAllSpawnedObjects()
    deleteAllButton.Text = "✓ Deleted " .. count .. "!"
    TweenService:Create(deleteAllButton, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(60, 180, 60) }):Play()
    task.wait(1.5)
    deleteAllButton.Text = "🗑️ Delete All Spawned Pets"
    TweenService:Create(deleteAllButton, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(180, 60, 60) }):Play()
end)

local uiLocked = false
local lockButton = Instance.new("TextButton")
lockButton.Size = UDim2.new(1, 0, 0, 30)
lockButton.Position = UDim2.new(0, 0, 0, 50)
lockButton.Text = "🔓 Unlock UI Movement"
lockButton.Font = Enum.Font.GothamBold
lockButton.TextSize = 10
lockButton.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.Parent = settingsPanel
Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 8)

lockButton.MouseButton1Click:Connect(function()
    uiLocked = not uiLocked
    if uiLocked then
        lockButton.Text = "🔒 Lock UI Movement"
        lockButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
    else
        lockButton.Text = "🔓 Unlock UI Movement"
        lockButton.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
    end
end)

local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Size = UDim2.new(1, 0, 0, 12)
watermarkLabel.Position = UDim2.new(0, 0, 1, -14)
watermarkLabel.BackgroundTransparency = 1
watermarkLabel.Font = Enum.Font.Gotham
watermarkLabel.TextSize = 7
watermarkLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
watermarkLabel.TextWrapped = true
watermarkLabel.Parent = mainFrame
watermarkLabel.Text = "ZetaScripts | " .. HttpService:GenerateGUID(false) 

local original_print = print
print = function(...)
    local args = {...}
    original_print(unpack(args))
end

local dragging = false
local dragStart = Vector2.new(0, 0)
local startPos = Vector2.new(0, 0)

mainFrame.InputBegan:Connect(function(input)
    if not uiLocked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        mainFrame.ZIndex = 100
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                mainFrame.ZIndex = 1
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if not uiLocked and dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

SwitchTab(activeTab)

print("ZetaScripts UI caricata con successo!")
