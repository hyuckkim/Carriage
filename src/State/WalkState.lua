local ObjectManager = require("lib.ObjectManager")
local DataStore = require("src.Datastore")
local CanvasMap = require("src.UI.canvasMap")
local CharacterFactory = require("src.CharacterFactory")
local genGrass = require("src.GenGrass")


local workthrough = 0
local endto = 5000
local speed = 300

local distBuffer = 0 
local nextSpawnDist = math.random(20, 50)

local WalkState = {}


local function walkWithGrass(dt)
    -- getPlant는 상단에서 require했으므로 항상 존재합니다.
    local moveStep = dt * 0.001 * speed
    distBuffer = distBuffer + moveStep

    if distBuffer >= nextSpawnDist then
        distBuffer = 0
        nextSpawnDist = math.random(40, 120)
        local screenW, _ = sys.getSize()
        genGrass(screenW)
    end
end

local customersSpawned = false
local function walkWithStation()
    local wagon = ObjectManager:Get('wagon')
    if customersSpawned then return end
    local screenW, _ = sys.getSize()
    
    -- 마차가 앞으로 더 가야 할 거리
    local remainingDist = endto - workthrough
    
    -- 마차의 현재 위치 + 남은 거리 = 마차가 최종 멈출 화면 좌표
    local finalWagonX = 150 + remainingDist -- (150은 wagon.x 초기값이라 가정)

    -- 최종 목적지가 화면 오른쪽 끝에 진입하는 순간!
    if finalWagonX <= screenW then
        customersSpawned = true
        
        for i = 1, 6 do
            local spawnX = finalWagonX + math.random(50, 350)
            
            CharacterFactory.createCustomer({
                x = spawnX,
                y = wagon.y,
                isBoarding = false -- 아직 안 탄 상태
            })
        end
    end
end

function WalkState.onEnter()
    local wagon = ObjectManager:Get('wagon')
    wagon:act('walk')
    local wagonTop = ObjectManager:Get('wagonTop')
    wagonTop:act('walk')
    workthrough = 0
    customersSpawned = false

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
    
    local newBurg = DataStore.get('canvasMap').selectedBurg
    local oldBurg = DataStore.get('currentTown')
    DataStore.update('previousTown', oldBurg)
    DataStore.update('currentTown', newBurg)
    DataStore.update('canvasMap', CanvasMap
        .new(DataStore.get('map'), newBurg.name, 800, 600, 4.0))
end

function WalkState.onExit()
    local wagon = ObjectManager:Get('wagon')
    local town = DataStore.get('currentTown')
    local passengers = ObjectManager:GetAll(function(obj)
        return obj.is_customer and obj.isBoarding
    end)
    for i, p in ipairs(passengers) do
        p:EndTravel(town and town.name or nil, wagon)
    end
end

function WalkState.onUpdate(dt)
    workthrough = workthrough + dt * 0.001 * speed
    ObjectManager:MoveWorld(dt * 0.001 * speed, 0)
    if workthrough >= endto then
        DataStore.get('fsm'):transition('idle')
    end
    walkWithGrass(dt)
    walkWithStation()

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