
local map = {}
local townMiniMap = nil
local function FlattenPoints(complex_points)
    local flat = {}
    if not complex_points then return flat end
    
    for i = 1, #complex_points do
        local p = complex_points[i]
        if type(p) == "table" or type(p) == "userdata" then
            table.insert(flat, p[1])
            table.insert(flat, p[2])
        end
    end
    return flat
end

-- Azgaar의 [[x,y,z], [x,y,z]] 구조를 위한 전용 플래트너
local function FlattenAzgaarPoints(complex_points)
    local flat = {}
    if not complex_points then return flat end
    for i = 1, #complex_points do
        local p = complex_points[i]
        -- p[1]은 x, p[2]는 y (p[3]은 무시)
        table.insert(flat, p[1])
        table.insert(flat, p[2])
    end
    return flat
end
local function DebugBurgs(mapData)
    if not mapData or not mapData.pack then 
        print("DEBUG: mapData.pack 이 없습니다.")
        return 
    end

    local burgs = mapData.pack.burgs
    print("DEBUG: pack.burgs 타입: " .. type(burgs))
    
    -- 인덱스 기반이든 키 기반이든 무조건 다 출력
    local count = 0
    for k, v in pairs(burgs) do
        count = count + 1
        if type(v) == "table" then
            print(string.format("DEBUG: 인덱스[%s] 이름: %s, 좌표: (%s, %s)", 
                tostring(k), tostring(v.name), tostring(v.x), tostring(v.y)))
        else
            print(string.format("DEBUG: 인덱스[%s] 데이터 타입: %s (값: %s)", 
                tostring(k), type(v), tostring(v)))
        end
        
        if count > 10 then break end -- 너무 많으면 상위 10개만
    end
end
local function GetCellColor(h)
    if h < 20 then return 40, 70, 130 
    elseif h < 50 then return 80, 150, 80 
    elseif h < 80 then return 120, 160, 100 
    else return 200, 200, 200 
    end
end

function BakeComprehensiveMap(mapData, centerTownName, width, height, zoom)
    if not mapData or not mapData.pack then return nil end
    local pack = mapData.pack
    
    -- 1. 중심 마을 찾기 (뷰포트 기준점 설정)
    local centerBurg = nil
    local i = 2
    while true do
        local b = pack.burgs[i]
        if not b or type(b) ~= "userdata" then break end
        if b.name == centerTownName then centerBurg = b break end
        i = i + 1
    end
    if not centerBurg then return nil end

    local canvas = g.offscreenCanvas(width, height)
    local viewX, viewY = centerBurg.x, centerBurg.y
    local halfW, halfH = (width / zoom) / 2, (height / zoom) / 2
    
    -- 좌표 변환 헬퍼 함수
    local function worldToScreen(wx, wy)
        return (wx - (viewX - halfW)) * zoom, (wy - (viewY - halfH)) * zoom
    end

    canvas:batchBegin()
        -- 배경
        canvas:color(30, 50, 100)
        canvas:rect(0, 0, width, height, true)

        -- A. 지형 셀 (화면 범위 내)
        local cIdx = 1
        while true do
            local cell = pack.cells[cIdx]
            if not cell or type(cell) ~= "userdata" then break end
            
            if math.abs(cell.p[1] - viewX) < (halfW * 1.5) and 
               math.abs(cell.p[2] - viewY) < (halfH * 1.5) then
                
                local r, g, b = GetCellColor(cell.h or 0)
                canvas:color(r, g, b) -- 채우기 색상
                
                local poly = {}
                for _, vIdx in ipairs(cell.v) do
                    local vObj = pack.vertices[vIdx + 1]
                    if vObj then
                        local sx, sy = worldToScreen(vObj.p[1], vObj.p[2])
                        table.insert(poly, sx) table.insert(poly, sy)
                    end
                end
                
                if #poly >= 6 then 
                    -- 1. 먼저 면을 채우고
                    canvas:polygon(poly) 
                    canvas:polyline(poly, true, 1.0) 
                end
            end
            cIdx = cIdx + 1
        end

        -- B. 도로 (Routes) 그리기
        local rIdx = 1
        while true do
            local route = pack.routes[rIdx]
            if not route or type(route) ~= "userdata" then break end
            
            canvas:color(200, 160, 110, 150) -- 도로 색상 (베이지톤 반투명)
            local linePoints = {}
            for j = 1, #route.points do
                local p = route.points[j] -- [x, y, z] 형태
                local sx, sy = worldToScreen(p[1], p[2])
                table.insert(linePoints, sx)
                table.insert(linePoints, sy)
            end
            if #linePoints >= 4 then canvas:polyline(linePoints, false, 1.5) end
            rIdx = rIdx + 1
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
                canvas:text(0, b.name, sx + 8, sy - 8)
            end
            bIdx = bIdx + 1
        end

    canvas:batchEnd()
    return canvas
end

function Init()
    map.task = res.jsonAsync("map.json")
    res.font("맑은 고딕", 20)
end

function Update(dt)
    if map.task and not map.task.isDone and map.task:check() then
        map.data = map.task:getResult()
        
        -- 로드가 끝나면 바로 "London" 지도를 굽습니다.
        townMiniMap = BakeComprehensiveMap(map.data, "상호", 300, 300, 4.0)
        print("미니 맵 생성 완료: " .. type(townMiniMap))
    end
end

function Draw()
    g.color(255, 255, 255, 150)
    g.rect(0, 0, 800, 600)
    if townMiniMap then
        -- 매 프레임 수천 개의 루프 없이 이미지 한 장처럼 출력!
        townMiniMap:draw(50, 50)
    else
        g.color(0,0,0)
        g.text(0, "로딩 중...", 10, 10)
    end
end