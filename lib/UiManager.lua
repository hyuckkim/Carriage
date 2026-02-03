local UIManager = {
    layers = {} -- UI 컴포넌트들을 담는 리스트
}

-- UI 요소를 추가 (뒤에 추가될수록 화면 위쪽에 그려짐)
function UIManager:add(component)
    table.insert(self.layers, component)
end

-- UI 요소를 모두 제거 (상태 전환 시 호출)
function UIManager:clear()
    self.layers = {}
end

-- 매 프레임 업데이트 (애니메이션이나 상태 체크용)
function UIManager:update(dt)
    local mx, my, ml = is.mouse()
    local consumed = false
    
    for i = #self.layers, 1, -1 do
        if self.layers[i]:update(dt, mx, my, ml, consumed) then
            consumed = true
        end
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
        -- 각 레이어(부모들)에게 클릭 전파 시작
        if self.layers[i]:dispatchClick(x, y, button) then
            return true
        end
    end
    return false
end

return UIManager