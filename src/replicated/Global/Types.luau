local Types = {}

-- CREATING Combat Handler Types CLIENT

export type AttackAnim = 'Attack1' | 'Attack2' | 'Attack3' | 'Attack4' 
export type AnimationId = string | number | AttackAnim | Animation -- number only(1,2,3,4); string only("rbxassetid://123456789")
export type WhatNeed = "Length" | "IsFinished" | "Nothing" | "AnimTrack"
export type AnimLength = number
export type IsFinished = boolean
export type PassArgs = {
    CanAttack : boolean?,
    IsRagdoll : boolean?,
    CanTakeDamage : boolean?,
    IsBlocking : boolean?,
    BackwardDash : boolean?,
    selfColdown : boolean?,
    IsDashing : boolean?,
    W : boolean?,A : boolean?,S : boolean?,D : boolean?

}

export type HitConfig = {
    Size : Vector3,
    CFrame : CFrame,
}

export type CombatHandler = {
    -- Properties
    BlockAnim : AnimationTrack?,
    LongDashCooldown : number,
    ShortDashCooldown : number,
    GetUpDash : number,
    DashKey : Enum.KeyCode?,
    ComboCount : number,
    LostCombo : thread?,
    Cooldown : boolean,
    Hit : boolean,
    IsDashing : boolean,

    -- Functions
    -- CombatHandler.new : () -> CombatHandler

    ListenEvents: (self : CombatHandler) -> (),
    
    Dash: (self : CombatHandler, lastKey: Enum.KeyCode) -> (),
    ResetDash: (self : CombatHandler, Key: Enum.KeyCode) -> (),
    Block: (self : CombatHandler) -> (),
    Attack: (self : CombatHandler) -> (),
    UnBlock: (self : CombatHandler) -> (),
    ResetCombo: (self : CombatHandler) -> (),
    StopHitbox: (self : CombatHandler, HitboxConnection: RBXScriptConnection) -> (),
    HitboxHit: (self : CombatHandler, Hitbox: Part, Character: Model, ComboCount: number) -> (),
    
    CanAttack: (self : CombatHandler, Pass: PassArgs?) -> boolean,
    LostComboFunction: (self : CombatHandler) -> thread,
    StartHitbox: (self : CombatHandler, ComboCount: number) -> RBXScriptConnection,
    CreateHitbox: (self : CombatHandler, HitConfig: HitConfig?) -> Part,
    AnimationLoader: (self : CombatHandler, AnimationId: AnimationId, WhatNeed: WhatNeed) -> IsFinished? | AnimLength? | AnimationTrack?
}

-- @Combat Handler CREATED!//


-- CREATING Events Handler Types SERVER

export type UserId = number
export type LastGetUppedTime = number

export type EventsHandler = {
    DamageEvent: (Player: Player, EnemyCharacter: Model, HitNumber: number, HitPartLookVector : Vector3) -> (), -- DamageEvent for RemoteEvent
    AnimationLoader: (EnemyCharacter: Model, AnimationAssetId: string, HitNumber : number) -> (), -- Helper Function for DamageEvent
    StopCharacterAndOffAttack: (Character: Model, RestartCharacterTime: number) -> (), -- Helper Function for DamageEvent
    RagdollCharacter: (Character: Model, HumanoidRootPart: Instance?) -> (), -- Helper Function for DamageEvent

    IsBehind: (HitPartLookVector: Vector3, CharacterHRPLookVector: Vector3) -> boolean, -- Helper Function for DamageEvent

    BlockEvent: (Player : Player, IsBlock: boolean) -> (), -- BlockEvent for RemoteEvent

    DeathEvent: (Player : Player, Character: Model) -> (), -- DeathEvent for RemoteEvent

    GetUpEvent: (Player : Player) -> (), -- GetUpEvent for RemoteEvent

    PlayerRemoving: (Player : Player) -> () -- PlayersRemoving for PlayerRemoving Event
}

-- @Events Handler CREATED!//

return Types