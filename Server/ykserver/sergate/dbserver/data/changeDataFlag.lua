---
--- Created by Administrator.
--- DateTime: 2018/8/17 23:17
---

---@class ChangeDataInfo
---@field data string
---@field flag ChangeDataFlag
---@field personalId string
---@field keyName string
---@field secondaryKeys table
---@field keyValue string
---@field needSavetoDB bool

---@class ChangeDataFlag
local m =
{
    Add = 1,
    Update = 2,
    Del = 3,
}
return m