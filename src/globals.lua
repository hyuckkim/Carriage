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