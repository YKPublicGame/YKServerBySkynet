--- Created by Administrator.
--- DateTime: 2018/8/20 0:30
---

local ctrl = require("ctrl")
local skynet = require("skynet")
local cjson = require("cjson")
local errorCode = require("errorCode")
local dataUtil = require("datamgr.dataSerUtil")
local serviceName = require("serviceNames")
local this = {}
---@param gs Gamesession
function this.login(gs,loginReq)
    local ec,data = errorCode.SystemError.unknow,nil
    if not loginReq then
        return ec
    end
    local token = loginReq.token
    local roleid = loginReq.roleId
    ec,data = ctrl.login(gs,token,roleid)
    return ec,data
end

return this