local DataStore = require("src.Datastore")

local UIManager = {
    layers = {},    -- 렌더링 순서용 (List)
    registry = {},  -- ID로 검색용 (Map: [id] = component)
}

--- 컴포넌트를 이름과 함께 등록
-- @param id 패널의 고유 식별자 (string)
-- @param component 패널 객체
function UIManager:add(id, component)
    -- 1. ID 중복 체크 (방어 코드)
    if self.registry[id] then
        print(string.format("[Warn] UIManager: ID '%s'가 이미 존재합니다. 덮어씌웁니다.", id))
    end

    -- 2. 검색용 맵에 등록
    self.registry[id] = component
    component.id = id -- 컴포넌트 스스로도 자기 이름을 알게 함
    
    -- 3. 렌더링용 리스트에 삽입
    table.insert(self.layers, component)
    
    -- 등록 시에는 일단 안 보이게 설정
    component.visible = false
end


function UIManager:clear()
    self.layers = {}
end

-- 매 프레임 업데이트
function UIManager:update(dt)
    local x, y, ml = is.mouse()
    local sw, sh = sys.getSize()

    local size = DataStore.get('settings').uiSize
    local mx = x / size
    local my = (y - sh) / size + sh -- scale의 기준점(0, sh)에 따른 보정

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

function UIManager:open(target, ...)
    if not target then return end
    local component
    if type(target) == "string" then
        component = self.registry[target]
    elseif type(target) == "table" then
        component = target
    end
    
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
        component:onInit(...)
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

function UIManager:AdjustScale(oldSize, newSize)
    local x, y = is.mouse() -- 실제 마우스 좌표
    local sw, sh = sys.getSize()

    -- UIManager에 직접 등록된 루트 패널들만 순회
    for _, comp in ipairs(self.layers) do
        -- comp는 UIElement 인스턴스
        local curW = comp.w * oldSize
        local curH = comp.h * oldSize
        
        -- 현재 화면상의 실제 좌표 (0, sh 기준 스케일 적용)
        local left = comp.x * oldSize
        local right = left + curW
        local top = (comp.y - sh) * oldSize + sh
        local bottom = top + curH

        -- 1. 마우스가 UI 영역 안에 있는지 체크
        local isInside = (x >= left and x <= right and y >= top and y <= bottom)

        if isInside then
            -- [Inside] 마우스 아래의 상대적 지점 유지
            local ratioX = (x - left) / curW
            local ratioY = (y - top) / curH

            comp.x = (x / newSize) - (comp.w * ratioX)
            comp.y = ((y - sh) / newSize + sh) - (comp.h * ratioY)
        else
            -- [Outside] 마우스와 가장 가까운 모서리 유지
            local anchorX = (x < left) and left or right
            local anchorY = (y < top) and top or bottom
            
            local ratioX = (anchorX == left) and 0 or 1
            local ratioY = (anchorY == top) and 0 or 1

            comp.x = (anchorX / newSize) - (comp.w * ratioX)
            comp.y = ((anchorY - sh) / newSize + sh) - (comp.h * ratioY)
            
            -- 2. 화면 밖 탈출 방지 (가상 좌표계 기준)
            local vW = sw / newSize
            local vH = sh / newSize
            
            -- 좌우 제한
            comp.x = math.max(0, math.min(comp.x, vW - comp.w))
            -- 상하 제한 (0, sh 기준이므로 y는 sh-vH 와 sh-h 사이)
            comp.y = math.max(sh - vH, math.min(comp.y, sh - comp.h))
        end

    end
end

return UIManager
