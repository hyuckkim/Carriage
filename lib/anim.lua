---@class Anim
local Anim = {}
Anim.__index = Anim

-- imgIds: { "skin_id", "cloth_id", "hair_id" } 처럼 테이블로 받습니다.
function Anim.new(imgIds, frameW, frameH, cols)
    ---@class Anim
    local obj = {
        layers = (type(imgIds) == "table") and imgIds or { imgIds }, -- 무조건 테이블로 변환
        fw = frameW, fh = frameH,
        cols = cols or 1,
        animations = {},
        current = nil,
        frameIdx = 1,
        timer = 0,
        flipX = false
    }
    return setmetatable(obj, Anim)
end

-- 특정 레이어만 교체하는 기능 (예: 옷 갈아입기)
function Anim:setLayer(index, newImgId)
    self.layers[index] = newImgId
end

-- 새로운 레이어 추가 (예: 무기 장착)
function Anim:addLayer(imgId)
    table.insert(self.layers, imgId)
end

function Anim:add(name, frames, intervalMs, loop)
    self.animations[name] = {
        frames = frames,
        interval = intervalMs or 100,
        loop = (loop == nil) and true or loop
    }
end

function Anim:play(name)
    if self.current == name then return end
    self.current = name
    self.frameIdx = 1
    self.timer = 0
end

function Anim:update(dt)
    local anim = self.animations[self.current]
    if not anim then return end

    self.timer = self.timer + dt
    while self.timer >= anim.interval do
        self.timer = self.timer - anim.interval
        self.frameIdx = self.frameIdx + 1
        if self.frameIdx > #anim.frames then
            if anim.loop then self.frameIdx = 1 else self.frameIdx = #anim.frames end
        end
    end
end

function Anim:draw(x, y, w, h)
    local anim = self.animations[self.current]
    if not anim then return end

    local frameNum = anim.frames[self.frameIdx]
    local sx = (frameNum % self.cols) * self.fw
    local sy = math.floor(frameNum / self.cols) * self.fh
    local drawW = w or self.fw
    local drawH = h or self.fh

    for _, imgId in ipairs(self.layers) do
        if imgId then
            g.image(imgId, x, y, drawW, drawH, sx, sy, self.fw, self.fh, self.flipX)
        end
    end
end
function Anim:drawFrame(animName, frameIdx, x, y, w, h)
    local anim = self.animations[animName]
    if not anim then return end
    
    -- 1. 전달받은 인덱스가 안전한지 확인 (기본값 1)
    local idx = frameIdx or 1
    local frameNum = anim.frames[idx] or anim.frames[1]
    
    -- 2. 시트에서의 좌표 계산 (기존 draw 로직과 동일)
    local sx = (frameNum % self.cols) * self.fw
    local sy = math.floor(frameNum / self.cols) * self.fh
    local drawW = w or self.fw
    local drawH = h or self.fh

    -- 3. 레이어 한땀 한땀 그리기
    for _, imgId in ipairs(self.layers) do
        if imgId then
            g.image(imgId, x, y, drawW, drawH, sx, sy, self.fw, self.fh)
        end
    end
end
return Anim