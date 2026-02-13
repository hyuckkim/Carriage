local NinePatch = require("lib.ninepatch")
local UIButton = require("lib.UI.UIButton")
local UIPanel   = require("lib.UI.UIPanel")
local Icons = {}

local function getIconRect(index)
    local col = (index - 1) % 12
    local row = math.floor((index - 1) / 12)
    -- { x, y, width, height, left, right, top, bottom }
    -- 아이콘이므로 9-slice 마진은 모두 0
    return { col * 16, row * 16, 16, 16, 0, 0, 0, 0 }
end

-- 아이템 스킨을 쉽게 등록하기 위한 헬퍼 함수
local function registerItemSkin(name, normalIdx)
    Icons[name] = {
        imagePath = "assets/icons.png",
        normal  = getIconRect(normalIdx),        -- 1~6번 라인 등
        hover   = getIconRect(normalIdx + 6),    -- 옆으로 6칸 이동 (7~9번 라인 등)
        pressed = getIconRect(normalIdx + 72)    -- 아래로 6줄 이동 (73번~ 라인)
    }
end

-- 1. 단순 아이콘 이미지 생성 (UI 패널 형태)
function Icons.createIcon(name, x, y, w, h)
    local skinData = Icons[name]
    if not skinData then return nil end
    
    local imgId = res.image(skinData.imagePath)
    local d = skinData.normal
    local np = NinePatch.new(imgId, d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8])
    
    return UIPanel.new(x, y, w or 16, h or 16, np)
end

-- 2. 클릭 가능한 아이콘 버튼 생성
function Icons.createIconButton(name, x, y, w, h, onClick)
    local skinData = Icons[name]
    if not skinData then return nil end
    
    local imgId = res.image(skinData.imagePath)
    
    local function makeNP(data)
        if not data then return nil end
        return NinePatch.new(imgId, data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8])
    end

    local nps = {
        normal  = makeNP(skinData.normal),
        hover   = makeNP(skinData.hover or skinData.normal),
        pressed = makeNP(skinData.pressed or skinData.normal)
    }
    
    -- 아이콘 버튼은 보통 텍스트가 없으므로 "" 전달, 색상은 흰색 기본값
    return UIButton.new(x, y, w or 16, h or 16, nps, "", onClick, {255, 255, 255})
end

registerItemSkin('setting', 42)
registerItemSkin('close', 29)

return Icons