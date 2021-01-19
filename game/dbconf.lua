--
-- Author: chenchaoyong
-- Date: 2015-11-30 09:29:29
--
--服务器配置

local dbconf = {}

dbconf.instance = 1

dbconf.mqconf = {
    opts = {
        username = "ltzd",
        password = "ltzd3600",
        vhost = "/"
    },
    ip = "192.168.8.35",
    port = 81,
    -- ip = "192.168.8.32",
    -- port = 61613,
    appid = "rok",
    defaultdst="/exchange/rok.log/rok_dead_log",--默认队列
    persistent = "true",--是否是持久化
}

return dbconf