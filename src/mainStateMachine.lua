local StateMachine = require("lib.statemachine")
local Anims = require("src.Anims")
local createRandomCustomer = require("src.CharacterFactory").create
local DataStore = require("src.Datastore")
local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")
local Tutorial = require("src.Sequence.Tutorial")

local mainStateMachine = {}
local fsm

local workthrough = 0

function mainStateMachine.init(self, wagonX, wagonY)
    fsm = StateMachine.new()
    fsm:addState("prologue", {
        onEnter = function()
            ObjectManager:Add(Anims.wagon(), 'wagon', 1, 0, {
                layer = 0,
                anim = 'idle'
            })
            ObjectManager:Add(Anims.chara(), 'chara', -32, 32, {
                layer = 2, sayOX = 32, sayOY = 20, defaultAnim = 'idle'
            })
            ObjectManager:Move('wagon', wagonX, wagonY)

            Tutorial:Init(wagonX, wagonY)
        end,
        onDraw = function()
            Tutorial:Draw()
        end,
        onUpdate = function(dt)
            Tutorial:Update(dt)
        end,
        onClick = function(x, y)
            Tutorial:OnClick(x, y)
        end
    })
    fsm:addState("idle", {
        onEnter = function(customers)
            -- 개별 anim:play가 아니라 ObjectManager에게 명령
            ObjectManager:Play('wagon', 'idle')
            ObjectManager:Play('chara', 'idle')

            if not customers then
                local newCustomers = {}
                for i = 1, 8 do
                    createRandomCustomer()
                end
                DataStore.update("customers", newCustomers)
            end
        end,
        onDraw = function()
            -- 여기선 더이상 wagonAnim:draw()를 부르지 않음 (main에서 그리니까)
        end,
        onClick = function() UIManager:open('mainPanel') end
    })

    fsm:addState("walk", {
        onEnter = function() 
            ObjectManager:Play('wagon', 'walk')
            workthrough = 0
        end,
        onUpdate = function(dt)
            workthrough = workthrough + dt
            if workthrough >= 5000 then fsm:transition('idle') end
        end,
        onDraw = function()
            -- 진행바 같은 UI 요소만 별도로 그림
            g.color(0, 0, 0)
            g.rect(wagonX + 10, wagonY - 50, 200, 5)
            g.color(255, 255, 255)
            g.rect(wagonX + 10, wagonY - 50, 200 / 5000 * workthrough, 5)
        end
    })

    return fsm
end

return mainStateMachine