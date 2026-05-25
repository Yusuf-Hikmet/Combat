local DataStoreService = game:GetService("DataStoreService")

local CombatDataStore = DataStoreService:GetDataStore("CombatDataStore")

local DataStore = {}

function DataStore:LoadPlayerData(Player: Player)
    local success, data = pcall(function()
        return CombatDataStore:GetAsync(Player.UserId.."_Kills")
    end)

    if success and data ~= nil then
        local leaderstats = Player:FindFirstChild("leaderstats")
        leaderstats.Kills.Value = data
    else
        warn(`[DataStore] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`, `Failed to load data for player ${Player.Name}: ${data}`)
    end

    return
end

function DataStore:SavePlayerData(Player: Player, Kills: number): ()
    local success, err = pcall(function()
        CombatDataStore:SetAsync(Player.UserId.."_Kills", Kills)
    end)
    if not success then warn(`[DataStore] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`, `Failed to save data for player ${Player.Name}: ${err}`) end

    return
end

return  DataStore