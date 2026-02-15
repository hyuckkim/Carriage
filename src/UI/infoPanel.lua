local UIManager   = require("lib.UIManager")
local UIFactory   = require("src.Table.UiFactory")
local UIViewport  = require("lib.UI.UIViewport")

return function ()

    ---@class infoPanel: DraggablePanel
    local panel = UIFactory.createDraggablePanel("Default", 260, 120, 500, 650)

    -------------------------------------------------
    -- 1️⃣ 상단 제목 영역
    -------------------------------------------------

    panel:addChild(UIFactory.createText(20, 15, "Carriage", "Large"))
    panel:addChild(UIFactory.createText(20, 45, "By hyuckkim", "Small"))
    panel:addChild(UIFactory.createText(20, 70, "Open Source & Assets", "Default"))

    local repoBtn = UIFactory.createButton(
        "Default", 320, 20, 150, 35,
        "Repository",
        function()
            if sys and sys.openURL then
                sys.openURL("https://github.com/hyuckkim/Carriage")
            end
        end
    )
    panel:addChild(repoBtn)

    -------------------------------------------------
    -- 2️⃣ 데이터 (하드코딩)
    -------------------------------------------------

    local credits = {
        {
            name = "Pixel Art Characters Bundle",
            author = "GandalfHardcore",
            license = "Custom License (Commercial Use Allowed)",
            url = "https://itch.io/s/174757/-pixel-art-characters-bundle-",
            thumbnail = "assets/thumbs/gandalfhardcore.png"
        },
        {
            name = "Free Basic Pixel User Interface for Fantasy Game",
            author = "ArtistName",
            license = "Used under CraftPix License",
            url = "https://free-game-assets.itch.io/free-basic-pixel-art-ui-for-rpg",
            thumbnail = "assets/thumbs/CraftPix.png"
        }
    }

    -------------------------------------------------
    -- 3️⃣ 항목 렌더링
    -------------------------------------------------

    local startY = 110
    local blockHeight = 90

    for i, entry in ipairs(credits) do
        local y = startY + (i - 1) * blockHeight

        -- 썸네일
        panel:addChild(UIViewport.new(20, y, 64, 64, function(x, y, w, h)
            if entry.thumbnail then
                g.image(res.image(entry.thumbnail), x, y, w, h)
            end
        end))

        panel:addChild(UIFactory.createPanel("Frame", 20, y, 64, 64))

        -- 이름 + 저작자
        panel:addChild(UIFactory.createText(
            100, y,
            entry.name
        ))
        panel:addChild(UIFactory.createText(
            100, y + 22,
            'By ' .. entry.author,
            "Small"
        ))

        -- 라이선스
        panel:addChild(UIFactory.createText(
            100, y + 34,
            entry.license,
            "Small"
        ))

        -- 링크 버튼
        panel:addChild(UIFactory.createButton(
            "Default",
            100, y + 50,
            160, 30,
            "링크 열기",
            function()
                if sys and sys.openURL then
                    sys.openURL(entry.url)
                end
            end
        ))
    end

    -------------------------------------------------
    -- 4️⃣ 닫기 버튼
    -------------------------------------------------

    panel:addChild(UIFactory.createButton(
        "Default",
        390, 600,
        90, 35,
        "닫기",
        function()
            UIManager:close(panel)
        end
    ))

    panel.visible = false
    return panel
end
