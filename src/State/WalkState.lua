local ObjectManager = require("lib.ObjectManager")
local DataStore = require("src.Datastore")

local workthrough = 0
local endto = 500
local speed = 30

local WalkState = {}
function WalkState.onEnter()
    local wagon = ObjectManager:Get('wagon')
    wagon:act('walk')
    local wagonTop = ObjectManager:Get('wagonTop')
    wagonTop:act('walk')
    workthrough = 0
    
    local passengers = ObjectManager:GetAll(function(obj)
        return obj.is_customer and obj.isBoarding
    end)
    local leaved = ObjectManager:GetAll(function(obj)
        return not obj.isBoarding and obj.pattern_script
    end)
    for i, p in ipairs(passengers) do
        p:StartTravel(i, wagon)
    end
    for _, l in ipairs(leaved) do
        l:setPattern(l.leaved_pattern or nil)
    end
    ObjectManager:Remove('chara')
end

function WalkState.onExit()
    local wagon = ObjectManager:Get('wagon')
    local passengers = ObjectManager:GetAll(function(obj)
        return obj.is_customer and obj.isBoarding
    end)
    for i, p in ipairs(passengers) do
        p:EndTravel(wagon)
    end
end

function WalkState.onUpdate(dt)
    workthrough = workthrough + dt * 0.001 * speed
    ObjectManager:MoveWorld(dt * 0.001 * speed, 0)
    if workthrough >= endto then
        DataStore.get('fsm'):transition('idle')
    end
    
    local leaved = ObjectManager:GetAll(function(obj)
        return obj.x < -1000
    end)
    for _, p in ipairs(leaved) do
        ObjectManager:Remove(p.key)
    end
end

function WalkState.onDraw()
    local wagon = ObjectManager:Get('wagon')
    if not wagon then return end -- 마차가 없을 경우 대비

    local wagonX, wagonY = wagon.x, wagon.y
    g.color(0, 0, 0)
    g.rect(wagonX + 10, wagonY - 50, 200, 5)
    g.color(255, 255, 255)
    g.rect(wagonX + 10, wagonY - 50, (200 / endto) * workthrough, 5)
end

return WalkState