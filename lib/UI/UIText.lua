local UIElement = require("lib.UI.UIElement")

---@class UIText : UIElement
local UIText = setmetatable({}, { __index = UIElement })
UIText.__index = UIText

function UIText.new(x, y, str, fontId, color)
---@class UIText
    local self = setmetatable(UIElement.new(x, y, 0, 0), UIText)
    
    self.fontId = fontId or 0
    self.color = color or {255, 255, 255} -- 기본 흰색 {R, G, B}
    self.align = "left" -- "left", "center", "right"
    self.passthrough = true
    
    self:setText(str or "")
    
    return self
end

-- 텍스트 내용 변경 및 영역 재계산
function UIText:setText(newText)
    self.text = tostring(newText)
    
    if self.text ~= "" then
        -- 엔진 API를 사용하여 텍스트의 실제 픽셀 크기 측정
        local tw, th = g.fontSize(self.fontId, self.text)
        self.w = tw
        self.h = th
    else
        self.w = 0
        self.h = 0
    end
end

function UIText:draw()
    if not self.visible or self.text == "" then return end
    
    local ax, ay = self:getAbsolutePos()
    
    -- 엔진 컬러 설정 (필요 시)
    g.color(self.color[1], self.color[2], self.color[3])
    
    -- 정렬 방식에 따른 출력 X 좌표 오프셋 계산
    local drawX = ax
    if self.align == "center" then
        drawX = ax - (self.w / 2)
    elseif self.align == "right" then
        drawX = ax - self.w
    end

    -- 엔진 텍스트 출력 API 호출
    g.text(self.fontId, self.text, drawX, ay)
    
    -- 자식 요소가 있다면 드로우 (보통 텍스트는 자식이 없지만 구조 유지)
    UIElement.draw(self)
end

return UIText