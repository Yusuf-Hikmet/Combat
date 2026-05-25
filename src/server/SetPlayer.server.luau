local ServerScriptService = game:GetService("ServerScriptService")
local PlayersService = game:GetService("Players")

local DataStoreService = require(ServerScriptService:WaitForChild("DataStore"))

PlayersService.PlayerAdded:Connect(function(player)
    player:SetAttribute(`CanAttack`, true)
    player:SetAttribute(`IsBlocking`, false)
    player:SetAttribute(`IsRagdoll`, false)
    player:SetAttribute(`CanTakeDamage`, true)
    player:SetAttribute(`LastTouchName`, nil)

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local Kills = Instance.new("IntValue")
    Kills.Name = "Kills"
    Kills.Parent = leaderstats
    DataStoreService:LoadPlayerData(player)
end)

PlayersService.PlayerRemoving:Connect(function(player)
    DataStoreService:SavePlayerData(player, player:FindFirstChild("leaderstats"):FindFirstChild("Kills").Value)
end)