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
	self.sync_log = {
		recharge_log = true,
		real_online_log = true,
		rank_log = true,
		online_log = true,
		offline_log = true,
		worldmap_refresh_log = true,
	}
	self.data = require("achievement_config")
	self.timer = require("timer").new()
end

--- 初始化函数
function rabbitmq_center:init( index )
	skynet.error("init =",index)
	self.index = index
	self.countidx = 0
	self.timeout_interval = mathrandom(1,30)
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
	self:test_write()
	self.timer:add(self.timeout_interval,handler(self,self.update))
end

local count = 0
-- 写入日志
function rabbitmq_center:test_write()
	local data = self.data
	local xpcallstatus,packData = xpcall(json.encode,sharefunc.exception,data)
	-- print("packdata =====",packData)
	if xpcallstatus and packData and self.mqclient then
		local destination
		local tmpKeyTab
		if tmpKeyTab and self.sync_log[tmpKeyTab] then
			--同步日志
			destination = string.format("/exchange/%s.log/%s_%s",self.appid,self.appid,"sync_log")
		else
			--异步日志
			destination = string.format("/exchange/%s.log/%s_%s",self.appid,self.appid,"async_log")
		end
		local headers = {}
		headers["destination"] = destination
		headers["receipt"] = self:autoid()
		headers["app-id"] = self.appid
		headers["persistent"] = self.persistent or "true"
		headers["content-type"] = "application/json"
		local ok, msg
		if dbconf.zip then
			headers["content-encoding"] = "deflate"
			local zlib = require("zlib")
	        local eof, bytes_in, outlen, result
	        local compress = zlib.deflate()
	        result, eof, bytes_in, outlen = compress(packData,'finish')
	        if result then
	        	headers["content-length"] = outlen
				ok, msg = self.mqclient:send(result, headers)
			end
		else
			ok, msg = self.mqclient:send(packData, headers)
		end
		if count < 1 then
			skynet.error("ok,msg ",ok,msg)
		end
		count = count + 1
	end
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