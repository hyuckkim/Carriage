local UIManager = require("lib.UIManager")

local UIElement = require("lib.UI.UIElement")
local UIViewport = require ("lib.UI.UIViewport")

local UIFactory = require("src.UiFactory")
local customers = require("src.Datastore").customers

local traitStyles = {
    Positive = "Trait_positive", -- 녹색/금색 계열
    Negative = "Trait_negative", -- 빨간색 계열
    Neutral = "Trait"    -- 회색/흰색 계열
}

return function ()
    ---@class CustomerPanel: DraggablePanel
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 320, 350)
    for i = 1, 4 do
        panel:addChild(UIElement.new(0, (i - 1) * 70 + 20, 300, 70))
    end
    panel.currentIdx = 1

    panel.onSetScroll = function (self, idx)
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
    panel.onInit = function (self)
        self:at(5):setItems(Range(#customers - 3))
        self:onSetScroll(1)
    end

    panel:addChild(UIFactory.createSlider(300, 10, 10, 280, {1, 2, 3, 4, 5}, function(v)
        panel:onSetScroll(v)
    end))
    panel:addChild(UIFactory.createButton("Default", 230, 300, 80, 40, "완료", function()
        UIManager:close(panel)
    end))

    panel.visible = false
    return panel
end