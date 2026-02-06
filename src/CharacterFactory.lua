local CharacterFactory = {}
local Anim = require('lib.anim')
local ObjectManager = require("lib.ObjectManager")
local Customer = require('src.Object.customer')

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

function CharacterFactory.createCustomer(gender, key)
    gender = gender or (math.random() > 0.5 and "male" or "female")
    local categories = {"skin", "top", "bottom", "hair", "footage", "hat"}
    local layerIds = {}
    local visualRecipe = { gender = gender, parts = {} }

    for i, cat in ipairs(categories) do
        local info = pickSkinInfo(gender, cat)
        if info then
            local imgId = res.image(info.path)
            if imgId then
                table.insert(layerIds, imgId)
                visualRecipe.parts[cat] = { grade = info.grade, file = info.file, id = imgId }
            end
        end
    end
    if #layerIds == 0 then return nil end

    local anim = Anim.new(layerIds, 80, 64, 10)
    anim:add("idle", {0, 1, 2, 3, 4})
    anim:add("walk", {10, 11, 12, 13, 14, 15, 16, 17})
    anim:play("idle")

    local firstNames = {"김", "이", "박", "최", "정", "강", "조", "윤"}
    local lastNames = {"철수", "영희", "춘자", "덕배", "광식", "지혜", "칠득", "소희"}
    local destinations = {"안산", "한양", "강릉", "부산", "평양", "수원", "강화"}
    
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

    local customerData = {
        name = firstNames[math.random(#firstNames)] .. lastNames[math.random(#lastNames)],
        destination = destinations[math.random(#destinations)],
        budget = math.random(2, 15) * 10,
        traits = { allTraits[t1].name, allTraits[t2].name },
        recipe = visualRecipe,
    }

    local objKey = key or ("cust_" .. math.random(1000, 9999))
    local customer = Customer.new(objKey, anim, customerData)

    customer.x = 400
    customer.y = 300
    
    ObjectManager:Register(customer)

    return customer
end

return CharacterFactory