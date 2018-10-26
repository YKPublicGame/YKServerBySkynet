local skynet = require "skynet"
local class    = require "class"
local nodeMgr = require("nodeMgr")
local serverType =require("serverType")
local logger = require("logger")
local cjson = require("cjson")
local dataSerUtil = require("datamgr.dataSerUtil")
local serviceNames = require("serviceNames")
local utils = require("utils")
local curNodename = skynet.getenv "nodename"
---@class Gamesession
local this = class()
local CMD = {}
this.command = CMD

local sessionRedisKey = "__GLOBAL_SESSIONS"
---@type Gamesession[]
local _globalSession = {}
local serverid
local uuid
local heartbeatInterval = tonumber(skynet.getenv("heartbeatInterval"))
local function CreateUUID()
    if not serverid then
        serverid = skynet.getenv("serverid")
    end
    if not uuid then
        uuid = require "uuid"
    end
    return uuid()..string.format("%02d", serverid)
end

---@param sessions Gamesession[]
local function Save(sessions)
    local keys = {}
    local values ={}
    for i, session in ipairs(sessions) do
        local data = cjson.encode(sessions)
        if data then
            table.insert(keys,string.format("%s:%d",sessionRedisKey,session.roleId))
            table.insert(values,data)
        end
    end
    if keys and #keys > 0 then
        dataSerUtil.callDataSer("SetExpire",keys,values,2 * 60 * 60);
    end
end
local connectNum = 0
local roleNum = 0
---@ 检查心跳
local function OnClearSession()
    while true do
        skynet.sleep(heartbeatInterval*100)
        local kickplayer = {}
        local sessions = {} ---@type Gamesession
        connectNum = 0
        roleNum = 0
        for i, v in pairs(_globalSession) do
            connectNum = connectNum + 1
            if os.time() - v.lastActivityTime > heartbeatInterval * 2 then
                table.insert(kickplayer,v)
            end

            if v.roleId and os.time() - v.lastActivityTime <= 60 then
                roleNum = roleNum + 1
                table.insert(sessions,v)
            end
        end
        for i, v in pairs(kickplayer) do
            nodeMgr.call(v.gateNodeName,v.gate,"HeartbeatTimeOut",v.client)
        end
        Save(sessions)
    end
end

function this:_init(fd,msg)
    self.ip = msg.ip
    self.gate = msg.gate
    self.isLoginSucc = false
    self.client = fd
    self.sessionID = CreateUUID()
    self.roomId = nil
    self.lastActivityTime = os.time()
    self.cacheServersNodeNames = {}
    self.cacheServersNodeNames[serverType.GATE] = msg.gateNodeName
    self.cacheServiceAddr = {}
    self.cacheServiceAddr[msg.gateNodeName] = {}
    for i, v in pairs(serviceNames.uniqueService) do
        self.cacheServiceAddr[msg.gateNodeName][i] = v
    end
end

function this:Bind(roleId)
    self.roleId = roleId
    self.isLoginSucc = true
    --CMD.broadcastGateMsgToServices(self,"userOnline")
end

function this:BindSserver(type,nodeName)
    self.cacheServersNodeNames[type] = nodeName
end
function this:BindService(serviceName,addr,nodeName)
    nodeName = nodeName or curNodename
    if not self.cacheServiceAddr[nodeName] then
        self.cacheServiceAddr[nodeName] = {}
    end
    self.cacheServiceAddr[nodeName][serviceName] = addr
end

function this.Init()
    skynet.fork(OnClearSession)
end

function CMD.RefreshSession(fd)
    if _globalSession[fd] then
        _globalSession[fd].lastActivityTime = os.time()
        return _globalSession[fd]
    end
    return nil
end
---@param gamesession Gamesession
function CMD.Clear(gamesession)
    if gamesession and _globalSession[gamesession.client] then
        _globalSession[gamesession.client] = nil
        if gamesession.roleId ~= nil and gamesession.roleId > 0  then
            CMD.broadcastGateMsgToServices(gamesession,"userOffline")
        end
    end
end
---@param gamesession Gamesession
function CMD.broadcastGateMsgToServices(gamesession,cmd,...)
    for node, services in pairs(gamesession.cacheServiceAddr) do
        for serviceName, addr in pairs(services) do
            if serviceNames.listenerGate[serviceName] then
                return nodeMgr.call(node,addr,cmd,gamesession,...)
            end
        end
    end
end

function CMD.Craeate(fd,msg)
    local session = this(fd,msg)
    _globalSession[fd] = session
    return session
end

function CMD.FindByUserId(roleId)
    for i, v in pairs(_globalSession) do
        if v.roleId and v.roleId == roleId then
            return v
        end
    end
    return nil
end

function CMD.FindByFD(fd)
    for i, v in pairs(_globalSession) do
        if i == fd then
            return v
        end
    end
end
function CMD.getRoleNum()
    return roleNum
end

function CMD.closeclient(fd)
    local session = CMD.FindByFD(fd)
    if session then
        CMD.Clear(session)
    end
end

function CMD.BindUserId(roleId,fd)
    local session = CMD.FindByFD(fd)
    if session then
        session:Bind(roleId)
        return true
    end
    return false
end
function CMD.BindService(fd,serviceName,addr,nodeName)
    local session = CMD.FindByFD(fd)
    if session then
        session:BindService(serviceName,addr,nodeName)
        return true
    end
    return false
end

return this