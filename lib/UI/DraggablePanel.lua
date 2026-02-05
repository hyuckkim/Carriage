-- lib/DraggablePanel.lua
local UIPanel = require("lib.UI.UIPanel")
---@class DraggablePanel : UIPanel
local DraggablePanel = setmetatable({}, { __index = UIPanel })
DraggablePanel.__index = DraggablePanel

---@override
function DraggablePanel.new(x, y, w, h, np)
    local self = setmetatable(UIPanel.new(x, y, w, h), DraggablePanel)
    self.np = np
    self.isDragging = false
    self.offsetX = 0
    self.offsetY = 0
    return self
end

function DraggablePanel:update(dt, mx, my, ml, consumed)
    -- 드래그 중이면 마우스 좌표에 따라 내 위치 갱신 (가장 먼저 수행)
    if self.isDragging then
        if ml then
            self.x = mx - self.offsetX
            self.y = my - self.offsetY
            -- 내가 드래그 중이면 자식들이나 아래 레이어가 반응 못 하게 true 반환
            -- 부모의 update를 호출하되 consumed를 true로 강제 주입
            return UIPanel.update(self, dt, mx, my, ml, true) or true
        else
            self.isDragging = false
        end
    end

    -- 평상시에는 부모의 로직(자식 전파 + isHit 판정)을 따름
    return UIPanel.update(self, dt, mx, my, ml, consumed)
end

-- UIElement가 isHit 결과를 myHit으로 넘겨주면 여기서 상태를 확정합니다.
function DraggablePanel:updateState(myHit, ml)
    if self.isDragging then return end -- 이미 드래그 중이면 패스

    -- 마우스가 내 위에 있고, 클릭이 막 발생했다면
    if myHit and ml then
        local mx, my = is.mouse() -- 현재 정확한 좌표 획득
        self.isDragging = true
        self.offsetX = mx - self.x
        self.offsetY = my - self.y
    end
end

function DraggablePanel:draw()
    if not self.visible then return end
    
    local ax, ay = self:getAbsolutePos()
    
    -- 배경 그리기
    if self.np then
        self.np:draw(ax, ay, self.w, self.h)
    end
    
    -- 자식 그리기
    UIPanel.draw(self)
end

return DraggablePanel