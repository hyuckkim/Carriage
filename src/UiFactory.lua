local NinePatch = require("lib.ninepatch")
local UIButton = require("lib.UI.UIButton")
local UIPanel   = require("lib.UI.UIPanel")
local DraggablePanel = require("lib.UI.DraggablePanel")
local UIFactory = {}

-- 미리 정의된 UI 스킨들 (나인패치 설정 모음)
UIFactory.Skins = {
    Default = {
      imagePath = "assets/ui_sheet.png",
        normal = { 0, 0, 64, 64, 16, 16, 16, 16 },
        pressed = { 128, 0, 64, 64, 16, 16, 16, 16 },
        hover = { 64, 0, 64, 64, 16, 16, 16, 16 },
    },
    Frame = {
        imagePath = "assets/ui_sheet.png",
        normal = { 144, 112, 64, 64, 16, 16, 16, 16}
    },
    House = {
        imagePath = "assets/house.png",
        normal = { 32, 154, 32, 32, 0, 0, 0, 0}
    }
}

-- 스타일을 적용한 버튼 생성 함수
function UIFactory.createButton(style, x, y, w, h, text, onClick, fontStyle)
    local skinData = UIFactory.Skins[style] or UIFactory.Skins.Default
    local fontData = UIFactory.Fonts[fontStyle] or UIFactory.Fonts.Default
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
    return UIButton.new(x, y, w, h, nps, text, onClick, fontData.color)
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

function UIFactory.createSlider(x, y, w, h, items, onChange, default)
    local imgId = res.image("assets/ui_sheet.png")
    local isVertical = h > w
    local slider
    
    -- 1. 방향에 따른 클래스 로드
    if isVertical then
        local UIVerticalSlider = require("lib.UI.UIVerticalSlider")
        slider = UIVerticalSlider.new(x, y, w, h)
        
        -- 세로형 기본 스킨 (트랙은 9패치로 늘리고, 핸들은 중앙 정렬)
        local trackNP = NinePatch.new(imgId, 501, 113, 6, 63, 2, 2, 8, 9)
        local handleNP = NinePatch.new(imgId, 210, 160, 12, 16, 0, 0, 0, 0)
        
        -- 가로폭(w)에 맞춰 핸들 너비를 잡고, 높이는 24 정도로 설정
        slider:setSkins(trackNP, handleNP, 16, 24)
    else
        local UIHorizontalSlider = require("lib.UI.UIHorizontalSlider")
        slider = UIHorizontalSlider.new(x, y, w, h)
        
        local trackNP = NinePatch.new(imgId, 208, 149, 64, 7, 9, 9, 2, 3)
        local handleNP = NinePatch.new(imgId, 210, 160, 12, 16, 0, 0, 0, 0)
        
        -- 세로폭(h)에 맞춰 핸들 높이를 잡고, 너비는 24 정도로 설정
        slider:setSkins(trackNP, handleNP, 16, 24)
    end

    -- 2. 데이터 모드 설정 (Table이면 아이템 모드, 아니면 비율 모드)
    if type(items) == "table" then
        slider:setItems(items) -- 내부적으로 setIndex(1) 호출함
        if default then
            slider:setIndex(default)
        end
    end

    -- 3. 콜백 연결
    slider.onChange = onChange

    return slider
end

-- 기본 텍스트 스타일 정의
UIFactory.Fonts = {
    Default = {
        fontId = res.fontFile("assets/NanumSquareRoundR.ttf", "나눔스퀘어라운드 Regular", 20),
        color = {255, 255, 255},
        align = "left"
    },
    Small = {
        fontId = res.fontFile("assets/NanumSquareRoundR.ttf", "나눔스퀘어라운드 Regular", 12),
        color = {255, 255, 255},
        align = "left"
    },
    Trait = {
        fontId = res.fontFile("assets/NanumSquareRoundR.ttf", "나눔스퀘어라운드 Regular", 12),
        color = {255, 255, 200},
        align = "left"
    },
    Trait_positive = {
        fontId = res.fontFile("assets/NanumSquareRoundR.ttf", "나눔스퀘어라운드 Regular", 12),
        color = {200, 255, 200},
        align = "left"
    },
    Trait_negative = {
        fontId = res.fontFile("assets/NanumSquareRoundR.ttf", "나눔스퀘어라운드 Regular", 12),
        color = {255, 200, 200},
        align = "left"
    }
}

function UIFactory.createText(x, y, str, styleName)
    local style = UIFactory.Fonts[styleName] or UIFactory.Fonts.Default
    local UIText = require("lib.UI.UIText")
    
    local txt = UIText.new(x, y, str, style.fontId, style.color)
    txt.align = style.align
    
    return txt
end

return UIFactory