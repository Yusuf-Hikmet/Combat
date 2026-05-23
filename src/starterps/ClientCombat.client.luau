local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local PlayersService = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules") :: Folder
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Global = ReplicatedStorage:WaitForChild("Global")

local Types = require(Global:WaitForChild("Types"))
local CombatModule = require(Modules:WaitForChild("CombatHandler"))

local DeathEvent = Remotes:WaitForChild("DeathEvent", 5) :: RemoteEvent

if not game:IsLoaded() then game.Loaded:Wait() end

local LocalPlayer = PlayersService.LocalPlayer
local Combat = CombatModule.new() :: Types.CombatHandler

Combat:ListenEvents()

local function CharacterAddedFunction(Character: Model)
    local Humanoid = Character:WaitForChild("Humanoid", 5) :: Humanoid
    if not Humanoid then warn(`[ClientCombat] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in Character`) ;return end
    local hrp = Character:WaitForChild("HumanoidRootPart", 5) :: Part
    if not hrp then warn(`[ClientCombat] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`HumanoidRootPart not found in Character`) ;return end

    Humanoid.Died:Connect(function()
        DeathEvent:FireServer(Character)
    end)

    Humanoid.StateChanged:Connect(function(old, new)
        if new == Enum.HumanoidStateType.Landed then
             if hrp:FindFirstChild(`Unragdollbodyvelocity`) then 
                hrp:FindFirstChild(`Unragdollbodyvelocity`):Destroy()
            end
        end
    end)
end

local function FindDashKey(): Enum.KeyCode

    if UserInputService:IsKeyDown(Enum.KeyCode.A) and 
     not UserInputService:IsKeyDown(Enum.KeyCode.W) and 
     not UserInputService:IsKeyDown(Enum.KeyCode.S) and 
     not UserInputService:IsKeyDown(Enum.KeyCode.D) then
        return Enum.KeyCode.A
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.D) and 
     not UserInputService:IsKeyDown(Enum.KeyCode.W) and 
     not UserInputService:IsKeyDown(Enum.KeyCode.A) and 
     not UserInputService:IsKeyDown(Enum.KeyCode.S) then
        return Enum.KeyCode.D
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        return Enum.KeyCode.W
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        return Enum.KeyCode.S
    end

    return Enum.KeyCode.W
end

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if GameProcessed then return end

    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Combat:Attack()
    end

    if Input.KeyCode == Enum.KeyCode.F then
        Combat:Block()
    end

    if Input.KeyCode == Enum.KeyCode.Q then  

        Combat:Dash(FindDashKey())
    end

end)

UserInputService.InputEnded:Connect(function(Input, GameProcessed)
    if GameProcessed then return end

    if Input.KeyCode == Enum.KeyCode.F then
        Combat:UnBlock()
    end
    
end)

LocalPlayer.CharacterAdded:Connect(CharacterAddedFunction)