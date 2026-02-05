WindowTitle = "wagon"

local UIManager = require("lib.UIManager")
local UIFactory = require("src.UIFactory")
local UIElement = require("lib.UIElement")
local CharacterFactory = require "src.CharacterFactory"
local UIViewport = require "lib.UIViewport"

local sw, sh -- 창 위치
local wagonX, wagonY -- 마차 위치
local character

local mainStateMachine = require("src.mainStateMachine")
local customers = require("src.Datastore").customers
local fsm

local mainSize = 1.5

local mainPanel
local settingPanel
local customerPanel

local function initWindow()
    sw, sh = sys.getWorkArea()
    sys.setSize(sw, sh)
    sys.setPos(0, 0)
    sys.setCursor()
end

local function initWagon()
    wagonX = 0
    wagonY = sh - 96
end


function Range(n)
    local t = {}
    for i = 1, n do
        t[i] = i
    end
    return t
end

local traitStyles = {
    Positive = "Trait_positive", -- 녹색/금색 계열
    Negative = "Trait_negative", -- 빨간색 계열
    Neutral = "Trait"    -- 회색/흰색 계열
}

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
            local ctx = self:at(i)
            
            ctx.children = {}

            ctx:addChild(UIViewport.new(20, 0, 64, 64, function (x, y, w, h)
                g.image(res.image("assets/house.png"), x, y, w, h, 32, 154, 32, 32)
                customer:draw(x - 48, y - 20, 160, 128)
            end))

            ctx:addChild(UIFactory.createText(100, 0, customer.name))
            ctx:addChild(UIFactory.createText(100, 26, customer.dest .. " | " .. customer.fee .. "G", "Small"))
            ctx:addChild(UIFactory.createText(100, 44, customer.trait1.name, traitStyles[customer.trait1.type]))
            ctx:addChild(UIFactory.createText(160, 44, customer.trait2.name, traitStyles[customer.trait2.type]))
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
        self:at(5):setItems(Range(#customers - 3))
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
    fsm = mainStateMachine:init(wagonX, wagonY)
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
