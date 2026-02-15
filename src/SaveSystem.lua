local DataStore = require("src.DataStore")
local SettingMethod = require("src.SettingMethod")

local SaveSystem = {}

function SaveSystem.save()
    local fsm = DataStore.get('fsm')
    if not fsm or not fsm.current then
        print("저장 실패: 현재 FSM 상태를 찾을 수 없습니다.")
        return
    end

    local stateSpecificData = fsm.current.GetPersistentData()

    local root = {
        state = stateSpecificData,
        gold = DataStore.get('gold') or 0,
    }

    res.saveTable("save.json", root)
    SettingMethod.Save()
end

function SaveSystem.load()
    local root = res.loadTable("save.json")
    if not root then return {} end
    
    local fsm = DataStore.get('fsm')
    if fsm then

        fsm:transition(root.state.stateType)
        if fsm.current.Restore then
            fsm.current.Restore(root.state)
        end
    end

    return root
end

return SaveSystem