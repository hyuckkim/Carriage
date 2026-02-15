local MapQuery = {}
MapQuery.__index = MapQuery

function MapQuery.new(mapData)
    local self = setmetatable({}, MapQuery)
    self.data = mapData
    return self
end
function MapQuery:getNameTown(name)
    local pack = self.data.pack
    if not pack then return nil end

    local i = 2
    while true do
        local b = pack.burgs[i]
        if not b or type(b) ~= "userdata" then break end
        if b.name == name then return b end
        i = i + 1
    end

    return nil
end
function MapQuery:getRealDistance(startWx, startWy, endWx, endWy)
    local dx = endWx - startWx
    local dy = endWy - startWy
    local coordinateDistance = math.sqrt(dx * dx + dy * dy)

    local scale = self.data.settings.distanceScale or 1
    local unit = self.data.settings.distanceUnit or "km"

    return coordinateDistance * scale, unit
end
function MapQuery:getDistanceBetweenTowns(name1, name2)
    local b1 = self:getNameTown(name1)
    local b2 = self:getNameTown(name2)
    if not b1 or not b2 then return nil end

    return self:getRealDistance(b1.x, b1.y, b2.x, b2.y)
end
function MapQuery:findClosestBurg(wx, wy, radius)
    local pack = self.data.pack
    local closest = nil
    local minDistSq = radius * radius

    local i = 2
    while true do
        local b = pack.burgs[i]
        if not b or type(b) ~= "userdata" then break end

        local dx, dy = b.x - wx, b.y - wy
        local distSq = dx*dx + dy*dy

        if distSq < minDistSq then
            minDistSq = distSq
            closest = b
        end

        i = i + 1
    end

    return closest
end

return MapQuery