--!strict 

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")
local DebrisService = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Global = ReplicatedStorage:WaitForChild("Global")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local AnimData = require(Modules:WaitForChild("AnimData"))
local Types = require(Global:WaitForChild("Types"))

local DamageEvent = Remotes:WaitForChild("DamageEvent", 5) :: RemoteEvent
local BlockEvent = Remotes:WaitForChild("BlockEvent", 5) :: RemoteEvent
local GetUpCharacter = Remotes:WaitForChild("GetUpCharacter", 5) :: RemoteEvent
local UnRagdollEvent = Remotes:WaitForChild("UnRagdollEvent", 5) :: RemoteEvent

local CombatHandler = {}
CombatHandler.__index = CombatHandler

local LocalPlayer = PlayersService.LocalPlayer
local Camera = workspace.CurrentCamera

local WASD = {
    [Enum.KeyCode.W] = true,
    [Enum.KeyCode.A] = true,
    [Enum.KeyCode.S] = true,
    [Enum.KeyCode.D] = true
}

local LONG_DASH_COOLDOWN = 5
local SHORT_DASH_COOLDOWN = 4
local GET_UP_DASH = 15

function CombatHandler.new(): Types.CombatHandler
    local self = setmetatable({
        ComboCount = 0 :: number,
        Cooldown = false :: boolean,
        LostCombo = nil :: thread?,
        BlockAnim = nil :: AnimationTrack?,
        Hit = false :: boolean,
        LongDashCooldown = LONG_DASH_COOLDOWN :: number,
        ShortDashCooldown = SHORT_DASH_COOLDOWN :: number,
        GetUpDash = GET_UP_DASH :: number,
        IsDashing = false :: boolean,
        DashKey = nil :: Enum.KeyCode?
    }, CombatHandler)

    return (self :: any) :: Types.CombatHandler
end

function CombatHandler:ListenEvents(): ()
    self = self :: Types.CombatHandler

    BlockEvent.OnClientEvent:Connect(function()
        if self.BlockAnim then
            self.BlockAnim:Stop()
            self.BlockAnim = nil
        end
    end)

    UnRagdollEvent.OnClientEvent:Connect(function()
        local Character = game.Players.LocalPlayer.Character
        if not Character then return end

        local humanoid = Character:FindFirstChildOfClass("Humanoid")
        local hrp = Character:FindFirstChild("HumanoidRootPart") :: BasePart
        if not humanoid or not hrp then return end
        
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)
end

function CombatHandler:ResetCombo(): ()
    self.ComboCount = 0
    return
end

