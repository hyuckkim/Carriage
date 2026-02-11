local UIManager = require("lib.UIManager")
local UIFactory = require("src.UiFactory")
local Datastore = require("src.Datastore")
local SettingMethod = require("src.SettingMethod")

local monitorIdx = 1

return function ()
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 200, 320)
    local s = SettingMethod.GetFilled(Datastore.get('settings'))

    panel:addChild(UIFactory.createText(20, 15, "환경설정"))
    
    -- 옵션 리스트 정의
    local gameSizeOptions = { 1, 1.5, 2, 3, 4 }
    local uiSizeOptions = { 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0 }

    -- 1. 게임 크기 슬라이더
    local gameSizeLabel = UIFactory.createText(20, 60, "게임 크기 배수: " .. s.mainSize .. "x", 'Small')
    panel:addChild(gameSizeLabel)

    panel:addChild(UIFactory.createSlider(20, 90, 160, 10, gameSizeOptions, function (v)
        SettingMethod.ApplyGameSize(v)
        gameSizeLabel:setText("게임 크기 배수: " .. v .. "x")
    end, FindIndex(gameSizeOptions, s.mainSize))) -- 현재 설정값에 맞는 인덱스 전달

    -- 2. UI 크기 슬라이더
    local uiSizeLabel = UIFactory.createText(20, 110, "UI 크기 배수: " .. s.uiSize .. "x", 'Small')
    panel:addChild(uiSizeLabel)

    panel:addChild(UIFactory.createSlider(20, 140, 160, 10, uiSizeOptions, function (v)
        SettingMethod.ApplyUISize(v)
        uiSizeLabel:setText("UI 크기 배수: " .. v .. "x")
    end, FindIndex(uiSizeOptions, s.uiSize))) -- 현재 설정값에 맞는 인덱스 전달

    -- 3. 항상 위 체크박스
    panel:addChild(UIFactory.createText(20, 165, "항상 맨 위에 표시", 'Small'))
    panel:addChild(UIFactory.createCheckbox("Default", 160, 160, 24, 24, function(v)
        SettingMethod.ApplyAlwayTop(v)
    end, Datastore.get('settings').topmost or true))

    -- 4. 모니터 변경 버튼
    monitorIdx = s.monitor
    panel:addChild(UIFactory.createButton("Default", 10, 200, 180, 40, "모니터 변경: " .. s.monitor, function()
        local monitors = sys.getMonitors()
        monitorIdx = monitorIdx + 1
        if monitorIdx > #monitors then monitorIdx = 1 end
        SettingMethod.ApplyMonitorIdx(monitorIdx)
        panel:at(8):setText("모니터 변경: " .. monitorIdx)
    end))

    -- 5. 완료/닫기 버튼
    panel:addChild(UIFactory.createButton("Default", 90, 250, 100, 40, "완료", function()
        SettingMethod.Save()
        UIManager:close(panel)
    end))

    panel.visible = false
    return panel
end