local UIManager = require("lib.UIManager")
local UIFactory = require("src.Table.UiFactory")
local DataStore = require("src.DataStore")
local UIViewport = require("lib.UI.UIViewport")
local Icons = require("src.Table.Icons")
local SaveSystem = require("src.SaveSystem")
local IdleState = require("src.State.IdleState")
local Sounds = require("src.Sounds")
local CanvasMap = require("src.UI.canvasMap")

---@param self DraggablePanel
local function redraw(self)
    local map = DataStore.get('canvasMap')
    local currentTown = DataStore.get('currentTown')
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
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 605, 300)

    -- 1: 출발 버튼
    panel:addChild(UIFactory.createButton("Default", 415, 10, 180, 50, "출발", function()
        local map = DataStore.get('canvasMap')
        if not map or not map.selectedBurg then return end

        UIManager:closeAll()
        IdleState.startBoardingSequence()
    end, "Gray"))
        Sounds.play('click')

    -- 2~5: 기타 버튼들
    panel:addChild(UIFactory.createButton("Default", 415, 60, 180, 50, "손님 받기", function()
        UIManager:open('customerPanel')
        Sounds.play('click')
    end))
    panel:addChild(UIFactory.createButton("Default", 415, 110, 180, 50, "상점", function()
        Sounds.play('click')
        
    end))
    panel:addChild(UIFactory.createButton("Default", 415, 160, 180, 50, "유지 관리", function()
        Sounds.play('click')

    end))
    panel:addChild(UIFactory.createButton("Default", 415, 240, 180, 50, "통계", function()
        Sounds.play('click')

    end))

    panel.mapOffsetX = 200
    panel.mapOffsetY = 150
    local MAP_W, MAP_H = 400, 300
    local VIEW_W, VIEW_H = 200, 150

    -- 6: 지도 뷰포트
    panel:addChild(UIViewport.new(10, 10, 200, 150, function (x, y, w, h)
        local map = DataStore.get('canvasMap')
        if map then
            map:Draw(x, y, w, h, panel.mapOffsetX, panel.mapOffsetY, MAP_W, MAP_H)
        end
    end, function (x, y, button)
        local map = DataStore.get('canvasMap')
        local currentTown = DataStore.get('currentTown')
        if map and currentTown then
            local town = map:getClickTown(x, y, VIEW_W, VIEW_H, panel.mapOffsetX, panel.mapOffsetY, MAP_W, MAP_H)
            local route = town and map:findRoadPathWithLimit(town.name, currentTown.name)

            if not route or town.name == currentTown.name then
                panel.mapOffsetX = panel.mapOffsetX + x - VIEW_W / 2
                panel.mapOffsetY = panel.mapOffsetY + y - VIEW_H / 2
                panel.mapOffsetX = math.max(0,
                    math.min(panel.mapOffsetX, MAP_W)
                )
                panel.mapOffsetY = math.max(0,
                    math.min(panel.mapOffsetY, MAP_H)
                )
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

    
    panel:addChild(UIFactory.createSlider(10, 155, 200, 8, {2, 2.3, 2.6, 3, 3.3, 3.6, 4.0}, function (v)    
        local map = DataStore.get('map')
        if not map then return end
        local newCanvasMap = CanvasMap
            .new(map, DataStore.get('currentTown').name, 800, 600, v)
        DataStore.update('canvasMap', newCanvasMap)
    end, 7))

    local statusText = UIFactory.createText(220, 15, "운송 일지", "Default")
    panel:addChild(statusText)

    local goldText = UIFactory.createText(220, 45, "0 G", "Small")
    goldText.color = { 255, 215, 0 }
    panel:addChild(goldText)

        -- 1. 설정 버튼 (Icons 모듈 활용)
    local settingBtn = Icons.createIconButton('setting', 6, 264, 32, 32, function()
        UIManager:open('settingPanel')
        Sounds.play('click')
    end)
    panel:addChild(settingBtn)

    -- 2. 종료 버튼 (Icons 모듈 활용)
    local closeBtn = Icons.createIconButton('close', 36, 264, 32, 32, function()
        SaveSystem.save()
        sys.quit()
        Sounds.play('click')
    end)
    panel:addChild(closeBtn)

    local infoBtn = Icons.createIconButton('info', 66, 264, 32, 32, function()
        UIManager:open('infoPanel')
        Sounds.play('click')
    end)
    panel:addChild(infoBtn)

    panel.onInit = function (self)
        redraw(self)
    end
    panel.onUpdate = function (self)
        local gold = DataStore.get('gold') or 0
        goldText.text = string.format("%d Gold", math.floor(gold))
    end
    
    panel.visible = false
    return panel
end