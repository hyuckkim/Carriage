WindowTitle = "wagon"

local UIManager = require("lib.UIManager")
local UIFactory = require("lib.UIFactory")
local Anim = require "lib.anim"
local StateMachine = require "lib.statemachine"

local sw, sh -- 창 위치
local wagonX, wagonY -- 마차 위치
local fontMain
local character
local workthrough = 0

local fsm = StateMachine.new()
local wagonAnim

local mainPanel

local function initWindow()
    sw, sh = sys.getWorkArea()
    sys.setSize(sw, sh)
    sys.setPos(0, 0)
    sys.setCursor()
    fontMain = res.fontFile("assets/NanumSquareRoundR.ttf", "나눔스퀘어라운드 Regular", 20)
end

local function initWagon()
    wagonX = 0
    wagonY = sh - 96
    wagonAnim = Anim.new(res.image("assets/wagon_sheet.png"), 272, 96, 8)

    wagonAnim:add("walk", {0, 1, 2, 3, 4, 5}, 100, true)
    wagonAnim:add("run", {8, 9, 10, 11, 12, 13}, 100, true)
    wagonAnim:add("idle", {16, 17, 18, 19, 20, 21, 22, 23}, 100, true)
    wagonAnim:add("feed", {24, 25, 26, 27, 28, 29, 30, 31}, 100, true)

    character = Anim.new(res.image("assets/wagon_woman.png"), 64, 64, 8)
    character:add("idle", {0, 1, 2, 3, 4}, 100, true)
    character:add("any", {8, 9, 10, 11, 12, 13, 14, 15}, 100, true)
end

local function initStateMachine()
    fsm = StateMachine.new()
    fsm:addState("idle", {
        onEnter = function() 
            wagonAnim:play("idle")
            character:play("idle")
            mainPanel.visible = true
        end,
        onUpdate = function(dt)
            wagonAnim:update(dt)
            character:update(dt)
        end,
        onExit = function()

        end,
        onDraw = function()
            wagonAnim:draw(wagonX, wagonY)
            character:draw(wagonX + 120, wagonY + 32, 64, 64)
        end
    })
    fsm:addState("walk", {
        onEnter = function() 
            wagonAnim:play("walk")
            workthrough = 0
        end,
        onUpdate = function(dt)
            wagonAnim:update(dt)
            workthrough = workthrough + dt
            if (workthrough >= 5000) then
                fsm:transition('idle')
            end
        end,
        onExit = function()

        end,
        onDraw = function()
            wagonAnim:draw(wagonX, wagonY)
            g.color(0, 0, 0)
            g.rect(wagonX + 10, wagonY - 50, 200, 5)
            g.color(255, 255, 255)
            g.rect(wagonX + 10, wagonY - 50, 200 / 5000 * workthrough, 5)
        end
    })
end

local function initUI()
    mainPanel = UIFactory.createDraggablePanel("Default", 300, 700, 200, 300)
    mainPanel:addChild(UIFactory.createButton("Default", 20, 50, 160, 50, "출발", function()
        fsm:transition("walk")
        mainPanel.visible = false
    end))
    mainPanel:addChild(UIFactory.createButton("Default", 20, 100, 160, 50, "손님 받기", function()
        print("Child Button Clicked!")
    end))
    mainPanel:addChild(UIFactory.createButton("Default", 20, 100, 160, 50, "물품 구매", function()
        print("Child Button Clicked!")
    end))
    mainPanel:addChild(UIFactory.createButton("Default", 20, 150, 160, 50, "게임 종료", function()
        sys.quit()
    end))

    UIManager:add(mainPanel)
end

function Init()
    initWindow()
    initWagon()
    initStateMachine()
    initUI()
    fsm:transition("idle")
end

function Update(dt)
    fsm:update(dt)
    UIManager:update(dt)
end

function OnKeyDown(key)
    if key == 0x20 then
    end
end
function OnKeyUp(key)
    if key == 0x51 then
    end
end

function Draw()
    fsm:draw()
    UIManager:draw()
end

function OnMouseDown(x, y)
end
function OnMouseUp(x, y)
    local clicked = UIManager:dispatchClick(x, y, "left")
end
function OnRightMouseDown(x, y)
end
function OnRightMouseUp(x, y)
    local clicked = UIManager:dispatchClick(x, y, "right")
end
