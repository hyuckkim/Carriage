require('src.globals')

WindowTitle = "wagon"
local UIManager = require("lib.UIManager")
local Datastore = require("src.Datastore")
local mainStateMachine = require("src.mainStateMachine")

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
    Datastore.update('fsm', mainStateMachine:init(wagonX, wagonY))

    UIManager:add("mainPanel", require("src.UI.mainPanel")())
    UIManager:add("settingPanel", require("src.UI.settingPanel")())
    UIManager:add("customerPanel", require("src.UI.customerPanel")())

    Datastore.fsm:transition("idle")
end

function Update(dt)
    Datastore.fsm:update(dt)
    UIManager:update(dt)
end

function Draw()
    g.push()
        local size = Datastore.settings.mainSize
        g.scale(size, size, 0, sh)
        Datastore.fsm:draw()
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
    local clicked = UIManager:dispatchClick(x, y, "left")
    if not clicked then
        UIManager:open('mainPanel')
    end
end
function OnRightMouseDown(x, y)
end
function OnRightMouseUp(x, y)
    local clicked = UIManager:dispatchClick(x, y, "right")
end
