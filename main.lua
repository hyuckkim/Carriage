require('src.globals')

WindowTitle = "wagon"
local ObjectManager = require("lib.ObjectManager")
local UIManager = require("lib.UIManager")
local DataStore = require("src.Datastore")
local mainStateMachine = require("src.mainStateMachine")
local CanvasMap = require("src.UI.canvasMap")
local Character = require("src.Object.character")
local CharacterFactory = require("src.CharacterFactory")
local SettingMethod = require("src.SettingMethod")
local genGrass = require("src.GenGrass")

local sw, sh -- 창 위치
local wagonX, wagonY -- 마차 위치
local grassCoroutine = nil

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
local function initGrass()
    local town = DataStore.get('currentTown')
    
    -- 혹시라도 마을 데이터가 아직 로드되지 않았을 경우를 대비해 기본값 설정
    local townName = town and town.name or "대음"
    
    -- 2. 화면 사이즈 확인
    local screenW, _ = sys.getSize()
    local startX = 0
    local range = screenW
    
    grassCoroutine = genGrass.SpawnTownScenery(townName, startX, range)
end

local debugger

function Init()
    initWindow()
    initWagon()
    initGrass()
    SettingMethod.Init("settings.json")

    DataStore.update('fsm', mainStateMachine:init(wagonX, wagonY))

    UIManager:add("mainPanel", require("src.UI.mainPanel")())
    UIManager:add("settingPanel", require("src.UI.settingPanel")())
    UIManager:add("customerPanel", require("src.UI.customerPanel")())

    DataStore.get('fsm'):transition("idle")
    DataStore.registerTask('map', res.jsonAsync('map.json'))

    SettingMethod.ApplyAll()
    debugger = CharacterFactory.createCustomer({
        x = 0, y = 0
    })
    debugger.layer = -14
    ObjectManager:Register(debugger)
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

    if not DataStore.get('canvasMap') and map then
        local newCanvasMap = CanvasMap
            .new(map, '대음', 800, 600, 4.0)
        DataStore.update('canvasMap', newCanvasMap)
        DataStore.update('currentTown', newCanvasMap:getNameTown('대음'))
    end
end

function Draw()
    g.push()
        local size = DataStore.get('settings').mainSize
        g.scale(size, size, 0, sh)
        ObjectManager:Draw()
        DataStore.get('fsm'):draw()
    g.pop()
    g.push()
        size = DataStore.get('settings').uiSize
        g.scale(size, size, 0, sh)
        UIManager:draw()
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

        debugger.x = worldX
        debugger.y = worldY
        debugger.anim.flipX = not debugger.anim.flipX
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