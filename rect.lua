local sound = nil
local color = {r = 255, g = 255, b = 255, a = 150}

function Init()
    sound = res.sound("click.wav")print("Sound ID is: " .. tostring(sound))
end
function Draw()
    g.color(color.r, color.g, color.b, 150)
    g.rect(0, 0, 800, 600)
end

function OnMouseUp(x, y)
    color.r = math.random(0, 255)
    color.g = math.random(0, 255)
    color.b = math.random(0, 255)

    s.play(sound, false, 1.0)
end