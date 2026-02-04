local UIElement = require("lib.UIElement")

---@class UIVerticalSlider : UIElement
local UIVerticalSlider = setmetatable({}, { __index = UIElement })
UIVerticalSlider.__index = UIVerticalSlider

function UIVerticalSlider.new(x, y, w, h)
    ---@class UIVerticalSlider
    local self = setmetatable(UIElement.new(x, y, w, h), UIVerticalSlider)
    
    -- 기본 설정
    self.trackNP = nil
    self.handleNP = nil
    self.handleW = w
    self.handleH = 20 -- 세로형이니 핸들의 높이가 기준
    
    self.value = 0          -- 0.0 (최상단) ~ 1.0 (최하단)
    self.isDragging = false
    self.onChange = nil     -- 값이 변할 때 호출할 콜백 (value 전달)
    
    self.lastDown = false
    return self
end

-- 스킨 설정 (Vertical용으로 hw, hh 의미가 바뀜)
function UIVerticalSlider:setSkins(trackNP, handleNP, hw, hh)
    self.trackNP = trackNP
    self.handleNP = handleNP
    self.handleW = hw or self.handleW
    self.handleH = hh or self.handleH
end

-- 가로형과 동일하게 setItems 추가
function UIVerticalSlider:setItems(items)
    self.items = items
    self:setIndex(1)
end

-- 인덱스로 값 변경 (가로형 로직 이식)
function UIVerticalSlider:setIndex(idx)
    if not self.items or #self.items == 0 then return end
    idx = math.max(1, math.min(#self.items, idx))
    
    if self.selectedIndex == idx then return end
    
    self.selectedIndex = idx
    if #self.items > 1 then
        self.value = (idx - 1) / (#self.items - 1)
    else
        self.value = 0
    end

    if self.onChange then
        self.onChange(self.items[idx], idx)
    end
end

-- 마우스 Y 위치로부터 값 업데이트 (아이템 기반 스냅 포함)
function UIVerticalSlider:updateValueFromPos(my)
    local _, ay = self:getAbsolutePos()
    local range = self.h - self.handleH
    if range <= 0 then return end

    local relativeY = my - ay - (self.handleH / 2)
    local percent = math.max(0, math.min(1, relativeY / range))
    
    if self.items then
        -- 아이템 리스트가 있다면 가장 가까운 단계로 스냅
        local newIdx = math.floor(percent * (#self.items - 1) + 0.5) + 1
        self:setIndex(newIdx)
    else
        -- 리스트가 없으면 그냥 0..1 비율로 처리 (스크롤용)
        self.value = percent
        if self.onChange then self.onChange(self.value) end
    end
end

function UIVerticalSlider:getHandleRect()
    local ax, ay = self:getAbsolutePos()
    local range = self.h - self.handleH
    local hx = ax + (self.w - self.handleW) / 2
    local hy = ay + (self.value * range)
    return hx, hy, self.handleW, self.handleH
end

---@override
function UIVerticalSlider:update(dt, mx, my, ml, consumed)
    local hx, hy, hw, hh = self:getHandleRect()
    
    local isOverHandle = (mx >= hx and mx <= hx + hw and my >= hy and my <= hy + hh)
    local isOverTrack = self:isHit(mx, my)
    local myHit = (isOverHandle or isOverTrack) and not consumed

    -- 드래그 로직
    if self.isDragging then
        if ml then
            self:updateValueFromPos(my)
            return true -- 드래그 중엔 이 요소가 이벤트를 독점
        else
            self.isDragging = false
        end
    end

    -- 클릭 시작 체크
    if myHit and ml and not self.lastDown then
        self.isDragging = true
        if not isOverHandle then
            -- 트랙 클릭 시 즉시 점프
            self:updateValueFromPos(my)
        end
    end

    self.lastDown = ml
    return UIElement.update(self, dt, mx, my, ml, consumed) or myHit
end

function UIVerticalSlider:draw()
    if not self.visible then return end
    local ax, ay = self:getAbsolutePos()

    -- 1. 트랙(배경) 그리기
    if self.trackNP then
        self.trackNP:draw(ax, ay, self.w, self.h)
    end

    -- 2. 핸들(손잡이) 그리기
    local hx, hy, hw, hh = self:getHandleRect()
    if self.handleNP then
        self.handleNP:draw(hx, hy, hw, hh)
    end

    UIElement.draw(self)
end

return UIVerticalSlider