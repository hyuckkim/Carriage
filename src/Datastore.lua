local Datastore = {
    settings = {
        mainSize = 1.5,
    },
    customers = {},
    ---@class StateMachine
    fsm = nil,
}

local function replaceContents(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then return end

    for k in pairs(target) do
        target[k] = nil
    end

    for k, v in pairs(source) do
        target[k] = v
    end
end

function Datastore.update(key, newData)
    local target = Datastore[key]
    if target then
        replaceContents(target, newData)
    else
        Datastore[key] = newData
    end
end

return Datastore