-- PlayerData.server.lua
-- Place in ServerScriptService.
-- Creates leaderstats (Coins) and a Gems counter, and saves/loads both with DataStoreService.
-- Failed loads never overwrite saved data, and every DataStore call is retried.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local STORE_NAME = "PlayerData_v1"
local AUTOSAVE_INTERVAL = 60 -- seconds
local MAX_RETRIES = 3

local store = DataStoreService:GetDataStore(STORE_NAME)

-- Only players whose data loaded successfully are allowed to save.
-- Otherwise a failed load would overwrite their real progress with zeros.
local loaded: { [Player]: boolean } = {}

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

-- Runs a DataStore call, retrying with a growing delay if it errors.
local function withRetry(callback: () -> any): (boolean, any)
	local ok, result
	for attempt = 1, MAX_RETRIES do
		ok, result = pcall(callback)
		if ok then
			break
		end
		warn(string.format("DataStore attempt %d/%d failed: %s", attempt, MAX_RETRIES, tostring(result)))
		if attempt < MAX_RETRIES then
			task.wait(2 ^ attempt)
		end
	end
	return ok, result
end

local function setupPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	leaderstats.Parent = player

	player:SetAttribute("Gems", 0)

	local ok, data = withRetry(function()
		return store:GetAsync(keyFor(player))
	end)

	if not player.Parent then
		return -- they left while we were loading
	end

	if ok then
		if type(data) == "table" then
			coins.Value = tonumber(data.Coins) or 0
			player:SetAttribute("Gems", tonumber(data.Gems) or 0)
		end
		loaded[player] = true
	else
		warn("Could not load data for " .. player.Name .. ". Progress will not be saved this session.")
	end
end

local function saveData(player: Player)
	if not loaded[player] then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins then
		return
	end

	local payload = {
		Coins = coins.Value,
		Gems = player:GetAttribute("Gems") or 0,
	}

	withRetry(function()
		store:SetAsync(keyFor(player), payload)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	loaded[player] = nil
end)

-- Autosave so a crash doesn't lose everything.
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(saveData, player)
		end
	end
end)

-- Save everyone when the server shuts down.
game:BindToClose(function()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			saveData(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
