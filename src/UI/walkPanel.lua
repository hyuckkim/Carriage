local UIManager = require("lib.UIManager")
local UIFactory = require("src.Table.UiFactory")
local Datastore = require("src.Datastore")
local UIViewport = require("lib.UI.UIViewport")
local SaveSystem = require("src.SaveSystem")

return function ()
    ---@class walkPanel: DraggablePanel
    -- 버튼이 하나 더 늘어나므로 패널 높이를 약간 조절 (260 -> 310)
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 220, 310)

    -- 1: 지도 뷰포트 (여정 중 마차의 위치 실시간 표시)
    panel:addChild(UIViewport.new(10, 10, 200, 150, function (x, y, w, h)
        local map = Datastore.get('canvasMap')
        local currentTown = Datastore.get('previousTown')
        local targetTown = Datastore.get('currentTown')
        
        if map and currentTown and targetTown then
            -- 맵 베이스 그리기
            map:Draw(x, y, w, h, 200, 150, 400, 300)
        end
    end, function (x, y, button)
       
    end))

    panel:addChild(UIFactory.createText(10, 170, "이동 중...", "Default"))

    panel:addChild(UIFactory.createButton("Default", 10, 210, 200, 40, "현재 상태 저장", function()
        SaveSystem.save()
    end))

    panel:addChild(UIFactory.createButton("Default", 10, 260, 200, 40, "게임 종료", function()
        SaveSystem.save()
        sys.quit()
    end))

    panel.visible = false
    return panel
end