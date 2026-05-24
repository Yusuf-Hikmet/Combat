local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Anims = require(Modules:WaitForChild("AnimData"))

local anims = {}
for _, AnimId in pairs(Anims.GameUsedAllAnims) do
    local Anim = Instance.new("Animation")
    Anim.AnimationId = AnimId
    table.insert(anims, Anim)
end

ContentProvider:PreloadAsync(anims)

for _, Anim in anims do
    Anim:Destroy()
end

print("Animations Loaded!")