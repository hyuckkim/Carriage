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
    self.data.name = data.name or "이름 없는 나그네"
    self.data.traits = data.traits or {}
    self.data.budget = data.budget or 100
    self.data.destination = data.destination or "알 수 없음"
    
    -- 필터링을 위한 플래그
    self.is_customer = true
    return self
end

return Customer