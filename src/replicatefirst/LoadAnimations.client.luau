local ContentProvider = game:GetService("ContentProvider")

local GameUsedAllAnims: {string} = {
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
}

local anims = {}
for _, AnimId in GameUsedAllAnims do
    local Anim = Instance.new("Animation")
    Anim.AnimationId = AnimId
    table.insert(anims, Anim)
end

ContentProvider:PreloadAsync(anims)

for _, Anim in anims do
    Anim:Destroy()
end

print("Animations Loaded!")