local Anim = {}
Anim.__index = Anim

-- cols: 가로로 몇 칸인지 추가로 받습니다.
function Anim.new(imgId, frameW, frameH, cols)
    local obj = {
        imgId = imgId,
        fw = frameW, fh = frameH,
        cols = cols or 1, -- 한 줄에 들어있는 프레임 개수
        animations = {},
        current = nil,
        frameIdx = 1,
        timer = 0
    }
    return setmetatable(obj, Anim)
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

-- 매 프레임 업데이트
function Anim:update(dt)
    local anim = self.animations[self.current]
    if not anim then return end

    self.timer = self.timer + dt
    
    while self.timer >= anim.interval do
        self.timer = self.timer - anim.interval
        self.frameIdx = self.frameIdx + 1
        
        if self.frameIdx > #anim.frames then
            if anim.loop then
                self.frameIdx = 1
            else
                self.frameIdx = #anim.frames
            end
        end
    end
end

function Anim:draw(x, y, w, h)
    local anim = self.animations[self.current]
    if not anim then return end

    -- 현재 애니메이션 배열에서 프레임 번호(0, 1, 2...)를 가져옴
    local frameNum = anim.frames[self.frameIdx]

    -- 바둑판 좌표 계산
    -- % : 나머지 연산 (몇 번째 칸인가)
    -- // : 정수 나눗셈 (몇 번째 줄인가)
    local sx = (frameNum % self.cols) * self.fw
    local sy = math.floor(frameNum / self.cols) * self.fh

    g.image(self.imgId, x, y, w or self.fw, h or self.fh, sx, sy, self.fw, self.fh)
end

return Anim