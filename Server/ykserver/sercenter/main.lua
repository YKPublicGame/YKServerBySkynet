local skynet      = require "skynet"
local nodeMonitor = require "node_monitor"
local debugPort    = skynet.getenv("debugPort")
skynet.start(function()
    skynet.error("------debug_console----------");
    skynet.uniqueservice("debug_console",tonumber(debugPort))
    skynet.uniqueservice("server_log")
    skynet.uniqueservice("NodeMonitord")
    nodeMonitor.start()
    skynet.error("centerserver start!")
    skynet.exit()
end)
