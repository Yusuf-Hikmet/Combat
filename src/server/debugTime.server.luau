local DataStoreService = game:GetService("DataStoreService")
local PlayersService = game:GetService("Players")
local DebugTimeDataStore = DataStoreService:GetDataStore("DebugTimeDataStore")

PlayersService.PlayerAdded:Connect(function(player)
    local success, debugTime = pcall(function()
        return DebugTimeDataStore:GetAsync(player.UserId)
    end)

    local Time = Instance.new("IntValue", player)
    Time.Name = "DebugTime"

    if success and debugTime then
        Time.Value = debugTime
    else
        Time.Value = 0
    end

    task.wait(.1)

    task.spawn(function()
        while player and player.Parent do
            task.wait(1)
            Time.Value += 1
        end
    end)
end)

PlayersService.PlayerRemoving:Connect(function(player)
    local debugTime = player:FindFirstChild(`DebugTime`)

    if debugTime then
        local success = pcall(function()
            return DebugTimeDataStore:SetAsync(player.UserId, debugTime.Value)
        end)

        if not success then
            warn(`Failed to save debug time for player {player.Name}: {debugTime}`)
        end

    end
end)

game:BindToClose(function()
    task.wait(.5) 
end)