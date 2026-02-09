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

    self.data = data or {}
    self.data.name = data.name or "홍길동"
    self.data.traits = data.traits or {}
    self.data.budget = data.budget or 100
    self.data.destination = data.destination or "알 수 없음"
    self.ox, self.oy = -40, 32
    self.sayOX, self.sayOY = 40, 20
    
    -- 필터링을 위한 플래그
    self.is_customer = true
    return self
end

function Customer:StartTravel(idx, wagon)
    self.moveTime = 0
    self.vx, self.vy = 0, 0
    self:act('idle')
    ObjectManager:SetLayer(self.key, -15)
    self:StopSay()
    self:setPattern(self.travel_pattern or nil)
    
    print(idx)
    if idx == 1 then
        self.x, self.y = wagon.x + 54, wagon.y - 30
        self.anim.flipX = true
    elseif idx == 2 then
        self.x, self.y = wagon.x + 80, wagon.y - 26
        self.anim.flipX = true
    elseif idx == 3 then
        self.x, self.y = wagon.x + 121, wagon.y - 27
        self.anim.flipX = false
    elseif idx == 4 then
        self.x, self.y = wagon.x + 127, wagon.y - 51
        self.anim.flipX = false
    end

    self.isAbsolute = true
    self.is_traveling = true
end

function Customer:EndTravel(wagon)
    self:StopSay()
    self:setPattern(self.arrive_pattern or nil)

    self.x, self.y = math.random() * 400 + 50, wagon.y
    self.isAbsolute = false
    self.is_traveling = false
    ObjectManager:SetLayer(self.key, 1)
end

return Customer