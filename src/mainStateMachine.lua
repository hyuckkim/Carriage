local StateMachine = require("lib.statemachine")
local Anims = require("src.Anims")
local createRandomCustomer = require("src.CharacterFactory").create
local DataStore = require("src.Datastore")
local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")
local Tutorial = require("src.Sequence.Tutorial")

local mainStateMachine = {}
local fsm

local wagonAnim
local topAnim
local character

local workthrough = 0

function mainStateMachine.init(self, wagonX, wagonY)
    wagonAnim = Anims.wagon()
    topAnim = Anims.wagonTop()
    character = Anims.chara()

    local newCustomers = {}
    for i = 1, 8 do
        table.insert(newCustomers, createRandomCustomer())
    end

    -- 참조 끊김 없이 Datastore.customers의 내용만 바뀜!
    DataStore.update("customers", newCustomers)
    fsm = StateMachine.new()
    fsm:addState("prologue", {
        onEnter = function()
            ObjectManager:Add(Anims.wagon(), 'wagon', 1, 0, {
                layer = 0,
                anim = 'idle',
            })
            ObjectManager:Add(Anims.chara(), 'chara', -32, 32, {
                layer = 1,
                anim = 'idle'
            })
            ObjectManager:Add(Anims.Advisor(), 'advisor', -32, 32, {
                layer = 1,
                anim = 'idle'
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
    fsm:addState("tutorial", {

    })
    fsm:addState("idle", {
        onEnter = function() 
            wagonAnim:play("idle")
            character:play("idle")
            topAnim:play("idle")
        end,
        onUpdate = function(dt)
            wagonAnim:update(dt)
            character:update(dt)
            -- characters[1]:update(dt)
            -- characters[2]:update(dt)
            -- characters[3]:update(dt)
            -- characters[4]:update(dt)
            topAnim:update(dt)
        end,
        onDraw = function()
            wagonAnim:draw(wagonX, wagonY)
            character:draw(wagonX + 120, wagonY + 32, 64, 64)
            -- characters[1]:draw(15, wagonY + 6, 80, 64)
            -- characters[2]:draw(40, wagonY + 9, 80, 64)
            -- characters[3]:draw(65, wagonY + 8, 80, 64)
            -- characters[4]:draw(80, wagonY + 6, 80, 64)
            topAnim:draw(wagonX, wagonY)
        end,
        onClick = function()
            UIManager:open('main')
        end
    })
    fsm:addState("walk", {
        onEnter = function() 
            wagonAnim:play("walk")
            workthrough = 0
        end,
        onUpdate = function(dt)
            wagonAnim:update(dt)
            workthrough = workthrough + dt
            if (workthrough >= 5000) then
                fsm:transition('idle')
            end
        end,
        onExit = function()

        end,
        onDraw = function()
            wagonAnim:draw(wagonX, wagonY)
            g.color(0, 0, 0)
            g.rect(wagonX + 10, wagonY - 50, 200, 5)
            g.color(255, 255, 255)
            g.rect(wagonX + 10, wagonY - 50, 200 / 5000 * workthrough, 5)
        end
    })

    return fsm
end

return mainStateMachine