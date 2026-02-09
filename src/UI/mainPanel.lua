local UIManager = require("lib.UIManager")
local UIFactory = require("src.UiFactory")
local Datastore = require("src.Datastore")
local UIViewport = require("lib.UI.UIViewport")

return function ()
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 405, 300)
    panel:addChild(UIFactory.createButton("Default", 215, 10, 180, 50, "출발", function()
        Datastore.get('fsm'):transition("walk")
        UIManager:closeAll()
    end))
    panel:addChild(UIFactory.createButton("Default", 215, 60, 180, 50, "손님 받기", function()
        UIManager:open('customerPanel')
    end))
    panel:addChild(UIFactory.createButton("Default", 215, 110, 180, 50, "물품 구매", function()
        print("Child Button Clicked!")
    end))
    panel:addChild(UIFactory.createButton("Default", 215, 190, 180, 50, "환경설정", function()
        UIManager:open('settingPanel')
    end))
    panel:addChild(UIFactory.createButton("Default", 215, 240, 180, 50, "게임 종료", function()
        sys.quit()
    end))
    panel:addChild(UIViewport.new(10, 10, 200, 150, function (x, y, w, h)
        local map = Datastore.get('canvasMap')
        if map then
            map:Draw(x, y, w, h, 200, 150, 400, 300)
        end
    end, function (x, y, button)
        local map = Datastore.get('canvasMap')
        if map then
            local town = map:getClickTown(x, y, 200, 150, 200, 150, 400, 300)
            if not town then return end
            if town.name == Datastore.get('currentTown').name then
                map.selectedBurg = nil
                return
            end
            local route = map:findRoadPathWithLimit(town.name, Datastore.get('currentTown').name)
            if route then

            else
                map.selectedBurg = nil
            end
        end
    end))
    
    panel.visible = false
    return panel
end