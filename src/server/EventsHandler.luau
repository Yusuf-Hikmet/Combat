--!strict
local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Global = ReplicatedStorage:WaitForChild("Global") -- Folder
local Modules = ReplicatedStorage:WaitForChild("Modules") -- Folder
local Remotes = ReplicatedStorage:WaitForChild("Remotes") -- Folder

local AnimData = require(Modules:WaitForChild("AnimData"))
local Types = require(Global:WaitForChild("Types"))

local BlockEvent = Remotes:WaitForChild("BlockEvent", 5) :: RemoteEvent
local UnRagdollEvent = Remotes:WaitForChild("UnRagdollEvent", 5) :: RemoteEvent

local function RagdollCharacter(Character: Model, SelfHumanodRootPart: Instance?): ()
	local humanoid = Character:FindFirstChildOfClass("Humanoid")
	
	if not humanoid then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,"Humanoid not found!"); return end
	local Player = PlayersService:GetPlayerFromCharacter(Character)

    if Player then 
        Player:SetAttribute(`IsRagdoll`, true)
        Player:SetAttribute(`CanTakeDamage`, false)
     end
    
    humanoid.BreakJointsOnDeath = false
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    humanoid.PlatformStand = true
    humanoid.HipHeight = 0
    humanoid.AutoRotate = false

    local hrp = Character:FindFirstChild("HumanoidRootPart")

    if hrp and hrp:IsA("BasePart") then
        if SelfHumanodRootPart and SelfHumanodRootPart:IsA("BasePart") then
            local xAxisVector = SelfHumanodRootPart and SelfHumanodRootPart.CFrame.X or 0
            hrp:ApplyImpulse(Vector3.new(xAxisVector, 130, xAxisVector * 25))
        else
            warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`HumanoidRootPart not found!`)
        end
    end

	for _, joint in pairs(Character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local part0: BasePart? = joint.Part0
			local part1: BasePart? = joint.Part1

            if not part0 or not part1 or not part0:IsA("BasePart") or not part1:IsA("BasePart") then continue end

			local a0 = Instance.new("Attachment")
			local a1 = Instance.new("Attachment")
            a0.Name = `RagdollAttachment0`
            a1.Name = `RagdollAttachment1`

			a0.Parent = part0
			a1.Parent = part1
			a0.CFrame = joint.C0
			a1.CFrame = joint.C1

			local ball = Instance.new("BallSocketConstraint")
            ball.Name = `RagdollBallSocketConstraint`
			ball.Attachment0 = a0
			ball.Attachment1 = a1
			ball.LimitsEnabled = true
			ball.TwistLimitsEnabled = true
			ball.Parent = part0

			part0.CanCollide = true
			part1.CanCollide = true

			joint.Enabled = false
		end
	end
	
	task.wait(.1)
	for _, Limb in pairs(Character:GetDescendants()) do
		if Limb.Name == "Handle" then continue end
		if not Limb:IsA("BasePart") then continue end
		if Limb.Name == "Head" then Limb.CanCollide = false; continue end
		if Limb.Name == "HumanoidRootPart" or Limb.Name == "Torso" then continue end
		
		Limb.CanCollide = true
	end

    return
end

local function IsBehind(HitPartLookVector: Vector3, CharacterHRPLookVector: Vector3): boolean
    if not HitPartLookVector or not CharacterHRPLookVector then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid arguments provided to IsBehind`) ;return false end
    if typeof(HitPartLookVector) ~= "Vector3" or typeof(CharacterHRPLookVector) ~= "Vector3" then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid argument types provided to IsBehind`) ;return false end

    local DotProduct = HitPartLookVector:Dot(CharacterHRPLookVector)
    return DotProduct < 0.2
end

