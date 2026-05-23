local PlayersService = game:GetService("Players")

PlayersService.PlayerAdded:Connect(function(player)
    player:SetAttribute(`CanAttack`, true)
    player:SetAttribute(`IsBlocking`, false)
    player:SetAttribute(`IsRagdoll`, false)
    player:SetAttribute(`CanTakeDamage`, true)

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local Kills = Instance.new("IntValue")
    Kills.Name = "Kills"
    Kills.Parent = leaderstats
end)