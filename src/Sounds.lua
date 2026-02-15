local DataStore = require("src.DataStore")

local Sounds = {}

local registry = {}

function Sounds.register(name, pathList)
    registry[name] = pathList
end

function Sounds.play(name, loop, volume)
    local settings = DataStore.get('settings')
    if settings and settings.sfxEnabled == false then
        return
    end
    local list = registry[name]
    if not list then return end

    local index = math.random(#list)

    if type(list[index]) == "string" then
        list[index] = res.sound(list[index])
    end

    return s.play(list[index], loop or false, volume or 1)
end


Sounds.register('click', {
    'assets/sound/click1.wav',
    'assets/sound/click2.wav',
    'assets/sound/click3.wav',
    'assets/sound/click4.wav',
})
Sounds.register('coin', {
    'assets/sound/coin1.wav',
    'assets/sound/coin2.wav',
    'assets/sound/coin3.wav',
    'assets/sound/coin4.wav',
    'assets/sound/coin5.wav',
    'assets/sound/coin6.wav',
})
return Sounds
