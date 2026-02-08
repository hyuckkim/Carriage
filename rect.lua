local map = {
    time = 0,
    is_initialized = false,
    data = nil,
    task = nil,
    cells = {},   -- 캐싱된 폴리곤 데이터
    routes = {},  -- 캐싱된 도로 데이터 (Flattened)
    config = {
        screenW = 600,
        screenH = 600,
        zoom = 4,
        target_burg_idx = 22
    }
}

local chunk_system = {
    size = 200, -- 한 청크의 가로세로 크기 (픽셀 단위)
    grid = {}   -- [y][x] = { cell_indices... }
}

-- 초기화 시점에 청크 등록
local function BuildChunks()
    for i, cell in ipairs(map.cells) do
        -- 셀의 중심점이나 첫 번째 점을 기준으로 청크 계산
        local cx, cy = cell.points[1], cell.points[2]
        local gx = math.floor(cx / chunk_system.size)
        local gy = math.floor(cy / chunk_system.size)
        
        chunk_system.grid[gy] = chunk_system.grid[gy] or {}
        chunk_system.grid[gy][gx] = chunk_system.grid[gy][gx] or {}
        table.insert(chunk_system.grid[gy][gx], i)
    end
end

-- 2차원 [x, y, z] 배열을 1차원 [x1, y1, x2, y2...]로 변환
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

-- 고도에 따른 색상 반환
local function GetCellColor(h)
    if h < 20 then return 40, 70, 130      -- Deep Sea
    else return 80, 150, 80               -- Mountain
    end
end

local function InitializeMap()
    if not map.data or not map.data.pack then return end
    
    local pack = map.data.pack
    
    -- 1. 셀(영역) 캐싱
    map.cells = {}
    for i = 1, #pack.cells do
        local cell = pack.cells[i]
        local poly = {}
        for _, vIdx in ipairs(cell.v or {}) do
            local vObj = pack.vertices[vIdx + 1]
            if vObj and vObj.p then
                table.insert(poly, vObj.p[1])
                table.insert(poly, vObj.p[2])
            end
        end
        table.insert(map.cells, { points = poly, h = cell.h or 0 })
    end

    -- 2. 도로(Route) 캐싱 (매 프레임 Flatten 연산 방지)
    map.routes = {}
    for _, r in ipairs(pack.routes or {}) do
        if r.points then
            table.insert(map.routes, {
                points = FlattenPoints(r.points),
                is_main = (r.group == "main")
            })
        end
    end
    BuildChunks()

    map.is_initialized = true
    print("Map Processed: " .. #map.cells .. " cells, " .. #map.routes .. " routes.")
end
-- 도로 렌더링
local function DrawRoutes()
    for _, r in ipairs(map.routes) do
        if #r.points >= 4 then
            if r.is_main then
                g.color(200, 140, 80, 150)
                g.lineWidth(1.5)
            else
                g.color(180, 180, 180, 100)
                g.lineWidth(0.8)
            end
            g.polyline(r.points)
        end
    end
end

-- 도시 렌더링
local function DrawBurgs(currentTarget)
    local burgs = map.data.pack.burgs
    g.lineWidth(1.0)
    
    for i = 1, #burgs do
        local b = burgs[i]
        
        -- 핵심: b가 숫자(0)가 아닌 '테이블'일 때만 로직 수행
        if type(b) == "table" or type(b) == "userdata" then
            g.color(255, 255, 255)
            g.circle(b.x, b.y, 3)
            
            -- currentTarget(우리가 보고 있는 대상)과 같은 도시라면 이름 출력
            if currentTarget and type(currentTarget) ~= "number" and currentTarget.name == b.name then
                g.color(255, 255, 255)
                g.text(0, b.name, b.x + 5, b.y - 5)
            end
        end
    end
end

function Init()
    sys.setSize(map.config.screenW, map.config.screenH)
    sys.setPos(1200, 400)
    map.task = res.jsonAsync("map.json")
    res.font('맑은 고딕', 20)
end

function Update(dt)
    map.time = map.time + dt
    if map.task and not map.task.isDone and map.task:check() then
        map.data = map.task:getResult()
        InitializeMap()
    end
end

function DrawMapRegion(sx, sy, sw, sh, dx, dy, dw, dh)
    g.push()
    
    -- 1. 화면의 목적지(d)로 이동
    g.translate(dx, dy)
    
    -- 2. 소스 크기(s)를 목적지 크기(d)에 맞게 확대/축소 비율 계산
    local scaleX = dw / sw
    local scaleY = dh / sh
    g.scale(scaleX, scaleY, 0, 0)
    
    -- 3. 지도의 소스 시작점(s)을 원점으로 당김
    g.translate(-sx, -sy)

    -- 4. 실제 그리기 (가시성 검사 포함)
    DrawBurgs(map.config.target_burg_idx)
    DrawRoutes()
    g.pop()
end

function Draw()
    if not map.is_initialized then return end

    local sw, sh = map.config.screenW, map.config.screenH -- 600, 600
    local target = map.data.pack.burgs[map.config.target_burg_idx]
    
    -- [Source 영역 계산] 
    -- 타겟 중심으로 지도를 얼마나(zoom) 잘라낼 것인가?
    local viewW = sw / map.config.zoom
    local viewH = sh / map.config.zoom
    local viewX = target.x - viewW / 2
    local viewY = target.y - viewH / 2

    DrawMapRegion(viewX, viewY, viewW, viewH, 0, 0, sw, sh)
end