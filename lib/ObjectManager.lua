local UIFactory = require('src.UiFactory')
local EmotesFactory = require("src.Emotes")

local ObjectManager = {
    objects = {},
    renderQueue = {}, -- 정렬된 객체들을 담을 보관함
    scrollX = 0,
    scrollY = 0,
    width = 0,
    height = 0
}
ObjectManager.bubbleOffsets = {
    Quote = { x = -100, y = -50 },
    QuoteL = { x = -5, y = -50 }
}
function ObjectManager:Init(width, height)
    self.width = width
    self.height = height
    self.objects = {}
    self.renderQueue = {} -- 초기화
    self.scrollX = 0
    self.scrollY = 0
end

function ObjectManager:Add(anim, key, ox, oy, opts)
    -- 기본값 설정 (opts가 없을 경우를 대비)
    opts = opts or {}
    
    local obj = {
        anim = anim,
        key = key,
        x = 0, y = 0,
        ox = ox or 0,
        oy = oy or 0,
        -- 테이블에서 필요한 값을 꺼내고 없으면 기본값(or) 사용
        layer = opts.layer or 1,
        sayOX = opts.sayOX or 0,
        sayOY = opts.sayOY or -50,
        targetX = 0,
        targetY = 0,
        moveTime = 0,
        vx = 0,
        vy = 0
    }
    
    self.objects[key] = obj
    table.insert(self.renderQueue, obj)
    self:SortLayers()
    
    -- 기본 애니메이션 실행
    if opts.anim then
        anim:play(opts.anim)
    end
end

-- 레이어 순서대로 정렬 (Z-Index 정렬)
function ObjectManager:SortLayers()
    table.sort(self.renderQueue, function(a, b)
        return a.layer < b.layer
    end)
end

function ObjectManager:Play(key, animName)
    local obj = self.objects[key]
    if obj and obj.anim then
        obj.anim:play(animName)
    end
end
function ObjectManager:Update(dt)
    for _, obj in pairs(self.objects) do
        -- 1. 애니메이션 프레임 업데이트
        obj.anim:update(dt)

        -- 2. 이동 및 자동 반전(Flip) 로직
        if obj.moveTime > 0 then
            if obj.targetX > obj.x then
                obj.anim.flipX = true  -- 오른쪽을 봄 (이미지 기본이 왼쪽일 경우)
            elseif obj.targetX < obj.x then
                obj.anim.flipX = false -- 왼쪽을 봄
            end

            -- 기존 이동 계산
            if dt >= obj.moveTime then
                obj.x, obj.y = obj.targetX, obj.targetY
                obj.moveTime = 0
                if obj.onFinishAnim then
                    obj.anim:play(obj.onFinishAnim)
                    obj.onFinishAnim = nil -- 한 번만 실행하고 비우기
                end
            else
                obj.x = obj.x + (obj.vx * dt)
                obj.y = obj.y + (obj.vy * dt)
                obj.moveTime = obj.moveTime - dt
            end
        end
        if obj.say then
            local len = utf8.len(obj.say.fullText)
            if obj.say.charIndex < len then
                obj.say.typeTimer = obj.say.typeTimer + dt
                if obj.say.typeTimer >= obj.say.typeSpeed then
                    obj.say.typeTimer = 0
                    obj.say.charIndex = obj.say.charIndex + 1
                    
                    -- utf8.offset을 사용해 정확한 바이트 위치 계산
                    local byteOffset = utf8.offset(obj.say.fullText, obj.say.charIndex + 1) - 1
                    obj.say.text = string.sub(obj.say.fullText, 1, byteOffset)
                    
                elseif obj.say.timer then
                    obj.say.timer = obj.say.timer - dt
                    if obj.say.timer <= 0 then obj.say = nil end
                end
            end
        end
        if obj.emote then
            obj.emote.anim:update(dt)
            
            if obj.emote.timer then
                obj.emote.timer = obj.emote.timer - dt
                if obj.emote.timer <= 0 then 
                    obj.emote = nil 
                end
            end
        end
    end
end
function ObjectManager:Draw()
    -- 이제 objects 대신 정렬된 renderQueue를 순회합니다.
    for _, obj in ipairs(self.renderQueue) do
        local drawX = (obj.x - self.scrollX) + obj.ox
        local drawY = (obj.y - self.scrollY) + obj.oy
        obj.anim:draw(drawX, drawY)

        if obj.say then
            -- 1. 캐릭터별 기본 말풍선 위치 (머리 위)
            local tx = drawX + obj.sayOX
            local ty = drawY + obj.sayOY
            
            -- 2. 말풍선 종류(Style)에 따른 꼬리 위치 보정
            local style = obj.say.style or 'Quote'
            local offset = self.bubbleOffsets[style] or { x = 0, y = 0 }
            
            local finalX = tx + offset.x
            local finalY = ty + offset.y
            
            -- 3. 그리기
            UIFactory.createPanel(style, finalX, finalY, 130, 45):draw()
            UIFactory.createText(finalX + 5, finalY + 5, obj.say.text, 'Quote'):draw()
        end
        if obj.emote then
            local ex = drawX + obj.sayOX - 8
            local ey = drawY + obj.sayOY - 16
            obj.emote.anim:draw(ex, ey)
        end
    end
end

-- (나중에 레이어를 실시간으로 바꾸고 싶을 때를 대비)
function ObjectManager:SetLayer(key, newLayer)
    if self.objects[key] then
        self.objects[key].layer = newLayer
        self:SortLayers()
    end
end

function ObjectManager:Move(key, targetX, targetY, time, onFinishAnim)
    local obj = self.objects[key]
    if not obj then return end
    obj.onFinishAnim = onFinishAnim

    if time and time > 0 then
        obj.targetX = targetX
        obj.targetY = targetY
        obj.moveTime = time
        obj.vx = (targetX - obj.x) / time
        obj.vy = (targetY - obj.y) / time
    else
        obj.x, obj.y = targetX, targetY
        obj.targetX, obj.targetY = targetX, targetY
        obj.moveTime = 0
        if onFinishAnim then obj.anim:play(onFinishAnim) end
    end
end

function ObjectManager:Say(key, text, style, duration)
    local obj = self.objects[key]
    if not obj then return end

    obj.say = {
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
function ObjectManager:StopSay(key)
    if self.objects[key] then
        self.objects[key].say = nil
    end
end
function ObjectManager:ClearAllSay()
    for _, obj in pairs(self.objects) do
        obj.say = nil
    end
end
function ObjectManager:Emote(key, emotionIndex, duration)
    local obj = self.objects[key]
    if not obj then return end

    local emoNames = {
        "question", "exclamation", "idea", "skull", "sweat",
        "sleep", "angry", "sad", "heart_eye", "cry",
        "smile", "neutral", "heart", "big_smile", "wink"
    }
    local name = emoNames[emotionIndex] or "question"

    -- [핵심] .new()를 호출해 독립적인 객체 생성!
    obj.emote = {
        anim = EmotesFactory.new(),
        timer = duration or 1500
    }
    obj.emote.anim:play(name)
end

function ObjectManager:Scroll(deltaX, deltaY)
    self.scrollX = self.scrollX + deltaX
    self.scrollY = self.scrollY + deltaY
end

return ObjectManager