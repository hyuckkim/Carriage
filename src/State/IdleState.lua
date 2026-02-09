local CharacterFactory = require("src.CharacterFactory")
local UIManager = require("lib.UIManager")
local DataStore = require("src.Datastore")
local CanvasMap = require("src.UI.canvasMap")

local IdleState = {}


function IdleState.onEnter(initialCustomers)
    if not initialCustomers then
        for i = 1, 8 do
            CharacterFactory.createCustomer()
        end
    end
end

function IdleState.onClick()
    UIManager:open('mainPanel')
end

return IdleState