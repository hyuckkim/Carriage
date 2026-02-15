local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")
local UIElement = require("lib.UI.UIElement")
local UIViewport = require("lib.UI.UIViewport")
local UIFactory = require("src.Table.UiFactory")

return function ()
    ---@class passengerPanel: DraggablePanel
    -- 스크롤이 없으므로 폭을 조금 줄이고 높이는 4명 분량에 맞췄습니다.
    local panel = UIFactory.createDraggablePanel("Default", 300, 830, 300, 330)

    -- 상단 제목
    panel:addChild(UIFactory.createText(20, 15, "현재 탑승객 명단", "Default"))

    -- 4개의 손님 슬롯 미리 생성 (y: 45부터 65px 간격으로 배치)
    for i = 1, 4 do
        panel:addChild(UIElement.new(0, (i - 1) * 65 + 45))
    end

    -- 실시간 탑승객 정보 갱신 함수
    panel.onUpdate = function (self)
        -- 1. 탑승 중인 손님만 필터링
        local allCustomers = ObjectManager:GetAll('is_customer')
        local passengers = {}
        for _, c in ipairs(allCustomers) do
            if c.isBoarding then
                table.insert(passengers, c)
            end
        end

        -- 2. 4개의 슬롯 업데이트
        for i = 1, 4 do
            local ctx = self:at(i + 1) -- 첫번째 자식은 제목이므로 i+1
            ctx.children = {} -- 이전 렌더링 초기화
            
            local p = passengers[i]
            if p then
                local d = p.data
                -- [초상화 영역]
                ctx:addChild(UIViewport.new(20, 0, 50, 50, function (x, y, w, h)
                    -- 배경 박스
                    g.image(res.image("assets/house.png"), x, y, w, h, 32, 154, 32, 32)
                    -- 손님 애니메이션 (크기 살짝 조정)
                    p.anim:drawFrame("idle", 1, x - 35, y - 15, 120, 96)
                end))
                ctx:addChild(UIFactory.createPanel("Frame", 20, 0, 50, 50))

                -- [정보 영역]
                ctx:addChild(UIFactory.createText(85, 0, d.name, "Default"))
                ctx:addChild(UIFactory.createText(85, 24, "목적지: " .. (d.destination or "??"), "Small"))
                
                -- 특성(Traits) 표시 (공간 확보를 위해 간략히 표시)
                if d.traits and d.traits[1] then
                    local trait = d.traits[1]
                    local tName = type(trait) == "table" and trait.name or trait
                    local tType = type(trait) == "table" and trait.type or "Neutral"
                    ctx:addChild(UIFactory.createText(85, 42, tName, tType))
                end
                if d.traits and d.traits[2] then
                    local trait = d.traits[2]
                    local tName = type(trait) == "table" and trait.name or trait
                    local tType = type(trait) == "table" and trait.type or "Neutral"
                    ctx:addChild(UIFactory.createText(145, 42, tName, tType))
                end
            else
                -- 빈 슬롯 표시 (선택 사항)
                ctx:addChild(UIFactory.createText(85, 15, "(빈 좌석)", "Gray"))
            end
        end
    end

    -- 닫기 버튼 (중앙 하단)
    panel:addChild(UIFactory.createButton("Default", 215, 290, 80, 35, "닫기", function()
        panel.visible = false
    end))

    panel.visible = false
    return panel
end