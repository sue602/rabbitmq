-- @Author: suyinxiang
-- @Date:   2020-09-08 10:54:18
-- @Last Modified by:   suyinxiang
-- @Last Modified time: 2020-12-26 17:15:39

local json = require("json")
local skynet = require "skynet"
local rabbitmqstomp = require "rabbitmqstomp"

local mathceil = math.ceil
local mathfloor = math.floor
local mathseed = math.randomseed
local mathrandom = math.random
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local osdate = os.date

--class define
local rabbitmq_center = class("rabbitmq_center")

local instance = nil
function rabbitmq_center.singleton()
    if not instance then
        instance = rabbitmq_center.new()
    end
    return instance
end

--[[constrator
]]
function rabbitmq_center:ctor()
	-- 随机种子
	mathseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
	self.datas = {}
	self.send = {
	}
	self.timer = require("timer").new()
end

--- 初始化函数
function rabbitmq_center:init( index )
	skynet.error("init =",index)
	self.index = index
	self.countidx = 0
	self.timeout_interval = mathrandom(1,300)
	self.timer:start()
	self.timer:add(100 + mathrandom(1,300),handler(self,self.connectMQ))
end

--- 获取ID
function rabbitmq_center:autoid()
	local rnd1 =  mathrandom(1000000000,9999999999)
	local rnd2 =  mathrandom(100000,999999)
	self.countidx = self.countidx + 1
	return string.format("%d@%d@%d@%d@%d",self.index,rnd1,rnd2,sharefunc.systemTime(),self.countidx)
end

--- 连接
function rabbitmq_center:connectMQ()
	skynet.error("connect mq start",self.index)
	self.appid = dbconf.mqconf.appid
	self.persistent = dbconf.mqconf.persistent
	self.defaultdst = dbconf.mqconf.defaultdst

	local opts = dbconf.mqconf.opts
	self.mqconnect = false
	local err
	self.mqclient, err = rabbitmqstomp.new(opts)
	if self.mqclient then
		local sessionID, err = self.mqclient:connect(dbconf.mqconf.ip,dbconf.mqconf.port)
		skynet.error("connectMQ sessionID == ",sessionID,err)
		if sessionID then
			self.mqconnect = true
		end
	end
	if true == self.mqconnect then
		self.timer:add(self.timeout_interval,handler(self,self.update))
	else
		self.timer:add(100,handler(self,self.connectMQ))
	end
end

--- 更新
function rabbitmq_center:update()
	local len = #(self.datas)
	if len > 0 then
		-- 写入数据库
	end
	self.timer:add(self.timeout_interval,handler(self,self.update))
end


--- 分发日志
function rabbitmq_center:dispatch( source, address, cmd, ... )
	local f = assert(instance[cmd])
    if self.sendCmd[cmd] then
        f(self, ...)
    else
        local ok,ret = xpcall(f,sharefunc.exception,self, ...)
        skynet.ret(skynet.pack(ok,ret))
    end
end

return rabbitmq_center