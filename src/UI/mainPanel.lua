local UIManager = require("lib.UIManager")
local UIFactory = require("src.UiFactory")
local Datastore = require("src.Datastore")
local UIViewport = require("lib.UI.UIViewport")


---@param self UIPanel
local function redraw(self)
    local map = Datastore.get('canvasMap')
    if not map then return end
    if map.selectedBurg then
        self:at(1).color = { 255, 255, 255 }
    else
        self:at(1).color = { 100, 100, 100 }
    end
end
return function ()
    ---@class mainPanel: DraggablePanel
    local panel = UIFactory.createDraggablePanel("Default", 300, 700, 405, 300)
    panel:addChild(UIFactory.createButton("Default", 215, 10, 180, 50, "출발", function()
        local map = Datastore.get('canvasMap')
        if not map or not map.selectedBurg then return end
        Datastore.get('fsm'):transition("walk")
        UIManager:closeAll()
    end, "Gray"))

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
            if not town then redraw(panel) return end
            local route = map:findRoadPathWithLimit(town.name, Datastore.get('currentTown').name)
            if not route or town.name == Datastore.get('currentTown').name then
                map.selectedBurg = nil
            end

            redraw(panel);
        end
    end))

    panel.onInit = function (self)
        redraw(self)
    end
    panel.onUpdate = function (self)
        -- polling logic...
    end
    panel.visible = false
    return panel
end