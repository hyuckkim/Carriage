local UIManager = require("lib.UIManager")
local UIFactory = require("src.Table.UiFactory")
local Datastore = require("src.Datastore")
local UIViewport = require("lib.UI.UIViewport")

---@param self DraggablePanel
local function redraw(self)
    local map = Datastore.get('canvasMap')
    local currentTown = Datastore.get('currentTown')
    if not map or not currentTown then return end

    local startBtn = self:at(1)
    local locationText = self:at(7)
    local distanceText = self:at(8)
    local legendText = self:at(9)

    local isSelected = (map.selectedBurg and map.selectedBurg.name ~= currentTown.name)
    local targetTown = isSelected and map.selectedBurg or currentTown

    -- 1. 전역 설명(Legend) 갱신
    legendText.text = targetTown and targetTown.legend or "상세 정보가 없습니다."
    if isSelected then
        startBtn.color = { 255, 255, 255 }
        locationText.text = currentTown.name .. " -> " .. map.selectedBurg.name
        
        -- 거리 및 시간 계산
        local dist, unit = map:getRealDistance(currentTown.x, currentTown.y, map.selectedBurg.x, map.selectedBurg.y)
        local wagonSpeedKmh = 15 
        local travelTimeHours = dist / wagonSpeedKmh
        local totalMinutes = math.floor(travelTimeHours * 60)
        local remainingSeconds = math.floor((travelTimeHours * 3600) % 60)

        distanceText.text = string.format("%.1f %s | 약 %d분 %02d초 소요", 
            dist, unit, totalMinutes, remainingSeconds)
    else
        startBtn.color = { 100, 100, 100 }
        locationText.text = currentTown.name
        distanceText.text = "현재 위치" 
        -- 선택된 게 현재 마을과 같다면 선택 해제 처리
        if map.selectedBurg and map.selectedBurg.name == currentTown.name then
            map.selectedBurg = nil 
        end
    end
end

return function ()
    ---@class mainPanel: DraggablePanel
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 405, 300)

    -- 1: 출발 버튼
    panel:addChild(UIFactory.createButton("Default", 215, 10, 180, 50, "출발", function()
        local map = Datastore.get('canvasMap')
        if not map or not map.selectedBurg then return end
        Datastore.get('fsm'):transition("walk")
        UIManager:closeAll()
    end, "Gray"))

    -- 2~5: 기타 버튼들
    panel:addChild(UIFactory.createButton("Default", 215, 60, 180, 50, "손님 받기", function()
        UIManager:open('customerPanel')
    end))
    panel:addChild(UIFactory.createButton("Default", 215, 110, 180, 50, "물품 구매", function()
        print("물품 구매 클릭")
    end))
    panel:addChild(UIFactory.createButton("Default", 215, 190, 180, 50, "환경설정", function()
        UIManager:open('settingPanel')
    end))
    panel:addChild(UIFactory.createButton("Default", 215, 240, 180, 50, "게임 종료", function()
        sys.quit()
    end))

    -- 6: 지도 뷰포트
    panel:addChild(UIViewport.new(10, 10, 200, 150, function (x, y, w, h)
        local map = Datastore.get('canvasMap')
        if map then
            map:Draw(x, y, w, h, 200, 150, 400, 300)
        end
    end, function (x, y, button)
        local map = Datastore.get('canvasMap')
        local currentTown = Datastore.get('currentTown')
        if map and currentTown then
            local town = map:getClickTown(x, y, 200, 150, 200, 150, 400, 300)
            if not town then redraw(panel) return end

            -- 경로가 있는지 확인 (findRoadPathWithLimit 활용)
            local route = map:findRoadPathWithLimit(town.name, currentTown.name)
            if not route or town.name == currentTown.name then
                map.selectedBurg = nil
            else
                map.selectedBurg = town
            end
            redraw(panel)
        end
    end))

    -- 7: 마을 이름 텍스트 (지도 바로 아래)
    panel:addChild(UIFactory.createText(10, 170, "마을 이름", "Default"))
    
    -- 8: 거리 표시 텍스트 (이름 아래 작게)
    panel:addChild(UIFactory.createText(10, 195, "0.0 km", "Small"))
    panel:addChild(UIFactory.createText(10, 220, "설명 정보", "Small"))

    panel.onInit = function (self)
        redraw(self)
    end
    
    panel.visible = false
    return panel
end