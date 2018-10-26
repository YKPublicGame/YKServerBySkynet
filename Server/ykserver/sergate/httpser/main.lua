---
--- Created by Administrator.
--- DateTime: 2018/8/18 19:14
---
local skynet = require "skynet"
local socket = require "skynet.socket"
local httpport = tonumber(skynet.getenv("httpport")) or 8001
skynet.start(function()
    local agent = {}
    for i= 1, 10 do
        -- 启动 20 个代理服务用于处理 http 请求
        agent[i] = skynet.newservice("httpagent")
    end
    local balance = 1
    -- 监听一个 web 端口
    local id = socket.listen("0.0.0.0", httpport)
    skynet.error("开始监听httpurl=0.0.0.0:"..httpport)
    socket.start(id , function(id, addr)
        -- 当一个 http 请求到达的时候, 把 socket id 分发到事先准备好的代理中去处理。
        --skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
        skynet.send(agent[balance], "lua", id)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end

    end)
end)