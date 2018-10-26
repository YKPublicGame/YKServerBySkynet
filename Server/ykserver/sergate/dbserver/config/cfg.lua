local this =
{
    redisCfg =
    {
        host    =   "192.168.1.10",
        port    =   6379 ,
        db      =   0
    },
    mysqlCfg =
    {
        host        =   "192.168.1.14",
        port        =   3306,
        database    =   "gameserver2",
        user        =   "root",
        password    =   "system",
    }
}
return this