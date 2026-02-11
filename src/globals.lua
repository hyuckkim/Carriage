function Range(a, b)
    local t = {}
    local start, stop
    
    -- 인자가 하나면 1 ~ a, 두 개면 a ~ b
    if b == nil then
        start, stop = 1, a
    else
        start, stop = a, b
    end

    -- 루프를 돌며 테이블 생성
    for i = start, stop do
        table.insert(t, i)
    end
    
    return t
end

function MergeTable(t1, t2)
    local result = {}
    for k, v in pairs(t1) do result[k] = v end
    for k, v in pairs(t2) do result[k] = v end
    return result
end

function FindIndex(tbl, target)
    for i, v in ipairs(tbl) do
        if v == target then
            return i
        end
    end
    return 1 -- 기본값
end