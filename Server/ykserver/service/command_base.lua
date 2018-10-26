require("debug")
local skynet = require "skynet"
local profile = require "skynet.profile"
local command = {}
local ti = {}

-- 运行lua文件,热更新用
-- @param source
-- @param filename
-- @return deskId
function command.run(source, filename, ...)
    local output = {}
    local function print(...)
        local value = {...}
        for k, v in ipairs(value) do
            value[k] = tostring(v)
        end
        table.insert(output, table.concat(value, "\t"))
    end

    local env = setmetatable({print = print, args = {...}}, {__index = _ENV})
    local func, err = load(source, filename, "bt", env)
    if not func then
        return {err}
    end
    local ok, err = xpcall(func, debug.traceback)
    if not ok then
        table.insert(output, err)
    end
end

local function profileCall(func, cmd, ...)
    profile.start()
    local ret1, ret2, ret3, ret4 = func(...)
    local time = profile.stop()
    local p = ti[cmd]
    if p == nil then
        p = { n = 0, ti = 0}
        ti[cmd] = p
    end
    p.n = p.n + 1
    p.ti = p.ti + time
    return ret1, ret2, ret3, ret4
end

local function dispatch(session, address, cmd, ...)
    local func = assert(command[cmd], string.format("func = command[%s] is nil", cmd))
    local ret1, ret2, ret3, ret4

    if session == 0 then
        return func(...)
    end

    skynet.ret(skynet.pack(func(...)))
end
skynet.dispatch("lua", dispatch)

skynet.info_func(function()
    return { mem = collectgarbage("count"), profile = ti }
end)

return command
