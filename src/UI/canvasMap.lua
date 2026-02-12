---@class CanvasMap
local CanvasMap = {}
CanvasMap.__index = CanvasMap

local function GetCellColor(h)
    if h < 20 then return 40, 70, 130 
    elseif h < 50 then return 80, 150, 80 
    elseif h < 80 then return 120, 160, 100 
    else return 200, 200, 200 
    end
end

local function getCenterBurg(burgs, name)
    local centerBurg = nil

    local i = 2
    while true do
        local b = burgs[i]
        if not b or type(b) ~= "userdata" then break end
        if b.name == name then centerBurg = b break end
        i = i + 1
    end
    return centerBurg
end

function CanvasMap:LoadInc(mapData, centerTownName, width, height, zoom)
if not mapData or not mapData.pack then return nil end
    local pack = mapData.pack

    local centerBurg = getCenterBurg(pack.burgs, centerTownName)
    if not centerBurg then return nil end
    
    local canvas = g.offscreenCanvas(width, height)
    local viewX, viewY = centerBurg.x, centerBurg.y
    local halfW, halfH = (width / zoom) / 2, (height / zoom) / 2
    local function worldToScreen(wx, wy)
        return (wx - (viewX - halfW)) * zoom, (wy - (viewY - halfH)) * zoom
    end
    local poly = {}
    return coroutine.create(function()
    coroutine.yield()
    canvas:batchBegin()
        -- 배경
        canvas:color(30, 50, 100)
        canvas:rect(0, 0, width, height, true)

        -- A. 지형 셀 (화면 범위 내)
        local cIdx = 1
        local count = 0

        while true do
            local cell = pack.cells[cIdx]
            if not cell or type(cell) ~= "userdata" then break end
            
            if math.abs(cell.p[1] - viewX) < (halfW * 1.5) and 
               math.abs(cell.p[2] - viewY) < (halfH * 1.5) then
                
                local r, g, b = GetCellColor(cell.h or 0)
                canvas:color(r, g, b) -- 채우기 색상
                
                for k in pairs(poly) do poly[k] = nil end
                local pIdx = 1
                for _, vIdx in ipairs(cell.v) do
                    local vObj = pack.vertices[vIdx + 1]
                    if vObj then
                        local sx, sy = worldToScreen(vObj.p[1], vObj.p[2])
                        poly[pIdx] = sx
                        poly[pIdx + 1] = sy
                        pIdx = pIdx + 2
                    end
                end
                
                if #poly >= 6 then 
                    -- 1. 먼저 면을 채우고
                    canvas:polygon(poly) 
                    
                    -- 2. [추가] 동일한 색상으로 외곽선을 그려서 틈새를 메움
                    -- 두께는 1.0~1.5 정도면 충분합니다.
                    canvas:polyline(poly, true, 1.0) 
                end
            end
            cIdx = cIdx + 1
            count = count + 1
            if count >= 100 then
                canvas:batchEnd() -- 1. 지금까지 그린 것들을 비트맵에 기록(Flush)
                coroutine.yield() -- 2. 다음 프레임까지 대기
                canvas:batchBegin() -- 3. 다음 프레임 작업 시작
                count = 0
            end
        end

        -- B. 도로 (Routes) 그리기
        local rIdx = 1
        while true do
            local route = pack.routes[rIdx]
            if not route or type(route) ~= "userdata" then break end
            
            canvas:color(200, 160, 110, 150)
            for k in pairs(poly) do poly[k] = nil end
            
            local pIdx = 1 -- [수정] 도로마다 인덱스를 1로 초기화해야 합니다!
            for j = 1, #route.points do
                local p = route.points[j]
                local sx, sy = worldToScreen(p[1], p[2])
                poly[pIdx] = sx
                poly[pIdx + 1] = sy
                pIdx = pIdx + 2
            end
            
            -- pIdx가 1보다 크면 데이터가 있는 것 (#poly 대신 pIdx 사용이 더 정확함)
            if pIdx > 4 then canvas:polyline(poly, false, 1.5) end
            
            rIdx = rIdx + 1
            count = count + 1
            if count >= 300 then
                canvas:batchEnd() -- 1. 지금까지 그린 것들을 비트맵에 기록(Flush)
                coroutine.yield() -- 2. 다음 프레임까지 대기
                canvas:batchBegin() -- 3. 다음 프레임 작업 시작
                count = 0
            end
        end

        -- C. 모든 마을 (Burgs) 표시
        local bIdx = 2
        while true do
            local b = pack.burgs[bIdx]
            if not b or type(b) ~= "userdata" then break end
            
            local sx, sy = worldToScreen(b.x, b.y)
            -- 화면 안에 있는 마을만 그리기
            if sx >= 0 and sx <= width and sy >= 0 and sy <= height then
                -- 중심 마을은 빨간색, 나머지는 흰색
                if b.name == centerTownName then
                    canvas:color(255, 50, 50)
                    canvas:circle(sx, sy, 6, true)
                else
                    canvas:color(255, 255, 255)
                    canvas:circle(sx, sy, 3, true)
                end
            end
            bIdx = bIdx + 1
            count = count + 1
            if count >= 500 then
                canvas:batchEnd() -- 1. 지금까지 그린 것들을 비트맵에 기록(Flush)
                coroutine.yield() -- 2. 다음 프레임까지 대기
                canvas:batchBegin() -- 3. 다음 프레임 작업 시작
                count = 0
            end
        end

    canvas:batchEnd()
    self.drawnAll = true
    end), canvas, viewX, viewY
end

function CanvasMap.new(mapData, centerTownName, width, height, zoom)
    ---@class CanvasMap
    local self = setmetatable({}, CanvasMap)

    local loader, canvas, viewX, viewY = self:LoadInc(mapData, centerTownName, width, height, zoom)
    if loader then
        printOnce('canvas initialized!')
    else
        printOnce('canvas initialized failed!')
        return nil
    end

    self.canvas = canvas
    self.data = mapData
    self.selectedBurg = nil
    self.loader = loader
    self.drawnAll = false
    self.viewport = {
        width = width,
        height = height,
        viewX = viewX,
        viewY = viewY,
        zoom = zoom
    }
    return self
end


function CanvasMap:Draw(x, y, w, h, sx, sy, sw, sh)
    if not self.canvas then return end
    -- 1. 먼저 구워진 캔버스를 그립니다.
    g.color(40, 70, 130)
    g.rect(x, y, w, h)
    self.canvas:draw(x, y, w, h, sx, sy, sw, sh)

    if not self.drawnAll then
    -- 상태 확인
        local status = coroutine.status(self.loader)
        
        if status == "dead" then
            print("DEBUG: 코루틴이 죽어있습니다. (더 이상 실행 불가)")
            self.drawnAll = true -- 더 이상 시도하지 않도록 플래그 처리
        else
            -- resume의 반환값(success, error_msg)을 반드시 확인해야 합니다.
            local success, err = coroutine.resume(self.loader)
            if not success then
                print("DEBUG 코루틴 내부 에러 발생!!: ", err)
            end
        end
    end

    -- 2. 선택된 마을이 있다면 그 위에 오버레이를 덧그립니다.
    if self.selectedBurg then
        -- 캔버스 렌더링 옵션(sx, sy, sw, sh)을 고려한 좌표 변환
        local wx, wy = self.selectedBurg.x, self.selectedBurg.y
        
        -- 월드 -> 캔버스 내부 좌표 변환
        local vp = self.viewport
        local halfW = (vp.width / vp.zoom) / 2
        local halfH = (vp.height / vp.zoom) / 2
        
        local canvasX = (wx - (vp.viewX - halfW)) * vp.zoom
        local canvasY = (wy - (vp.viewY - halfH)) * vp.zoom

        -- 캔버스 내부 좌표 -> 현재 화면(Viewport) 좌표 변환
        -- (캔버스의 특정 영역(sw, sh)을 잘라서 화면(w, h)에 그리고 있으므로)
        local ratioX = w / sw
        local ratioY = h / sh
        
        local screenX = x + (canvasX - sx) * ratioX
        local screenY = y + (canvasY - sy) * ratioY

        -- 화면 범위 안에 있을 때만 그리기
        if screenX >= x and screenX <= x + w and screenY >= y and screenY <= y + h then
            -- 강조 효과 (노란색 원)
            g.color(255, 255, 0, 200)
            g.circle(screenX, screenY, 8 * ratioX)
            
            -- 이름표
            g.color(255, 255, 255)
            g.text(0, self.selectedBurg.name, screenX + 10, screenY - 10)
        end
    end
end

-- map:getClickTown(마우스X, 마우스Y, 드로우W, 드로우H, 소스X, 소스Y, 소스W, 소스H)
function CanvasMap:getClickTown(mx, my, drawW, drawH, srcX, srcY, srcW, srcH)
    if not self.data or not self.data.pack then return nil end
    
    local vp = self.viewport
    local pack = self.data.pack

    -- 1. 화면(200x150) 마우스 좌표를 캔버스 소스(400x300) 상의 좌표로 변환
    -- 비율 계산: (소스 크기 / 드로우 크기)
    local ratioX = srcW / drawW
    local ratioY = srcH / drawH
    
    -- 캔버스 데이터 상의 상대 좌표 (sx, sy 기준)
    local canvasRelX = mx * ratioX
    local canvasRelY = my * ratioY
    
    -- 캔버스 전체 데이터 상의 절대 좌표
    local canvasX = srcX + canvasRelX
    local canvasY = srcY + canvasRelY

    -- 2. 캔버스 좌표를 월드 좌표로 역변환
    -- 캔버스는 (viewX - halfW) 지점부터 그려졌으므로 이를 더해줌
    local halfW = (vp.width / vp.zoom) / 2
    local halfH = (vp.height / vp.zoom) / 2
    
    local wx = (canvasX / vp.zoom) + (vp.viewX - halfW)
    local wy = (canvasY / vp.zoom) + (vp.viewY - halfH)

    -- 3. 마을 찾기 루프 (동일)
    local closestBurg = nil
    local clickRadiusWorld = 40 / vp.zoom 
    local minDistanceSq = clickRadiusWorld * clickRadiusWorld 

    local i = 2
    while true do
        local b = pack.burgs[i]
        if not b or type(b) ~= "userdata" then break end
        local dx, dy = b.x - wx, b.y - wy
        local distSq = (dx * dx) + (dy * dy)
        if distSq < minDistanceSq then
            minDistanceSq = distSq
            closestBurg = b
        end
        i = i + 1
    end
    self.selectedBurg = closestBurg
    return closestBurg
end

-- 마을 이름을 입력받아 burg 객체를 반환합니다.
function CanvasMap:getNameTown(name)
    if not self.data or not self.data.pack then return nil end
    local pack = self.data.pack

    local i = 2 -- Azgaar 데이터 특성상 2번부터 실제 데이터
    while true do
        local b = pack.burgs[i]
        
        -- 데이터가 없거나 끝에 도달하면 종료
        if not b or type(b) ~= "userdata" then break end
        
        -- 이름을 비교 (대소문자 구분 없이 하고 싶다면 string.lower 사용)
        if b.name == name then
            return b
        end
        
        i = i + 1
    end
    
    return nil -- 찾지 못한 경우
end

function CanvasMap:getBurgCell(burg)
    -- burg.cell이 직접 저장되어 있다면 그것을 사용하고, 
    -- 없다면 좌표와 가장 가까운 cell을 찾습니다.
    if burg.cell then return burg.cell end
    
    local minState = 1000000
    local targetIdx = -1
    for i, cell in ipairs(self.data.pack.cells) do
        local dx, dy = cell.p[1] - burg.x, cell.p[2] - burg.y
        local dist = dx*dx + dy*dy
        if dist < minState then
            minState = dist
            targetIdx = cell.i
        end
    end
    return targetIdx
end
function CanvasMap:findRoadPath(startTownName, endTownName)
    local pack = self.data.pack
    local startBurg = getCenterBurg(pack.burgs, startTownName)
    local endBurg = getCenterBurg(pack.burgs, endTownName)
    
    if not startBurg or not endBurg then return nil end

    local startNode = self:getBurgCell(startBurg)
    local endNode = self:getBurgCell(endBurg)

    -- A* 알고리즘용 테이블
    local openSet = {startNode}
    local cameFrom = {}
    local gScore = { [startNode] = 0 }

    while #openSet > 0 do
        -- 1. 가장 점수가 낮은 노드 선택 (실제 구현시 우선순위 큐 권장)
        table.sort(openSet, function(a, b) return (gScore[a] or 1e9) < (gScore[b] or 1e9) end)
        local current = table.remove(openSet, 1)

        if current == endNode then
            -- 경로 복원 및 경유지 추출
            return self:reconstructPath(cameFrom, current)
        end

        local cell = pack.cells[current+1]
        if cell.routes then
            for neighborIdx, routeId in pairs(cell.routes) do
                local neighbor = tonumber(neighborIdx)
                -- 도로가 있으므로 가중치를 1(매우 낮음)로 설정
                local tentative_gScore = gScore[current] + 1 

                if neighbor and (not gScore[neighbor] or tentative_gScore < gScore[neighbor]) then
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentative_gScore
                    table.insert(openSet, neighbor)
                end
            end
        end
    end
end

function CanvasMap:findRoadPathWithLimit(startTownName, endTownName, limit)
    local limit = limit or 5 -- 최대 탐색 비용 (거리 혹은 셀 개수)
    local pack = self.data.pack
    
    -- 1. 시작/목표 마을 찾기
    local startBurg = getCenterBurg(pack.burgs, startTownName)
    local endBurg = getCenterBurg(pack.burgs, endTownName)
    if not startBurg or not endBurg then return nil, "TOWN_NOT_FOUND" end

    -- 2. 마을이 속한 셀 찾기
    local startNode = self:getBurgCell(startBurg)
    local endNode = self:getBurgCell(endBurg)

    -- 3. A* 탐색 준비
    local openSet = {startNode}
    local cameFrom = {}
    local gScore = { [startNode] = 0 }
    
    -- 간단한 거리 계산용 로컬 함수
    local function getDist(aIdx, bIdx)
        local c1, c2 = pack.cells[aIdx+1], pack.cells[bIdx+1]
        return math.sqrt((c1.p[1]-c2.p[1])^2 + (c1.p[2]-c2.p[2])^2)
    end

    -- 4. 탐색 루프
    local found = false
    while #openSet > 0 do
        -- 가장 점수가 낮은 노드 추출 (Priority Queue 대용)
        table.sort(openSet, function(a, b) return (gScore[a] or 1e9) < (gScore[b] or 1e9) end)
        local current = table.remove(openSet, 1)

        -- 목적지 도착 성공!
        if current == endNode then
            found = true
            break
        end

        -- [거리 제한] 현재까지의 거리가 리미트를 넘었다면 더 이상 확장 안 함
        if gScore[current] >= limit then
            -- 이 노드는 건너뛰고 openSet의 다른 후보를 확인
        else
            local cell = pack.cells[current+1]
            if cell.routes then
                for neighborIdx, _ in pairs(cell.routes) do
                    local neighbor = tonumber(neighborIdx)
                    -- 도로가 있으면 가중치를 1로 둠 (단순 셀 개수 기준 리미트인 경우)
                    local tentative_gScore = gScore[current] + 1 

                    if neighbor and (not gScore[neighbor] or tentative_gScore < gScore[neighbor]) then
                        cameFrom[neighbor] = current
                        gScore[neighbor] = tentative_gScore
                        table.insert(openSet, neighbor)
                    end
                end
            end
        end
    end

    -- 5. 경로 복원 (성공했을 때만 실행)
    if found then
        local pathCells = {}
        local waypoints = {}
        local totalDist = 0
        local curr = endNode

        while curr do
            table.insert(pathCells, 1, curr)
            local cell = pack.cells[curr+1]
            
            -- 마을 이름 추출 (시작/끝 마을 포함)
            if cell.burg and cell.burg > 0 then
                local b = pack.burgs[cell.burg]
                table.insert(waypoints, 1, b.name)
            end
            
            local prev = cameFrom[curr]
            if prev then
                totalDist = totalDist + getDist(curr, prev)
            end
            curr = prev
        end

        return {
            distance = totalDist,
            towns = waypoints,
            cells = pathCells
        }
    end

    -- 6. 실패 시 반환
    return nil, "PATH_NOT_FOUND_OR_TOO_FAR"
end

return CanvasMap