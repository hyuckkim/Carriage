local ObjectManager = require("lib.ObjectManager")
local UIFactory = require("src.UiFactory")
local EmotesFactory = require("src.emotes")
local Object = require("src.Object.object")

---@class Character: Object
local Character = setmetatable({}, { __index = Object })
Character.__index = Character

---@return Character
function Character.new(key, anim)
    ---@class Character
    local self = Object.new(key, anim)
    setmetatable(self, Character)
    
    self.say = nil
    self.is_npc = true

    self.sayOX = 0
    self.sayOY = 0

    self.behavior_type = 'none' -- 기본은 아무것도 안 함
    self.pattern_script = nil
    self.pattern_index = 0
    self.timer = 0
    return self
end
Character.bubbleOffsets = {
    Quote = { x = -120, y = -50 },
    QuoteL = { x = -5, y = -50 }
}

-- 조상의 update를 확장(Override)
function Character:update(dt)
    local base = getmetatable(Character).__index
    base.update(self, dt)

    -- 2. Character만의 전용 로직 (OM에서 떼어온 것들)
    self:_updateDialogue(dt)
    self:_updateMovement(dt)
    self:_updateEmote(dt)
    self:updatePattern(dt)
end

function Character:_updateDialogue(dt)
    if not self.say then return end
    local len = utf8.len(self.say.fullText)
    if self.say.charIndex < len then
        self.say.typeTimer = self.say.typeTimer + dt
        if self.say.typeTimer >= self.say.typeSpeed then
            self.say.typeTimer = 0
            self.say.charIndex = self.say.charIndex + 1
            
            -- utf8.offset을 사용해 정확한 바이트 위치 계산
            local byteOffset = utf8.offset(self.say.fullText, self.say.charIndex + 1) - 1
            self.say.text = string.sub(self.say.fullText, 1, byteOffset)
            
        elseif self.say.timer then
            self.say.timer = self.say.timer - dt
            if self.say.timer <= 0 then self.say = nil end
        end
    end
end
function Character:_updateEmote(dt)
    if not self.emote then return end
    self.emote.anim:update(dt)
    
    if self.emote.timer then
        self.emote.timer = self.emote.timer - dt
        if self.emote.timer <= 0 then 
            self.emote = nil 
        end
    end
end
function Character:_updateMovement(dt)
    if not self.moveTime then return end
    if self.moveTime > 0 then
        if self.targetX > self.x then
            self.anim.flipX = true  -- 오른쪽을 봄 (이미지 기본이 왼쪽일 경우)
        elseif self.targetX < self.x then
            self.anim.flipX = false -- 왼쪽을 봄
        end

        -- 기존 이동 계산
        if dt >= self.moveTime then
            self.x, self.y = self.targetX, self.targetY
            self.moveTime = 0
            if self.onFinishAnim then
                self.anim:play(self.onFinishAnim)
                self.onFinishAnim = nil -- 한 번만 실행하고 비우기
            end
        else
            self.x = self.x + (self.vx * dt)
            self.y = self.y + (self.vy * dt)
            self.moveTime = self.moveTime - dt
        end
    end
end

function Character:draw(scrollX, scrollY)
    local base = getmetatable(Character).__index
    base.draw(self, scrollX, scrollY)

    local drawX = self.x - scrollX + self.ox
    local drawY = self.y - scrollY + self.oy
    self:_drawDialogue(drawX, drawY)
    self:_drawEmote(drawX, drawY)
end

function Character:_drawDialogue(drawX, drawY)
    if not self.say then return end
    -- 1. 캐릭터별 기본 말풍선 위치 (머리 위)
    local tx = drawX + self.sayOX
    local ty = drawY + self.sayOY
    
    -- 2. 말풍선 종류(Style)에 따른 꼬리 위치 보정
    local style = self.say.style or 'Quote'
    local offset = self.bubbleOffsets[style] or { x = 0, y = 0 }
    
    local finalX = tx + offset.x
    local finalY = ty + offset.y
    
    -- 3. 그리기
    UIFactory.createPanel(style, finalX, finalY, 130, 45):draw()
    UIFactory.createText(finalX + 5, finalY + 5, self.say.text, 'Quote'):draw()
