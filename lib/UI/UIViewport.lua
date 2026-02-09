local UIElement = require("lib.UI.UIElement")

---@class UIViewport: UIElement
local UIViewport = setmetatable({}, { __index = UIElement })
UIViewport.__index = UIViewport

---@param x number 부모 기준 X
---@param y number 부모 기준 Y
---@param w number 마스킹 너비
---@param h number 마스킹 높이
---@param drawCallback function? (ax, ay, w, h)를 인자로 받는 커스텀 그리기 함수
---@praam clickCallback function?
function UIViewport.new(x, y, w, h, drawCallback, clickCallback)
    ---@class UIViewport
    local self = setmetatable(UIElement.new(x, y, w, h), UIViewport)
    self.onDraw = drawCallback
    self.onClick = clickCallback
    self.passthrough = not clickCallback
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

function UIViewport:dispatchClick(x, y, button)
    if not self.visible or not self:isHit(x, y) then return false end

    for i = #self.children, 1, -1 do
        if self.children[i].dispatchClick and self.children[i]:dispatchClick(x, y, button) then
            return true
        end
    end

    if button == "left" and self.onClick then
        local lx, ly = self:getAbsolutePos()
        self.onClick(x - lx, y - ly, button)
        return true
    end
    return true
end
return UIViewport