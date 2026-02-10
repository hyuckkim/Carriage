local UIManager = require("lib.UIManager")
local UIFactory = require("src.UiFactory")
local Datastore = require("src.Datastore")

local monitorIdx = 1
local SETTINGS_PATH = "settings.json" -- 설정 파일 경로

return function ()
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 200, 320)
    
    -- [데이터 로드 로직]
    -- 창이 생성되거나 초기화될 때 호출되도록 설정 (UIManager:open 시 호출됨)
    panel.onInit = function(self)
        -- 로드된 데이터에 맞춰 UI 요소들의 초기 텍스트/상태 동기화
        -- 필요한 경우 체크박스나 슬라이더의 현재 value도 s.mainSize 등에 맞춰 업데이트하는 로직 추가
    end
    local s = Datastore.get('settings')


    panel:addChild(UIFactory.createText(20, 15, "환경설정"))
    
    -- 1. 게임 크기 슬라이더
    panel:addChild(UIFactory.createText(20, 60, "게임 크기 배수: " .. s.mainSize .. "x", 'Small'))
    panel:addChild(UIFactory.createSlider(20, 90, 160, 10, { 1, 1.5, 2, 3, 4 }, function (v)
        Datastore.get('settings').mainSize = v
        panel:at(2):setText("게임 크기 배수: " .. v .. "x")
    end, 2))

    -- 2. UI 크기 슬라이더
    panel:addChild(UIFactory.createText(20, 110, "UI 크기 배수: " .. s.uiSize .. "x", 'Small'))
    panel:addChild(UIFactory.createSlider(20, 140, 160, 10, { 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0 }, function (v)
        local oldSize = Datastore.get('settings').uiSize
        UIManager:AdjustScale(oldSize, v)
        Datastore.get('settings').uiSize = v
        panel:at(4):setText("UI 크기 배수: " .. v .. "x")
    end, 3))

    -- 3. 항상 위 체크박스
    panel:addChild(UIFactory.createText(20, 165, "항상 맨 위에 표시", 'Small'))
    panel:addChild(UIFactory.createCheckbox("Default", 160, 160, 24, 24, function(v)
        Datastore.get('settings').topmost = v
        sys.setTopmost(v)
    end, Datastore.get('settings').topmost or true))

    -- 4. 모니터 변경 버튼
    local monitors = sys.getMonitors()
    panel:addChild(UIFactory.createButton("Default", 10, 200, 180, 40, "모니터 변경: " .. s.monitor, function()
        monitorIdx = monitorIdx + 1
        if monitorIdx > #monitors then monitorIdx = 1 end
        local m = monitors[monitorIdx]
        sys.setPos(m.workX, m.workY)
        panel:at(8):setText("모니터 변경: " .. monitorIdx)
        Datastore.get('settings').monitor = monitorIdx
    end))

    -- 5. 완료/닫기 버튼 (여기서 저장 수행)
    panel:addChild(UIFactory.createButton("Default", 90, 250, 100, 40, "완료", function()
        -- [데이터 내보내기]
        local currentSettings = Datastore.get('settings')
        local success = res.saveTable(SETTINGS_PATH, currentSettings)
        
        if success then
            print("[System] 설정이 저장되었습니다.")
        end
        
        UIManager:close(panel)
    end))

    panel.visible = false
    return panel
end