local MIN_COOLDOWN_TIME: number = .35
local LAST_ATTACK_TIME_OUT: number = 1
local MIN_STUN_TIME: number = 1.5
local RAGDOLL_TIME: number = 4.5
return {
    BlockId = "rbxassetid://72920129123463",

    Attack1 = {
        AnimationId = "rbxassetid://92996601034298",
        Damage = 3,
        Cooldown = MIN_COOLDOWN_TIME
    },

    Attack2 = {
        AnimationId = "rbxassetid://111843736753991",
        Damage = 3,
        Cooldown = MIN_COOLDOWN_TIME
    },

    Attack3 = {
        AnimationId = "rbxassetid://107412169105711",
        Damage = 3,
        Cooldown = MIN_COOLDOWN_TIME
    },

    Attack4 = {
        AnimationId = "rbxassetid://73131787995385",
        Damage = 5,
        Cooldown = LAST_ATTACK_TIME_OUT
    },

    Hit1 = {
        AnimationId = "rbxassetid://79908399081236",
        StunTime = MIN_STUN_TIME
    },

    Hit2 = {
        AnimationId = "rbxassetid://131393326440354",
        StunTime = MIN_STUN_TIME
    },

    Hit3 = {
        AnimationId = "rbxassetid://107837404546611",
        StunTime = MIN_STUN_TIME 
    },

    Hit4 = {
        StunTime = RAGDOLL_TIME
    },

    Dashs = {
        [Enum.KeyCode.W] =  "rbxassetid://79808745054557",
        [Enum.KeyCode.A] =  "rbxassetid://138440539803721",
        [Enum.KeyCode.S] =  "rbxassetid://71435285280067",
        [Enum.KeyCode.D] =  "rbxassetid://139549717176862",

        Durations = {
            [Enum.KeyCode.W] = 1.5,
            [Enum.KeyCode.A] = 1,
            [Enum.KeyCode.S] = 1,
            [Enum.KeyCode.D] = 0.7
        },

        Speeds = {
            [Enum.KeyCode.W] = 100,
            [Enum.KeyCode.A] = 75,
            [Enum.KeyCode.S] = 75,
            [Enum.KeyCode.D] = 75
        }
        
    },
    Walk = "rbxassetid://74647033055142",
    Run = "rbxassetid://85775044489327",
    
    GameUsedAllAnims = {
        -- Dash
        "rbxassetid://79808745054557",
        "rbxassetid://138440539803721",
        "rbxassetid://71435285280067",
        "rbxassetid://139549717176862",
        -- Hit
        "rbxassetid://79908399081236",
        "rbxassetid://131393326440354",
        "rbxassetid://107837404546611",
        -- LMB / Attacks
        "rbxassetid://73131787995385",
        "rbxassetid://107412169105711",
        "rbxassetid://111843736753991",
        "rbxassetid://92996601034298",
        -- Block
        "rbxassetid://72920129123463",
        -- Walk & Run
        "rbxassetid://74647033055142",
        "rbxassetid://85775044489327"
    } 
}