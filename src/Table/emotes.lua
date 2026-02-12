local Anim = require("lib.anim")

local Emotes = {}

-- 새로운 이모트 애니메이션 객체를 생성하는 함수
function Emotes.new()
    -- 호출될 때마다 독립적인 Anim 객체 생성
    local instance = Anim.new(res.image('assets/emoji.png'), 16, 16, 19)

    instance:add('question',    Range(1, 19),   100)
    instance:add('exclamation', Range(20, 38),  100)
    instance:add('idea',        Range(39, 57),  100)
    instance:add('skull',       Range(58, 76),  100)
    instance:add('sweat',       Range(77, 95),  100)
    instance:add('sleep',       Range(96, 114), 100)
    instance:add('angry',       Range(115, 133), 100)
    instance:add('sad',         Range(134, 152), 100)
    instance:add('heart_eye',   Range(153, 171), 100)
    instance:add('cry',         Range(172, 190), 100)
    instance:add('smile',       Range(191, 209), 100)
    instance:add('neutral',     Range(210, 228), 100)
    instance:add('heart',       Range(229, 247), 100)
    instance:add('big_smile',   Range(248, 266), 100)
    instance:add('wink',        Range(267, 285), 100)

    return instance
end

return Emotes