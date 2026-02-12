local CharacterFactory = require("src.CharacterFactory")
local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")
local Character = require("src.Object.character")
local Anims = require("src.Anims")

local IdleState = {}


function IdleState.onEnter()
    local wagon = ObjectManager:Get('wagon')
    wagon:act('idle')
    local wagonTop = ObjectManager:Get('wagonTop')
    wagonTop:act('idle')

    if not ObjectManager:Get('chara') then
        local chara = Character.new('chara', Anims.chara())
        chara.ox, chara.oy = -32, -64
        chara.sayOX, chara.sayOY = 32, 20
        chara.x = wagon.x + 150
        chara.y = wagon.y
        chara.anim.flipX = true
        chara:act('idle')
        ObjectManager:Register(chara)
    end
end

function IdleState.onClick()
    UIManager:open('mainPanel')
end

return IdleState