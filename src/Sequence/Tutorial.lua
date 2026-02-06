local ObjectManager = require("lib.ObjectManager")
local Datastore = require("src.Datastore")
local Anims = require("src.Anims")
local Character = require("src.Object.character")
local Customer = require("src.Object.customer")

local Tutorial = {
    is_active = false,
    current_index = 0,
    timer = nil,
    wx = 0, wy = 0
}

local TutorialScript = {
    { duration = 0, action = "walk",  key = 'advisor', from = 181, to = 180 },
    { duration = 0, action = "walk",  key = 'chara',   from = -200, to = 40, movetime = 2000 },
    { duration = 2000, action = "wait" },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "오셨군요." },
    { action = "say",   key = 'chara',   style = 'QuoteL', text = "네." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "여기 이 마차가\n'그' 마차입니다." },
    { duration = 600, action = "walk",  key = 'chara',   from = 40, to = 80, movetime = 600 },
    { duration = 600, action = "walk",  key = 'chara',   from = 80, to = 40, movetime = 600 },
    { duration = 300, action = "walk",  key = 'chara',   from = 40, to = 42, movetime = 20 },
    { action = "say",   key = 'chara',   style = 'QuoteL', text = "반짝반짝하네요." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "일반적인 마차는\n이렇게 반짝반짝하지 않죠." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "저희야 만들라기에\n만들었습니다만..." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "어째서 이런 마차를\n주문하셨는지요?" },
    { action = "say",   key = 'chara',   style = 'QuoteL', text = "마차를 타 보면서\n느꼈어요." },
    { action = "say",   key = 'chara',   style = 'QuoteL', text = "평범한 마차들에는\n짐을 한가득 실어서" },
    { action = "say",   key = 'chara',   style = 'QuoteL', text = "느려 터졌고\n좁고 냄새나요." },
    { action = "say",   key = 'chara',   style = 'QuoteL', text = "사람만 나르는 멋진 마차가\n있으면 좋겠다 싶어서요." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "그건 알겠습니다만\n아가씨," },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "그걸 왜 본인이 직접\n하신다는 거죠?" },
    { duration = 1200, action = "emote", key = 'chara', emotion = 1 },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "...아닙니다." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "그냥 마차를\n몰고 싶으신 거군요." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "마차 타실 때마다..." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "마부들만 보고 있던 게\n눈에 선합니다." },
    { duration = 1200, action = "emote", key = 'chara', emotion = 2 },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "그럼 어디\n아가씨 솜씨 좀 볼까요." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "어차피 마차를 등록하려면\n수도로 가야 하는 김에" },
    { action = "say",   key = 'advisor', style = 'Quote',  text = " 한 번 태워주시지요." },
}

function Tutorial:Init(wagonX, wagonY)
    self.wx, self.wy = wagonX, wagonY
    self.is_active = true
    self.current_index = 1

    local advisor = Character.new('advisor', Anims.Advisor())
    advisor.ox, advisor.oy = -32, 32
    advisor.sayOX, advisor.sayOY = 32, 20

    ObjectManager:Register(advisor)
    advisor:Move(wagonX + 160, wagonY)
    self:Execute(TutorialScript[self.current_index])
end

function Tutorial:Draw()
end

function Tutorial:Next()
    self.current_index = self.current_index + 1
    local next_event = TutorialScript[self.current_index]
    
    if next_event then
        self:Execute(next_event)
    else
        self:Finish() -- 스크립트가 끝났을 때 정리하는 함수
    end
end


function Tutorial:Update(dt)
    if not self.is_active then return end

    -- 현재 이벤트에 할당된 제한 시간이 있다면
    if self.timer and self.timer > 0 then
        self.timer = self.timer - dt
        
        -- 시간이 다 된 순간!
        if self.timer <= 0 then
            self.timer = nil -- 타이머 초기화
            self:Next()      -- 무조건 다음으로!
        end
    end
end

local function clearAllSay()
    for _, obj in pairs(ObjectManager:GetAll('StopSay')) do
        obj:StopSay()
    end
end

function Tutorial:Execute(event)
    if not event then self:Finish(); return end

    -- 객체 직접 찾기
    local obj = ObjectManager:Get(event.key)
    self.timer = event.duration

    if event.action == "walk" then
        if obj then
            obj:Move(event.from, self.wy) -- 순간이동
            obj.anim:play('walk')
            -- 이제 movetime 대신 Speed를 쓰거나, 내부 Move 로직을 활용
            obj:Move(event.to, self.wy, (event.movetime or 0), 'idle')
        end

    elseif event.action == "say" then
        clearAllSay() -- 전체 대사 정리
        if obj then obj:Say(event.text, event.style) end

    elseif event.action == "emote" then
        clearAllSay()
        if obj then obj:Emote(event.emotion) end
        
    elseif event.action == "wait" then
        -- 아무것도 안 하고 timer만 작동
    end

    -- 즉시 다음으로 넘어가는 경우 처리
    if self.timer == 0 then
        self.timer = nil
        self:Next()
    end
end

function Tutorial:OnClick(x, y)
    if not self.is_active then return end
    if self.timer and self.timer > 0 then
        return
    end

    local current_event = TutorialScript[self.current_index]
    if current_event and current_event.action == "say" then
        local obj = ObjectManager.objects[current_event.key]
        if obj and obj.say and obj.say.charIndex < utf8.len(obj.say.fullText) then
            obj.say.charIndex = utf8.len(obj.say.fullText)
            obj.say.text = obj.say.fullText
            return
        end
    end
    self:Next()
end

local AdvisorPattern = {
    { action = "walk", to = 250, speed = 0.04 },
    { action = "say", text = "아가씨가 이런 걸\n하게 되는 날이 오다니..", duration = 4000 },
    { action = "walk", to = 180, speed = 0.04 },
    { action = "wait", duration = 3000 },
    { action = "say", text = "마차를 '클릭' 하면\n운행을 준비할 수 있답니다...", duration = 4000 },
    { action = "listen", text = "아저씨가 마차를\n다 가리고 있는데요.", duration = 4000 },
    { action = "say", text = "예? 저는\n말 옆에 서 있는데요?", duration = 4000 },
    { action = "listen", text = "...아무튼\n그런 게 있어요.", duration = 4000 },
}
function Tutorial:Finish()
    self.is_active = false
    self.timer = nil
    
    clearAllSay()

    local oldAdvisor = ObjectManager:Get('advisor')
    if oldAdvisor then
        -- 손님 데이터 준비
        local customerData = {
            name = "박덕배",
            destination = "한양",
            budget = 150,
            traits = { "애주가", "쾌활함" }
        }
        
        local advisor = Customer.new('advisor', oldAdvisor.anim, customerData)
        advisor.x, advisor.y = oldAdvisor.x, oldAdvisor.y
        advisor.ox, advisor.oy = oldAdvisor.ox, oldAdvisor.oy
        advisor.sayOX, advisor.sayOY = oldAdvisor.sayOX, oldAdvisor.sayOY

        ObjectManager:Remove('advisor')
        ObjectManager:Register(advisor)
        
        advisor:setPattern(AdvisorPattern, true)

        -- FSM 전환
        Datastore.get('fsm'):transition('idle', { advisor })
    end
end

return Tutorial