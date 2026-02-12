local ObjectManager = {
    objects = {},
    renderQueue = {},
    scrollX = 0, scrollY = 0,
    isDirty = false
}

function ObjectManager:Register(obj)
    self.objects[obj.key] = obj
    table.insert(self.renderQueue, obj)
    self:SortLayers()
end
function ObjectManager:Remove(key)
    -- 1. 딕셔너리에서 객체 참조를 가져옴
    local obj = self.objects[key]
    if not obj then return end

    obj.is_destroyed = true
    -- 2. renderQueue(리스트)에서 해당 객체를 찾아 제거
    for i = #self.renderQueue, 1, -1 do
        if self.renderQueue[i] == obj then
            table.remove(self.renderQueue, i)
            break -- 찾았으면 루프 종료
        end
    end

    -- 3. 메인 객체 테이블에서 제거
    self.objects[key] = nil
end

function ObjectManager:SetLayer(key, newLayer)
    local obj = self.objects[key]
    if obj then
        obj.layer = newLayer
        self.isDirty = true -- 변경되었으므로 더럽다고 표시
    end
end

function ObjectManager:Update(dt)
    local player = self.objects['chara']
    local wagon = self.objects['wagon']
    local refX = (player and player.x) or (wagon and wagon.x) or 400

    for _, obj in pairs(self.objects) do
        obj:update(dt, refX)
    end
end

function ObjectManager:Draw()
    if self.isDirty then
        self:SortLayers()
    end

    local settings = require("src.Datastore").get('settings')
    local bgAlpha = settings.bgAlpha or 1.0
    local isApplyingBgAlpha = false

    -- 1. 객체 그리기 루프
    for _, obj in ipairs(self.renderQueue) do
        -- 레이어가 -20보다 낮으면 배경으로 간주
        if obj.layer < -20 then
            if not isApplyingBgAlpha then
                g.globalAlpha(bgAlpha) -- 배경 알파 적용
                isApplyingBgAlpha = true
            end
        else
            -- 배경 레이어를 벗어나는 순간 알파 복구
            if isApplyingBgAlpha then
                g.globalAlpha(1.0)
                isApplyingBgAlpha = false
            end
        end

        obj:draw(self.scrollX, self.scrollY)
    end

    -- 루프가 끝났는데 여전히 배경 알파 상태라면 안전하게 복구
    if isApplyingBgAlpha then
        Draw.globalAlpha(1.0)
    end

    -- 2. UI 그리기 루프 (UI는 배경 알파의 영향을 받지 않도록 별도 처리)
    for _, obj in ipairs(self.renderQueue) do
        if obj.drawUI then
            local sx = obj.isAbsolute and 0 or self.scrollX
            local sy = obj.isAbsolute and 0 or self.scrollY
            obj:drawUI(sx, sy)
        end
    end
end

function ObjectManager:SortLayers()
    table.sort(self.renderQueue, function(a, b) return a.layer < b.layer end)self.isDirty = false
end

function ObjectManager:Get(key) return self.objects[key] end

function ObjectManager:GetAll(filter)
    local list = {}
    for _, obj in pairs(self.objects) do
        if type(filter) == "function" then
            if filter(obj) then table.insert(list, obj) end
        else
            if obj[filter] then table.insert(list, obj) end
        end
    end
    return list
end

function ObjectManager:MoveWorld(dx, dy)
    for _, obj in pairs(self.objects) do
        -- absolute(UI 등)가 아닌 객체들만 이동시킴
        if not obj.isAbsolute then
            obj.x = obj.x - dx
            obj.y = obj.y - dy
        end
    end
end
return ObjectManager