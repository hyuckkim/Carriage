local UIManager = require("lib.UIManager")
local UIFactory = require("src.UiFactory")
local Datastore = require("src.Datastore")

return function ()
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 400, 300)
    panel:addChild(UIFactory.createButton("Default", 210, 10, 180, 50, "출발", function()
        Datastore.fsm:transition("walk")
        UIManager:closeAll()
    end))
    panel:addChild(UIFactory.createButton("Default", 210, 60, 180, 50, "손님 받기", function()
        UIManager:open('customerPanel')
    end))
    panel:addChild(UIFactory.createButton("Default", 210, 110, 180, 50, "물품 구매", function()
        print("Child Button Clicked!")
    end))
    panel:addChild(UIFactory.createButton("Default", 210, 190, 180, 50, "환경설정", function()
        UIManager:open('settingPanel')
    end))
    panel:addChild(UIFactory.createButton("Default", 210, 240, 180, 50, "게임 종료", function()
        sys.quit()
    end))
    
    panel.visible = false
    return panel
end