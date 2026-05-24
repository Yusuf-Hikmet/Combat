local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local PlayersService = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules") :: Folder
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Global = ReplicatedStorage:WaitForChild("Global")

local Types = require(Global:WaitForChild("Types"))
local CombatModule = require(Modules:WaitForChild("CombatHandler"))
local AnimData = require(Modules:WaitForChild("AnimData"))

local DeathEvent = Remotes:WaitForChild("DeathEvent", 5) :: RemoteEvent

if not game:IsLoaded() then game.Loaded:Wait() end

local LocalPlayer = PlayersService.LocalPlayer
local Camera = workspace.CurrentCamera
local Combat = CombatModule.new() :: Types.CombatHandler

Combat:ListenEvents()

local function CharacterAdded(Character: Model)
    local Humanoid = Character:WaitForChild("Humanoid", 5) :: Humanoid
    if not Humanoid then warn(`[ClientCombat] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in Character`) ;return end
    local hrp = Character:WaitForChild("HumanoidRootPart", 5) :: Part
    if not hrp then warn(`[ClientCombat] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`HumanoidRootPart not found in Character`) ;return end
    local Animator = Humanoid:WaitForChild("Animator", 5) :: Animator
    if not Animator then warn(`[ClientCombat] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Animator not found in Humanoid`) ;return end

    Humanoid.Died:Connect(function()
        DeathEvent:FireServer(Character)
    end)

    local CurrentTrack -- AnimationTrack?

    local function UpdateAnimation(Anim: string): () -- string only(rbxassetid)
        if not Combat:CanAttack() then
            if CurrentTrack then
                CurrentTrack:Stop()
                CurrentTrack = nil
            end
            return
        end
        if CurrentTrack and CurrentTrack.Animation.AnimationId == Anim then return end

        if CurrentTrack then
            CurrentTrack:Stop()
            CurrentTrack = nil
        end
        if AnimData.Run == Anim then
            Humanoid.WalkSpeed = 20
        elseif AnimData.Walk == Anim then
            Humanoid.WalkSpeed = 16
        end

        local Animation = Instance.new("Animation")
        Animation.AnimationId = Anim
        CurrentTrack = Animator:LoadAnimation(Animation) 
        CurrentTrack:Play() 

        Animation:Destroy()
    end

    task.spawn(function()
        while Humanoid do
            if Humanoid.MoveDirection.Magnitude > 0 then
                local CameraDot = Camera.CFrame.LookVector:Dot(hrp.CFrame.LookVector)
                
                if CameraDot > 0 then
                    UpdateAnimation(AnimData.Run)
                else
                    UpdateAnimation(AnimData.Walk)
                end
            else
                if CurrentTrack then
                    CurrentTrack:Stop()
                    CurrentTrack = nil
                end
            end
            task.wait(0.2)
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

LocalPlayer.CharacterAdded:Connect(CharacterAdded)