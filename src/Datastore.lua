local Datastore = {
    -- 모든 최종 데이터(동기 로드된 설정 + 비동기 완료된 결과)를 보관
    cache = {
        settings = { mainSize = 1.5 },
    },
    -- 현재 진행 중인 비동기 작업들
    tasks = {},
}

-- 내부 함수: 테이블 내용물 교체 (기존 유지)
local function replaceContents(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then return end
    for k in pairs(target) do target[k] = nil end
    for k, v in pairs(source) do target[k] = v end
end

-- 비동기 Task 등록
function Datastore.registerTask(key, task)
    Datastore.tasks[key] = task
end

-- 핵심: 데이터 가져오기 (On-Demand)
function Datastore.get(key)
    -- 1. 이미 캐시에 있으면 즉시 반환 (동기 데이터 포함)
    if Datastore.cache[key] then
        return Datastore.cache[key]
    end

    -- 2. 캐시에 없는데 진행 중인 Task가 있다면 체크
    local t = Datastore.tasks[key]
    if t then
        if t:check() then
            local newData = t:getResult()
            -- 기존에 빈 테이블이 있었다면 내용물만 교체, 없었다면 통째로 삽입
            Datastore.update(key, newData)
            Datastore.tasks[key] = nil -- Task 종료
            return Datastore.cache[key]
        end
    end

    return nil
end

-- 데이터 업데이트 (동기/비동기 공용)
function Datastore.update(key, newData)
    if type(newData) == "table" and Datastore.cache[key] then
        replaceContents(Datastore.cache[key], newData)
    else
        Datastore.cache[key] = newData
    end
end

return Datastore