function CombatHandler:AnimationLoader(AnimationId: Types.AnimationId, WhatNeed: Types.WhatNeed): Types.IsFinished? | Types.AnimLength? | AnimationTrack?
    if not AnimationId then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`AnimationId not found`) ;return end

    local function LoadAnim(AnimId: string): Types.IsFinished? | Types.AnimLength? | AnimationTrack?
        local Animation = Instance.new("Animation")
        Animation.AnimationId = AnimId

        local Character = LocalPlayer.Character
        if not Character then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Character not found for LocalPlayer`) ;return end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in Character`) ;return end
        local Animator: Animator = Humanoid:FindFirstChildOfClass("Animator")
        if not Animator then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Animator not found in Humanoid`) ;return end

        local LoadedAnimation = Animator:LoadAnimation(Animation)

        if WhatNeed  ~= `Nothing` then
            if WhatNeed == "Length" then
                local Length = LoadedAnimation.Length
                LoadedAnimation:Destroy()
                return Length
            elseif WhatNeed == `AnimTrack` then 
                return  LoadedAnimation
            elseif WhatNeed ~= "IsFinished" then
                warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid WhatNeed provided {WhatNeed}`)
                return
            end
        end

        LoadedAnimation:Play()
        Animation:Destroy()

        LoadedAnimation.Stopped:Once(function()
            LoadedAnimation:Destroy()
            if WhatNeed == "IsFinished" then
                return true
            end
        end)

        task.delay(5, function()
            if LoadedAnimation and LoadedAnimation.Parent then
                LoadedAnimation:Destroy()
            end
        end)

        return
    end

    if typeof(AnimationId) == "string" and AnimationId:find(`rbxassetid://`) then
        return LoadAnim(AnimationId)
    elseif typeof(AnimationId) == "string" and AnimData[AnimationId] then
        return LoadAnim(AnimData[AnimationId].AnimationId)
    elseif typeof(AnimationId) == `number` and AnimationId > 0 and AnimationId < 5 then
        local ComboAnim = `Attack{AnimationId}`
        return LoadAnim(AnimData[ComboAnim].AnimationId)
    elseif tonumber(AnimationId) and tonumber(AnimationId) > 0 and tonumber(AnimationId) < 5 then
        local ComboAnim = `Attack{AnimationId}`
        return LoadAnim(AnimData[ComboAnim].AnimationId)
    elseif typeof(AnimationId) == "Instance" and AnimationId:IsA("Animation") then
        local Anim: Animation = AnimationId
        return LoadAnim(Anim.AnimationId)
    else
        warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid AnimationId provided {AnimationId}`)
    end

    return
end

function CombatHandler:CreateHitbox(HitConfig: Types.HitConfig?): Part
    local Hitbox = Instance.new("Part")
    Hitbox.Size = Vector3.new(5, 5, 5)
    Hitbox.Transparency = .96
    Hitbox.CanCollide = false
    Hitbox.Anchored = true

    if HitConfig then
        Hitbox.CFrame = HitConfig.CFrame
        Hitbox.Size = HitConfig.Size
    end

    return Hitbox
end

function CombatHandler:HitboxHit(Hitbox: Part, Character: Model, ComboCount: number): ()
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = {Character}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local Hits = workspace:GetPartsInPart(Hitbox, params)

    for _, part in Hits do
        if self.Hit == true then return end

        local HitCharacter = part:FindFirstAncestorOfClass("Model")
        if not HitCharacter then continue end
        local Humanoid = HitCharacter:FindFirstChildOfClass("Humanoid")
        if not Humanoid then continue end
        if HitCharacter == Character then continue end
        
        DamageEvent:FireServer(HitCharacter, ComboCount, Hitbox.CFrame.LookVector)
        self.Hit = true
    end

    return
end

function CombatHandler:LostComboFunction(): thread
    return task.delay(AnimData['Attack1'].Cooldown * 3.5, function()
        print(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Combo lost! {self.ComboCount}`)
        self:ResetCombo()
        self.LostCombo = nil
    end)
end

function CombatHandler:StartHitbox(ComboCount: number): RBXScriptConnection
    return RunService.PreRender:Connect(function()
        local Character = LocalPlayer.Character
        if not Character then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Character not found for LocalPlayer`) ;return end
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hrp then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`HumanoidRootPart not found in Character`) ;return end

        local Hitbox = self:CreateHitbox({CFrame = hrp.CFrame * CFrame.new(0, 0, -5), Size = Vector3.new(5, 5, 5)})

        self:HitboxHit(Hitbox, Character, ComboCount)

        DebrisService:AddItem(Hitbox, .1)
    end)
end

function CombatHandler:StopHitbox(HitboxConnection: RBXScriptConnection): ()
    if HitboxConnection and typeof(HitboxConnection) == "RBXScriptConnection" then
        HitboxConnection:Disconnect()
    else
        warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid HitboxConnection provided`)
    end

    return
end

