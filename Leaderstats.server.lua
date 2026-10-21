
-- Roblox Leaderstats Example
-- Place this script in ServerScriptService

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    -- Create the leaderboard folder
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    -- Create the Coins stat
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats
end)
