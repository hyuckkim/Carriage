local Anim = require("lib.anim")

---@class Object
local Object = {}
Object.__index = Object


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

function Object:GetPersistentData()
    -- 자식 클래스들이 확장하기 편하도록 기본 테이블 생성
    local data = {
        type = "Object", -- 팩토리 식별용
        key = self.key,
        x = self.x,
        y = self.y,
        ox = self.ox,
        oy = self.oy,
        layer = self.layer,
        -- Anim 객체에게 직접 데이터를 요구함 (경로 포함)
        animData = self.anim:GetPersistentData()
    }
    return data
end

function Object.newFromData(d)
    local ad = d.animData
    local restoredAnim = Anim.new(ad.imgPaths, ad.fw, ad.fh, ad.cols)
    restoredAnim.animations = ad.animations or {}
    
    if ad.current then
        restoredAnim.current = ad.current
        restoredAnim.frameIdx = ad.frameIdx or 1
        restoredAnim.timer = ad.timer or 0
     end
    restoredAnim.flipX = ad.flipX
    
    local self = Object.new(d.key, restoredAnim)
    self.x, self.y = d.x, d.y
    self.ox, self.oy = d.ox, d.oy
    self.layer = d.layer or 1
    
    return self
end

return Object