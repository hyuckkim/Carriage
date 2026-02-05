local text
local task -- 변수명을 task로 하면 더 명확하겠죠?
local data

function Init()
    sys.setSize(400, 400)
    sys.setPos(1400, 600)
    text = res.font("맑은 고딕", 20)
    print('initialize start...')
    -- 단일 Task 객체를 받음
    task = res.jsonAsync("map.json")
end

function Update(dt)
    -- 리스트가 아니므로 직접 체크
    if task and not task.isDone then
        if task:check() then
            data = task:getResult()
            print("로딩 완료! 결과 타입:", type(data))
        end
    end
end

function Draw()
    -- 로딩 중 연출 (사각형 회전 등)
    if task and not task.isDone then
        g.color(255, 255, 255, 150)
        g.text(text, "Loading map data...", 100, 180)
        -- 여기서 애니메이션을 넣으면 PeekMessage 덕분에 부드럽게 돌아갑니다.
    end

    if data then
        g.color(255, 255, 255)
        -- 데이터 구조가 data.info.description 인지 확인 필요
        g.text(text, data.info.description, 10, 10)
    end
end