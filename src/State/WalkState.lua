local ObjectManager = require("lib.ObjectManager")
local DataStore = require("src.Datastore")
local Customer = require("src.Object.customer")
local CharacterFactory = require("src.Table.CharacterFactory")
local genGrass = require("src.GenGrass")
local UIManager = require("lib.UIManager")

local workthrough = 0
local endto = 5000
local speed = 56       -- 목표 최대 속도
local currentSpeed = 0  -- 현재 속도 (0에서 시작)
local acceleration = 50 -- 초당 증가할 속도 값 (조절 가능)
local deceleration = 80 -- 감속도 (가속보다 조금 더 높으면 안정적임)
local decelDist = 700    -- 목적지로부터 몇 픽셀 전부터 감속할지

local distBuffer = 0 
local nextSpawnDist = 0

local WalkState = {}
local townCoroutine = nil

local customersSpawned = false
local isEnteringTown = false

local function walkWithGrass(dt, speed)
    if townCoroutine and coroutine.status(townCoroutine) ~= "dead" then
        local success, err = coroutine.resume(townCoroutine)
        if not success then print("Coroutine Error:", err) end
    else
        if isEnteringTown then return end
        local moveStep = dt * 0.001 * speed
        distBuffer = distBuffer + moveStep

        if distBuffer >= nextSpawnDist then
            distBuffer = 0
            local screenW, _ = is.size()
            genGrass.GenGrass(screenW + 100, math.random)
            nextSpawnDist = math.random(40, 120)
        end
    end
end

local function walkWithStation()
    local wagon = ObjectManager:Get('wagon')
    if customersSpawned or not wagon then return end
    
    local screenW, _ = is.size()
    local remainingDist = endto - workthrough
    local finalWagonX = remainingDist
    local destTown = DataStore.get('currentTown')

    -- 마을이 화면 오른쪽 끝에 걸치기 시작할 때
    if not townCoroutine and finalWagonX <= screenW + 500 then 
        if not destTown then return end
        townCoroutine = genGrass.SpawnTownScenery(destTown.name, destTown.group, finalWagonX, screenW)
    end

    if finalWagonX <= screenW then
    customersSpawned = true
    isEnteringTown = true -- 이제부터 '길' 풀 생성을 중단함
    -- 손님 스폰은 '길'의 풍경과 별개여야 하므로 일반 math.random 사용

        local boardingCustomers = ObjectManager:GetAll('isBoarding')
        local currentTownName = destTown and destTown.name or ""

        for _, customer in ipairs(boardingCustomers) do
            local d = customer.data
                local extraRate = 1.2
                d.budget = math.floor(d.budget * extraRate)
        end

        for i = 1, 6 do
            local spawnX = finalWagonX + math.random(150, 450)
            CharacterFactory.createCustomer({
                x = spawnX,
                y = wagon.y,
                isBoarding = false
            },  destTown)
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
    currentSpeed = 0
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

    -- 정상적인 진입 (파일 로드가 아님): idleState에서 진입했으므로
    local map = DataStore.get('canvasMap')
    if map then
        local newBurg = map.selectedBurg
        local oldBurg = DataStore.get('currentTown')

        if newBurg and oldBurg then
            local dist = map:getRealDistance(oldBurg.x, oldBurg.y, newBurg.x, newBurg.y)
            local KM_TO_PX = 13440

            endto = dist * KM_TO_PX
        else endto = 50000 end

        DataStore.update('previousTown', oldBurg)
        DataStore.update('currentTown', newBurg:to_table())
        DataStore.update('canvasMap', nil)

        ObjectManager:Remove('chara')

    end
end