local function UnRagdollCharacter(Character: Model): ()
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Player = PlayersService:GetPlayerFromCharacter(Character)

    if Player then Player:SetAttribute(`IsRagdoll`, false) end
    if not humanoid then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,"Humanoid not found!"); return end
    
    if humanoid.Health <= 0 then
        task.delay(3, function()
            Player:SetAttribute(`CanAttack`, true)
            Player:SetAttribute(`IsRagdoll`, false)
            Player:SetAttribute(`CanTakeDamage`, true)
        end)

        return 
    end
    
    humanoid.BreakJointsOnDeath = true
    humanoid.PlatformStand = false
    humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    humanoid.HipHeight = 0
    humanoid.AutoRotate = true

    for _, any in pairs(Character:GetDescendants()) do
        if any:IsA("Attachment") then
            if any.Name == `RagdollAttachment0` or any.Name == `RagdollAttachment1` then
                any:Destroy()
            end
        end

        if any:IsA("BallSocketConstraint") and any.Name == `RagdollBallSocketConstraint` then
            any:Destroy()
        end
    end

    for _, joint in pairs(Character:GetDescendants()) do
        if joint:IsA("Motor6D") then
            local part0: BasePart? = joint.Part0
            local part1: BasePart? = joint.Part1

            if not part0 or not part1 or not part0:IsA("BasePart") or not part1:IsA("BasePart") then continue end

            joint.Enabled = true

            part0.CanCollide = false
            part1.CanCollide = false
        end
    end

    UnRagdollEvent:FireClient(Player)

    humanoid.HipHeight = 0
    Player:SetAttribute(`CanTakeDamage`, true)

    return
end

local function AnimationLoader(Character: Model, AnimationAssetId: string, HitNumber: number): ()
    local Animation = Instance.new("Animation")
    Animation.AnimationId = AnimationAssetId
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in Character`) ;return end
    local Animator = Humanoid:FindFirstChildOfClass("Animator")
    if not Animator then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Animator not found in Humanoid`) ;return end
    local AnimationTrack = Animator:LoadAnimation(Animation)
    AnimationTrack.Name = `Hit{HitNumber}`

    AnimationTrack:Play()
    Animation:Destroy()

    AnimationTrack.Stopped:Once(function()
        AnimationTrack:Destroy()
    end)
end

local function StopCharacterAndOffAttack(Character: Model, RestartCharacterTime: number): ()
    local Player = PlayersService:GetPlayerFromCharacter(Character)
    if not Player then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Player not found from Character`) ;return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in Character`) ;return end
    Player:SetAttribute(`CanAttack`, false)

    Humanoid.WalkSpeed = 0
    Humanoid.JumpPower = 0

    task.delay(RestartCharacterTime, function()
        Player:SetAttribute(`CanAttack`, true)
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
    end)

    return
end

local function DamageEvent(Player: Player, EnemyCharacter: Model, HitNumber: number, HitPartLookVector: Vector3): ()
    local Damage = AnimData['Attack'..HitNumber].Damage or nil
    
    if not Player or not EnemyCharacter or not Damage or not HitNumber then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid arguments provided to DamageEvent`) ;return end
    if HitNumber < 1 or HitNumber > 4 then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid HitNumber provided to DamageEvent: {HitNumber}`) ;return end
    if not Player or not EnemyCharacter or not Damage then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid arguments provided to DamageEvent`) ;return end

    local EnemyHumanoid = EnemyCharacter:FindFirstChildOfClass("Humanoid")
    local EnemyPlayer = PlayersService:GetPlayerFromCharacter(EnemyCharacter)

    if EnemyPlayer:GetAttribute('CanTakeDamage') == false then return end
    if not EnemyHumanoid then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in EnemyCharacter`) ;return end

    type IsBehind = boolean
    local function ControlEnemyIsBlocking(): IsBehind
        if EnemyPlayer:GetAttribute('IsBlocking') == true then
            local EnemyHrp = EnemyCharacter:FindFirstChild("HumanoidRootPart")
            if EnemyHrp and EnemyHrp:IsA("BasePart") then 
                print(IsBehind(HitPartLookVector, EnemyHrp.CFrame.LookVector))
                if IsBehind(HitPartLookVector, EnemyHrp.CFrame.LookVector) then 
                    return true 
                else 
                    BlockEvent:FireClient(EnemyPlayer)
                    EnemyPlayer:SetAttribute(`IsBlocking`, false)
                    return false 
                end
            else
                return false
            end
        end

        return false
    end

    if ControlEnemyIsBlocking() then return end

    if HitNumber == 4 then
        local character = Player.Character

        local HumanoidRootPart: Instance? = character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("HumanoidRootPart") or nil
        local EnemyHumaniod = EnemyCharacter:FindFirstChildOfClass("Humanoid")

        if EnemyHumaniod then
            local EnemyAnimator = EnemyHumaniod:FindFirstChildOfClass("Animator")

            if EnemyAnimator then
                for _, track in pairs(EnemyAnimator:GetPlayingAnimationTracks()) do
                    if track.Animation.AnimationId == "rbxassetid://107837404546611" then
                        track:Stop()
                    end
                end
            end
        end

        RagdollCharacter(EnemyCharacter, HumanoidRootPart)

        task.delay(AnimData['Hit4'].StunTime, function()
            UnRagdollCharacter(EnemyCharacter)
        end)

        EnemyHumanoid:TakeDamage(Damage)
        EnemyPlayer:SetAttribute(`LastTouchName`, Player.Name)
        return
    end

    Player:SetAttribute(`IsBlocking`, false)
    AnimationLoader(EnemyCharacter, AnimData['Hit'..HitNumber].AnimationId, HitNumber)
    StopCharacterAndOffAttack(EnemyCharacter, AnimData['Hit'..HitNumber].StunTime)

    EnemyHumanoid:TakeDamage(Damage)
    EnemyPlayer:SetAttribute(`LastTouchName`, Player.Name)
    return