end

function Character:_drawEmote(drawX, drawY)
    if not self.emote then return end

    local ex = drawX + self.sayOX - 8
    local ey = drawY + self.sayOY - 16
    self.emote.anim:draw(ex, ey)
end

function Character:Move(targetX, targetY, time, onFinishAnim)
    self.onFinishAnim = onFinishAnim

    if time and time > 0 then
        self.targetX = targetX
        self.targetY = targetY
        self.moveTime = time
        self.vx = (targetX - self.x) / time
        self.vy = (targetY - self.y) / time
    else
        self.x, self.y = targetX, targetY
        self.targetX, self.targetY = targetX, targetY
        self.moveTime = 0
        if onFinishAnim then self.anim:play(onFinishAnim) end
    end
end

function Character:MoveBySpeed(targetX, targetY, speed, onFinishAnim)
    -- 현재 위치와 목표 위치 사이의 거리 계산 (피타고라스)
    local dx = targetX - self.x
    local dy = targetY - self.y
    local distance = math.sqrt(dx*dx + dy*dy)

    -- 거리 / 속도 = 걸리는 시간
    local travelTime = distance / speed

    -- 기존 Move 함수를 재활용 (시간을 넘겨줌)
    self:Move(targetX, targetY, travelTime, onFinishAnim)
end

function Character:Say(text, style, duration)
    self.say = {
        fullText = text,       -- 전체 문장
        text = "",             -- 현재 보여줄 문장 (빈 값으로 시작)
        style = style or 'Quote',
        timer = duration,      -- 대사 유지 시간
        
        -- 타이핑 관련
        charIndex = 0,         -- 현재 몇 번째 글자인지
        typeTimer = 0,         -- 다음 글자가 나올 때까지의 시간
        typeSpeed = 0.05       -- 글자당 속도 (낮을수록 빠름)
    }
end
function Character:StopSay()
    self.say = nil
end
function Character:Emote(emotionIndex, duration)
    local emoNames = {
        "question", "exclamation", "idea", "skull", "sweat",
        "sleep", "angry", "sad", "heart_eye", "cry",
        "smile", "neutral", "heart", "big_smile", "wink"
    }
    local name = emoNames[emotionIndex] or "question"

    -- [핵심] .new()를 호출해 독립적인 객체 생성!
    self.emote = {
        anim = EmotesFactory.new(),
        timer = duration or 1500
    }
    self.emote.anim:play(name)
end

function Character:setPattern(pattern, startImmediate)
    self.behavior_type = 'pattern'
    self.pattern_script = pattern
    self.pattern_index = 0
    
    -- 즉시 시작할지, 약간의 랜덤 대기를 가질지 결정
    self.timer = startImmediate and 0 or math.random(1, 3)
end

function Character:updatePattern(dt)
    if self.behavior_type ~= 'pattern' or not self.pattern_script then return end

    -- 1. 타이머 진행
    if self.timer and self.timer > 0 then
        self.timer = self.timer - dt
    end


    -- 2. 조건 체크 (타이머 종료 및 이동 중 아님)
    local is_moving = (self.moveTime and self.moveTime > 0)
    if (not self.timer or self.timer <= 0) and not is_moving then
        local speaker = ObjectManager:Get('chara') or ObjectManager:Get('wagon')
        -- 다음 단계 계산
        self.pattern_index = (self.pattern_index % #self.pattern_script) + 1
        local step = self.pattern_script[self.pattern_index]

        speaker:StopSay()
        self:StopSay()

        if step.action == "say" then
            local style = (self.x < 150) and 'QuoteL' or 'Quote'
            self:Say(step.text, style) -- 자기 자신의 Say 메서드 호출

        elseif step.action == "emote" then
            self:Emote(step.emotion)

        elseif step.action == "walk" then
            self.anim:play('walk')
            self:MoveBySpeed(step.to, self.y, step.speed or 40, 'idle')

        elseif step.action == "listen" then
            
            if speaker then
                local style = (speaker.x < 150) and 'QuoteL' or 'Quote'
                speaker:Say(step.text, style)
            end
        end

        self.timer = step.duration or 0
    end
end

return Character