function CombatHandler:CanAttack(PassArgs: Types.PassArgs?): boolean
    if PassArgs and typeof(PassArgs)  ~= "table" then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid PassArgs provided`) ;return false end

    local Pass = ((PassArgs or {}) :: any) :: Types.PassArgs

    if LocalPlayer:GetAttribute(`CanTakeDamage`) == false and not Pass.CanTakeDamage then return false 
    elseif LocalPlayer:GetAttribute(`CanAttack`) == false and not Pass.CanAttack then return false 
    elseif LocalPlayer:GetAttribute(`IsRagdoll`) == true and not Pass.IsRagdoll then return false 
    elseif LocalPlayer:GetAttribute(`IsBlocking`) == true and not Pass.IsBlocking then return false 
    elseif self.BackwardDash == true and not Pass.BackwardDash then return false 
    elseif self.Cooldown == true and not Pass.selfColdown then return false 
    elseif self.IsDashing == true and not Pass.IsDashing then return false 
    elseif self.DashKey == Enum.KeyCode.W and not Pass.W then return false 
    elseif self.DashKey == Enum.KeyCode.S and not Pass.S then return false
    elseif self.DashKey == Enum.KeyCode.A and not Pass.A then return false
    elseif self.DashKey == Enum.KeyCode.D and not Pass.D then return false end

    return true
end

function CombatHandler:Attack(): ()
     self = self :: Types.CombatHandler

    if not self:CanAttack({
        W = true, A = true, D = true, IsDashing = true
    }) then return end
    
    local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    Humanoid.WalkSpeed = 16

    self.Hit = false
    self.Cooldown = true

    if self.LostCombo then
        task.cancel(self.LostCombo)
        self.LostCombo = nil
    end

    self.LostCombo = self:LostComboFunction()

    local ANIM_TIME_OUT_TIME: number = nil

    self.ComboCount += 1
    local ComboCount = self.ComboCount

    task.delay(AnimData['Attack' .. ComboCount].Cooldown, function()
        self.Cooldown = false
    end)

    if ComboCount == 4 then
        self:ResetCombo()

        if self.LostCombo then
            task.cancel(self.LostCombo)
            self.LostCombo = nil
        end

        if Humanoid then
            Humanoid.WalkSpeed = 0
            Humanoid.JumpPower = 0

            task.delay(AnimData['Attack4'].Cooldown, function()
                if Humanoid then
                    Humanoid.WalkSpeed = 16
                    Humanoid.JumpPower = 50
                end
            end)
        else
            warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found!`)
        end
    end

    local AnimLength = self:AnimationLoader(ComboCount, "Length")
    local IsFinished = self:AnimationLoader(ComboCount, "IsFinished")
    
    if AnimLength == 0 then
        ANIM_TIME_OUT_TIME = 1
    else 
        if type(AnimLength) == "number" then
            ANIM_TIME_OUT_TIME = AnimLength + .3
        else
            ANIM_TIME_OUT_TIME = 1
        end
    end

    local HitboxConn = self:StartHitbox(ComboCount)

    while not IsFinished do
        task.wait(.1)
        ANIM_TIME_OUT_TIME -= .1

        if ANIM_TIME_OUT_TIME <= 0 then
            break
        end
    end

    self:StopHitbox(HitboxConn)

    return
end

function CombatHandler:Block(): ()
    if not self:CanAttack() then return end

    local Character = LocalPlayer.Character
    if not Character then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Character not found for LocalPlayer`) ;return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in Character`) ;return end
    local Animator: Animator = Humanoid:FindFirstChildOfClass("Animator")
    if not Animator then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Animator not found in Humanoid`) ;return end

    BlockEvent:FireServer(true)

    local BlockAnim = self:AnimationLoader(AnimData.BlockId, "AnimTrack")
    BlockAnim:Play()
    self.BlockAnim = BlockAnim

    Humanoid.WalkSpeed = 8
    Humanoid.JumpPower = 25

    return
end

function CombatHandler:UnBlock(): ()
    self = self :: Types.CombatHandler

    if not self:CanAttack({IsBlocking = true}) then return end

    if self.BlockAnim then
        self.BlockAnim:Stop()
        self.BlockAnim = nil
        BlockEvent:FireServer(false)
    end

    local Character = LocalPlayer.Character
    if not Character then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Character not found for LocalPlayer`) ;return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in Character`) ;return end

    Humanoid.WalkSpeed = 16
    Humanoid.JumpPower = 50

    return
end

function CombatHandler:ResetDash(Key: Enum.KeyCode, IsRagdoll: boolean): ()
    if Key == Enum.KeyCode.S or Key == Enum.KeyCode.W then
        task.delay(LONG_DASH_COOLDOWN, function()
            self.LongDashCooldown = LONG_DASH_COOLDOWN
        end)
    elseif Key == Enum.KeyCode.A or Key == Enum.KeyCode.D then
        if IsRagdoll == true then
            task.delay(GET_UP_DASH, function()
                self.GetUpDash = GET_UP_DASH
            end)
        else 
            task.delay(SHORT_DASH_COOLDOWN, function()
                self.ShortDashCooldown = SHORT_DASH_COOLDOWN
            end)
        end
    else
        warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Invalid Key provided for ResetDash {Key}`)
        return
    end

    return
