local ObjectManager = require("lib.ObjectManager")
local getPlant = require("src.Object.Grass")
local grassCounter = 0

local function GenGrass (initPos, rng)
    local wagon = ObjectManager:Get('wagon')
    if not wagon then return end
    
    -- 1. 랜덤 값 가져오기 로직 분리
    local function getVal(min, max)
        if type(rng) == "userdata" then
            return rng:range(min, max) -- C++ 객체일 때
        elseif type(rng) == "function" then
            return rng(min, max)       -- 루아 함수일 때
        else
            return math.random(min, max) -- 없을 때
        end
    end

    local sprite, name = getPlant(rng) 
    local isTree = string.find(name, "tree") or string.find(name, "pine")
    grassCounter = grassCounter + 1
    
    ObjectManager:Register({
        key = "env_" .. grassCounter .. "_" .. getVal(1, 10000),
        x = initPos,
        y = wagon.y,
        layer = isTree and -40 or -30,
        sprite = sprite,
        draw = function(self) self.sprite:draw(self.x, self.y) end,
        update = function() end
    })
end

local function SpawnTownSceneryCoroutine(townName, leftX, range)
    return coroutine.create(function()
        local s = 0
        for i = 1, #townName do s = (s * 31) + townName:byte(i) end
        local rng = res.random(s)

        local currentX = leftX
        local endX = leftX + range

        while currentX < endX do
            -- 1. 하나 생성
            GenGrass(currentX, rng)
            
            -- 2. 다음 위치 계산
            currentX = currentX + rng:range(40, 120)
            
            -- 3. 이 지점에서 실행을 멈추고 다음 프레임으로 넘김
            coroutine.yield() 
        end
    end)
end

return {
    GenGrass = GenGrass,
    SpawnTownScenery = SpawnTownSceneryCoroutine
}