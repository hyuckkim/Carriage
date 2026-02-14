local ObjectManager = require("lib.ObjectManager")

-- Customer.lua
local Character = require("src.Object.character")
---@class Customer: Character
local Customer = setmetatable({}, { __index = Character })
Customer.__index = Customer

---@return Customer
function Customer.new(key, anim, data)
    ---@class Customer
    local self = Character.new(key, anim)
    setmetatable(self, Customer)

    -- 고객 전용 데이터
    self.data = data or {}
    self.data.name = self.data.name or "홍길동"
    self.data.traits = self.data.traits or {}
    self.data.budget = self.data.budget or 100
    self.data.destination = self.data.destination or "알 수 없음"
    data.isBoarding = false

    -- 위치 보정
    self.ox, self.oy = -40, -64
    self.sayOX, self.sayOY = 40, 20
    
    -- 상태 및 필터링 플래그
    self.is_customer = true
    self.is_traveling = false
    self.travel_index = 0

    return self
end

function Customer:GetPersistentData()
    -- 1. 부모(Character)의 데이터 먼저 획득 (Object 데이터까지 포함됨)
    local data = getmetatable(Customer).__index.GetPersistentData(self)
    
    -- 2. Customer 전용 데이터 추가
    data.type = "Customer"
    data.customerData = self.data
    data.isBoarding = self.isBoarding
    data.is_traveling = self.is_traveling
    data.travel_index = self.travel_index
    data.isAbsolute = self.isAbsolute
    
    return data
end

function Customer.newFromData(d)
    ---@class Customer
    local self = Character.newFromData(d)
    setmetatable(self, Customer)
    
    -- 2. Customer 상태 복구
    self.is_customer = true
    self.data = d.customerData
    self.isBoarding = d.isBoarding or false
    self.is_traveling = d.is_traveling
    self.travel_index = d.travel_index or 0
    self.isAbsolute = d.isAbsolute or false
    
    -- 만약 여행 중이었다면 레이어 보정 등을 다시 수행해야 할 수도 있음
    if self.is_traveling then
        ObjectManager:SetLayer(self.key, -15)
    end
    
    return self
end

function Customer:StartTravel(idx, wagon)
    self.travel_index = idx -- 저장용 인덱스 보관
    self.moveTime = 0
    self.vx, self.vy = 0, 0
    self:act('idle')
    ObjectManager:SetLayer(self.key, -15)
    self:StopSay()
    self:setPattern(self.travel_pattern or nil)
    
    -- 마차 내부 좌석 위치 세팅
    if idx == 1 then
        self.x, self.y = wagon.x + 56, wagon.y - 28
        self.anim.flipX = true
    elseif idx == 2 then
        self.x, self.y = wagon.x + 78, wagon.y - 26
        self.anim.flipX = true
    elseif idx == 3 then
        self.x, self.y = wagon.x + 104, wagon.y - 26
        self.anim.flipX = false
    elseif idx == 4 then
        self.x, self.y = wagon.x + 114, wagon.y - 31
        self.anim.flipX = false
    end

    self.isAbsolute = true
    self.is_traveling = true
end

function Customer:EndTravel(town, wagon)
    self.is_traveling = false
    self.isAbsolute = false -- 이제 마차에 귀속되지 않음
    ObjectManager:SetLayer(self.key, 1) -- 마차보다 앞으로 나오게 설정
    
    -- 목적지 도착 여부만 반환하거나 플래그로 저장
    self.isAtDestination = (town == self.data.destination)
end

return Customer