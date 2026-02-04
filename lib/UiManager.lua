local UIManager = {
    layers = {} -- UI 컴포넌트들을 담는 리스트
}

function UIManager:add(component)
    table.insert(self.layers, component)
end

function UIManager:clear()
    self.layers = {}
end

-- 매 프레임 업데이트
function UIManager:update(dt)
    local mx, my, ml = is.mouse()
    local consumed = false
    local clickedIndex = nil
    
    -- 1. 역순으로 업데이트 (가장 위에 있는 것부터)
    for i = #self.layers, 1, -1 do
        local comp = self.layers[i]
        
        -- 이미 앞에서 이벤트를 먹었으면(consumed), 뒤에 있는 요소들은 '미클릭' 상태로 업데이트
        local isHit = false
        if not consumed then
            isHit = comp:update(dt, mx, my, ml, false)
            if isHit then
                consumed = true
                if ml and not self.lastDown then
                    clickedIndex = i
                end
            end
        else
            -- 이미 앞에서 consumed 되었으므로 ml(클릭)을 false로 강제하여 전파 차단
            comp:update(dt, mx, my, false, true)
        end
    end

    self.lastDown = ml -- 다음 프레임을 위해 클릭 상태 저장

    -- 클릭된 요소를 맨 앞으로 이동 (Z-Order 변경)
    if clickedIndex then
        local comp = table.remove(self.layers, clickedIndex)
        table.insert(self.layers, comp) -- 맨 뒤(화면상 맨 위)에 삽입
    end
end

-- 화면에 그리기
function UIManager:draw()
    for _, comp in ipairs(self.layers) do
        if comp.visible then
            comp:draw()
        end
    end
end

function UIManager:dispatchClick(x, y, button)
    for i = #self.layers, 1, -1 do
        if self.layers[i]:dispatchClick(x, y, button) then
            -- 클릭된 요소를 맨 위로 올리는 로직을 여기에도 적용 가능
            local comp = table.remove(self.layers, i)
            table.insert(self.layers, comp)
            return true -- 하나가 먹었으면 바로 종료
        end
    end
    return false
end

function UIManager:open(component)
    if not component then return end
    
    -- 1. 일단 보이게 설정
    component.visible = true
    
    -- 2. 레이어 리스트에서 해당 컴포넌트를 찾아 위치 이동 (Bring to Front)
    for i, comp in ipairs(self.layers) do
        if comp == component then
            table.remove(self.layers, i)
            table.insert(self.layers, component) -- 맨 뒤(최상단)에 삽입
            break
        end
    end
    if component.onInit then
        component:onInit()
    end
end

-- 특정 컴포넌트를 숨깁니다.
function UIManager:close(component)
    if not component then return end
    component.visible = false
    
    -- (선택 사항) 만약 닫을 때 드래그 상태 등을 초기화해야 한다면 추가
    if component.isDragging then
        component.isDragging = false
    end
end

function UIManager:closeAll()
    for _, comp in ipairs(self.layers) do
        comp.visible = false
    end
end
return UIManager