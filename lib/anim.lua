---@class Anim
local Anim = {}
Anim.__index = Anim

-- imgIds: { "skin_id", "cloth_id", "hair_id" } 처럼 테이블로 받습니다.
function Anim.new(imgPaths, frameW, frameH, cols)
    local paths = (type(imgPaths) == "table") and imgPaths or { imgPaths }
    
    ---@class Anim
    local obj = {
        imgPaths = paths, -- [저장용] 경로 테이블
        imgIds = {},      -- [실행용] 실제 ID 테이블
        fw = frameW, fh = frameH,
        cols = cols or 1,
        animations = {},
        current = nil,
        frameIdx = 1,
        timer = 0,
        timeScale = 1.0,
        flipX = false
    }
    
    -- 생성 시점에 경로를 ID로 변환하여 채워넣음
    for i, path in ipairs(paths) do
        -- res.image가 이미 로드된 건 기존 ID를 줄 테니 안심하고 호출
        obj.imgIds[i] = res.image(path)
    end
    
    return setmetatable(obj, Anim)
end

-- 특정 레이어만 교체하는 기능 (예: 옷 갈아입기)
function Anim:setLayer(index, newPath)
    self.imgPaths[index] = newPath
    self.imgIds[index] = res.image(newPath)
end

-- 새로운 레이어 추가 (예: 무기 장착)
function Anim:addLayer(newPath)
    table.insert(self.imgPaths, newPath)
    table.insert(self.imgIds, res.image(newPath))
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

    self.timer = self.timer + (dt * self.timeScale)
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

    for _, id in ipairs(self.imgIds) do
        if id then
            g.image(id, x, y, drawW, drawH, sx, sy, self.fw, self.fh, self.flipX)
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

    for _, id in ipairs(self.imgIds) do
        if id then
            g.image(id, x, y, drawW, drawH, sx, sy, self.fw, self.fh, self.flipX)
        end
    end
end

function Anim:GetPersistentData()
    ---@class AnimPersistentData
    return {
        imgPaths = self.imgPaths,
        fw = self.fw,
        fh = self.fh,
        cols = self.cols,
        current = self.current,
        flipX = self.flipX,
        animations = self.animations
    }
end
return Anim