local skynet       = require "skynet"
local distributeClientMsg = require "distributeClientMsg"
local protoUtils = require("protoUtil")
local cjson = require("cjson")
local ServiceBase = {
  name = nil,
  modules = {},
  command = nil,
}

distributeClientMsg.ServiceBase = ServiceBase
ServiceBase.command = require "command_base"
local command = ServiceBase.command

--转发客户端的请求
function command.redirect(ctx, buffer)
  distributeClientMsg.redirect(ctx, buffer)
end

--转发服务间的请求
function command.redirectS2S(module,cmd,ctx, ...)
  return distributeClientMsg.redirectS2S(module,cmd,ctx, ...)
end

function command.gc()
  collectgarbage("collect")
end

function ServiceBase.onStart()

end

function ServiceBase.start()
  skynet.start(function()
    ServiceBase.onStart()
  end)
end

return ServiceBase
