local skynet       = require "skynet"
local serviceNames = require("serviceNames")
local crypt = require("skynet.crypt")
local utils = require("utils")
--local nodeMonitor  = require "node_monitor"
local debugPort    = skynet.getenv("debugPort")
local wsConfig =
{
    address     = "0.0.0.0",
    port        = tonumber(skynet.getenv("wsListenPort")),
    maxclient   = tonumber(skynet.getenv("wsMaxClient")),
    nodelay     = skynet.getenv("wsNodelay")
}

skynet.start(function()
    skynet.uniqueservice("debug_console", tonumber(debugPort))

    skynet.uniqueservice("server_log")
    skynet.uniqueservice("webclientser")
    skynet.uniqueservice("ykwsgate")

    skynet.call(serviceNames.wsgate,"lua","open",wsConfig)

    skynet.uniqueservice("httpser")

    skynet.uniqueservice("dbserver")

    skynet.uniqueservice("test")

    skynet.uniqueservice("authser")

    skynet.error(" start!")
    skynet.exit()
end)
