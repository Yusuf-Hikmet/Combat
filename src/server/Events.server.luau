local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")
local EventsHandler = require(script.Parent.EventsHandler)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DamageEvent = Remotes:WaitForChild("DamageEvent", 5) :: RemoteEvent
local BlockEvent = Remotes:WaitForChild("BlockEvent", 5) :: RemoteEvent
local DeathEvent = Remotes:WaitForChild("DeathEvent", 5) :: RemoteEvent
local GetUpCharacter = Remotes:WaitForChild("GetUpCharacter", 5) :: RemoteEvent

DamageEvent.OnServerEvent:Connect(EventsHandler.DamageEvent)
BlockEvent.OnServerEvent:Connect(EventsHandler.BlockEvent)
DeathEvent.OnServerEvent:Connect(EventsHandler.DeathEvent)
GetUpCharacter.OnServerEvent:Connect(EventsHandler.GetUpEvent)

PlayersService.PlayerRemoving:Connect(EventsHandler.PlayerRemoving)
