local atlas = {
    helmet = {"assets/houses/a.png", 192, 128},
    village = {"assets/houses/b.png", 320, 144},
    town = {"assets/houses/c.png", 320, 144},
    city = {"assets/houses/d.png", 326, 160},
    capital = {"assets/houses/e.png", 320, 208}
}

local FixedImage = require("lib.fixedImage")

-- 1. 마을 등급별 에셋 정의 (경로, 너비, 높이)
local houseData = {
    helmet  = {"assets/houses/a.png", 192, 128},
    village = {"assets/houses/b.png", 320, 144},
    town    = {"assets/houses/c.png", 320, 144},
    city    = {"assets/houses/d.png", 326, 160},
    capital = {"assets/houses/e.png", 320, 208}
}

-- 2. 등급별 등장 가중치 (필요 시 조정)
-- 예: 'town' 등급 마을이라도 가끔 작은 집(village)이 섞여 나올 수 있게 설계
local weights = {
    helmet  = 100,
    village = 100,
    town    = 100,
    city    = 100,
    capital = 100
}

local sprites = {}
local isInitialized = false

local function init()
    if isInitialized then return end
    for k, v in pairs(houseData) do
        -- 통이미지이므로 Rect는 0, 0부터 전체 크기만큼 설정
        sprites[k] = FixedImage.new(res.image(v[1]), 0, 0, v[2], v[3])
    end
    isInitialized = true
end

-- 안전한 키 추출 (정렬 포함)
local function getSortedKeys()
    local keys = {}
    for k in pairs(weights) do table.insert(keys, k) end
    table.sort(keys)
    return keys
end

--- @param forceGroup string|nil 특정 등급을 강제하고 싶을 때 사용 (예: "capital")
--- @param rng any C++ RNG 객체 혹은 math.random
return function(forceGroup, rng)
    init()

    -- 1. 강제 지정된 그룹이 있다면 해당 스프라이트 즉시 반환
    if forceGroup and sprites[forceGroup] then
        return sprites[forceGroup], forceGroup
    end

    -- 2. 가중치 기반 랜덤 선택 (기존 로직 활용)
    local sortedKeys = getSortedKeys()
    local total = 0
    for _, k in ipairs(sortedKeys) do total = total + weights[k] end

    local rand = (type(rng) == "table" or type(rng) == "userdata") and rng:range(1, total) or rng(1, total)
    
    local current = 0
    for _, key in ipairs(sortedKeys) do
        current = current + weights[key]
        if rand <= current then
            return sprites[key], key
        end
    end
end