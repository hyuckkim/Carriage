local UIManager = require("lib.UIManager")
local UIFactory = require("src.Table.UiFactory")
local Datastore = require("src.Datastore")
local SettingMethod = require("src.SettingMethod")

local monitorIdx = 1

return function ()
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 400, 320)
    local s = SettingMethod.GetFilled(Datastore.get('settings'))

    panel:addChild(UIFactory.createText(20, 15, "환경설정"))

    -- 옵션 리스트 정의
    local gameSizeOptions = { 1, 1.5, 2, 3, 4 }
    local uiSizeOptions = { 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0 }
    -- 투명도 옵션 (0.1 단위)
    local alphaOptions = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0 }
    local uiAlphaOptions = { 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0 }

    local gameSizeLabel = UIFactory.createText(20, 60, "게임 크기 배수: " .. s.mainSize .. "x", 'Small')
    panel:addChild(gameSizeLabel)
    panel:addChild(UIFactory.createSlider(20, 90, 160, 10, gameSizeOptions, function (v)
        SettingMethod.ApplyGameSize(v)
        gameSizeLabel:setText("게임 크기 배수: " .. v .. "x")
    end, FindIndex(gameSizeOptions, s.mainSize)))

    local uiSizeLabel = UIFactory.createText(20, 110, "UI 크기 배수: " .. s.uiSize .. "x", 'Small')
    panel:addChild(uiSizeLabel)
    panel:addChild(UIFactory.createSlider(20, 140, 160, 10, uiSizeOptions, function (v)
        SettingMethod.ApplyUISize(v)
        uiSizeLabel:setText("UI 크기 배수: " .. v .. "x")
    end, FindIndex(uiSizeOptions, s.uiSize)))

    -- 3. 항상 위 체크박스
    panel:addChild(UIFactory.createText(20, 165, "항상 맨 위에 표시", 'Small'))
    panel:addChild(UIFactory.createCheckbox("Default", 160, 160, 24, 24, function(v)
        SettingMethod.ApplyAlwayTop(v)
    end, Datastore.get('settings').topmost ~= false))

    -- 4. 모니터 변경 버튼
    local currentMonitor = s.monitor
    local monitorBtn
    monitorBtn = UIFactory.createButton("Default", 10, 200, 180, 40, string.format("모니터 변경: %d", currentMonitor), function()
        local monitors = sys.getMonitors()
        currentMonitor = currentMonitor + 1
        if currentMonitor > #monitors then currentMonitor = 1 end
        
        SettingMethod.ApplyMonitorIdx(currentMonitor)
        monitorBtn:setText(string.format("모니터 변경: %d", currentMonitor))
    end)
    panel:addChild(monitorBtn)

    -- 6. UI(설정창) 투명도 슬라이더 (0.1 ~ 1.0)
    local uiAlphaLabel = UIFactory.createText(220, 60, "UI 투명도: " .. (s.uiAlpha or 1.0), 'Small')
    panel:addChild(uiAlphaLabel)
    panel:addChild(UIFactory.createSlider(220, 90, 160, 10, uiAlphaOptions, function (v)
        -- SettingMethod에 ApplyUIAlpha가 있다고 가정
        SettingMethod.ApplyUIAlpha(v) 
        uiAlphaLabel:setText("UI 투명도: " .. v)
    end, FindIndex(uiAlphaOptions, s.uiAlpha or 1.0)))

    -- 7. 배경 투명도 슬라이더 (0.0 ~ 1.0)
    local bgAlphaLabel = UIFactory.createText(220, 110, "배경 투명도: " .. (s.bgAlpha or 1.0), 'Small')
    panel:addChild(bgAlphaLabel)
    panel:addChild(UIFactory.createSlider(220, 140, 160, 10, alphaOptions, function (v)
        -- SettingMethod에 ApplyBackgroundAlpha가 있다고 가정
        SettingMethod.ApplyBackgroundAlpha(v)
        bgAlphaLabel:setText("배경 투명도: " .. v)
    end, FindIndex(alphaOptions, s.bgAlpha or 1.0)))

    -- 5. 완료/닫기 버튼
    panel:addChild(UIFactory.createButton("Default", 90, 250, 100, 40, "완료", function()
        SettingMethod.Save()
        UIManager:close(panel)
    end))

    panel.visible = false
    return panel
end