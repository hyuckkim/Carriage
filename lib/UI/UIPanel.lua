local UIElement = require("lib.UI.UIElement")
---@class UIPanel: UIElement
local UIPanel = setmetatable({}, { __index = UIElement })
UIPanel.__index = UIPanel

function UIPanel.new(x, y, w, h, ninepatch)
    ---@class UIPanel
    local self = setmetatable(UIElement.new(x, y, w, h), UIPanel)
    self.np = ninepatch
    return self
end

function UIPanel:draw()
    if not self.visible then return end
    if self.np then
        local ax, ay = self:getAbsolutePos()
        self.np:draw(ax, ay, self.w, self.h)
    end
    UIElement.draw(self)
end

return UIPanel