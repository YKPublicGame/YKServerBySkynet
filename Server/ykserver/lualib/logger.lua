local logging = require "logging"
local l = logging:new()
l.stack_level = l.stack_level + 1

local logger = {}

function logger.Game(...)
    l:Game(...)
end

function logger.Debug(...)
    l:Debug(...) 
end
function logger.Debugf(format, ...)
    l:Debugf(format, ...)
end

function logger.Info(...)
    l:Info(...)
end
function logger.Infof(format, ...)
    l:Infof(format, ...)
end

function logger.Warning(...)
    l:Warning(...)
end
function logger.Warningf(format, ...)
    l:Warningf(format, ...)
end

function logger.Error(...)
    l:Error(...)
end

function logger.Errorf(format, ...)
    l:Errorf(format, ...)
end

function logger.Critical(...)
    l:Critical(...)
end
function logger.Criticalf(format, ...)
    l:Criticalf(format, ...)
end

function logger.Fatal(...)
    l:Fatal(...)
end

function logger.Fatalf(format, ...)
    l:Fatalf(format,...)
end

function logger.Assert(v, message)
    return l:Assert(v,message)
end

function logger.SError(message, level)
    level = level and level+1 or 2
    return l:SError(message, level) 
end

function logger.Tag(key, value)
    l:Tag(key,value)
end

function logger.Untag(key)
    l:Untag(key)
end

function logger.set_modname(name)
    l:set_modname(name)
end

function logger.config(t)
    l:config(t)
end

return logger