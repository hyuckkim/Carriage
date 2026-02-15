local SETTINGS_PATH = ""

local SettingMethod = {}
local Datastore = require("src.Datastore")
local UIManager = require("lib.UIManager")

function SettingMethod.ApplyUIAlpha(v)
    Datastore.get('settings').uiAlpha = v
end

function SettingMethod.ApplyBackgroundAlpha(v)
    Datastore.get('settings').bgAlpha = v
end
function SettingMethod.ApplyGameSize(v)
    Datastore.get('settings').mainSize = v
end
function SettingMethod.ApplySFXEnabled(v)
    Datastore.get('settings').sfxEnabled = v
end
function SettingMethod.ApplyUISize(v)
    local oldSize = Datastore.get('settings').uiSize
    UIManager:AdjustScale(oldSize, v)
    Datastore.get('settings').uiSize = v
end
function SettingMethod.ApplyAlwayTop(v)
    Datastore.get('settings').topmost = v
    sys.topmost(v)
end
function SettingMethod.ApplyMonitorIdx(v)
    local monitors = is.monitors()

    local m = monitors[v]
    sys.pos(m.workX, m.workY)
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
    SettingMethod.ApplyUIAlpha(settings.uiAlpha or 1.0)
    SettingMethod.ApplyBackgroundAlpha(settings.bgAlpha or 1.0)
    SettingMethod.ApplySFXEnabled(settings.sfxEnabled or true)
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

function SettingMethod.Init(settingPath)
    SETTINGS_PATH = settingPath
    local data = res.loadTable(SETTINGS_PATH) or {}
    data = SettingMethod.GetFilled(data)

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
            uiAlpha = 1.0,    -- 기본 UI 투명도 (불투명)
            bgAlpha = 1.0,    -- 기본 배경 투명도 (불투명)
            uiPosition = {},
            sfxEnabled = true,
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