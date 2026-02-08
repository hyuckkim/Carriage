local testCanvas = nil
local canvasSize = 200

function Init()
    res.font("맑은 고딕", 20)

    InitializeMap()
end
function InitializeMap()
    -- 1. 200x200 사이즈의 작은 테스트 캔버스 생성
    print("Creating Test Canvas...")
    testCanvas = g.offscreenCanvas(canvasSize, canvasSize)
    print(type(testCanvas))

    -- 2. 캔버스에 그리기 (베이킹 테스트)
    -- batchBegin을 쓰면 성능이 극대화되지만, 단일 명령은 그냥 써도 작동하게 설계했습니다.
    testCanvas:batchBegin()
        -- 배경을 약간 투명한 파란색으로 채움
        testCanvas:color(0, 0, 255, 150)
        testCanvas:rect(0, 0, canvasSize, canvasSize, true)

        -- 중앙에 노란색 원 하나 그림
        testCanvas:color(255, 255, 0, 255)
        testCanvas:circle(100, 100, 50, true)

        -- "OFFSCREEN" 텍스트 테스트 (0번 폰트가 있다고 가정)
        testCanvas:color(255, 255, 255, 255)
        testCanvas:text(0, "OFFSCREEN", 10, 10)
    testCanvas:batchEnd()
    
    print("Canvas Baking Complete!")
end

function Draw()
    -- 매 프레임 화면을 녹색(세피아 대신 테스트용)으로 지우기
    g.color(50, 100, 50, 150)
    g.rect(0, 0, 800, 600)

    -- 3. 구워진 캔버스를 화면에 출력
    -- 마우스 좌표를 가져올 수 있다면 마우스 위치에 그려보세요.
    -- 여기서는 일단 (100, 100) 고정 위치에 그립니다.
    if testCanvas then
        -- 캔버스 자체를 출력 (이때 g.push/pop 영향도 받는지 확인 가능)
        testCanvas:draw(100, 100)
    end

    -- 4. 비교를 위해 전역 g로 화면에 직접 하나 더 그림
    g.color(0, 255, 0)
    g.circle(400, 300, 20)
end