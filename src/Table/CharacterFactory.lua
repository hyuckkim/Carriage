local CharacterFactory = {}
local Anim = require('lib.anim')
local ObjectManager = require("lib.ObjectManager")
local Customer = require('src.Object.customer')
local Datastore = require("src.Datastore")
local NewName = require("src.Table.Name")

local SkinAssets = {
    base_path = "assets/generate/",
    
    male = {
        skin = {
            prefix = "1_skin/",
            weights = { common = 80, special = 20 },
            list = {
                common = { "Male Skin1", "Male Skin2", "Male Skin3", "Male Skin4", "Male Skin5" },
                special = { "Male Demon skin", "Male Devil skin", "Male Ghost skin", "Male Orc skin", "Male Zombie skin" }
            }
        },
        top = {
            prefix = "2_top/",
            weights = { common = 90, rare = 10 },
            list = {
                common = { "Shirt", "Shirt v2", "Blue Shirt v2", "Green Shirt v2", "orange Shirt v2", "Purple Shirt v2" },
                rare = { "Shirt v2" } -- 더 희귀한 게 생기면 여기에 추가
            }
        },
        bottom = {
            prefix = "3_bottom/",
            weights = { common = 100 },
            list = {
                common = { "Pants", "Blue Pants", "Green Pants", "Orange Pants", "Purple Pants" }
            }
        },
        hair = {
            prefix = "4_hair/",
            weights = { common = 70, rare = 25, legend = 5 },
            list = {
                common = { "Male Hair1", "Male Hair2", "Male Hair3", "Male Hair4", "Male Hair5" },
                rare = { 
                    "Male Hair6", "Male Hair7", "Male Hair8", "Male Hair9", "Male Hair10",
                    "Male Hair11", "Male Hair12", "Male Hair13", "Male Hair14", "Male Hair15",
                    "Male Hair16", "Male Hair17", "Male Hair18", "Male Hair19", "Male Hair20",
                    "Male Hair21", "Male Hair22", "Male Hair23", "Male Hair24", "Male Hair25",
                    "Male Hair26", "Male Hair27", "Male Hair28", "Male Hair29", "Male Hair30"
                },
                legend = { "Fancy Hair", "Queen hair", "Shield Maiden hair" }
            }
        },
        footage = {
            prefix = "5_footage/",
            weights = { common = 100 },
            list = {
                common = { "Boots", "Shoes" }
            }
        },
        hat = {
            prefix = "6_hat/",
            weights = { none = 40, common = 40, rare = 15, legend = 5 },
            list = {
                none = { nil },
                common = { 
                    "Male Blue cap", "Male Green cap", "Male Orange cap", 
                    "Male Purple cap", "Male Red cap", "Farming Hat M" 
                },
                rare = { 
                    "Male Hat1", "Male Hat2", "Male Hat3", "Male Hat4", "Male Hat5",
                    "Male Hat6", "Male Hat7", "Male Hat8", "Male Hat9", "Male Hat10",
                    "Guard Helmet", "Male Mining Helmet", "Viking Helmet"
                },
                legend = { "Viking Helmet with horns", "Pumpkin hat", "Male Santa hat" }
            }
        }
    },
    female = {
        skin = {
            prefix = "1_skin/",
            weights = { common = 80, special = 20 },
            list = {
                common = { 
                    "Female Skin1", "Female Skin2", "Female Skin3", "Female Skin4", "Female Skin5" 
                },
                special = { 
                    "Female Demon skin", "Female Devil skin", "Female Ghost skin", "Female Orc skin", "Female Zombie skin" 
                }
            }
        },
        top = {
            prefix = "2_top/",
            weights = { common = 70, rare = 30 },
            list = {
                common = { 
                    "Corset", "Corset v2", "Blue Corset", "Green Corset", "Orange Corset", "Purple Corset",
                    "Blue Bodice", "Green Bodice", "Orange Bodice", "Purple Bodice", "Red Bodice"
                },
                rare = { 
                    "Armored Corset", "Corset Long Sleeves", "Blue Corset Long Sleeves", "Purple Corset v2 Long Sleeves",
                    "Green Bodice Mid Sleeves", "Orange Bodice Long Sleeves"
                }
            }
        },
        bottom = {
            prefix = "3_bottom/",
            weights = { common = 60, rare = 40 },
            list = {
                common = { "Skirt", "Short Skirt", "Blue dress", "Long dress blue", "Long dress red" },
                rare = { 
                    "Fancy Blue Dress", "Queen Dress", "Black Thigh-High Boots", "Brown Thigh-High Boots" 
                }
            }
        },
        hair = {
            prefix = "4_hair/",
            weights = { common = 80, rare = 20 },
            list = {
                common = (function()
                    local l = {}
                    for i=1, 20 do table.insert(l, "Female Hair" .. i) end
                    return l
                end)(),
                rare = (function()
                    local l = {}
                    for i=21, 35 do table.insert(l, "Female Hair" .. i) end
                    return l
                end)()
            }
        },
        footage = {
            prefix = "5_footage/",
            weights = { common = 100 },
            list = {
                common = { "Boots", "Socks", "Green Socks", "Red Socks", "Skyblue Socks" }
            }
        },
        hat = {
            prefix = "6_hat/",
            weights = { none = 30, common = 40, rare = 25, legend = 5 },
            list = {
                none = { nil },
                common = { "Female Blue cap", "Female Red cap", "Farming Hat F", "Bunny ears1" },
                rare = { "Female Hat1", "Female Hat5", "Female Mining Helmet", "Witch hat", "Bunny ears5" },
                legend = { "Female Santa hat" }
            }
        }
    }
}

