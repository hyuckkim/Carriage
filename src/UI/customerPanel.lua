local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")

local UIElement = require("lib.UI.UIElement")
local UIViewport = require ("lib.UI.UIViewport")

local UIFactory = require("src.UiFactory")
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

    panel.onSetScroll = function (self, idx)
        self.currentIdx = idx
        -- 범용 필터링 함수 사용
        local customers = ObjectManager:GetAll('is_customer')
        
        for i = 1, 4 do
            local customer = customers[idx + i - 1]
            local ctx = self:at(i)
            ctx.children = {}

            if customer then
                -- 데이터는 이제 customer.data 안에 있습니다.
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

                -- 승차/환불 버튼
                ctx:addChild(UIFactory.createButton("Default", 210, 20, 80, 40,
                customer.isBoarding and "환불" or "승차", function()
                    customer.isBoarding = not customer.isBoarding
                    self:onSetScroll(idx)
                end))
                
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