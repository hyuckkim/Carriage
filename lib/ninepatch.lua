local NinePatch = {}
NinePatch.__index = NinePatch

-- imgId: 이미지 번호
-- sx, sy, sw, sh: 시트 내 영역
-- l, r, t, b: 왼쪽, 오른쪽, 위, 아래 슬라이스 크기 (pixel)
function NinePatch.new(imgId, sx, sy, sw, sh, l, r, t, b)
    local obj = {
        img = imgId,
        sx = sx, sy = sy,
        sw = sw, sh = sh,
        l = l, r = r, t = t, b = b
    }
    return setmetatable(obj, NinePatch)
end

function NinePatch:draw(x, y, width, height)
    -- 소스(Source) 좌표 계산
    local s = {
        x0 = self.sx,
        x1 = self.sx + self.l,
        x2 = self.sx + self.sw - self.r,
        wMid = self.sw - self.l - self.r,
        
        y0 = self.sy,
        y1 = self.sy + self.t,
        y2 = self.sy + self.sh - self.b,
        hMid = self.sh - self.t - self.b
    }

    -- 목적지(Destination) 좌표 계산
    local d = {
        x0 = x,
        x1 = x + self.l,
        x2 = x + width - self.r,
        wMid = width - self.l - self.r,
        
        y0 = y,
        y1 = y + self.t,
        y2 = y + height - self.b,
        hMid = height - self.t - self.b
    }

    -- 1. 모서리 (고정 크기)
    g.image(self.img, d.x0, d.y0, self.l, self.t, s.x0, s.y0, self.l, self.t) -- 좌상
    g.image(self.img, d.x2, d.y0, self.r, self.t, s.x2, s.y0, self.r, self.t) -- 우상
    g.image(self.img, d.x0, d.y2, self.l, self.b, s.x0, s.y2, self.l, self.b) -- 좌하
    g.image(self.img, d.x2, d.y2, self.r, self.b, s.x2, s.y2, self.r, self.b) -- 우하

    -- 2. 변 (늘리기)
    g.image(self.img, d.x1, d.y0, d.wMid, self.t, s.x1, s.y0, s.wMid, self.t) -- 상
    g.image(self.img, d.x1, d.y2, d.wMid, self.b, s.x1, s.y2, s.wMid, self.b) -- 하
    g.image(self.img, d.x0, d.y1, self.l, d.hMid, s.x0, s.y1, self.l, s.hMid) -- 좌
    g.image(self.img, d.x2, d.y1, self.r, d.hMid, s.x2, s.y1, self.r, s.hMid) -- 우

    -- 3. 중앙
    g.image(self.img, d.x1, d.y1, d.wMid, d.hMid, s.x1, s.y1, s.wMid, s.hMid)
end

return NinePatch