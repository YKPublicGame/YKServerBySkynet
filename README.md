# YKServerBySkynet 简介
## 目录结构
### Server 服务器代码
  - skynet `skynet代码`
    - bin `编译后的代码这里 windows的不行`
    - src `skynet源码`
  - ykserver `框架部分代码`
  - start_ykserver_gate.sh `启动服务shell 需要安装screen`
  - test.sh `控制台启动skynet服务器`
  - 打包.bat `luac编译整个项目`
### luac5.3.5 这个是用来编译lua文件luac5.3
 
# 怎么运行

编辑 Server/ykserver/sergate/dbserver/cfg.lua 配置好数据库
  
  ```
  local this =
{
    redisCfg =
    {
        host    =   "redis地址",
        port    =   端口 ,
        db      =   库
    },
    mysqlCfg =
    {
        host        =   "数据库地址",
        port        =   端口,
        database    =   "数据库名",
        user        =   "用户名",
        password    =   "密码",
    }
}
return this
  ```
