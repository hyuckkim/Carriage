local UIElement = require("lib.UI.UIElement")
---@class UIHorizontalSlider : UIElement
local UIHorizontalSlider = setmetatable({}, { __index = UIElement })
UIHorizontalSlider.__index = UIHorizontalSlider

function UIHorizontalSlider.new(x, y, w, h)
    ---@class UIHorizontalSlider
    local self = setmetatable(UIElement.new(x, y, w, h), UIHorizontalSlider)
    
    -- 기본 설정
    self.trackNP = nil
    self.handleNP = nil
    self.handleW = 20
    self.handleH = h
    
    self.value = 0          -- 0.0 ~ 1.0 (그리기용 비율)
    self.items = nil        -- 데이터 리스트 (예: {800, 1280, 1920})
    self.selectedIndex = 1  -- 현재 선택된 아이템의 인덱스
    
    self.isDragging = false
    self.onChange = nil     -- 콜백
    self.lastDown = false
    
    return self
end

function UIHorizontalSlider:setItems(items)
    self.items = items
    self:setIndex(1) -- 기본값은 첫 번째 아이템
end

function UIHorizontalSlider:setIndex(idx)
    if not self.items or #self.items == 0 then return end
    
    idx = math.max(1, math.min(#self.items, idx))
    if self.selectedIndex == idx and self.initialized then
        return
    end
    
    self.selectedIndex = idx
    self.initialized = true
    
    -- 그리기용 value 계산 (0~1 사이 비율)
    if #self.items > 1 then
        self.value = (idx - 1) / (#self.items - 1)
    else
        self.value = 0
    end

    -- 콜백 호출 (현재 아이템 값과 인덱스 전달)
    if self.onChange then
        self.onChange(self.items[idx], idx)
    end
end

-- 스킨 설정
function UIHorizontalSlider:setSkins(trackNP, handleNP, hw, hh)
    self.trackNP = trackNP
    self.handleNP = handleNP
    self.handleW = hw or self.handleW
    self.handleH = hh or self.handleH
end

-- 드래그 중에 값을 갱신하는 로직
function UIHorizontalSlider:updateValueFromPos(mx)
    local ax, _ = self:getAbsolutePos()
    local range = self.w - self.handleW
    if range <= 0 then return end

    local relativeX = mx - ax - (self.handleW / 2)
    local percent = math.max(0, math.min(1, relativeX / range))
    
    if self.items then
        -- 가장 가까운 인덱스로 스냅
        local newIdx = math.floor(percent * (#self.items - 1) + 0.5) + 1
        self:setIndex(newIdx)
    else
        -- 아이템 리스트가 없으면 부드러운 0~1 값으로 처리
        self.value = percent
        if self.onChange then self.onChange(self.value) end
    end
end

-- 핸들 영역 계산 (Draw와 Update에서 공용)
function UIHorizontalSlider:getHandleRect()
    local ax, ay = self:getAbsolutePos()
    local range = self.w - self.handleW
    local hx = ax + (self.value * range)
    local hy = ay + (self.h - self.handleH) / 2
    return hx, hy, self.handleW, self.handleH
end

---@override
function UIHorizontalSlider:update(dt, mx, my, ml, consumed)
    local hx, hy, hw, hh = self:getHandleRect()
    local isOverHandle = (mx >= hx and mx <= hx + hw and my >= hy and my <= hy + hh)
    local isOverTrack = self:isHit(mx, my)
    local myHit = (isOverHandle or isOverTrack) and not consumed

    -- 드래그 처리
    if self.isDragging then
        if ml then
            self:updateValueFromPos(mx)
            return true -- 드래그 중엔 이벤트 독점
        else
            self.isDragging = false
        end
    end

    -- 클릭 시작
    if myHit and ml and not self.lastDown then
        self.isDragging = true
        if not isOverHandle then
            self:updateValueFromPos(mx)
        end
    end

    self.lastDown = ml
    return UIElement.update(self, dt, mx, my, ml, consumed) or myHit
end

function UIHorizontalSlider:draw()
    if not self.visible then return end
    local ax, ay = self:getAbsolutePos()

    -- 1. 트랙 그리기
    if self.trackNP then
        self.trackNP:draw(ax, ay, self.w, self.h)
    end

    -- 2. 핸들 그리기
    local hx, hy, hw, hh = self:getHandleRect()
    if self.handleNP then
        self.handleNP:draw(hx, hy, hw, hh)
    end

    UIElement.draw(self)
end

return UIHorizontalSlider