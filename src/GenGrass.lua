local ObjectManager = require("lib.ObjectManager")
local getPlant = require("src.Object.Grass")
local grassCounter = 0

return function (initPos)
    local wagon = ObjectManager:Get('wagon')
    if not wagon then return end
    local sprite, name = getPlant()
    
    local isTree = string.find(name, "tree") or string.find(name, "pine")
    grassCounter = grassCounter + 1
    ObjectManager:Register({
        key = "env_" .. grassCounter .. "_" .. math.random(1000),
        x = initPos + 100,
        y = wagon.y,
        layer = isTree and -40 or -30,
        sprite = sprite,
        draw = function(self) self.sprite:draw(self.x, self.y) end,
        update = function() end
    })
end