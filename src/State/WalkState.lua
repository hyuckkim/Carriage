local ObjectManager = require("lib.ObjectManager")
local DataStore = require("src.Datastore")
local CanvasMap = require("src.UI.canvasMap")
local CharacterFactory = require("src.CharacterFactory")
local genGrass = require("src.GenGrass")

local workthrough = 0
local endto = 5000
local speed = 300

local distBuffer = 0 
local nextSpawnDist = 0

local WalkState = {}
local townCoroutine = nil

local customersSpawned = false
local isEnteringTown = false

local function walkWithGrass(dt)
    if townCoroutine and coroutine.status(townCoroutine) ~= "dead" then
        local success, err = coroutine.resume(townCoroutine)
        if not success then print("Coroutine Error:", err) end
    else
        if isEnteringTown then return end
        local moveStep = dt * 0.001 * speed
        distBuffer = distBuffer + moveStep

        if distBuffer >= nextSpawnDist then
            distBuffer = 0
            local screenW, _ = sys.getSize()
            genGrass.GenGrass(screenW + 100, math.random)
            nextSpawnDist = math.random(40, 120)
        end
    end
end

local function walkWithStation()
    local wagon = ObjectManager:Get('wagon')
    if customersSpawned or not wagon then return end
    
    local screenW, _ = sys.getSize()
    local remainingDist = endto - workthrough
    local finalWagonX = remainingDist

    -- 마을이 화면 오른쪽 끝에 걸치기 시작할 때
    if not townCoroutine and finalWagonX <= screenW + 500 then 
        local destTown = DataStore.get('currentTown')
        if not destTown then return end
        townCoroutine = genGrass.SpawnTownScenery(destTown.name, finalWagonX, screenW)
    end

    if finalWagonX <= screenW then
    customersSpawned = true
    isEnteringTown = true -- 이제부터 '길' 풀 생성을 중단함
    -- 손님 스폰은 '길'의 풍경과 별개여야 하므로 일반 math.random 사용
        for i = 1, 6 do
            local spawnX = finalWagonX + math.random(50, 350)
            CharacterFactory.createCustomer({
                x = spawnX,
                y = wagon.y,
                isBoarding = false
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
    distBuffer = 0
    customersSpawned = false
    isEnteringTown = false
    townCoroutine = nil
    
    
    -- 2. 초기 거리 설정
    nextSpawnDist = math.random(20, 50)

    -- 3. 이전 데이터 처리
    local passengers = ObjectManager:GetAll(function(obj)
        return obj.is_customer and obj.isBoarding
    end)
    for i, p in ipairs(passengers) do
        p:StartTravel(i, wagon)
    end

    local newBurg = DataStore.get('canvasMap').selectedBurg
    local oldBurg = DataStore.get('currentTown')
    DataStore.update('previousTown', oldBurg)
    DataStore.update('currentTown', newBurg)
    DataStore.update('canvasMap', CanvasMap.new(DataStore.get('map'), newBurg.name, 800, 600, 4.0))
end

function WalkState.onUpdate(dt)
    local moveAmount = dt * 0.001 * speed
    workthrough = workthrough + moveAmount
    ObjectManager:MoveWorld(moveAmount, 0)

    if workthrough >= endto then
        DataStore.get('fsm'):transition('idle')
    end

    -- 배경 생성 및 역 도착 체크
    walkWithGrass(dt)
    walkWithStation()
    
    -- 화면 밖 오브젝트 제거
    local leaved = ObjectManager:GetAll(function(obj)
        return obj.x < -300
    end)
    for _, p in ipairs(leaved) do
        ObjectManager:Remove(p.key)
    end
end

function WalkState.onDraw()
    local wagon = ObjectManager:Get('wagon')
    if not wagon then return end

    local wagonX, wagonY = wagon.x, wagon.y
    g.color(0, 0, 0)
    g.rect(wagonX + 10, wagonY - 50, 200, 5)
    g.color(255, 255, 255)
    g.rect(wagonX + 10, wagonY - 50, (200 / endto) * workthrough, 5)
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

return WalkState