require "skynet.manager"
local skynet = require "skynet"

local clientLogPath = skynet.getenv("clientLogPath") or "./client_log/"
local clientLogFile = skynet.getenv("clientLogFile") or "client_%s.log"
os.execute("mkdir -p " .. clientLogPath)
local logFile       = nil --日志文件
local logFilePath   = nil --日志文件日期

local function getLogFilePath()
    local file = string.format(clientLogFile, os.date("%Y_%m_%d", os.time()))
    return clientLogPath .. file
end

local function getLogFile()
    if not logFile then
        logFilePath = getLogFilePath()
        logFile = assert(io.open(logFilePath, "a"), "open logFile err")
        return logFile
    end

    local newLogFilePath = getLogFilePath()
    if logFilePath ~= newLogFilePath then
        logFile:close()
        logFile = assert(io.open(newLogFilePath, "a"), "open logFile err")
        logFilePath = newLogFilePath
        return logFile
    end

    return logFile
end

local dumplog = function(text)
    local file = getLogFile()
    file:write(text)
    file:write("\n")
    file:flush()
end

local function log(msg)
    dumplog(msg)
end

skynet.start(function()
    skynet.register(SERVICE.CLIENT_LOG)

    skynet.dispatch("lua", function(session, address, ...)
        log(...)
    end)
end)
