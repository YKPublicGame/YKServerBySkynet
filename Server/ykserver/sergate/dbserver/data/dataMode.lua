---
--- Created by Administrator.
--- DateTime: 2018/8/18 17:38
---
local sqlhelp = require("sqlHelp")
local cjson = require("cjson")
local serviceNames = require("serviceNames")
local m =
{
    ---@type DataBase[]
    dataClasss =
    {
        require("data.userData"),
        require("data.accountData"),
        --require("data.wxData"),
    },
    modes = {
        [serviceNames.dbModeName.auth] = require("datamgr.authDB"),
    }
}

---@return DataBase
function m.getTableClass(personalId)
    for i, v in pairs(m.dataClasss) do
        if v.personalId == personalId then
            return v
        end
    end
    return nil
end

---@return ChangeDataInfo[]
function m.initMysql(db)
    print("初始化数据库中...")
    for i, v in pairs(m.dataClasss) do
        v:init(db)
    end
    print("初始化数据库完成...")
end

function m.initRedis(db)
    print("初始化Redis中...")
    local needUpdate = {}
    for i, v in pairs(m.dataClasss) do
        if v.needSavetoDB then
            local datas = db:hvals(v.personalId)
            if datas then
                for i, da in pairs(datas) do
                    local changeDataInfo = {} ---@type ChangeDataInfo
                    local data = v()
                    data:setData(da)
                    changeDataInfo = data:ToSaveData()
                    table.insert(needUpdate,changeDataInfo)
                end
            end
        end
    end
    for i, v in pairs(m.modes) do
        if v.init then
            v.init(db)
        end
    end
    print("初始化Redis完成...")

    return needUpdate
end

return m