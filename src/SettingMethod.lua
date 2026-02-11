local SETTINGS_PATH = "settings.json"

local SettingMethod = {}
local Datastore = require("src.Datastore")
local UIManager = require("lib.UIManager")

function SettingMethod.ApplyGameSize(v)
    Datastore.get('settings').mainSize = v
end
function SettingMethod.ApplyUISize(v)
    local oldSize = Datastore.get('settings').uiSize
    UIManager:AdjustScale(oldSize, v)
    Datastore.get('settings').uiSize = v
end
function SettingMethod.ApplyAlwayTop(v)
    Datastore.get('settings').topmost = v
    sys.setTopmost(v)
end
function SettingMethod.ApplyMonitorIdx(v)
    local monitors = sys.getMonitors()

    local m = monitors[v]
    sys.setPos(m.workX, m.workY)
    Datastore.get('settings').monitor = v
end
function SettingMethod.ApplyStoredPositions(positionTable)
    for id, pos in pairs(positionTable) do
        local comp = UIManager.registry[id]
        if comp then
            comp.x = pos.x
            comp.y = pos.y
        end
    end
end

function SettingMethod.ApplyAll()
    local settings = Datastore.get('settings')
    if not settings then return nil end
    
    SettingMethod.ApplyGameSize(settings.mainSize)
    SettingMethod.ApplyUISize(settings.uiSize)
    SettingMethod.ApplyAlwayTop(settings.topmost)
    SettingMethod.ApplyMonitorIdx(settings.monitor)
    SettingMethod.ApplyStoredPositions(settings.uiPosition)
end


function SettingMethod.GetUIPositionTable()
    local positionData = {}

    for id, component in pairs(UIManager.registry) do
        positionData[id] = {
            x = component.x,
            y = component.y,
            visible = component.visible
        }
    end

    return positionData
end

function SettingMethod.Init()
    local data = res.loadTable(SETTINGS_PATH)
    if not data then data = {} end

    Datastore.update('settings', data)
    return data
end
function SettingMethod.GetFilled(data)
    if not data then data = {} end
    data = MergeTable(
        {
            mainSize = 1.5,
            uiSize = 1.0,
            topmost = true,
            monitor = 1,
            uiPosition = {},
        },
    data)
    return data
end
function SettingMethod.Save()
    local currentSettings = Datastore.get('settings')
    currentSettings.uiPosition = SettingMethod.GetUIPositionTable()
    local success = res.saveTable(SETTINGS_PATH, currentSettings)
    
    if success then
        print("[System] 설정이 저장되었습니다.")
    end
end




return SettingMethod