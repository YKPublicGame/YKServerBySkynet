local this =
{
}

this.uniqueService = {
    NODE_MONITOR    = ".nodeMonitord",      --节点监控服务
    HTTPCLI         = ".webclientser",      --节点监控服务
    SERVER_LOG      = ".server_log",        --服务器日志服务
    WSWATCHDOG      = ".wswatchdog",        --websocket网关服务
    wsgate          = ".wsgate",            --websocket网关服务
    dbserver        = ".dbserver",             --DB 服务
    mySqlDB         = ".mySqlDB",             --mysql 服务
    httpser         = ".httpser",             --Http 服务
    test            = ".test",             --测试服务
    auth            = ".auth",             --验证服务
}
this.unUniqueService = {
}

this.dbModeName =
{
    auth = "auth"
}
this.listenerGate =
{
    
}
for i, v in pairs(this.uniqueService) do
    this[i] = v
end
return this