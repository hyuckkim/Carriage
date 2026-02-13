local DataStore = require("src.Datastore")
local UIManager = require("lib.UIManager")
local ObjectManager = require("lib.ObjectManager")
local Character = require("src.Object.character")
local Anims = require("src.Table.Anims")
local genGrass = require("src.GenGrass")
local Customer = require("src.Object.customer")

local IdleState = {}
local grassCoroutine = nil


function IdleState.onEnter()
    local wagon = ObjectManager:Get('wagon')
    wagon:act('idle')
    local wagonTop = ObjectManager:Get('wagonTop')
    wagonTop:act('idle')

    if not ObjectManager:Get('chara') then
        local chara = Character.new('chara', Anims.chara())
        chara.ox, chara.oy = -32, -64
        chara.sayOX, chara.sayOY = 32, 20
        chara.x = wagon.x + 150
        chara.y = wagon.y
        chara.anim.flipX = true
        chara:act('idle')
        ObjectManager:Register(chara)
    end
end

function IdleState.onUpdate(dt)

    if grassCoroutine and coroutine.status(grassCoroutine) ~= "dead" then
        local success, err = coroutine.resume(grassCoroutine)
        if not success then print("Coroutine Error:", err) end
    end
end

function IdleState.onClick()
    UIManager:open('mainPanel')
end

function IdleState.GetPersistentData()
    local data = {
        stateType = "idle",
        customers = {},
        town = DataStore.get('currentTown') or {},
    }

    local locals = ObjectManager:GetAll(function(obj)
        return obj.is_customer
    end)
    
    for _, c in ipairs(locals) do
        table.insert(data.customers, c:GetPersistentData())
    end
    return data
end

function IdleState.Restore(data)
    if data.town then
        DataStore.update('currentTown', data.town)
        
        local screenW, _ = sys.getSize()
        grassCoroutine = genGrass.SpawnTownScenery(
            data.town.name, data.town.group, 0, screenW)
    end

    for _, cData in ipairs(data.customers or {}) do
        local c = Customer.newFromData(cData)
        ObjectManager:Register(c)
    end
    
end
return IdleState