local MapPathfinder = {}
MapPathfinder.__index = MapPathfinder

local function getCenterBurg(burgs, name)
    local i = 2
    while true do
        local b = burgs[i]
        if not b or type(b) ~= "userdata" then break end
        if b.name == name then return b end
        i = i + 1
    end
    return nil
end

function MapPathfinder.new(mapData)
    local self = setmetatable({}, MapPathfinder)
    self.data = mapData
    return self
end

function MapPathfinder:getBurgCell(burg)
    if burg.cell then return burg.cell end

    local minState = 1e9
    local targetIdx = -1

    for _, cell in ipairs(self.data.pack.cells) do
        local dx = cell.p[1] - burg.x
        local dy = cell.p[2] - burg.y
        local dist = dx*dx + dy*dy
        if dist < minState then
            minState = dist
            targetIdx = cell.i
        end
    end

    return targetIdx
end

function MapPathfinder:findRoadPath(startTownName, endTownName)
    local pack = self.data.pack
    local startBurg = getCenterBurg(pack.burgs, startTownName)
    local endBurg = getCenterBurg(pack.burgs, endTownName)
    print("mapfilter!")
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
            -- 그런 일은 있을 수가 없음! 제발!
            print("current가 endNode와 같습니다. 어떻게?")
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
function MapPathfinder:pickDestination(startTownName)
    local pack = self.data.pack
    local startBurg = getCenterBurg(pack.burgs, startTownName)
    if not startBurg then return nil end

    -- 1. 시작 셀 찾기
    local startNode = self:getBurgCell(startBurg)
    local queue = {startNode}
    local visited = { [startNode] = true }
    local gScore = { [startNode] = 0 }
    local head = 1
    
    local searchLimit = 100 
    local chance = 0.6
    local lastValidCandidates = nil 

    while head <= #queue do
        local currentLevelNodes = {}
        local currentStep = gScore[queue[head]]
        if not currentStep then break end

        -- 현재 계층 노드 수집
        while head <= #queue and gScore[queue[head]] == currentStep do
            table.insert(currentLevelNodes, queue[head])
            head = head + 1
        end

        local candidatesInLevel = {}
        for _, nodeIdx in ipairs(currentLevelNodes) do
            -- [보정] cells index 0 기준 -> Lua 1 기준
            local cell = pack.cells[nodeIdx + 1]
            if cell and cell.routes then
                for neighborIdxStr, _ in pairs(cell.routes) do
                    local neighbor = tonumber(neighborIdxStr)
                    
                    if neighbor and not visited[neighbor] then
                        visited[neighbor] = true
                        gScore[neighbor] = currentStep + 1
                        table.insert(queue, neighbor)
                        
                        -- [보정] neighbor index 0 기준 -> Lua 1 기준
                        local nCell = pack.cells[neighbor + 1]
                        
                        -- Azgaar에서 burg가 0이면 마을 없음, >0 이면 마을 존재
                        if nCell and nCell.burg and nCell.burg > 0 then
                            -- [보정] burg index 0 기준 -> Lua 1 기준
                            local b = pack.burgs[nCell.burg + 1] 
                            if b and b.name and b.name ~= startTownName then
                                table.insert(candidatesInLevel, b)
                            end
                        end
                    end
                end
            end
        end

        -- 이번 계층에서 마을을 찾았다면 60% 확률 주사위
        if #candidatesInLevel > 0 then
            lastValidCandidates = candidatesInLevel
            if math.random() < chance then
                return candidatesInLevel[math.random(#candidatesInLevel)], currentStep + 1
            end
        end

        if currentStep >= searchLimit then break end
    end

    -- 끝까지 안 나오면 가장 가까웠던 놈이라도 반환
    if lastValidCandidates then
        return lastValidCandidates[math.random(#lastValidCandidates)], "fallback"
    end

    return nil, "NO_TOWN_IN_RANGE"
end
function MapPathfinder:findRoadPathWithLimit(startTownName, endTownName, limit)
    local limit = limit or 5 -- 최대 탐색 비용 (거리 혹은 셀 개수)
    local pack = self.data.pack
    
    -- 1. 시작/목표 마을 찾기
    local startBurg = getCenterBurg(pack.burgs, startTownName)
    local endBurg = getCenterBurg(pack.burgs, endTownName)
    if not startBurg or not endBurg then return nil, "TOWN_NOT_FOUND" end

    -- 2. 마을이 속한 셀 찾기
    local startNode = self.pathfinder:getBurgCell(startBurg)
    local endNode = self.pathfinder:getBurgCell(endBurg)

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

return MapPathfinder