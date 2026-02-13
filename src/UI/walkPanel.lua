local UIManager = require("lib.UIManager")
local UIFactory = require("src.Table.UiFactory")
local DataStore = require("src.Datastore")
local UIViewport = require("lib.UI.UIViewport")

return function ()
    ---@class walkPanel: DraggablePanel
    -- 지도가 들어가야 하므로 가로를 다시 220 정도로 유지하고 높이를 조금 넉넉히 잡습니다.
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 220, 380)

    -- 1: 다시 돌아온 이쁜 지도 (여정 실시간 표시)
    panel:addChild(UIViewport.new(10, 10, 200, 150, function (x, y, w, h)
        local map = DataStore.get('canvasMap')
        -- 주의: WalkState에서 canvasMap을 nil로 밀어버렸다면, 
        -- 그리기용 맵 참조를 따로 유지하거나 여기서 다시 가져와야 합니다.
        if map then
            map:Draw(x, y, w, h, 200, 150, 400, 300)
        end
        
        -- 여기에 마차 위치를 찍어주는 커스텀 드로우 로직을 추가하면 더 이쁘겠죠?
    end, function (x, y, button) end))

    -- 2: 주행 상태 및 골드 (지도 바로 아래)
    local statusText = UIFactory.createText(10, 170, "이동 중...", "Default")
    panel:addChild(statusText)

    local goldText = UIFactory.createText(10, 195, "0 Gold", "Small")
    goldText.color = { 255, 215, 0 }
    panel:addChild(goldText)

    -- 3: 진행률 바 (Visual Bar)
    -- 배경
    panel:addChild(UIFactory.createPanel("Gray", 10, 225, 200, 8))
    -- 게이지
    local progressBar = UIFactory.createPanel("White", 10, 225, 0, 8)
    panel:addChild(progressBar)

    -- 4: 상세 수치 (남은 거리)
    local distText = UIFactory.createText(10, 240, "계산 중...", "Small")
    panel:addChild(distText)

    -- 5: 하단 버튼
    panel:addChild(UIFactory.createButton("Default", 10, 320, 200, 45, "게임 종료", function()
        SaveSystem.save()
        sys.quit()
    end))

    -- 실시간 데이터 업데이트
panel.onUpdate = function (self)
        local progress = DataStore.get('walkProgress')
        
        -- 1. 골드 표시 (소수점 버림 및 G 단위)
        local gold = DataStore.get('gold') or 0
        goldText.text = string.format("%d Gold", math.floor(gold))

        if progress then
            -- 2. 게이지 갱신
            local ratio = math.min(progress.current / progress.target, 1)
            progressBar.width = 200 * ratio

            -- 3. 남은 거리 텍스트 (픽셀 -> km 변환)
            -- WalkState 기준 1km = 13440px
            local remainingPx = math.max(0, progress.target - progress.current)
            local remainingKm = remainingPx / 13440
            
            -- 소수점 첫째 자리까지 표시
            distText.text = string.format("남은 거리: %.2f km", remainingKm)

            -- 4. 감속 구간 피드백 (약 0.1km 이내일 때)
            if remainingPx < 1000 then
                statusText.text = "마을 진입 중!"
                statusText.color = { 150, 255, 150 }
            end
        end
    end

    panel.visible = false
    return panel
end