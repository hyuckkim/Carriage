local NinePatch = require("lib.ninepatch")
local UIButton = require("lib.UI.UIButton")
local UIPanel   = require("lib.UI.UIPanel")
local Icons = {}
local Items = {}
local ItemFunc = {}

local function getIconRect(index)
    local col = (index - 1) % 12
    local row = math.floor((index - 1) / 12)
    -- { x, y, width, height, left, right, top, bottom }
    -- 아이콘이므로 9-slice 마진은 모두 0
    return { col * 16, row * 16, 16, 16, 0, 0, 0, 0 }
end

-- 아이템 스킨을 쉽게 등록하기 위한 헬퍼 함수
local function registerIconSkin(name, normalIdx)
    Icons[name] = {
        imagePath = "assets/icons.png",
        normal  = getIconRect(normalIdx),        -- 1~6번 라인 등
        hover   = getIconRect(normalIdx + 6),    -- 옆으로 6칸 이동 (7~9번 라인 등)
        pressed = getIconRect(normalIdx + 72)    -- 아래로 6줄 이동 (73번~ 라인)
    }
end

-- 1. 단순 아이콘 이미지 생성 (UI 패널 형태)
function ItemFunc.createIcon(name, x, y, w, h)
    local skinData = Icons[name]
    if not skinData then return nil end
    
    local imgId = res.image(skinData.imagePath)
    local d = skinData.normal
    local np = NinePatch.new(imgId, d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8])
    
    return UIPanel.new(x, y, w or 16, h or 16, np)
end

-- 2. 클릭 가능한 아이콘 버튼 생성
function ItemFunc.createIconButton(name, x, y, w, h, onClick)
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

local function getItemRect(col, row)
    -- 1-index이므로 (번호 - 1)을 해야 0, 16, 32... 좌표가 나옵니다.
    local x = (col - 1) * 16
    local y = (row - 1) * 16
    
    -- { x, y, width, height, left, right, top, bottom }
    return { x, y, 16, 16, 0, 0, 0, 0 }
end
local function registerItemSkin(name, x, y)
    Items[name] = {
        imagePath = "assets/items.png",
        normal  = getItemRect(x, y),        -- 1~6번 라인 등
    }
end
function ItemFunc.createItemRect(name, x, y, w, h)
    local skinData = Items[name]
    if not skinData then return nil end
    
    local imgId = res.image(skinData.imagePath)
    local d = skinData.normal
    
    -- NinePatch 생성 (x, y, w, h, left, right, top, bottom)
    local np = NinePatch.new(imgId, d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8])
    
    -- UIPanel로 이미지 생성하여 반환
    return UIPanel.new(x, y, w or 16, h or 16, np)
end

registerIconSkin('setting', 42)
registerIconSkin('close', 29)

registerItemSkin('flag', 17, 4)
return ItemFunc