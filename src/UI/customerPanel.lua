local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")

local UIElement = require("lib.UI.UIElement")
local UIViewport = require ("lib.UI.UIViewport")

local UIFactory = require("src.Table.UiFactory")
local Datastore = require("src.Datastore")

local traitStyles = {
    Positive = "Trait_positive", -- 녹색/금색 계열
    Negative = "Trait_negative", -- 빨간색 계열
    Neutral = "Trait"    -- 회색/흰색 계열
}

return function ()
    ---@class customerPanel: DraggablePanel
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 320, 350)
    for i = 1, 4 do
        panel:addChild(UIElement.new(0, (i - 1) * 70 + 20))
    end
    panel.currentIdx = 1

    panel.countText = UIFactory.createText(20, 310, "현재 손님: 0 / 4", "Small")
    panel:addChild(panel.countText)

    panel.onSetScroll = function (self, idx)
        self.currentIdx = idx
        local customers = ObjectManager:GetAll('is_customer')
        local boardingCount = #ObjectManager:GetAll('isBoarding')
        self.countText:setText(string.format("현재 손님: %d / 4", boardingCount))

        for i = 1, 4 do
            local customer = customers[idx + i - 1]
            local ctx = self:at(i)
            ctx.children = {}

            if customer then

                local d = customer.data 

                ctx:addChild(UIViewport.new(20, 0, 64, 64, function (x, y, w, h)
                    g.image(res.image("assets/house.png"), x, y, w, h, 32, 154, 32, 32)
                    customer.anim:drawFrame("idle", 1, x - 48, y - 20, 160, 128)
                end))
                
                -- 명칭과 상세 정보 (customer.data 참조)
                ctx:addChild(UIFactory.createText(100, 0, d.name))
                ctx:addChild(UIFactory.createText(100, 26, (d.destination or "??") .. " | " .. (d.budget or 0) .. "G", "Small"))
                
                -- 특성(Traits) 표시 로직
                -- 만약 traits가 배열 형태라면 반복문으로 처리하면 더 좋습니다.
                if d.traits and d.traits[1] then
                    ctx:addChild(UIFactory.createText(100, 44, d.traits[1], traitStyles.Positive))
                end
                if d.traits and d.traits[2] then
                    ctx:addChild(UIFactory.createText(160, 44, d.traits[2], traitStyles.Positive))
                end
                local isFull = boardingCount >= 4
                local btnText = customer.isBoarding and "환불" or "승차"
                
                local btnAction = function()
                    customer.isBoarding = not customer.isBoarding
                    -- 상태가 바뀌었으므로 다시 onSetScroll을 호출해 텍스트와 버튼 상태를 갱신
                    self:onSetScroll(idx)
                end

                -- 만원이면 승차 버튼 비활성화 (환불은 가능해야 함)
                if not customer.isBoarding and isFull then
                    btnAction = function() end -- 아무것도 안 함
                end

                local btnStyle = (not customer.isBoarding and isFull) and "Gray" or "Default"
                ctx:addChild(UIFactory.createButton("Default", 210, 20, 80, 40, btnText, btnAction, btnStyle))
                ctx:addChild(UIFactory.createPanel("Frame", 20, 0, 64, 64))
            end
        end
    end

    panel.onInit = function (self)
        local customers = ObjectManager:GetAll('is_customer')
        local totalCount = #customers
        
        -- 슬라이더 범위 설정 (최소 1로 고정하여 0이나 음수 방지)
        local scrollRange = math.max(1, totalCount - 3)
        
        -- 슬라이더가 5번째 자식(at(5))이라면 아이템 개수 갱신
        if self:at(5).setItems then
            self:at(5):setItems(Range(scrollRange))
        end
        local slider = self:at(5)
        self:onSetScroll(slider.value or 1)
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