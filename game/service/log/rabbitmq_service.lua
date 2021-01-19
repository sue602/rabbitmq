-- @Author: suyinxiang
-- @Date:   2020-09-08 10:53:47
-- @Last Modified by:   suyinxiang
-- @Last Modified time: 2020-12-24 21:46:43

local skynet = require "skynet"

local rabbitmq_center = require("rabbitmq_center").singleton()

local index = tonumber( ... )

skynet.init(function()
	rabbitmq_center:init(index)
end)

skynet.start(function()
	skynet.dispatch(skynet.PTYPE_LUA, function (source, address, cmd, ...)
		rabbitmq_center:dispatch(source, address, cmd, ...)
	end)
end)