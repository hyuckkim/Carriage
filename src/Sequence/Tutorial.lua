local ObjectManager = require("lib.ObjectManager")
local Anims = require("src.Anims") -- 아까 만든 애니메이션 생성 모듈

local Tutorial = {
    is_active = false,
    current_index = 0,
    elapsed_time = 0,
    wx = 0, wy = 0
}

-- 스크립트 데이터는 그대로 유지
local TutorialScript = {
    { action = "walk",  key = 'advisor', from = 181, to = 180 },
    { action = "walk",  key = 'chara',   from = -200, to = 40 },
    
    -- style: 'Quote' (오른쪽 배치/말풍선), 'QuoteL' (왼쪽 배치/말풍선)
    { action = "say",   key = 'advisor', style = 'Quote',  text = "오셨군요." },
    { action = "say",   key = 'chara',   style = 'QuoteL', text = "네." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "여기 이 마차가\n'그' 마차입니다." },
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
    { action = "emote", key = 'chara',   style = 'QuoteL', emotion = 1 },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "...아닙니다." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "그냥 마차를\n몰고 싶으신 거군요." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "마차 타실 때마다..." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "마부들만 보고 있던 게\n눈에 선합니다." },
    { action = "emote", key = 'chara',   style = 'QuoteL', emotion = 2 },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "그럼 어디\n아가씨 솜씨 좀 볼까요." },
    { action = "say",   key = 'advisor', style = 'Quote',  text = "어차피 마차를 등록하려면\n수도로 가야 하는 김에" },
    { action = "say",   key = 'advisor', style = 'Quote',  text = " 한 번 태워주시지요." },
}

function Tutorial:Init(wagonX, wagonY)
    self.wx, self.wy = wagonX, wagonY
    self.is_active = true
    self.current_index = 1
    self.elapsed_time = 0

    -- 1. 객체 등록 (ObjectManager)
    -- 아가씨 (말풍선 위치 조정: sayOY = -60)
    ObjectManager:Add(Anims.chara(), 'chara', -32, 32, {
        layer = 2, sayOX = 32, sayOY = 20, defaultAnim = 'idle' 
    })
    -- 조언자
    ObjectManager:Add(Anims.Advisor(), 'advisor', -32, 32, {
        layer = 2, sayOX = 12, sayOY = 20, defaultAnim = 'idle' 
    })
    
    -- 초기 위치 설정 (조언자는 마차 근처 대기)
    ObjectManager:Move('advisor', wagonX + 160, wagonY)

    -- 2. 첫 번째 이벤트 실행
    self:Execute(TutorialScript[self.current_index])
end

function Tutorial:Update(dt)
    if not self.is_active then return end
    self.elapsed_time = self.elapsed_time + dt
end

function Tutorial:Draw()
end

function Tutorial:Execute(event)
    if not event then 
        self.is_active = false
        return
    end
    local target = event.key

    if event.action == "walk" then
        -- 등장 씬: 시작 위치로 순간이동 후 목표 위치로 걷기
        ObjectManager:Move(target, event.from, self.wy)
        ObjectManager:Play(target, 'walk')
        ObjectManager:Move(target, event.to, self.wy, 2.0, 'idle')

    elseif event.action == "say" then
        -- 말하기: 기존의 다른 말풍선은 다 끄고 이번 타겟만 말함
        ObjectManager:ClearAllSay()
        ObjectManager:Say(target, event.text, event.style)

    elseif event.action == "emote" then
        ObjectManager:ClearAllSay()
        ObjectManager:Emote(target, event.emotion)
        self.elapsed_time = 0
    end
end

function Tutorial:OnClick(x, y)
    if not self.is_active then return end

    self.current_index = self.current_index + 1
    local next_event = TutorialScript[self.current_index]
    
    if next_event then
        self:Execute(next_event)
    else
        -- 스크립트 종료 처리
        ObjectManager:ClearAllSay()
        self.is_active = false
        print("튜토리얼 종료!")
    end
end

return Tutorial