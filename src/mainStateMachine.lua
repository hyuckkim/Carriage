local StateMachine = require("lib.statemachine")
local Anims = require("src.Anims")
local CharacterFactory = require("src.CharacterFactory")
local DataStore = require("src.Datastore")
local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")
local Tutorial = require("src.Sequence.Tutorial")
local Character = require("src.Object.character")

local mainStateMachine = {}
local fsm
local workthrough = 0

function mainStateMachine.init(self, wagonX, wagonY)
    fsm = StateMachine.new()
    fsm:addState("prologue", {
        onEnter = function()
            -- 마차 생성 (일반 Object로 생성하거나 Character로 생성 가능)
            local wagon = Character.new('wagon', Anims.wagon())
            wagon:Move(wagonX, wagonY)
            wagon:act('idle')
            ObjectManager:Register(wagon)

            -- 주인공 생성 (Character 클래스 활용)
            local chara = Character.new('chara', Anims.chara())
            chara.ox, chara.oy = -32, 32
            chara.sayOX, chara.sayOY = 32, 20
            ObjectManager:Register(chara)

            -- 튜토리얼 시작
            Tutorial:Init(wagonX, wagonY)
        end,
        onUpdate = function(dt) Tutorial:Update(dt) end,
        onDraw   = function()   Tutorial:Draw()   end,
        onClick  = function(x, y) Tutorial:OnClick(x, y) end
    })
    fsm:addState("idle", {
        onEnter = function(initialCustomers)
            if not initialCustomers then
                for i = 1, 8 do
                    CharacterFactory.createCustomer()
                end
            end
        end,
        onClick = function() 
            UIManager:open('mainPanel')
        end
    })

    fsm:addState("walk", {
        onEnter = function() 
            ObjectManager:Play('wagon', 'walk')
            workthrough = 0
            
            local passengers = ObjectManager:GetAll(function(obj) 
                return obj.is_customer and obj.isBoarding 
            end)
            for _, p in ipairs(passengers) do
                p.visible = false
            end
        end,
        onUpdate = function(dt)
            workthrough = workthrough + dt
            if workthrough >= 5000 then
                fsm:transition('idle')
            end
        end,
        onDraw = function()
            -- 진행바 UI
            g.color(0, 0, 0)
            g.rect(wagonX + 10, wagonY - 50, 200, 5)
            g.color(255, 255, 255)
            g.rect(wagonX + 10, wagonY - 50, (200 / 5000) * workthrough, 5)
        end
    })

    return fsm
end

return mainStateMachine