require "skynet.manager"
local skynet = require "skynet"
local logger = require "logger"
local serviceNames = require "serviceNames"
local logpath = skynet.getenv("logpath") or "./log/"
local logfile = skynet.getenv("logfile") or "server.log"
os.execute("mkdir -p " .. logpath)
print(logpath .. logfile)
local file = assert(io.open(logpath .. logfile, "a"), "open logfile err")

local dumplog = function(text)
    file:write(text)
    file:write("\n")
    file:flush()
end

local log_level_desc = {
    [0]   = "NOLOG",
    [10]  = "DEBUG",
    [20]  = "INFO",
    [30]  = "WARNING",
    [40]  = "ERROR",
    [50]  = "CRITICAL",
    [60]  = "FATAL",
}

--[[log object]]
local function log_format(self)
    if self.tags and next(self.tags) then
        return string.format("[%s %s] [%s]%s %s", self.timestamp,self.level,table.concat(self.tags, ","),self.src,self.msg)
    else
        return string.format("[%s %s]%s %s", self.timestamp,self.level,self.src,self.msg)
    end
end

local function log(name, modname, level, timestamp, msg, src, tags)
    dumplog(log_format {
        name = name,
        modname = modname,
        level = log_level_desc[level],
        timestamp = timestamp,
        msg = msg,
        src = src or '',
        tags = tags,
    })
end

skynet.start(function()
    skynet.register(serviceNames.SERVER_LOG)
    local config = {}
    config.name       = skynet.getenv("logName")
    config.to_screen  = skynet.getenv("toScreen")
    config.level      = skynet.getenv("logLevel")
    config.log_src    = skynet.getenv("logSrc")
    config.module_name= skynet.getenv("logModuleName")
    config.dump_level = tonumber(skynet.getenv("dumpLevel"))
    --设置日志配置
    logger.config(config)

    skynet.dispatch("lua", function(session, address, ...)
        log(...)
    end)

    dumplog("================server start >> "..os.date("%Y-%m-%d %H:%M:%S",os.time()).." << =====================")
end)
