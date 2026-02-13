local UIManager = require("lib.UIManager")
local UIFactory = require("src.Table.UiFactory")
local DataStore = require("src.Datastore")
local UIViewport = require("lib.UI.UIViewport")

return function ()
    ---@class walkPanel: DraggablePanel
    -- 가로를 420으로 늘려 3구역 공간 확보 (지도 200 / 정보 200 / 여백 및 정렬)
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 420, 200)

    -- [1구역: 왼쪽 - 시각적 정보 (지도)]
    panel:addChild(UIViewport.new(10, 10, 200, 150, function (x, y, w, h)
        local map = DataStore.get('canvasMap')
        if map then
            map:Draw(x, y, w, h, 200, 150, 400, 300)
        end
    end, function (x, y, button) end))

    -- [2구역: 중앙 - 수치 정보 (자산 및 주행)]
    -- 제목/상태
    local statusText = UIFactory.createText(220, 15, "주행 중", "Default")
    panel:addChild(statusText)

    -- 골드 (자산)
    local goldText = UIFactory.createText(220, 45, "0 G", "Small")
    goldText.color = { 255, 215, 0 }
    panel:addChild(goldText)

    -- 거리 (km)
    local distText = UIFactory.createText(220, 95, "잔여: 0.00 km", "Small")
    panel:addChild(distText)

    -- [3구역: 오른쪽 - 제어 (버튼)]
    -- 가로가 넓어졌으므로 버튼을 우측에 세로로 배치하거나 하단에 배치할 수 있습니다.
    -- 여기서는 대시보드 느낌을 살려 우측 끝에 배치합니다.
    panel:addChild(UIFactory.createButton("Default", 220, 130, 180, 45, "게임 종료", function()
        SaveSystem.save()
        sys.quit()
    end))

    -- 실시간 데이터 업데이트
    panel.onUpdate = function (self)
        local progress = DataStore.get('walkProgress')
        
        -- 1. 골드 갱신
        local gold = DataStore.get('gold') or 0
        goldText.text = string.format("%d Gold", math.floor(gold))

        if progress then

            -- 3. 거리 갱신 (km)
            local remainingPx = math.max(0, progress.target - progress.current)
            local remainingKm = remainingPx / 13440
            distText.text = string.format("잔여: %.2f km", remainingKm)

            -- 4. 상태 변화 피드백
            if remainingPx < 1000 then
                statusText.text = "도착 임박!"
                statusText.color = { 150, 255, 150 }
            else
                statusText.text = "주행 중"
                statusText.color = { 255, 255, 255 }
            end
        end
    end

    panel.visible = false
    return panel
end