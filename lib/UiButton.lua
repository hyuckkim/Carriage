local UIElement = require("lib.UIElement")
local UIPanel = require("lib.UIPanel")

---@class UIButton: UIPanel
local UIButton = setmetatable({}, { __index = UIPanel })
UIButton.__index = UIButton

function UIButton.new(x, y, w, h, skins, text, onClick, color)
---@class UIButton
    local self = UIPanel.new(x, y, w, h)

    setmetatable(self, UIButton)
    self.nps = skins
    self:setText(text or "")
    self.callback = onClick
    self.state = "normal"
    self.color = color or { 255, 255, 255 }
    return self
end
function UIButton:setText(newText)
    self.text = newText
    -- 여기서 딱 한 번만 호출!
    if self.text ~= "" then
        self.tw, self.th = g.fontSize(0, self.text)
    else
        self.tw, self.th = 0, 0
    end
end

function UIButton:updateState(myHit, ml)
    if myHit then
        if ml then self.state = "pressed" else self.state = "hover" end
    else
        self.state = "normal"
    end
    
    -- 상태에 맞는 나인패치 갈아끼우기
    self.np = self.nps[self.state] or self.nps["normal"]
end

function UIButton:draw()
    if not self.visible then return end
    UIPanel.draw(self)

    -- 텍스트 드로우 (가운데 정렬)
    g.color(self.color[1], self.color[2], self.color[3])
    if self.text and #self.text > 0 then
        local ax, ay = self:getAbsolutePos()
        local tx = ax + (self.w - self.tw) / 2
        local ty = ay + (self.h - self.th) / 2
        g.text(0, self.text, tx, ty)
    end

    UIElement.draw(self)
end

function UIButton:dispatchClick(x, y, button)
    if not self.visible or not self:isHit(x, y) then return false end

    -- 1. 자식에게 먼저 기회를 줌
    for i = #self.children, 1, -1 do
        if self.children[i].dispatchClick and self.children[i]:dispatchClick(x, y, button) then
            return true
        end
    end

    -- 2. 자식이 처리 안 했으면 내가 처리
    if button == "left" and self.callback then
        self.callback()
        return true
    end
    return true
end

return UIButton