end

function CombatHandler:Dash(PressedKey: Enum.KeyCode): ()
    local CharRagdoll = LocalPlayer:GetAttribute(`IsRagdoll`)
    local PassCanTakeDamage = false

    if CharRagdoll == true then
        PassCanTakeDamage = true

        if self.GetUpDash <= 0 then
            PassCanTakeDamage = false
            CharRagdoll = false
        end
    end

    if not self:CanAttack({IsRagdoll = CharRagdoll, CanTakeDamage = PassCanTakeDamage}) or  
        not WASD[PressedKey] or self.IsDashing == true then
        return
    end

    if PressedKey == Enum.KeyCode.S or PressedKey == Enum.KeyCode.W then
        if self.LongDashCooldown > 0 then
            self.LongDashCooldown = 0
            self:ResetDash(PressedKey, false)
        else
            return
        end
    elseif PressedKey == Enum.KeyCode.A or PressedKey == Enum.KeyCode.D then
        if LocalPlayer:GetAttribute(`IsRagdoll`) == true and self.GetUpDash > 0 then
            GetUpCharacter:FireServer()
            self.GetUpDash = 0
            self:ResetDash(PressedKey, true)
        elseif LocalPlayer:GetAttribute(`IsRagdoll`) == false then
            if self.ShortDashCooldown > 0 then
                self.ShortDashCooldown = 0
                self:ResetDash(PressedKey, false)
            else
                return
            end
        end
    end
    self.IsDashing = true
    self.DashKey = PressedKey

    local Character = LocalPlayer.Character
    if not Character then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Character not found for LocalPlayer`) ;return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`Humanoid not found in Character`) ;return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then warn(`[CombatHandler] line: {debug.info(1, "l")}, function: {debug.info(1, "n")}\n`,`HumanoidRootPart not found in Character`) ;return end

    self:AnimationLoader(AnimData.Dashs[PressedKey], "Nothing")

    local directionMap = {
        [Enum.KeyCode.W] = function() return HumanoidRootPart.CFrame.LookVector end,
        [Enum.KeyCode.S] = function() return -HumanoidRootPart.CFrame.LookVector end,
        [Enum.KeyCode.A] = function() return -HumanoidRootPart.CFrame.RightVector end,
        [Enum.KeyCode.D] = function() return HumanoidRootPart.CFrame.RightVector end
    }

    local function fDash(t: number, dt: number): ()
        local Duration = AnimData.Dashs.Durations[PressedKey]

        local direction = directionMap[PressedKey]()
        local flatDirection = Vector3.new(direction.X, 0, direction.Z).Unit
        local currentY = HumanoidRootPart.AssemblyLinearVelocity.Y

        local speed = AnimData.Dashs.Speeds[PressedKey] * ((1 - t / Duration) ^ 2)
        
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(
            flatDirection.X * speed,
            currentY,
            flatDirection.Z * speed
        )
    end
    
    if PressedKey == Enum.KeyCode.S then
        Humanoid.AutoRotate = false
    end

    local t: number = 0
    local conn: RBXScriptConnection; conn = RunService.PreRender:Connect(function(dt)  
        t += dt

        if PressedKey == Enum.KeyCode.S then
            Humanoid.AutoRotate = false
            local cameraLook = Camera.CFrame.LookVector
            local flatLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
            HumanoidRootPart.CFrame = CFrame.lookAt(HumanoidRootPart.Position, HumanoidRootPart.Position + flatLook)
        end

        if t >= AnimData.Dashs.Durations[PressedKey] - .3 then
            conn:Disconnect()
            Humanoid.AutoRotate = true
            self.IsDashing = false
            self.DashKey = Enum.KeyCode.Unknown
            return
        end

        fDash(t, dt)
    end)

    return
end

return CombatHandler