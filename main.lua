require('src.globals')

WindowTitle = "wagon"
local ObjectManager = require("lib.ObjectManager")
local UIManager = require("lib.UIManager")
local DataStore = require("src.Datastore")
local mainStateMachine = require("src.mainStateMachine")
local CanvasMap = require("src.UI.canvasMap")
local Character = require("src.Object.character")
local CharacterFactory = require("src.CharacterFactory")

local sw, sh -- 창 위치
local wagonX, wagonY -- 마차 위치

local function initWindow()
    sw, sh = sys.getWorkArea()
    sys.setSize(sw, sh)
    sys.setPos(0, 0)
    sys.setCursor()
end
local SETTINGS_PATH = "settings.json"
local function initSettings()
    
    local loaded = res.loadTable(SETTINGS_PATH)
    if loaded then
        DataStore.update('settings', loaded)
    else
        DataStore.update('settings', { mainSize = 1.5, uiSize = 1.0, topmost = true, monitor = 1 })
        loaded = DataStore.get('settings')
    end
    sys.setTopmost(loaded.topmost)

    local monitorIdx = loaded.monitor
    local monitors = sys.getMonitors()
    if monitorIdx > #monitors then monitorIdx = 1 end
    local m = monitors[monitorIdx]
    sys.setPos(m.workX, m.workY)
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
local debugger

function Init()
    initWindow()
    initSettings()
    initWagon()

    DataStore.update('fsm', mainStateMachine:init(wagonX, wagonY))

    UIManager:add("mainPanel", require("src.UI.mainPanel")())
    UIManager:add("settingPanel", require("src.UI.settingPanel")())
    UIManager:add("customerPanel", require("src.UI.customerPanel")())

    DataStore.get('fsm'):transition("idle")
    DataStore.registerTask('map', res.jsonAsync('map.json'))

    
    debugger = CharacterFactory.createCustomer({
        x = 0, y = 0
    })
    debugger.layer = -14
    ObjectManager:Register(debugger)
end

function Update(dt)
    ObjectManager:Update(dt)
    DataStore.get('fsm'):update(dt)
    UIManager:update(dt)
    
    local map = DataStore.get('map')

    if not DataStore.get('canvasMap') and map then
        local newCanvasMap = CanvasMap
            .new(map, 'Buyana', 800, 600, 4.0)
        DataStore.update('canvasMap', newCanvasMap)
        DataStore.update('currentTown', newCanvasMap:getNameTown('Buyana'))
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
