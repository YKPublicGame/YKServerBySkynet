require "skynet.manager"
local  serviceNames = require("serviceNames")

local skynet   = require "skynet"
local cluster  = require "skynet.cluster"

local command = {}
local watchList   = {}     --需要通知的服务

--node
local curNodeName   = skynet.getenv("nodename")             --本节点名
local curNodePort   = skynet.getenv("nodeport")             --节点端口
local curNodeIP     = skynet.getenv("nodeip")
local S2STimeOut    = tonumber(skynet.getenv("checkS2STimeOut"))           --服务器之间通讯超时时间

local centernode = skynet.getenv("centernode") --中心服务ip和端口

--server
local servertype  = skynet.getenv("servertype")
local serverid    = tonumber(skynet.getenv("serverid"))
local serverindex = tonumber(skynet.getenv("serverindex"))
local isbackup    = tonumber(skynet.getenv("isbackup"))

local centerServerName = skynet.getenv("centerServerName")
---@class Nodeinfo
local curNodeinfo = {
    nodename     = curNodeName,                   --当前节点名
    nodeport     = curNodePort,                   --节点监听端口
    nodeip       = curNodeIP,                     --内网ip
    serverid     = serverid,                      --服务器id
    servertype   = servertype,                    --服务器类型
    serverindex  = serverindex,                   --服务器索引
    isbackup     = isbackup,                      --是否备进程
    activeTime   = os.time(),                     --最后一次回应的时间
}
---@type Nodeinfo[]
local onlineNodes = {}  ---当前存活的节点

local function addNodeInfo(nodeinfo)
    local nodename = nodeinfo.nodename
    onlineNodes[nodename] = nodeinfo
    if nodename ~= curNodeName then

        cluster.add_node(nodename, nodeinfo.nodeip ..":" .. nodeinfo.nodeport)
    end
    for addr, _ in pairs(watchList) do
        skynet.send(addr, "lua", "monitorUpdate", "addNode", nodeinfo)
    end
end

local function delNodeInfo(nodename)
    local nodeinfo = onlineNodes[nodename]
    if not nodeinfo then
        return false
    end

    cluster.remove_node(nodename)

    onlineNodes[nodename] = nil
    for addr, _ in pairs(watchList) do
        skynet.send(addr, "lua", "monitorUpdate", "delNode", nodeinfo)
    end
    return true
end

function command.watch(addr)
    watchList[addr] = true
end

function command.unwatch(addr)
    watchList[addr] = nil
end

function command.getOnlineNodes()
    return onlineNodes
end

function command.ping()
    return true
end

local function initCenterServer()
    local function checkHearBeat()
        local remove_tbl = {}
        skynet.fork(function()
            while true do
                skynet.sleep(S2STimeOut * 100)
                remove_tbl = {}
                ---@param v Nodeinfo
                for name, v in pairs(onlineNodes) do
                    if os.time() - v.activeTime > S2STimeOut*2 then
                        remove_tbl[name] = true
                    end
                end
                for k, v in pairs(remove_tbl) do
                    delNodeInfo(k)
                end
                command.broadcast("onDelNodes",remove_tbl)
            end
        end)
        end
    function command.broadcast(cmd, data, except)
        for nodename,_  in pairs(onlineNodes) do
            if nodename ~= curNodeName and nodename ~= except then
                cluster.send(nodename, serviceNames.NODE_MONITOR, cmd, data)
            end
        end
    end

    function command.register(node)
        addNodeInfo(node)
        command.broadcast("onAddNode", node, node.nodename)
        return onlineNodes
    end

    function command.unregister(nodename)
        delNodeInfo(nodename)
        return true
    end

    function command.heartbeat(nodename)
        if onlineNodes[nodename] then
            onlineNodes[nodename].activeTime = os.time()
        end
    end

    function command.start()
        checkHearBeat()
    end
end

local function InitOtherNodeServer()
    function command.heartbeat()
        skynet.fork(
        function ()
            while true do
                skynet.sleep(3*100)
                local ok, msg = xpcall(function()
                    cluster.call(centerServerName, serviceNames.NODE_MONITOR, "heartbeat", curNodeName)
                end, debug.traceback)
                if not ok then
                    error(msg)
                end
            end
        end)
    end

    function command.register()
        local nodes
        local ok, msg = xpcall(function()
            nodes = cluster.call(centerServerName, serviceNames.NODE_MONITOR, "register", curNodeinfo)
        end, debug.traceback)
        if not ok then
            error(msg)
            skynet.timeout(3*100, command.register)
        end

        if nodes then
            onlineNodes = nodes
            for _, node in pairs(nodes) do
                addNodeInfo(node)
            end
        end
    end

    function command.onAddNode(node)
        print("on add node........")
        addNodeInfo(node)
    end

    function command.onDelNodes(nodes)
        for name,_ in pairs(nodes) do
            delNodeInfo(name)
        end
    end

    function command.start()
        cluster.add_node(centerServerName, centernode) ---如果不是中心服务那么添加一个中心服
        command.register()
        command.heartbeat()
    end
end

if centerServerName == curNodeName then
    initCenterServer()
else
    InitOtherNodeServer()
end


skynet.start(function()

    cluster.open(tonumber(curNodePort))
    skynet.dispatch("lua", function(session, _, cmd, ...)
        local f = command[cmd]
        assert(f, string.format("nodeMonitord function[%s] is nil, current nodename[%s]", cmd, curNodeName))
        local ret1, ret2, ret3, ret4 = f(...)
        if cmd == "checkalive" then
            return
        end
        if session > 0 then
            skynet.ret(skynet.pack(ret1, ret2, ret3, ret4))
        end
    end)
    skynet.register(serviceNames.NODE_MONITOR)
end)











