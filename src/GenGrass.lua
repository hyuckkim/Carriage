local ObjectManager = require("lib.ObjectManager")
local getPlant = require("src.Object.Grass")
local HouseGen = require("src.Object.House")

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

local function SpawnTownSceneryCoroutine(townName, townGroup, leftX, range)
    return coroutine.create(function()
        local wagon = ObjectManager:Get('wagon')
        if not wagon then coroutine.yield() end

        -- 1. 결정론적 시드 설정
        local s = 0
        for i = 1, #townName do s = (s * 31) + townName:byte(i) end
        local rng = res.random(s)

        local currentX = leftX
        local endX = leftX + range
        local midX = leftX + 300
        local hasSpawnedHouse = false

        while currentX < endX do
            if not hasSpawnedHouse and currentX >= midX then
                -- 건물 생성
                local sprite, groupName = HouseGen(townGroup, rng)
                
                if sprite then
                    ObjectManager:Register({
                        sprite = sprite,
                        key = "town_building_" .. townName .. "_" .. math.random(1000, 9999),
                        x = currentX,
                        y = wagon.y,
                        layer = -35, 
                        type = "BUILDING",
                        name = groupName,
                        draw = function(self) 
                            self.sprite:draw(self.x, self.y) 
                        end,
                        update = function(self, dt) end
                    })
                end
                
                hasSpawnedHouse = true
                currentX = currentX + 200 
            else
                GenGrass(currentX, rng)
                currentX = currentX + rng:range(40, 120)
            end
            
            coroutine.yield() 
        end
    end)
end

return {
    GenGrass = GenGrass,
    SpawnTownScenery = SpawnTownSceneryCoroutine
}