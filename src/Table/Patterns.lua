local Patterns = {}

Patterns.AdvisorIdle = {
    { action = "walk", to = 250, speed = 0.04 },
    { action = "say", text = "아가씨가 이런 걸\n하게 되는 날이 오다니..", duration = 4000 },
    { action = "walk", to = 180, speed = 0.04 },
    { action = "wait", duration = 3000 },
    { action = "say", text = "마차를 '클릭' 하면\n운행을 준비할 수 있답니다...", duration = 4000 },
    { action = "listen", text = "아저씨가 마차를\n다 가리고 있는데요.", duration = 4000 },
    { action = "say", text = "예? 저는\n말 옆에 서 있는데요?", duration = 4000 },
    { action = "listen", text = "...아무튼\n그런 게 있어요.", duration = 4000 },
}

return Patterns