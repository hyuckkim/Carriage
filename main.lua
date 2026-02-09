require('src.globals')

WindowTitle = "wagon"
local ObjectManager = require("lib.ObjectManager")
local UIManager = require("lib.UIManager")
local DataStore = require("src.Datastore")
local mainStateMachine = require("src.mainStateMachine")
local CanvasMap = require("src.UI.canvasMap")

local sw, sh -- 창 위치
local wagonX, wagonY -- 마차 위치

local function initWindow()
    sw, sh = sys.getWorkArea()
    sys.setSize(sw, sh)
    sys.setPos(0, 0)
    sys.setCursor()
end


function Init()
    initWindow()
    wagonX = 0
    wagonY = sh - 96
    DataStore.update('fsm', mainStateMachine:init(wagonX, wagonY))

    UIManager:add("mainPanel", require("src.UI.mainPanel")())
    UIManager:add("settingPanel", require("src.UI.settingPanel")())
    UIManager:add("customerPanel", require("src.UI.customerPanel")())

    DataStore.get('fsm'):transition("prologue")
    DataStore.registerTask('map', res.jsonAsync('map.json'))
end

function Update(dt)
    ObjectManager:Update(dt)
    DataStore.get('fsm'):update(dt)
    UIManager:update(dt)
    
    local map = DataStore.get('map')

    if not DataStore.get('canvasMap') and map then
        DataStore.update('canvasMap', CanvasMap
            .new(map, 'Buyana', 800, 600, 4.0))
    end
end

function Draw()
    g.push()
        local size = DataStore.get('settings').mainSize
        g.scale(size, size, 0, sh)
        ObjectManager:Draw()
        DataStore.get('fsm'):draw()
    g.pop()
    UIManager:draw()
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
    -- UI는 보통 화면 고정(Overlay)이므로 그대로 처리
    local clicked = UIManager:dispatchClick(x, y, "left")
    
    if not clicked then
        -- 월드 좌표로 보정 (Scale이 적용된 월드를 클릭할 때)
        local size = DataStore.get('settings').mainSize
        local worldX = x / size
        local worldY = (y - sh) / size + sh -- scale의 기준점(0, sh)에 따른 보정
        
        DataStore.get('fsm'):click(worldX, worldY)
    end
end
function OnRightMouseDown(x, y)
end
function OnRightMouseUp(x, y)
    local clicked = UIManager:dispatchClick(x, y, "right")
end
