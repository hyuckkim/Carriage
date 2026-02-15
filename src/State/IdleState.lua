local DataStore = require("src.DataStore")
local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")
local Character = require("src.Object.character")
local Anims = require("src.Table.Anims")
local genGrass = require("src.GenGrass")
local Customer = require("src.Object.customer")

local IdleState = {}
local grassCoroutine = nil
local boardingCoroutine = nil
local unboardingCoroutine = nil

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
    IdleState.startUnboardingSequence()
end

function IdleState.onUpdate(dt)

    if grassCoroutine and coroutine.status(grassCoroutine) ~= "dead" then
        local success, err = coroutine.resume(grassCoroutine)
        if not success then print("Coroutine Error:", err) end
    end
    if boardingCoroutine and coroutine.status(boardingCoroutine) ~= "dead" then
        local success, err = coroutine.resume(boardingCoroutine, dt)
        if not success then print("Boarding Error:", err) end
    end
    if unboardingCoroutine and coroutine.status(unboardingCoroutine) ~= "dead" then
        local success, err = coroutine.resume(unboardingCoroutine, dt)
        if not success then print("Unboarding Error:", err) end
    end
end

function IdleState.onClick()
    UIManager:open('mainPanel')
end

function IdleState.startBoardingSequence()
    boardingCoroutine = coroutine.create(function()
        local wagon = ObjectManager:Get('wagon')
        local customers = ObjectManager:GetAll(function(obj)
            return obj.is_customer
        end)

        -- 1. 모든 손님을 일단 멈춤
        for _, c in ipairs(customers) do
            c.behavior_type = 'none'
            c:StopSay()
        end

        for _, c in ipairs(ObjectManager:GetAll(function(obj)
            return obj.isBoarding
        end)) do
            -- Move 함수도 밀리초를 쓰므로 1000ms(1초) 동안 이동
            c:Move(wagon.x + 80, wagon.y, 1000)
            c.anim:play('walk')
        end
        -- 2. 모든 손님이 도착할 때까지 대기 (1200ms)
        local timer = 0
        while timer < 1200 do
            local dt = coroutine.yield() -- onUpdate에서 들어오는 16.67ms 등
            timer = timer + dt
        end

        -- 3. 손님들을 마차 칸으로 '쏙' 사라지게 함
        for _, c in ipairs(customers) do
            c.visible = false
        end

        local wait = 0
        while wait < 200 do
            local dt = coroutine.yield()
            wait = wait + dt
        end

        DataStore.get('fsm'):transition("walk")
    end)
end

function IdleState.startUnboardingSequence()
    unboardingCoroutine = coroutine.create(function()
        local wagon = ObjectManager:Get('wagon')
        local passengers = ObjectManager:GetAll(function(obj)
            return obj.is_customer and obj.isBoarding
        end)

        -- 1. 한 명씩 순차적으로 내리기
        for _, p in ipairs(passengers) do
            p.visible = true
            p.anim:play('walk')
            p.x = 80
            p.y = wagon.y
    
            -- 데이터 즉시 처리 (이미 이전 대화에서 논의한 대로)
            if p.isAtDestination then
                p.is_customer = false
                p.isBoarding = false
                p.is_npc = true
            end

            -- 마차 밖 임의의 지점으로 걸어나옴 (속도 60도 밀리초 기준이라면 맞춰서 작동할 것)
            local exitX = wagon.x + math.random(150, 300)
            p:MoveBySpeed(exitX, wagon.y, 0.08, 'idle')
            
            -- 손님이 내리는 간격 대기 (500ms)
            local t = 0
            while t < 200 do
                t = t + coroutine.yield()
            end
        end

        -- 2. 모든 손님이 내린 후 작별 인사 대기 (1000ms)
        local wait = 0
        while wait < 1000 do
            wait = wait + coroutine.yield()
        end

        for _, p in ipairs(passengers) do
            if p.isAtDestination then
                p:Say("감사합니다!", "Quote", 2000) -- 대사 지속시간도 2000ms
                p:MoveBySpeed(-350, p.y, 0.08) -- 퇴장
            end
        end
    end)
end

function IdleState.GetPersistentData()
    local currnetTown = DataStore.get('currentTown')
    local data = {
        stateType = "idle",
        customers = {},
        town = currnetTown and {
            name = currnetTown.name,
            group = currnetTown.group
        } or {},
    }

    local locals = ObjectManager:GetAll(function(obj)
        return obj.is_customer
    end)
    
    for _, c in ipairs(locals) do
        table.insert(data.customers, c:GetPersistentData())
    end
    return data
end

function IdleState.Restore(data)
    if data.town then
        DataStore.update('currentTown', data.town)
        
        local screenW, _ = is.size()
        grassCoroutine = genGrass.SpawnTownScenery(
            data.town.name, data.town.group, 0, screenW)
    end

    for _, cData in ipairs(data.customers or {}) do
        local c = Customer.newFromData(cData)
        ObjectManager:Register(c)
    end
    
end
return IdleState