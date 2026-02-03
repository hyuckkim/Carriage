local UIButton = require("lib.UIButton")
local NinePatch = require("lib.ninepatch")
local UIPanel   = require("lib.UIPanel")
local DraggablePanel = require("lib.DraggablePanel")
local UIFactory = {}

-- 미리 정의된 UI 스킨들 (나인패치 설정 모음)
UIFactory.Skins = {
    Default = {
      imagePath = "assets/ui_sheet.png",
        normal = { 0, 0, 64, 64, 16, 16, 16, 16 },
        pressed = { 128, 0, 64, 64, 16, 16, 16, 16 },
        hover = { 64, 0, 64, 64, 16, 16, 16, 16 },
    }
}

-- 스타일을 적용한 버튼 생성 함수
function UIFactory.createButton(style, x, y, w, h, text, onClick)
    local skinData = UIFactory.Skins[style] or UIFactory.Skins.Default
    local imgId = res.image(skinData.imagePath)

    -- 상태별 나인패치를 만들 때 인자를 하나씩 명확히 전달
    local function makeNP(data)
        if not data then return nil end
        -- data: { sx, sy, sw, sh, l, r, t, b } 8개
        return NinePatch.new(imgId, data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8])
    end

    local nps = {
        normal  = makeNP(skinData.normal),
        hover   = makeNP(skinData.hover or skinData.normal),
        pressed = makeNP(skinData.pressed or skinData.normal)
    }
    return UIButton.new(x, y, w, h, nps, text, onClick)
end

-- 스타일을 적용한 버튼 생성 함수
function UIFactory.createPanel(style, x, y, w, h)
    local skinData = UIFactory.Skins[style] or UIFactory.Skins.Default
    local imgId = res.image(skinData.imagePath)

    -- 상태별 나인패치를 만들 때 인자를 하나씩 명확히 전달
    local function makeNP(data)
        if not data then return nil end
        -- data: { sx, sy, sw, sh, l, r, t, b } 8개
        return NinePatch.new(imgId, data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8])
    end
    return UIPanel.new(x, y, w, h, makeNP(skinData.normal))
end

function UIFactory.createDraggablePanel(style, x, y, w, h)
    local skinData = UIFactory.Skins[style] or UIFactory.Skins.Default
    local imgId = res.image(skinData.imagePath)

    -- 상태별 나인패치를 만들 때 인자를 하나씩 명확히 전달
    local function makeNP(data)
        if not data then return nil end
        -- data: { sx, sy, sw, sh, l, r, t, b } 8개
        return NinePatch.new(imgId, data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8])
    end
    return DraggablePanel.new(x, y, w, h, makeNP(skinData.normal))
end
return UIFactory