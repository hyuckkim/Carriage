local UIElement = require("lib.UIElement")
---@class UIHorizontalSlider : UIElement
local UIHorizontalSlider = setmetatable({}, { __index = UIElement })
UIHorizontalSlider.__index = UIHorizontalSlider

function UIHorizontalSlider.new(x, y, w, h)
  ---@class UIHorizontalSlider
    local self = setmetatable(UIElement.new(x, y, w, h), UIHorizontalSlider)
    
    -- 기본 스킨 및 상태 데이터
    self.trackNP = nil
    self.handleNP = nil
    self.handleW = 20
    self.handleH = h
    
    self.value = 0          -- 0.0 ~ 1.0
    self.steps = nil        -- 단계별 이동 (예: 5)
    self.isDragging = false
    self.onChange = nil     -- 콜백

    self.items = nil        -- 데이터 리스트 (예: {800, 1280, 1920})
    self.selectedIndex = 1  -- 현재 선택된 아이템의 인덱스
    self.value = 0          -- 0.0 ~ 1.0 (그리기용 비율)
    
    return self
end
-- 아이템 리스트 설정 함수
function UIHorizontalSlider:setItems(items)
    self.items = items
    self:setIndex(1) -- 기본값은 첫 번째 아이템
end

-- 인덱스로 값 변경
function UIHorizontalSlider:setIndex(idx)
    if not self.items or #self.items == 0 then return end
    
    idx = math.max(1, math.min(#self.items, idx))
    
    -- [핵심] 값이 실제로 변했을 때만 실행!
    if self.selectedIndex == idx then 
        return 
    end
    
    self.selectedIndex = idx
    
    -- 그리기용 value 계산 (0~1 사이)
    if #self.items > 1 then
        self.value = (idx - 1) / (#self.items - 1)
    else
        self.value = 0
    end

    -- 값이 바뀌었을 때만 콜백 호출
    if self.onChange then
        self.onChange(self.items[idx], idx)
    end
end

function UIHorizontalSlider:setSkins(trackNP, handleNP, hw, hh)
    self.trackNP = trackNP
    self.handleNP = handleNP
    self.handleW = hw or self.handleW
    self.handleH = hh or self.handleH
end

-- 드래그 중에 값을 갱신하는 핵심 로직
function UIHorizontalSlider:updateValueFromPos(mx)
    local ax, _ = self:getAbsolutePos()
    local range = self.w - self.handleW
    if range <= 0 or not self.items then return end

    local relativeX = mx - ax - (self.handleW / 2)
    local percent = math.max(0, math.min(1, relativeX / range))
    
    -- 퍼센트를 기반으로 가장 가까운 인덱스 찾기
    local newIdx = math.floor(percent * (#self.items - 1) + 0.5) + 1
    self:setIndex(newIdx)
end

---@override
---@override
function UIHorizontalSlider:update(dt, mx, my, ml, consumed)
    -- 1. 핸들 위치와 크기 계산
    local hx, hy, hw, hh = self:getHandleRect()
    
    -- 2. 핸들 영역에 마우스가 있는지 체크
    local isOverHandle = (mx >= hx and mx <= hx + hw and my >= hy and my <= hy + hh)
    -- 3. 기존 트랙 영역 체크 (부모 로직)
    local isOverTrack = self:isHit(mx, my)
    
    -- 슬라이더 전체(트랙 or 핸들) 중 하나라도 마우스가 올라가 있으면 'Hit'으로 간주
    local myHit = (isOverHandle or isOverTrack) and not consumed

    -- 4. 드래그 상태 관리
    if self.isDragging then
        if ml then
            self:updateValueFromPos(mx)
            -- 드래그 중엔 무조건 consumed 전파
            return UIElement.update(self, dt, mx, my, ml, true) or true
        else
            self.isDragging = false
        end
    end

    -- 5. 상태 확정 (updateState 대신 여기서 직접 처리하거나 넘겨줌)
    if myHit and ml and not self.lastDown then
        if isOverHandle then
            self.isDragging = true
            self.dragOffsetX = mx - (hx + hw / 2)
        elseif isOverTrack then
            -- 트랙 클릭 시 점프 로직 (원치 않으면 제거)
            self.isDragging = true
            self:updateValueFromPos(mx)
            self.dragOffsetX = 0
        end
    end

    self.lastDown = ml

    -- 자식들에게 전달 및 consumed 반환
    return UIElement.update(self, dt, mx, my, ml, consumed) or myHit
end

function UIHorizontalSlider:getHandleRect()
    local ax, ay = self:getAbsolutePos()
    local range = self.w - self.handleW
    local hx = ax + (self.value * range)
    local hy = ay + (self.h - self.handleH) / 2
    return hx, hy, self.handleW, self.handleH
end

---@override
function UIHorizontalSlider:updateState(myHit, ml)
    if self.isDragging then return end

    -- myHit이 true라면 마우스가 트랙 혹은 핸들 위에 있다는 뜻입니다.
    if myHit and ml and not self.lastDown then
        local mx, my = is.mouse()
        local hx, hy, hw, hh = self:getHandleRect()

        -- 1. 핸들 영역을 직접 클릭했는지 체크
        if mx >= hx and mx <= hx + hw and my >= hy and my <= hy + hh then
            self.isDragging = true
            -- 핸들 중심과 마우스 클릭 지점의 차이를 저장 (부드러운 드래그용)
            self.dragOffsetX = mx - (hx + hw / 2)
        else
            -- 2. 핸들은 아니지만 트랙 영역(myHit이 true니까)을 클릭한 경우
            -- 즉시 해당 위치로 핸들을 점프시키고 드래그 시작
            self.isDragging = true
            self.dragOffsetX = 0
            self:updateValueFromPos(mx)
        end
    end
    
    self.lastDown = ml
end

function UIHorizontalSlider:draw()
    if not self.visible then return end
    local ax, ay = self:getAbsolutePos()

    -- 1. 트랙 그리기
    if self.trackNP then
        self.trackNP:draw(ax, ay, self.w, self.h)
    end

    -- 2. 핸들 좌표 계산 및 그리기
    local hx = ax + (self.value * (self.w - self.handleW))
    local hy = ay + (self.h - self.handleH) / 2

    if self.handleNP then
        self.handleNP:draw(hx, hy, self.handleW, self.handleH)
    end

    UIElement.draw(self)
end

return UIHorizontalSlider