local UIElement = require("lib.UIElement")

---@class UIViewport: UIElement
local UIViewport = setmetatable({}, { __index = UIElement })
UIViewport.__index = UIViewport

---@param x number 부모 기준 X
---@param y number 부모 기준 Y
---@param w number 마스킹 너비
---@param h number 마스킹 높이
---@param drawCallback function? (ax, ay, w, h)를 인자로 받는 커스텀 그리기 함수
function UIViewport.new(x, y, w, h, drawCallback)
    ---@class UIViewport
    local self = setmetatable(UIElement.new(x, y, w, h), UIViewport)
    self.onDraw = drawCallback
    return self
end

function UIViewport:draw()
    if not self.visible then return end

    local ax, ay = self:getAbsolutePos()

    g.push()
        g.clip(ax, ay, self.w, self.h)
        if self.onDraw then
            self.onDraw(ax, ay, self.w, self.h)
        end


    g.pop()
    UIElement.draw(self)
end

return UIViewport