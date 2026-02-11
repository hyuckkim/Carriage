---@class FixedImage
local FixedImage = {}
FixedImage.__index = FixedImage

---@class FixedImage
local FixedImage = {}
FixedImage.__index = FixedImage

function FixedImage.new(imgId, sx, sy, sw, sh)
    ---@class FixedImage
    local obj = {
        imgId = imgId,
        sx = sx, sy = sy,
        sw = sw, sh = sh,
        ox = sw / 2,
        oy = sh, 
        flipX = false,
        visible = true
    }
    return setmetatable(obj, FixedImage)
end

function FixedImage:draw(x, y, dw, dh)
    if not self.visible then return end

    local finalW = dw or self.sw
    local finalH = dh or self.sh

    g.image(
        self.imgId, 
        x - self.ox, y - self.oy,
        finalW, finalH, 
        self.sx, self.sy, self.sw, self.sh, 
        self.flipX
    )
end

function FixedImage:update(dt) end
function FixedImage:act() end

return FixedImage