-- 등급 결정 함수
local function pickGrade(weightTable)
    local total = 0
    for _, w in pairs(weightTable) do total = total + w end
    local rand = math.random() * total
    local cur = 0
    for grade, w in pairs(weightTable) do
        cur = cur + w
        if rand <= cur then return grade end
    end
end

-- 정보를 함께 반환하는 Skin 선택 함수
local function pickSkinInfo(gender, categoryName)
    local config = SkinAssets[gender][categoryName]
    if not config then return nil end

    local grade = pickGrade(config.weights)
    local list = config.list[grade]
    
    if list and list[1] ~= nil then
        local fileName = list[math.random(#list)]
        local fullPath = SkinAssets.base_path .. gender .. "/" .. config.prefix .. fileName .. ".png"
        
        -- 경로뿐만 아니라 메타데이터를 함께 리턴
        return {
            path = fullPath,
            grade = grade,
            file = fileName
        }
    end
    return nil
end

local function calculateBudget(origin, target, traits)
    local map = Datastore.get('canvasMap')
    if not map or not origin or not target then return math.random(30, 60) end

    -- 1. 거리 계산
    local dist, _ = map:getRealDistance(origin.x, origin.y, target.x, target.y)
    
    local baseFare = 30   -- 기본 요금 (시내 단거리 기본 단가)
    local perKm = 20      -- km당 요금 (거리가 멀수록 수익 체감)
    local distanceFare = dist * perKm

    -- 2. 특성(Traits)에 따른 심리적 예산 변동
    local multiplier = 1.0
    for _, traitName in ipairs(traits) do
        if traitName == "부자" then 
            multiplier = multiplier + 0.4    -- 팁을 후하게 줄 준비가 됨
        elseif traitName == "구두쇠" then 
            multiplier = multiplier - 0.2    -- 깎으려고 시도함 (예산 한도 낮음)
        elseif traitName == "짐꾼" then 
            multiplier = multiplier + 0.15   -- 수하물 추가 요금 인지
        elseif traitName == "여행객" then
            multiplier = multiplier + 0.1    -- 초행길이라 시세를 잘 모름(후함)
        elseif traitName == "학자" then
            multiplier = multiplier - 0.1    -- 정확한 거리를 계산해서 딱 맞춰 주려 함
        end
    end

    -- 3. 최종 요금 산출
    -- 거리가 너무 짧아도(예: 0.5km) 기본료 덕분에 손해는 안 봄
    local rawBudget = (baseFare + distanceFare) * multiplier
    
    -- ±15%의 개인차 (협상의 여지)
    local noise = math.random(85, 115) / 100 
    local finalBudget = rawBudget * noise

    -- [게임적 허용] 10G 단위로 깔끔하게 절삭
    -- 143G -> 140G, 158G -> 160G
    return math.max(30, math.floor(finalBudget + 5))
end

function CharacterFactory.createCustomer(pos, currentTown, key)
    local current = currentTown or Datastore.get('currentTown')
    local targetTown = Datastore.get('canvasMap'):pickDestination(current.name)
    
    local gender = (math.random() > 0.5 and "male" or "female")
    local categories = {"skin", "top", "bottom", "hair", "footage", "hat"}
    local layerIds = {}
    local visualRecipe = { gender = gender, parts = {} }

    for i, cat in ipairs(categories) do
        local info = pickSkinInfo(gender, cat)
        if info then

            table.insert(layerIds, info.path)
            visualRecipe.parts[cat] = { grade = info.grade, file = info.file, id = info.path }
        end
    end
    if #layerIds == 0 then return nil end

    local anim = Anim.new(layerIds, 80, 64, 10)
    anim:add("idle", {0, 1, 2, 3, 4})
    anim:add("walk", {10, 11, 12, 13, 14, 15, 16, 17})
    anim:play("idle")
    
    local allTraits = {
        { name = "애주가", type = "Positive" }, { name = "부자", type = "Positive" },
        { name = "정직함", type = "Positive" }, { name = "쾌활함", type = "Positive" },
        { name = "술꾼", type = "Negative" }, { name = "구두쇠", type = "Negative" },
        { name = "까칠함", type = "Negative" }, { name = "수다쟁이", type = "Negative" },
        { name = "평범함", type = "Neutral" }, { name = "여행객", type = "Neutral" },
        { name = "학자", type = "Neutral" }, { name = "짐꾼", type = "Neutral" }
    }

    local t1 = math.random(#allTraits)
    local t2 = math.random(#allTraits)
    while t1 == t2 do t2 = math.random(#allTraits) end
    local selectedTraits = { allTraits[t1], allTraits[t2] }

    local customerData = {
        name = NewName(),
        origin = current and current.name or "알 수 없는 곳",
        destination = targetTown and targetTown.name or "먼 곳",
        -- 거리에 비례한 예산 책정 (예: 1km당 5G)
        budget = calculateBudget(current, targetTown, selectedTraits),
        traits = selectedTraits,
        recipe = visualRecipe,
    }

    local objKey = key or ("cust_" .. math.random(1000, 9999) .. "_" .. customerData.name)
    local customer = Customer.new(objKey, anim, customerData)

    customer.x = pos.x
    customer.y = pos.y
    
    ObjectManager:Register(customer)

    return customer
end

return CharacterFactory