---@class UIElement
local UIElement = {}
UIElement.__index = UIElement

function UIElement.new(x, y, w, h)
---@class UIElement
    local self = setmetatable({}, UIElement)
    self.x, self.y, self.w, self.h = x or 0, y or 0, w or 0, h or 0
    self.visible = true
    self.children = {}
    self.parent = nil
    self.updateState = nil
    return self
end

function UIElement:getAbsolutePos()
    local ax, ay = self.x, self.y
    if self.parent then
        local px, py = self.parent:getAbsolutePos()
        ax, ay = ax + px, ay + py
    end
    return ax, ay
end

function UIElement:at(idx)
    return self.children[idx]
end

function UIElement:len()
    return #self.children
end

function UIElement:isHit(mx, my)
    local ax, ay = self:getAbsolutePos()
    return mx >= ax and mx <= ax + self.w and my >= ay and my <= ay + self.h
end

function UIElement:addChild(child)
    table.insert(self.children, child)
    child.parent = self
end

-- 공통 로직: 자식부터 역순으로 업데이트/드로우
function UIElement:update(dt, mx, my, ml, consumed)
    if not self.visible then return consumed end
    local childConsumed = false
    
    -- 자식들에게 전파 (역순)
    for i = #self.children, 1, -1 do
        if self.children[i]:update(dt, mx, my, ml, consumed or childConsumed) then
            childConsumed = true
        end
    end
    
    local myHit = false
    if not consumed and not childConsumed then
        myHit = self:isHit(mx, my)
    end
    
    if self.updateState then
        self:updateState(myHit, ml)
    end
    return consumed or childConsumed or myHit
end

function UIElement:draw()
    if not self.visible then return end
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function UIElement:dispatchClick(x, y, button)
    if not self.visible or not self:isHit(x, y) then return false end

    -- 자식들에게 역순으로 전파 (위에 있는 자식이 먼저 클릭을 먹음)
    for i = #self.children, 1, -1 do
        if self.children[i].dispatchClick and self.children[i]:dispatchClick(x, y, button) then
            return true
        end
    end

    -- 자식이 안 먹었을 때, Element 자체는 딱히 할 일이 없으므로 
    -- '내 영역 안이다'라는 의미로 true만 반환 (클릭 가로채기)
    return true 
end
return UIElement