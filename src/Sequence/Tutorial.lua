local ObjectManager = require("lib.ObjectManager")
local Datastore = require("src.Datastore")
local Anims = require("src.Anims")

local Tutorial = {
    is_active = false,
    current_index = 0,
    elapsed_time = 0,
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
    self.elapsed_time = 0

    ObjectManager:Add(Anims.Advisor(), 'advisor', -32, 32, {
        layer = 2, sayOX = 32, sayOY = 20, defaultAnim = 'idle'
    })
    -- 초기 위치 설정 (조언자는 마차 근처 대기)
    ObjectManager:Move('advisor', wagonX + 160, wagonY)

    -- 2. 첫 번째 이벤트 실행
    self:Execute(TutorialScript[self.current_index])
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
function Tutorial:Execute(event)
    if not event then 
        self:Finish()
        return 
    end

    local target = event.key
    self.timer = event.duration

    if event.action == "walk" then
        -- 등장 씬: 시작 위치로 순간이동 후 목표 위치로 걷기
        ObjectManager:Move(target, event.from, self.wy)
        ObjectManager:Play(target, 'walk')
        ObjectManager:Move(target, event.to, self.wy, event.movetime or 0, 'idle')

    elseif event.action == "say" then
        -- 말하기: 기존의 다른 말풍선은 다 끄고 이번 타겟만 말함
        ObjectManager:ClearAllSay()
        ObjectManager:Say(target, event.text, event.style)

    elseif event.action == "emote" then
        ObjectManager:ClearAllSay()
        ObjectManager:Emote(target, event.emotion)
        self.elapsed_time = 0
    end
    if self.timer == 0 then
        self.timer = nil
        self:Next()
    end
end

function Tutorial:OnClick(x, y)
    if not self.is_active then return end

    -- 1. 현재 자동 진행 중(duration이 남음)이라면 클릭 무시
    if self.timer and self.timer > 0 then
        return
    end

    -- 2. (선택 사항) 만약 텍스트가 아직 타이핑 중이라면?
    -- 글자를 한 번에 다 보여주는 스킵 기능만 수행하고 Next는 안 함
    local current_event = TutorialScript[self.current_index]
    if current_event and current_event.action == "say" then
        local obj = ObjectManager.objects[current_event.key]
        if obj and obj.say and obj.say.charIndex < utf8.len(obj.say.fullText) then
            obj.say.charIndex = utf8.len(obj.say.fullText)
            obj.say.text = obj.say.fullText
            return -- 텍스트만 채우고 끝
        end
    end

    -- 3. 위 조건들에 해당하지 않으면 다음으로 진행
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
    self.current_index = 0
    
    ObjectManager:ClearAllSay()

    -- 1. ObjectManager에 있는 실제 '객체'를 가져옵니다.
    -- (.anim이 아니라 객체 자체에 데이터를 넣는 것이 나중에 관리하기 편합니다)
    local advisor = ObjectManager.objects['advisor']
    
    if advisor then
        -- 2. 객체에 직접 손님 데이터 주입
        advisor.name = "박덕배"
        advisor.dest = "한양"
        advisor.fee = 150
        advisor.trait1 = { name = "애주가", type = "Positive" }
        advisor.trait2 = { name = "쾌활함", type = "Positive" }
        advisor.isBoarding = false
        
        -- 3. 이 객체가 '손님'임을 나타내는 플래그 (ObjectManager:GetCustomers에서 필터링용)
        advisor.is_npc = true
    end

    -- 4. 이제 인자 없이 transition (UI는 열릴 때 ObjectManager에서 직접 긁어감)
    Datastore.get('fsm'):transition('idle', { advisor })
    
    ObjectManager:InjectPattern('advisor', AdvisorPattern, true)
end

return Tutorial