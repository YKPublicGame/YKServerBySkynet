local skynet   = require "skynet"
local serviceNames = require("serviceNames")
local monitord = serviceNames.NODE_MONITOR
local monitor  = {}

local serverMap     = {}    -- servertype --> {nodeinfo1, nodeinfo2}
local nodeMap       = {}    -- nodename --> nodeinfo
local serverIndexs  = {}    -- servertype --> 1


function monitor.getServerMap()
  return serverMap
end

function monitor.getNodeMap()
  return nodeMap
end

--获取在线的节点
function monitor.getOnlineNodes()
  return skynet.call(monitord,"lua","getOnlineNodes")
end

--按服务器类型获取节点
function monitor.getServerByServerType(servertype)
  local onlineNodes = monitor.getOnlineNodes()
  if serverMap[servertype] == nil then
    return
  end

  local index = serverIndexs[servertype]
  if index > #serverMap[servertype] then
    index = 1
  end

  local nodeinfo = serverMap[servertype][index]
  serverIndexs[servertype] = index + 1
  return nodeinfo
end

--通过服务器id获取节点
function monitor.getServerByServerId(serverid)
  local onlineNodes = monitor.getOnlineNodes()
  for k, v in pairs(onlineNodes) do
    if v.serverid == serverid then
      return v
    end
  end
  return nil
end

--通过节点名获取节点
function monitor.getServerByNodename(nodename)
  local onlineNodes = monitor.getOnlineNodes()
  return onlineNodes[nodename]
end

--更新节点信息
function monitor.onUpdate(op, nodeinfo)
  monitor.init()
end

--监视节点变化
function monitor.watch()
  skynet.call(monitord, "lua", "watch", skynet.self())
end

--取消本节点监控
function monitor.unwatch()
  skynet.call(monitord, "lua", "unwatch", skynet.self())
end

--初始本节点数据
function monitor.init()
  nodeMap   = {}
  serverMap = {}
  local onlineNodes = monitor.getOnlineNodes()
  for _, nodeinfo in pairs(onlineNodes) do
    local nodename    = nodeinfo.nodename
    nodeMap[nodename] = nodeinfo
    local servertype  = nodeinfo.servertype
    serverMap[servertype] = serverMap[servertype] or {}
    table.insert(serverMap[servertype], nodeinfo)
    serverIndexs[servertype] = serverIndexs[servertype] or 1
  end

  --监控当前节点
  monitor.watch()
end

--本节点监控打开
function monitor.start()
  skynet.call(monitord, "lua", "start")
end

return monitor
