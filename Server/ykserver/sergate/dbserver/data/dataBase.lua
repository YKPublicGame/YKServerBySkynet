---
--- Created by Administrator.
--- DateTime: 2018/8/18 18:03
---
local skynet = require("skynet")
local logger = require("logger")
local class = require("class")
local cjson = require("cjson")
local sqlhelp = require("sqlHelp")
local encodeType =
{
    "string",
    "number",
    "boolean",
}

function encodeType.exist(k)
    for i, v in pairs(encodeType) do
        if v == k then
            return true
        end
    end
    return false
end



---@class DataBase
---@field personalId string
---@field keyName string
---@field secondaryKeys string
---@field needSavetoDB boolean
local m = {}
m.personalId = nil
m.keyName = "key"
m.secondaryKeys = nil
m.needSavetoDB = true
m.columnNameOptions = {}

---@param dataClass DataBase
local function CreateTable(dataClass,db)
    local sql = sqlhelp.createTable(dataClass.personalId,
            dataClass.columnNameOptions,
            dataClass.keyName,dataClass.secondaryKeys)
    local result = db:query(sql)

    if result.errno then
        logger.Errorf("CreateTable fatal err, sql:%s", sql)
        error(result.err)
        --return
    end
end

---@param dataClass DataBase
local function AddColumnName(columnNames,dataClass,db)
    for _, key in pairs(columnNames) do
        local sql = sqlhelp.addColumn(dataClass.personalId
        ,key,dataClass.columnNameOptions[key])
        local result = db:query(sql)
        if result.errno then
            logger.Errorf("AddColumnName fatal err, sql:%s", sql)
            error(result.err)
        end
    end
end

function m:init(db)
    if self.needSavetoDB then
        local result = db:query(sqlhelp.checkTableHas(self.personalId))

        if result == nil or #result == 0 then
            CreateTable(self,db)
        else
            local columns = {}
            result = db:query(sqlhelp.getTableColumnNames(self.personalId))
            if result then
                for i, v in pairs(result) do
                    table.insert(columns,v["column_name"])
                end
            end
            local needAdd = {}
            for key, v in pairs(self.columnNameOptions) do
                local flag = false
                for i, v in ipairs(columns) do
                    if v == key then
                        flag = true
                        break
                    end
                end
                if not flag then
                    table.insert(needAdd,key)
                end
            end
            if needAdd and #needAdd > 0 then
                AddColumnName(needAdd,self,db)
            end
        end
    end
end

---@return ChangeDataInfo
function m:ToSaveData()
    local data = {}
    for i, v in pairs(self) do
        if self:columnNameHasExist(i) then
            data[i] = v
        end
    end
    ---@type ChangeDataInfo
    local saveData =
    {
        data = cjson.encode(data),
        keyName = self.keyName,
        keyValue = self[self.keyName],
        personalId = self.personalId,
        needSavetoDB = self.needSavetoDB
    }
    local secondkeyT
    if self.secondaryKeys then
        secondkeyT = string.split(self.secondaryKeys,",")
    end
    if secondkeyT then
        saveData.secondaryKeys = {}
        for _, key in ipairs(secondkeyT) do
            saveData[key] = self[key]
            table.insert(saveData.secondaryKeys,key)
        end
    end
    return saveData
end

function m:setData(data)
    if data then
        if type(data)=="string" then
            data = cjson.decode(data)
        end
        for key, v in pairs(self.columnNameOptions) do
            if data[key] then
                self[key] = data[key]
            end
        end
        return self
    else
        return nil
    end
end

function m:columnNameHasExist(columnName)
    for i, v in pairs(self.columnNameOptions) do
        if i == columnName then
            return true
        end
    end
    return false
end

return m