function WalkState.onUpdate(dt)
    local remainingDist = endto - workthrough
    
    -- 가속/감속 계산을 위한 계수 (dt가 밀리초이므로 1000으로 나눔)
    -- 가속도 단위를 '픽셀/s^2'로 맞추기 위해 한 번 더 1000으로 나눈 효과를 줍니다.
    local step = dt * 0.001

    -- 1. 속도 제어
    if remainingDist <= 0 then
        currentSpeed = 0
        DataStore.get('fsm'):transition('idle')
        return
    elseif remainingDist < decelDist then
        -- [감속]
        currentSpeed = currentSpeed - (deceleration * step)
        if currentSpeed < 30 then currentSpeed = 30 end -- 최소 속도
    elseif currentSpeed < speed then
        -- [가속]
        currentSpeed = currentSpeed + (acceleration * step)
        if currentSpeed > speed then currentSpeed = speed end
    end

    -- 2. 실제 이동량 계산
    -- moveAmount = (픽셀/초) * (초) = 픽셀
    local moveAmount = currentSpeed * step
    workthrough = workthrough + moveAmount
    DataStore.update('walkProgress', {
        current = workthrough,
        target = endto,
        speed = currentSpeed
    })

    ObjectManager:MoveWorld(moveAmount, 0)

    -- 3. 도착 체크
    if workthrough >= endto then
        DataStore.get('fsm'):transition('idle')
    end

    -- 배경 생성 및 역 도착 체크
    walkWithGrass(dt, currentSpeed)
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

function WalkState.onClick()
    UIManager:open('walkPanel')
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

    UIManager:closeAll()
end

function WalkState.GetPersistentData()
    local town = DataStore.get('currentTown') or nil
    local townName = town and town.name or ''
    
    local data = {
        stateType = "walk",
        workthrough = workthrough,
        endto = endto,
        passengers = {},
        stationCustomers = {},
        prev = DataStore.get('previousTown') or {},
        town = town or {},
    }

    -- 1. 탑승객 데이터 추출
    local boarding = ObjectManager:GetAll(function(obj) return obj.is_customer and obj.isBoarding end)
    for _, p in ipairs(boarding) do
        table.insert(data.passengers, p:GetPersistentData())
    end

    -- 2. 역 대기 손님 데이터 추출
    if customersSpawned then
        local station = ObjectManager:GetAll(function(obj) 
            return obj.is_customer and not obj.isBoarding and obj.data.origin == townName
        end)
        for _, s in ipairs(station) do
            table.insert(data.stationCustomers, s:GetPersistentData())
        end
    end
    
    return data
end

function WalkState.Restore(data)
    local wagon = ObjectManager:Get('wagon')
    local screenW, _ = is.size()

    -- 1. 기본 수치 복구
    workthrough = data.workthrough or 0
    endto = data.endto or 5000
    currentSpeed = speed -- 로드 즉시 달리는 생동감 부여
    distBuffer = 0
    
    local remainingDist = endto - workthrough
    local finalWagonX = remainingDist 

    -- [추가] 화면 내 기본 풀 채우기
    -- 로드 시점에 화면이 비어있지 않도록 0부터 screenW까지 풀을 무작위로 뿌림
    for x = 0, screenW, math.random(40, 120) do
        genGrass.GenGrass(x, math.random)
    end

    local prevTown = data.prev
    local destTown = data.town
    if prevTown then
        DataStore.update('previousTown', prevTown)
        if workthrough < screenW then 
            townCoroutine = genGrass.SpawnTownScenery(prevTown.name, prevTown.group, -workthrough, screenW)
        end
    end
    if destTown then
        DataStore.update('currentTown', destTown)
        if finalWagonX <= screenW then
            townCoroutine = genGrass.SpawnTownScenery(destTown.name, destTown.group, finalWagonX, screenW)
            if finalWagonX <= screenW then
                isEnteringTown = true
            end
        end
    end
    -- 3. 손님 및 탑승객 복구 (이전 로직 동일)
    for i, pData in ipairs(data.passengers or {}) do
        local p = Customer.newFromData(pData)
        ObjectManager:Register(p)
        p:StartTravel(i, wagon)
    end

    if data.stationCustomers and #data.stationCustomers > 0 then
        for _, sData in ipairs(data.stationCustomers) do
            local s = Customer.newFromData(sData)
            ObjectManager:Register(s)
        end
        customersSpawned = true 
    else
        customersSpawned = false
    end

    -- 4. 마차 애니메이션 동기화
    wagon:act('walk')
    ObjectManager:Get('wagonTop'):act('walk')
end

return WalkState