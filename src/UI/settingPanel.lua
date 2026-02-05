local UIManager = require("lib.UIManager")
local UIFactory = require("src.UiFactory")
local Datastore = require("src.Datastore")

return function ()
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 200, 300)
    panel:addChild(UIFactory.createText(20, 15, "환경설정"))
    panel:addChild(UIFactory.createText(20, 60, "게임 크기 배수: 1.5x", 'Small'))
    panel:addChild(UIFactory.createSlider(20, 90, 160, 10, { 1, 1.5, 2, 3, 4 }, function (v)
        Datastore.settings.mainSize = v
        panel:at(2):setText("게임 크기 배수: " .. v .. "x")
    end, 2))
    panel:addChild(UIFactory.createButton("Default", 110, 250, 80, 40, "완료", function()
        UIManager:close(panel)
    end))

    panel.visible = false
    return panel
end