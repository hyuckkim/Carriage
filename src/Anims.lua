local Anim = require('lib.anim')

Anims = {}
function Anims.wagon()
    local anim = Anim.new(res.image("assets/wagon_sheet.png"), 272, 96, 8)
    anim:add("walk", {0, 1, 2, 3, 4, 5}, 100, true)
    anim:add("run", {8, 9, 10, 11, 12, 13}, 100, true)
    anim:add("feed", {16, 17, 18, 19, 20, 21, 22, 23}, 100, true)
    anim:add("idle", {24, 25, 26, 27, 28, 29, 30, 31}, 100, true)

    return anim
end
function Anims.wagonTop()
    local anim = Anim.new(res.image("assets/wagon_top.png"), 272, 96, 8)
    anim:add("walk", {0, 1, 2, 3, 4, 5}, 100, true)
    anim:add("run", {8, 9, 10, 11, 12, 13}, 100, true)
    anim:add("feed", {16, 17, 18, 19, 20, 21, 22, 23}, 100, true)
    anim:add("idle", {24, 25, 26, 27, 28, 29, 30, 31}, 100, true)

    return anim
end
function Anims.chara()
    local anim = Anim.new(res.image("assets/wagon_woman.png"), 64, 64, 8)
    anim:add("idle", {0, 1, 2, 3, 4}, 100, true)
    anim:add("walk", {8, 9, 10, 11, 12, 13, 14, 15}, 100, true)

    return anim
end


return Anims