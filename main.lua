WindowTitle = "wagon"

local UIManager = require("lib.UIManager")
local UIFactory = require("lib.UIFactory")
local UIElement = require("lib.UIElement")
local Anim = require "lib.anim"
local StateMachine = require "lib.statemachine"
local CharacterFactory = require "lib.CharacterFactory"
local UIViewport = require "lib.UIViewport"

local sw, sh -- 창 위치
local wagonX, wagonY -- 마차 위치
local character
local workthrough = 0

local fsm = StateMachine.new()
local wagonAnim
local topAnim

local mainSize = 1.5

local mainPanel
local settingPanel
local customerPanel

local characters = {}
local customers = {}

local function initWindow()
    sw, sh = sys.getWorkArea()
    sys.setSize(sw, sh)
    sys.setPos(0, 0)
    sys.setCursor()
end

local function initWagon()
    wagonX = 0
    wagonY = sh - 96
    wagonAnim = Anim.new(res.image("assets/wagon_sheet.png"), 272, 96, 8)
    wagonAnim:add("walk", {0, 1, 2, 3, 4, 5}, 100, true)
    wagonAnim:add("run", {8, 9, 10, 11, 12, 13}, 100, true)
    wagonAnim:add("feed", {16, 17, 18, 19, 20, 21, 22, 23}, 100, true)
    wagonAnim:add("idle", {24, 25, 26, 27, 28, 29, 30, 31}, 100, true)

    topAnim = Anim.new(res.image("assets/wagon_top.png"), 272, 96, 8)
    topAnim:add("walk", {0, 1, 2, 3, 4, 5}, 100, true)
    topAnim:add("run", {8, 9, 10, 11, 12, 13}, 100, true)
    topAnim:add("feed", {16, 17, 18, 19, 20, 21, 22, 23}, 100, true)
    topAnim:add("idle", {24, 25, 26, 27, 28, 29, 30, 31}, 100, true)

    character = Anim.new(res.image("assets/wagon_woman.png"), 64, 64, 8)
    character:add("idle", {0, 1, 2, 3, 4}, 100, true)
    character:add("walk", {8, 9, 10, 11, 12, 13, 14, 15}, 100, true)
end

local function initStateMachine()
    fsm = StateMachine.new()
    fsm:addState("idle", {
        onEnter = function() 
            wagonAnim:play("idle")
            character:play("idle")
            topAnim:play("idle")
            customers = {
                CharacterFactory.create(),
                CharacterFactory.create(),
                CharacterFactory.create(),
                CharacterFactory.create(),
                CharacterFactory.create(),
                CharacterFactory.create(),
                CharacterFactory.create(),
                CharacterFactory.create()
            }
        end,
        onUpdate = function(dt)
            wagonAnim:update(dt)
            character:update(dt)
            characters[1]:update(dt)
            characters[2]:update(dt)
            characters[3]:update(dt)
            characters[4]:update(dt)
            topAnim:update(dt)
        end,
        onExit = function()

        end,
        onDraw = function()
            wagonAnim:draw(wagonX, wagonY)
            character:draw(wagonX + 120, wagonY + 32, 64, 64)
            characters[1]:draw(15, wagonY + 6, 80, 64)
            characters[2]:draw(40, wagonY + 9, 80, 64)
            characters[3]:draw(65, wagonY + 8, 80, 64)
            characters[4]:draw(80, wagonY + 6, 80, 64)
            topAnim:draw(wagonX, wagonY)
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
    mainPanel = UIFactory.createDraggablePanel("Default", 300, 700, 400, 300)
    mainPanel:addChild(UIFactory.createButton("Default", 210, 10, 180, 50, "출발", function()
        fsm:transition("walk")
        UIManager:closeAll()
    end))
    mainPanel:addChild(UIFactory.createButton("Default", 210, 60, 180, 50, "손님 받기", function()
        UIManager:open(customerPanel)
    end))
    mainPanel:addChild(UIFactory.createButton("Default", 210, 110, 180, 50, "물품 구매", function()
        print("Child Button Clicked!")
    end))
    mainPanel:addChild(UIFactory.createButton("Default", 210, 190, 180, 50, "환경설정", function()
        UIManager:open(settingPanel)
    end))
    mainPanel:addChild(UIFactory.createButton("Default", 210, 240, 180, 50, "게임 종료", function()
        sys.quit()
    end))

    UIManager:add(mainPanel)
    UIManager:close(mainPanel)

    settingPanel = UIFactory.createDraggablePanel("Default", 300, 700, 200, 300)
    settingPanel:addChild(UIFactory.createText(20, 15, "환경설정"))
    settingPanel:addChild(UIFactory.createText(20, 60, "게임 크기 배수: 1.5x", 'Small'))
    settingPanel:addChild(UIFactory.createSlider(20, 90, 160, 10, { 1, 1.5, 2, 3, 4 }, function (v)
        mainSize = v
        settingPanel:at(2):setText("게임 크기 배수: " .. v .. "x")
    end, 2))
    settingPanel:addChild(UIFactory.createButton("Default", 110, 250, 80, 40, "완료", function()
        UIManager:close(settingPanel)
    end))

    UIManager:add(settingPanel)
    UIManager:close(settingPanel)

    customerPanel = UIFactory.createDraggablePanel("Default", 300, 700, 320, 350)

    for i = 1, 4 do
        customerPanel:addChild(UIElement.new(0, (i - 1) * 70 + 20, 300, 70))
    end
    customerPanel.onSetScroll = function (self, idx)
        self.currentIdx = idx
        for i = 1, 4 do
            local customer = customers[idx + i - 1]
            local ctx = customerPanel:at(i)
            
            ctx.children = {}

            ctx:addChild(UIViewport.new(20, 0, 64, 64, function (x, y, w, h)
                g.image(res.image("assets/house.png"), x, y, w, h, 32, 154, 32, 32)
                customer:draw(x - 48, y - 20, 160, 128)
            end))

            ctx:addChild(UIFactory.createText(100, 0, "김철수"))
            ctx:addChild(UIFactory.createText(100, 26, "안산 | 45G", "Small"))
            ctx:addChild(UIFactory.createText(100, 44, "애주가", "Trait"))
            ctx:addChild(UIFactory.createText(160, 44, "술꾼", "Trait_negative"))
            ctx:addChild(UIFactory.createButton("Default", 210, 20, 80, 40,
            customer.isBoarding and "환불" or "승차", function()
                print("boarding clicked")
                customer.isBoarding = not customer.isBoarding
                self:onSetScroll(idx)
            end))
            
            ctx:addChild(UIFactory.createPanel("Frame", 20, 0, 64, 64))
        end
    end
    customerPanel.onInit = function (self)
        self:onSetScroll(1)
    end

    customerPanel:addChild(UIFactory.createSlider(300, 10, 10, 280, {1, 2, 3, 4, 5}, function(v)
        customerPanel:onSetScroll(v)
    end))
    customerPanel:addChild(UIFactory.createButton("Default", 230, 300, 80, 40, "완료", function()
        UIManager:close(customerPanel)
    end))
    UIManager:add(customerPanel)
    UIManager:close(customerPanel)
end

function Init()
    initWindow()
    initWagon()
    initStateMachine()
    initUI()

    characters[1] = CharacterFactory.create()
    characters[1].flipX = true
    characters[2] = CharacterFactory.create()
    characters[2].flipX = true
    characters[3] = CharacterFactory.create()
    characters[4] = CharacterFactory.create()
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
    g.push()
        g.scale(mainSize, mainSize, 0, sh)
        fsm:draw()
    g.pop()
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
    if not clicked then
        UIManager:open(mainPanel)
    end
end
