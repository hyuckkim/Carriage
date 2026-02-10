local UIElement = require("lib.UI.UIElement")
local UIPanel = require("lib.UI.UIPanel")

---@class UICheckbox: UIPanel
local UICheckbox = setmetatable({}, { __index = UIPanel })
UICheckbox.__index = UICheckbox

-- skins는 { checked = np, unchecked = np } 형태를 기대합니다.
function UICheckbox.new(x, y, w, h, skins, onToggle, initialChecked)
    ---@class UICheckbox
    local self = UIPanel.new(x, y, w, h)
    setmetatable(self, UICheckbox)

    self.skins = skins
    self.checked = initialChecked or false
    self.callback = onToggle -- 체크 상태가 변할 때 호출될 함수
    
    self.color = { 255, 255, 255 }
    
    -- 초기 스킨 설정
    self:refreshSkin()
    
    return self
end

function UICheckbox:setText(newText)
    self.text = newText
    if self.text ~= "" then
        self.tw, self.th = g.fontSize(0, self.text)
    else
        self.tw, self.th = 0, 0
    end
end

-- 상태에 따라 스킨을 교체하는 함수
function UICheckbox:refreshSkin()
    local state = self.checked and "checked" or "unchecked"
    self.np = self.skins[state] or self.skins["unchecked"]
end

function UICheckbox:setChecked(value)
    if self.checked == value then return end
    self.checked = value
    self:refreshSkin()
    
    if self.callback then
        self.callback(self.checked)
    end
end

function UICheckbox:draw()
    if not self.visible then return end
    UIPanel.draw(self)

    local ax, ay = self:getAbsolutePos()
    UIElement.draw(self)
end

function UICheckbox:dispatchClick(x, y, button)
    if not self.visible or not self:isHit(x, y) then return false end

    if button == "left" then
        -- 상태 반전
        self:setChecked(not self.checked)
        return true
    end
    
    return false
end

return UICheckbox