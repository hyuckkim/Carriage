local UIManager = require("lib.UIManager")
local UIFactory = require("src.Table.UiFactory")
local DataStore = require("src.Datastore")
local UIViewport = require("lib.UI.UIViewport")
local Icons = require("src.Table.Icons")
local SaveSystem = require("src.SaveSystem")
local Sounds = require("src.Sounds")
local CanvasMap = require("src.UI.canvasMap")

return function ()
    ---@class walkPanel: DraggablePanel
    -- 가로를 420으로 늘려 3구역 공간 확보 (지도 200 / 정보 200 / 여백 및 정렬)
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 420, 200)

    -- [1구역: 왼쪽 - 시각적 정보 (지도)]
    panel.mapOffsetX = 200
    panel.mapOffsetY = 150
    local MAP_W, MAP_H = 400, 300
    local VIEW_W, VIEW_H = 200, 150

    panel:addChild(UIViewport.new(10, 10, 200, 150, function (x, y, w, h)
        local map = DataStore.get('canvasMap')
        if map then
            map:Draw(x, y, w, h, panel.mapOffsetX, panel.mapOffsetY, MAP_W, MAP_H)
        end
    end, function (x, y, button)
        panel.mapOffsetX = panel.mapOffsetX + x - VIEW_W / 2
        panel.mapOffsetY = panel.mapOffsetY + y - VIEW_H / 2
        panel.mapOffsetX = math.max(0,
            math.min(panel.mapOffsetX, MAP_W)
        )
        panel.mapOffsetY = math.max(0,
            math.min(panel.mapOffsetY, MAP_H)
        )
    end))

    panel:addChild(UIFactory.createSlider(10, 155, 200, 8, {2, 2.3, 2.6, 3, 3.3, 3.6, 4.0}, function (v)    
        local map = DataStore.get('map')
        if not map then return end
        local newCanvasMap = CanvasMap
            .new(map, DataStore.get('currentTown').name, 800, 600, v)
        DataStore.update('canvasMap', newCanvasMap)
    end, 7))

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

    panel:addChild(UIFactory.createButton("Default", 235, 148, 180, 45, "승객 목록", function()
        UIManager:open('passangerPanel')
        Sounds.play('click')
    end))


    -- 1. 설정 버튼
    local settingBtn = Icons.createIconButton('setting', 6, 164, 32, 32, function()
        UIManager:open('settingPanel')
        Sounds.play('click')
    end)
    panel:addChild(settingBtn)

    -- 2. 종료 버튼
    local closeBtn = Icons.createIconButton('close', 36, 164, 32, 32, function()
        SaveSystem.save()
        Sounds.play('click')
        sys.quit()
    end)
    panel:addChild(closeBtn)
    
    -- 3. 정보 버튼
    local infoBtn = Icons.createIconButton('info', 66, 164, 32, 32, function()
        UIManager:open('infoPanel')
        Sounds.play('click')
    end)
    panel:addChild(infoBtn)

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