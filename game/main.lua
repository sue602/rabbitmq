local skynet = require("skynet")

skynet.start(function()
	--调试控制台服务
    skynet.newservice("debug_console",3002)
	-- 服务启动
	for i=1,dbconf.instance do
		skynet.newservice("rabbitmq_service",i)
	end
	skynet.exit()
end)

