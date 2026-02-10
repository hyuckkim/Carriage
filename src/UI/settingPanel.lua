local UIManager = require("lib.UIManager")
local UIFactory = require("src.UiFactory")
local Datastore = require("src.Datastore")

local monitorIdx = 1

return function ()
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 200, 300)
    panel:addChild(UIFactory.createText(20, 15, "환경설정"))
    
    -- 1. 게임 크기 슬라이더
    panel:addChild(UIFactory.createText(20, 60, "게임 크기 배수: 1.5x", 'Small'))
    panel:addChild(UIFactory.createSlider(20, 90, 160, 10, { 1, 1.5, 2, 3, 4 }, function (v)
        Datastore.get('settings').mainSize = v
        panel:at(2):setText("게임 크기 배수: " .. v .. "x")
    end, 2))

    -- 2. UI 크기 슬라이더
    panel:addChild(UIFactory.createText(20, 110, "UI 크기 배수: 1.0x", 'Small'))
    panel:addChild(UIFactory.createSlider(20, 140, 160, 10, { 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0 }, function (v)
        local oldSize = Datastore.get('settings').uiSize
        UIManager:AdjustScale(oldSize, v) -- 튕겨나감 방지 로직 호출
        Datastore.get('settings').uiSize = v
        panel:at(4):setText("UI 크기 배수: " .. v .. "x") -- '게임' -> 'UI' 오타 수정
    end, 3))

    -- 3. 항상 위 체크박스
    panel:addChild(UIFactory.createText(20, 165, "항상 맨 위에 표시", 'Small'))
    panel:addChild(UIFactory.createCheckbox("Default", 160, 160, 24, 24, function(v)
        sys.setTopmost(v) -- 체크 상태(v)를 그대로 전달
    end, true))

    -- 4. 모니터 변경 버튼
    local monitors = sys.getMonitors()
    local btnMonitor = UIFactory.createButton("Default", 10, 200, 180, 40, "모니터 변경: 1", function()
        monitorIdx = monitorIdx + 1
        if monitorIdx > #monitors then monitorIdx = 1 end
        
        local m = monitors[monitorIdx]
        -- 모니터의 작업 영역(WorkArea) 좌상단으로 이동
        sys.setPos(m.workX, m.workY)
        panel:at(8):setText("모니터 변경: " .. monitorIdx)
    end)
    panel:addChild(btnMonitor)

    -- 5. 완료/닫기 버튼
    panel:addChild(UIFactory.createButton("Default", 90, 250, 100, 40, "완료", function()
        UIManager:close(panel)
    end))

    panel.visible = false
    return panel
end