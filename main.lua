require('src.globals')
require('defines')

local debugger = { x = 0, y = 0, visible = false }
WindowTitle = "wagon"

local UIManager = require("lib.UIManager")
local DataStore = require("src.Datastore")
local CanvasMap = require("src.UI.canvasMap")
local SettingMethod = require("src.SettingMethod")
local genGrass = require("src.GenGrass")
local SaveSystem = require("src.SaveSystem")
local StateMachine = require("lib.statemachine")
local Anims = require("src.Table.Anims")
local ObjectManager = require("lib.ObjectManager")
local Tutorial = require("src.Sequence.Tutorial")
local Character = require("src.Object.character")

local sw, sh -- 창 위치
local wagonX, wagonY -- 마차 위치
local grassCoroutine = nil

local StartTownData = Defines.StartTownData

local function initStateMachine()
    local fsm = StateMachine.new()
    fsm:addState("prologue", {
        onEnter = function()
            -- 주인공 생성 (Character 클래스 활용)
            local chara = Character.new('chara', Anims.chara())
            chara.ox, chara.oy = -32, -64
            chara.sayOX, chara.sayOY = 32, 20
            ObjectManager:Register(chara)

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
local function initWindow()
    sw, sh = sys.getWorkArea()
    sys.setSize(sw, sh)
    sys.setPos(0, 0)
    sys.setCursor()
end

local function initWagon()
    wagonX = 0
    wagonY = sh

    local wagon = Character.new('wagon', Anims.wagon())
    wagon:Move(wagonX, wagonY)
    wagon:act('idle')
    wagon.isAbsolute = true
    wagon.layer = -20
    wagon.oy = -96
    ObjectManager:Register(wagon)

    local wagonTop = Character.new('wagonTop', Anims.wagonTop())
    wagonTop:Move(wagonX, wagonY)
    wagonTop:act('idle')
    wagonTop.isAbsolute = true
    wagonTop.layer = -10
    wagonTop.oy = -96
    ObjectManager:Register(wagonTop)
end

function Init()
    initWindow()
    initWagon()
    SettingMethod.Init("settings.json")

    DataStore.update('fsm', initStateMachine())

    UIManager:add("mainPanel", require("src.UI.mainPanel")())
    UIManager:add("settingPanel", require("src.UI.settingPanel")())
    UIManager:add("customerPanel", require("src.UI.customerPanel")())
    UIManager:add("walkPanel", require("src.UI.walkPanel")())
    UIManager:add("passangerPanel", require("src.UI.passangerPanel")())

    DataStore.registerTask('map', res.jsonAsync('map.json'))

    SettingMethod.ApplyAll()
    local loadedData = SaveSystem.load()

    DataStore.update('gold', loadedData.gold or 0)
    
    if not loadedData then
        local screenW, _ = sys.getSize()
        
        grassCoroutine = genGrass.SpawnTownScenery(
            StartTownData.name, StartTownData.group, 0, screenW)
        DataStore.update('currentTown', StartTownData)
        DataStore.get('fsm'):transition("prologue")
    end
end

function Update(dt)
    if grassCoroutine and coroutine.status(grassCoroutine) ~= "dead" then
        local success, err = coroutine.resume(grassCoroutine)
        if not success then print("Coroutine Error:", err) end
    end
    ObjectManager:Update(dt)
    DataStore.get('fsm'):update(dt)
    UIManager:update(dt)
    
    local map = DataStore.get('map')

    if not DataStore.get('canvasMap') and map and DataStore.get('currentTown') then
        print("new town found: draw new town about " .. DataStore.get('currentTown').name)
        local newCanvasMap = CanvasMap
            .new(map, DataStore.get('currentTown').name, 800, 600, 4.0)
        DataStore.update('canvasMap', newCanvasMap)
        if newCanvasMap then
            DataStore.update('currentTown', newCanvasMap.centerBurg:to_table())
        end
    end
end

function Draw()
    local settings = DataStore.get('settings')
    local uiAlpha = settings.uiAlpha or 1.0

    -- 1. 게임 월드 렌더링 (배경, 캐릭터, 마차 등)
    g.push()
        local size = settings.mainSize
        g.scale(size, size, 0, sh)
        
        -- ObjectManager 내부에서 layer < -20인 객체들만 bgAlpha를 적용함
        ObjectManager:Draw()
        
        DataStore.get('fsm'):draw()
    g.pop()
    if debugger.visible then
        g.push()
            local size = DataStore.get('settings').mainSize
            g.scale(size, size, 0, sh)
            
            -- 빨간색 점과 좌표 텍스트
            g.color(255, 0, 0)
            g.circle(debugger.x, debugger.y, 3)
            g.text(0, 
                string.format("(%.0f, %.0f)", debugger.x, debugger.y), debugger.x + 5, debugger.y)
            g.color(255, 255, 255)
        g.pop()
    end
    
    -- 2. UI 렌더링 (설정창, 버튼 등)
    g.push()
        -- UI 전체 투명도 적용
        g.globalAlpha(uiAlpha) 
        
        local uiSize = settings.uiSize
        g.scale(uiSize, uiSize, 0, sh)
        
        UIManager:draw()
        
        -- 다른 곳에 영향을 주지 않도록 다시 1.0으로 복구 (pop이 해주겠지만 명시적 관리)
        g.globalAlpha(1.0)
    g.pop()
end
function OnKeyDown(key)
    if key == 0x20 then
    end
end
function OnKeyUp(key)
    if key == 0x51 then
    end
end


function OnMouseDown(x, y)
end
function OnMouseUp(x, y)
    local size = DataStore.get('settings').uiSize
    local worldX = x / size
    local worldY = (y - sh) / size + sh -- scale의 기준점(0, sh)에 따른 보정
    local clicked = UIManager:dispatchClick(worldX, worldY, "left")
    
    if not clicked then
        -- 월드 좌표로 보정 (Scale이 적용된 월드를 클릭할 때)
        size = DataStore.get('settings').mainSize
        worldX = x / size
        worldY = (y - sh) / size + sh -- scale의 기준점(0, sh)에 따른 보정
        
        DataStore.get('fsm'):click(worldX, worldY)

        if Defines.Debug then
            debugger.x = worldX
            debugger.y = worldY
            debugger.visible = true
        end
        print(worldX .. '/' .. wagonY - worldY)
    end
end
function OnRightMouseDown(x, y)
end
function OnRightMouseUp(x, y)
    local clicked = UIManager:dispatchClick(x, y, "right")
end

function OnInactive()
    UIManager:closeAll()
end
function CheckHit(x, y)
    if not (DataStore and UIManager and ObjectManager and sh) then return true end

    local settings = DataStore.get('settings')
    if not settings then return true end

    -- [추가] 1. UI 영역 체크
    local uiSize = settings.uiSize or 1.0
    local uiX, uiY = x / uiSize, (y - sh) / uiSize + sh
    
    -- UI가 떠 있고, 그 영역 안에 마우스가 있다면 클릭 접수(true)
    if UIManager.isHit and UIManager:isHit(uiX, uiY) then
        return true
    end

    -- 2. 마차 영역 체크
    local mainSize = settings.mainSize or 1.0
    local worldX, worldY = x / mainSize, (y - sh) / mainSize + sh
    local wagon = ObjectManager:Get('wagon')
    
    if wagon and wagon.anim then -- anim 존재 여부 확인 (필수)
        -- wagon.anim.fw 가 nil일 경우를 대비해 기본값 0 설정
        local fw = wagon.anim.fw or 0
        local fh = wagon.anim.fh or 0
        
        if worldX >= wagon.x and worldX <= wagon.x + fw and
           worldY <= wagon.y and worldY >= wagon.y - fh then
            return true 
        end
    end

    return false
end

function Quit()
    -- 종료 직전 자동 저장 수행
    SaveSystem.save()
    
    -- 추가적인 정리 작업이 필요하다면 여기서 수행
    print("Application is shutting down...")
end