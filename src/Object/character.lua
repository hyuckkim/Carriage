local ObjectManager = require("lib.ObjectManager")
local UIFactory = require("src.Table.UiFactory")
local EmotesFactory = require("src.Table.emotes")
local Object = require("src.Object.object")
local Patterns = require("src.Table.Patterns")

---@class Character: Object
local Character = setmetatable({}, { __index = Object })
Character.__index = Character

---@return Character
function Character.new(key, anim)
    ---@class Character: Object
    local self = Object.new(key, anim)
    setmetatable(self, Character)
    
    self.say = nil
    self.is_npc = true
    self.is_destroyed = false

    self.sayOX = 0
    self.sayOY = 0

    self.behavior_type = 'none' -- 기본은 아무것도 안 함
    self.pattern_script = nil
    self.pattern_index = 0
    self.timer = 0
    self.isAbsolute = false
    return self
end
Character.bubbleOffsets = {
    Quote = { x = -120, y = -50 },
    QuoteL = { x = -5, y = -50 }
}

function Character:GetPersistentData()
    -- 1. 조상(Object)의 데이터 먼저 가져오기
    local data = getmetatable(Character).__index.GetPersistentData(self)
    
    -- 2. Character 특유의 데이터 얹기
    data.type = "Character"
    data.sayOX, data.sayOY = self.sayOX, self.sayOY
    data.behavior_type = self.behavior_type
    data.pattern_name = self.pattern_name
    data.pattern_index = self.pattern_index
    data.timer = self.timer
    
    return data
end

function Character.newFromData(d)
    ---@class Character: Object
    local self = Object.newFromData(d)
    setmetatable(self, Character)
    
    -- 2. Character 상태 복구
    self.sayOX, self.sayOY = d.sayOX, d.sayOY
    
    if d.pattern_name then
        self:setPattern(d.pattern_name)
        self.pattern_index = d.pattern_index or 0
        self.timer = d.timer or 0
    end
    
    return self
end

function Character:update(dt)
    if self.is_destroyed then return end
    
    -- 조상 update 실행 (애니메이션 등)
    getmetatable(Character).__index.update(self, dt)

    -- 전용 로직
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
        if self.emote.timer <= 0 then self.emote = nil end
    end
end
function Character:_updateMovement(dt)
    if not self.moveTime or self.moveTime <= 0 then return end

    -- 방향 전환
    self.anim.flipX = (self.targetX > self.x)

    if dt >= self.moveTime then
        self.x, self.y = self.targetX, self.targetY
        self.moveTime = 0
        if self.onFinishAnim then
            self.anim:play(self.onFinishAnim)
            self.onFinishAnim = nil
        end
    else
        self.x = self.x + (self.vx * dt)
        self.y = self.y + (self.vy * dt)
        self.moveTime = self.moveTime - dt
    end
end

function Character:drawUI(scrollX, scrollY)
    if self.is_destroyed then return end
    local drawX, drawY = self.x - scrollX + self.ox, self.y - scrollY + self.oy
    
    self:_drawDialogue(drawX, drawY)
    self:_drawEmote(drawX, drawY)
end

function Character:_drawDialogue(drawX, drawY)
    if not self.say or not self.say.text then return end
    local style = self.say.style or 'Quote'
    local offset = self.bubbleOffsets[style] or { x = 0, y = 0 }
    local fx, fy = drawX + self.sayOX + offset.x, drawY + self.sayOY + offset.y
    
    UIFactory.createPanel(style, fx, fy, 130, 45):draw()
    UIFactory.createText(fx + 5, fy + 5, self.say.text, 'Quote'):draw()
end

function Character:_drawEmote(drawX, drawY)
    if not self.emote then return end
    self.emote.anim:draw(drawX + self.sayOX - 8, drawY + self.sayOY - 16)
end

function Character:Move(targetX, targetY, time, onFinishAnim)
    self.onFinishAnim = onFinishAnim
    if time and time > 0 then
        self.targetX, self.targetY, self.moveTime = targetX, targetY, time
        self.vx, self.vy = (targetX - self.x) / time, (targetY - self.y) / time
    else
        self.x, self.y, self.targetX, self.targetY, self.moveTime = targetX, targetY, targetX, targetY, 0
        if onFinishAnim then self.anim:play(onFinishAnim) end
    end
end

function Character:MoveBySpeed(targetX, targetY, speed, onFinishAnim)
    local dx, dy = targetX - self.x, targetY - self.y
    local travelTime = math.sqrt(dx*dx + dy*dy) / speed
    self:Move(targetX, targetY, travelTime, onFinishAnim)
end

function Character:Say(text, style, duration)
    if not text then 
        self.say = nil -- 텍스트가 없으면 대화창 제거
        return 
    end

    self.say = {
        fullText = text,
        displayBuffer = "", -- 화면에 실제로 그려질 텍스트
        style = style or 'Quote',
        timer = duration or 2, -- 기본 지속 시간(초) 설정
        charIndex = 0,
        typeTimer = 0,
        typeSpeed = 0.05
    }
end
function Character:StopSay()
    self.say = nil
end
function Character:Emote(emotionIndex, duration)
    local emoNames = { "question", "exclamation", "idea", "skull", "sweat", "sleep", "angry", "sad", "heart_eye", "cry", "smile", "neutral", "heart", "big_smile", "wink" }
    self.emote = { anim = EmotesFactory.new(), timer = duration or 1500 }
    self.emote.anim:play(emoNames[emotionIndex] or "question")
end

function Character:setPattern(patternName)
    local script = Patterns[patternName]
    if not script then return end
    self.behavior_type, self.pattern_name, self.pattern_script, self.pattern_index, self.timer = 'pattern', patternName, script, 0, 0
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