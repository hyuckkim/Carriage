local Object = {}
Object.__index = Object

---@return Object
function Object.new(key, anim)
    ---@class Object
    local self = setmetatable({}, Object)
    self.key = key
    ---@type Anim
    self.anim = anim
    self.x, self.y = 0, 0
    self.ox, self.oy = 0, 0
    self.layer = 1
    return self
end

function Object:update(dt)
    if self.anim then self.anim:update(dt) end
end

function Object:draw(scrollX, scrollY)
    if self.anim then
        self.anim:draw(self.x - scrollX + self.ox, self.y - scrollY + self.oy)
    end
end

function Object:act(key)
    if self.anim then
        self.anim:play(key)
    end
end

return Object