end

-- FBlockEvent = FunctionBlockEvent
local function FBlockEvent(Player: Player, IsBlock: boolean): ()
    if typeof(IsBlock) ~= "boolean" then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid argument type for IsBlock in BlockEvent`) ;return end
    Player:SetAttribute(`IsBlocking`, IsBlock)

    return
end

local function DeathEvent(Player: Player, Character: Model): ()
    if not Character or not Character:IsA("Model") then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid argument for Character in DeathEvent`) ;return end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid and Humanoid.Health > 0 then return end

    RagdollCharacter(Character)
    print(`Died {Character.Name}`)
    local DiedPlayer = PlayersService:GetPlayerFromCharacter(Character)

    if DiedPlayer and DiedPlayer:GetAttribute(`LastTouchName`) then
        local KillerPlayer = PlayersService:FindFirstChild(DiedPlayer:GetAttribute(`LastTouchName`))

        if KillerPlayer then
            KillerPlayer.leaderstats.Kills.Value += 1
        end
    end

    if Humanoid and Humanoid.Health <= 0 then
        task.delay(3, function()
            Player:SetAttribute(`CanAttack`, true)
            Player:SetAttribute(`IsBlocking`, false)
            Player:SetAttribute(`IsRagdoll`, false)
            Player:SetAttribute(`CanTakeDamage`, true)
            Player:LoadCharacterAsync()
        end)
    end

    return
end

local GetUppedPlayers: { [Types.UserId]: Types.LastGetUppedTime } = {}
local function GetUpEvent(Player: Player): ()
    local Character = Player.Character
    if not Character then warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Player has no character in GetUpEvent`) ;return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid and Humanoid.Health <= 0 then return end

    if not GetUppedPlayers[Player.UserId] then
        GetUppedPlayers[Player.UserId] = tick()
    else
        if tick() - GetUppedPlayers[Player.UserId] > AnimData['Hit4'].StunTime then 
            GetUppedPlayers[Player.UserId] = tick()
        else
            warn(`[EventsHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Player is on cooldown for GetUpEvent. Time left: {AnimData['Hit4'].StunTime - (tick() - GetUppedPlayers[Player.UserId])} seconds`)
            return 
        end
    end

    UnRagdollCharacter(Character)

    return
end

local function PlayerRemoving(Player: Player): ()
    if GetUppedPlayers[Player.UserId] then
        GetUppedPlayers[Player.UserId] = nil
    end

    return
end

local EventsHandler: Types.EventsHandler = {
    DamageEvent = DamageEvent,
    AnimationLoader = AnimationLoader,
    StopCharacterAndOffAttack = StopCharacterAndOffAttack,
    RagdollCharacter = RagdollCharacter,
    UnRagdollCharacter = UnRagdollCharacter,
    IsBehind = IsBehind,

    BlockEvent = FBlockEvent,

    DeathEvent = DeathEvent,

    GetUpEvent = GetUpEvent,

    PlayerRemoving = PlayerRemoving
} 

return EventsHandler