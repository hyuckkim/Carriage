local FixedImage = require("lib.fixedImage")

-- 1. 스프라이트 데이터 정의 (고정)
local atlas = {
    a = {0, 128, 32, 32}, b = {32, 129, 32, 32}, c = {64, 129, 32, 32}, d = {0, 160, 32, 32},
    e = {32, 160, 32, 32}, f = {64, 160, 32, 32}, g = {0, 192, 32, 32}, h = {0, 224, 32, 32}
}

local pineData = {
    pine_huge_1 = {0, 0, 94, 192},   pine_huge_2 = {96, 0, 94, 192}, 
    pine_large_1 = {17, 0, 62, 131}, pine_large_2 = {113, 0, 62, 131},
    pine_mid_1 = {22, 0, 50, 100},   pine_mid_2 = {118, 0, 50, 100}, 
    pine_small_1 = {32, 0, 32, 69},  pine_small_2 = {128, 0, 32, 69},
    pine_stump_1 = {194, 8, 27, 24}, pine_stump_2 = {194, 40, 28, 24}, pine_stump_3 = {193, 64, 29, 64},
}

-- 2. 가중치 설정 (숫자가 클수록 자주 나옴)
local weights = {
    a = 80, b = 80, c = 80, d = 80, e = 20, f = 20, g = 20, h = 20,
    tree_normal = 40, tree_birch = 20, tree_fruit = 1,
    pine_huge_1 = 5, pine_huge_2 = 5,
    pine_large_1 = 15, pine_large_2 = 15,
    pine_mid_1 = 25, pine_mid_2 = 25,
    pine_small_1 = 40, pine_small_2 = 40,
    pine_stump_1 = 30, pine_stump_2 = 30, pine_stump_3 = 30
}

-- 3. 이미지 미리 로드 (캐싱)
local sprites = {}
local isInitialized = false

local function init()
    if isInitialized then return end
    local greenImg = res.image("assets/green.png")
    local pineImg = res.image("assets/trees/pine.png")

    for k, v in pairs(atlas) do sprites[k] = FixedImage.new(greenImg, v[1], v[2], v[3], v[4]) end
    for k, v in pairs(pineData) do sprites[k] = FixedImage.new(pineImg, v[1], v[2], v[3], v[4]) end
    
    sprites['tree_birch'] = FixedImage.new(res.image("assets/trees/Birch1.png"), 0, 0, 80, 112)
    sprites['tree_normal'] = FixedImage.new(res.image("assets/trees/Tree1.png"), 0, 0, 256, 208)
    sprites['tree_fruit'] = FixedImage.new(res.image("assets/trees/Tree2.png"), 0, 0, 256, 208)
    isInitialized = true
end

-- 4. 내부 가중치 선택 함수
local function getWeightedKey(rng)
    local total = 0
    local sortedKeys = {}
    
    -- 1. 키 추출 및 정렬 (결정론적 결과를 위해 필수)
    for k in pairs(weights) do table.insert(sortedKeys, k) end
    table.sort(sortedKeys) 

    for _, k in ipairs(sortedKeys) do total = total + weights[k] end
    
    -- 2. RNG 호출 방식 분기
    local rand
    if type(rng) == "table" or type(rng) == "userdata" then
        -- C++ RNG 객체인 경우 (rng:range 메서드 사용)
        rand = rng:range(1, total)
    else
        -- 일반 함수(math.random 등)인 경우
        rand = rng(1, total)
    end
    
    local current = 0
    -- 3. 누적 가중치 계산
    for _, key in ipairs(sortedKeys) do
        current = current + weights[key]
        if rand <= current then return key end
    end
end

-- 정해진 확률에 따라 무작위 식물을 생성합니다.
return function(rng)
    init() -- 최초 1회 로드 보장
    local key = getWeightedKey(rng)
    return sprites[key], key
end