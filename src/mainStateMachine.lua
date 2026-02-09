local StateMachine = require("lib.statemachine")
local Anims = require("src.Anims")
local ObjectManager = require("lib.ObjectManager")
local Tutorial = require("src.Sequence.Tutorial")
local Character = require("src.Object.character")

local mainStateMachine = {}
local fsm

function mainStateMachine:init(wagonX, wagonY)
    fsm = StateMachine.new()
    fsm:addState("prologue", {
        onEnter = function()
            local wagon = Character.new('wagon', Anims.wagon())
            wagon:Move(wagonX, wagonY)
            wagon:act('idle')
            wagon.isAbsolute = true
            wagon.layer = -20
            ObjectManager:Register(wagon)

            -- 주인공 생성 (Character 클래스 활용)
            local chara = Character.new('chara', Anims.chara())
            chara.ox, chara.oy = -32, 32
            chara.sayOX, chara.sayOY = 32, 20
            ObjectManager:Register(chara)

            local wagonTop = Character.new('wagonTop', Anims.wagonTop())
            wagonTop:Move(wagonX, wagonY)
            wagonTop:act('idle')
            wagonTop.isAbsolute = true
            wagonTop.layer = -10
            ObjectManager:Register(wagonTop)

            -- 튜토리얼 시작
            Tutorial:Init(wagonX, wagonY)
        end,
        onUpdate = function(dt) Tutorial:Update(dt) end,
        onDraw   = function()   Tutorial:Draw()   end,
        onClick  = function(x, y) Tutorial:OnClick(x, y) end
    })
    fsm:addState("idle", require("src.State.IdleState"))
    fsm:addState("walk", require("src.State.WalkState"))

    return fsm
end

return mainStateMachine