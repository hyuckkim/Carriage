local ObjectManager = {
    objects = {},
    renderQueue = {},
    scrollX = 0, scrollY = 0
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

function ObjectManager:Update(dt)
    local player = self.objects['chara']
    local wagon = self.objects['wagon']
    local refX = (player and player.x) or (wagon and wagon.x) or 400

    for _, obj in pairs(self.objects) do
        obj:update(dt, refX)
    end
end

function ObjectManager:Draw()
    for _, obj in ipairs(self.renderQueue) do
        obj:draw(self.scrollX, self.scrollY)
    end
end

function ObjectManager:SortLayers()
    table.sort(self.renderQueue, function(a, b) return a.layer < b.layer end)
end

function ObjectManager:Get(key) return self.objects[key] end

function ObjectManager:GetAll(property)
    local list = {}
    for _, obj in pairs(self.objects) do
        -- 해당 속성이 존재하고 true인지 확인
        if obj[property] then 
            table.insert(list, obj)
        end
    end
    return list
end

return ObjectManager