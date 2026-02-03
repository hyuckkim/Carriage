local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new()
    local obj = {
        states = {},
        current = nil,
        currentStateName = nil
    }
    return setmetatable(obj, StateMachine)
end

-- 상태 등록 함수
-- name: 상태 이름
-- callbacks: { onEnter, onUpdate, onExit } 함수들을 담은 테이블
function StateMachine:addState(name, callbacks)
    self.states[name] = callbacks
end

-- 상태 이행 (Transition)
function StateMachine:transition(nextStateName, ...)
    local nextState = self.states[nextStateName]
    if not nextState then 
        print("[FSM] Error: State '" .. nextStateName .. "' not found.")
        return 
    end

    -- 1. 기존 상태의 Exit 함수 실행
    if self.current and self.current.onExit then
        self.current.onExit()
    end

    -- 2. 상태 교체
    self.currentStateName = nextStateName
    self.current = nextState

    -- 3. 새 상태의 Enter 함수 실행 (가변 인자 전달 가능)
    if self.current.onEnter then
        self.current.onEnter(...)
    end
end

-- 매 프레임 실행될 업데이트
function StateMachine:update(dt)
    if self.current and self.current.onUpdate then
        self.current.onUpdate(dt)
    end
end

function StateMachine:draw()
    if self.current and self.current.onDraw then
        self.current.onDraw()
    end
end

return StateMachine