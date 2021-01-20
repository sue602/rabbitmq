-- lua-resty-rabbitmqstomp: Opinionated RabbitMQ (STOMP) client lib
-- Copyright (C) 2013 Rohit 'bhaisaab' Yadav, Wingify
-- Opensourced at Wingify in New Delhi under the MIT License
--[[
协议参考: http://stomp.github.io/stomp-specification-1.2.html
启动:
./rabbitmq-plugins enable rabbitmq_management
web访问:http://localhost:15672
启动:RabbitMQ STOMP Adapter
./rabbitmq-plugins enable rabbitmq_stomp

local rabbitmqstomp =  require("rabbitmqstomp")
local opts ={
    username = "guest",
    password = "guest",
    vhost = "/"
}
local mq, err = rabbitmqstomp.new(opts)
local sessionID, err = mq:connect("127.0.0.1",61613)
skynet.error("connect sessionID == ",sessionID,err)

local tmpIndex = "76"
local msg = {key="value"..tmpIndex, key2="value"..tmpIndex}
local headers = {}
headers["destination"] = "/exchange/exchange.log/queue.log" --"/exchange/test/binding"
headers["receipt"] = "msg#"..tmpIndex
headers["app-id"] = "luaresty"..tmpIndex
headers["persistent"] = "true"
headers["content-type"] = "application/json"

local ok, err = mq:send(cjson.encode(msg), headers)
if not ok then
    skynet.error("send not ok")
    return
end

--watch for some queue
local headers_sub = {}
headers_sub["destination"] = "/queue/queue.log"
headers_sub["persistent"] = "true"
headers_sub["id"] = "3"

local function watching()
    local w = mq:watch()
    w:subscribe(headers_sub)
    -- w:unsubscribe(headers_sub)
    while true do
        local message,ret = w:message()
        skynet.error("Watch", message)
    end
end
skynet.fork(watching)

]]

local skynet = require("skynet")
local socketchannel = require("skynet.socketchannel")

local byte = string.byte
local concat = table.concat
local error = error
local find = string.find
local gsub = string.gsub
local insert = table.insert
local len = string.len
local pairs = pairs
local setmetatable = setmetatable
local sub = string.sub

local DEFAULT_HOST = "127.0.0.1"
local DEFAULT_PORT = 61613

-- _VERSION = "0.1"

local _M = {
    _VERSION = '0.1'
}

local mt = { __index = _M }

local EOL = "\x0d\x0a"
local NULL_BYTE = "\x00"
local STATE_CONNECTED = 1
local STATE_COMMAND_SENT = 2
local STATE_RECONNECTING = 3
local STATUS_DISCONNECT = 4
local STATE_RECONNECT_FAILED = 5
local RECONNECT_INTERVAL_TIME = 200 --2秒


-- local serviceFunctions = {}
-- function sharefunc.exception(errorMessage)
--     skynet.error("===========================================================")
--     skynet.error("LUA EXCEPTION: " .. tostring(errorMessage) .. "\n")
--     skynet.error(debug.traceback("", 2))
--     skynet.error("===========================================================")
-- end

function _M.new(opts)
    if opts == nil then
       opts = {username = "guest", password = "guest", vhost = "/"}
    end
    return setmetatable({ sock = nil, opts = opts}, mt)
end

local function _split_data( resp )
    -- print("_split_data resp == ",resp)
    local tmpRetArray = {}
    local tmpArray = string.split(resp, "\n")
    if #tmpArray > 0 then
        for key,item in pairs(tmpArray) do
            -- print("tmpArray[i]=",item)
            if string.len(item) > 0 then
                local k, v = string.match(item, "(.+):(.+)")
                -- print("kv=", k,v)
                if k and v then
                    tmpRetArray[k] = v
                else
                    tmpRetArray[key] = item
                end
            end
        end
        return true,tmpRetArray
    end
    return false,resp
end

local function _myreadreply( sock ,flag )
    -- print("flag == ",flag)
    if "CONNECT" == flag then
        local resp = sock:readline(NULL_BYTE)
        skynet.error("CONNECT resp === ",resp)
        if nil ~= resp then
            local tmpret,tmpArray = _split_data(resp)
            -- print("tmpret == ",tmpret)
            if true == tmpret and tmpArray then
                if "CONNECTED" == tmpArray[1] then
                    skynet.error("equal===")
                    return true,tmpArray.session
                end
            end
        end
        return false
    elseif "SEND" == flag then
        local resp = sock:readline(NULL_BYTE)
        if nil ~= resp then
            local tmpret,tmpArray = _split_data(resp)
            return true,tmpArray
        end
        return false
    elseif "DISCONNECT" == flag then
        local resp = sock:readline(NULL_BYTE)
        if nil ~= resp then
            local tmpret,tmpArray = _split_data(resp)
            return true,tmpArray
        end
        return false
    end
end

local function _query_resp(flag)
     -- print("_query_resp == ",flag)
     return function(sock)
        return _myreadreply(sock,flag)
    end
end


local function _build_frame(command, headers, body)
    local frame = {command, EOL}

    for key, value in pairs(headers) do
        insert(frame, key)
        insert(frame, ":")
        insert(frame, value)
        insert(frame, EOL)
    end

    insert(frame, EOL)

    if body then
        insert(frame, body)
    end

    insert(frame, NULL_BYTE)
    insert(frame, EOL)
    local tmpframe = concat(frame, "")
    -- print("tmpframe = ",tmpframe)
    return tmpframe
end

local function _receive_data(sock)
    -- print("socket == ",sock)
    if not sock then
        return false, STATUS_DISCONNECT
    end
    local resp,left = sock:readline(NULL_BYTE)
    -- print("resp === ",resp)
    return true,resp
end


local function _login(self)
    skynet.error("login mq server by =",self.opts.username,self.opts.password)
    local headers = {}
    headers["accept-version"] = "1.2"
    headers["login"] = self.opts.username
    headers["passcode"] = self.opts.password
    headers["host"] = self.opts.vhost
    local query_resp = _query_resp("CONNECT")
    -- local ret = self.sock:request(_build_frame("CONNECT", headers, nil), query_resp )
    local xpcallok,retSession = xpcall(handler(self.sock,self.sock.request),sharefunc.exception,_build_frame("CONNECT", headers, nil), query_resp)
    skynet.error("mq_login status == ",xpcallok,retSession)
    if nil ~= retSession then
        self.state = STATE_CONNECTED
        return retSession
    end
    return false
end


local function _logout(self)
    skynet.error("logout ====")
    local sock = self.sock
    if not sock then
       self.state = nil
       return nil, "not initialized"
    end

    if self.state == STATE_CONNECTED then
        -- Graceful shutdown
        local headers = {}
        headers["receipt"] = "disconnect"
        local query_resp = _query_resp("DISCONNECT")
        local xpcallok,ret = xpcall(handler(self.sock,self.sock.request),sharefunc.exception,_build_frame("DISCONNECT", headers, nil), query_resp)
        if xpcallok then
            
        end
    end
    self.state = nil
    sock:close()
    return true
end


function _M.connect(self, ...)
    local host,port = ...
    self.opts.host = host or DEFAULT_HOST
    self.opts.port = port or DEFAULT_PORT
    self.opts.conncetretry = 0
    self.opts.connectcount = 222222 --大概5天
    local channel = socketchannel.channel {
        host = host or DEFAULT_HOST,
        port = port or DEFAULT_PORT,
        nodelay = true,
    }
    -- try connect first only once
    local xpcallok = xpcall(handler(channel,channel.connect),sharefunc.exception,true)
    -- print("connect status = ",xpcallok)
    if xpcallok then
        self.sock = channel
        -- print("socket connect=",self.sock)    
        return _login(self)
    else
        channel:close()
        channel = nil
    end
    return false,"try connect mq server error"
end

--[[useless
]]
function _M.retryconnect(self)
    local timecount = 0
    if nil ~= self.sock then
        self.sock:close()
        self.sock = nil
    end
    for i=1,self.opts.connectcount do
        skynet.error("_M.send connect count ==="..i.." 次")
        local ret = self:connect(self.opts.host,self.opts.port)
        timecount = timecount + 1
        if false ~= ret then
            self.state = STATE_CONNECTED
            skynet.error("_M.send connect success ,cost ",timecount * RECONNECT_INTERVAL_TIME/100," s")
            return true,tostring(self.state)
        end
        skynet.sleep(RECONNECT_INTERVAL_TIME)
    end
    skynet.error("_M.send connect fial,cost ",timecount * RECONNECT_INTERVAL_TIME/100," s")
end

function _M.send(self, msg, headers)
    if self.state == nil then
        return false,STATUS_DISCONNECT
    end
    if self.state == STATE_RECONNECTING then
        --print("send call return when reconnecting ")
        return false,STATE_RECONNECTING
    end
    if headers["receipt"] ~= nil then
        local query_resp = _query_resp("SEND")
        local xpcallok,ret = xpcall(handler(self.sock,self.sock.request),sharefunc.exception,_build_frame("SEND", headers, msg), query_resp)
        -- print("send call ",xpcallok,ret)
        if xpcallok then
            if type(ret) == "table" then
                for kRet,vRet in pairs(ret) do
                    if tostring(vRet) == "RECEIPT" then
                        -- print("ret ======",kRet,vRet)
                        return true,ret["receipt-id"]
                    end
                end
                return false,ret["message"]
            end
            return false,ret
        else--断线重连
            if self.state ~= STATE_RECONNECTING then
                skynet.fork(handler(self,self.retryconnect)) --启动重连
                self.state = STATE_RECONNECTING
            end

            return false,tostring(self.state)
        end
    end

    local xpcallok = xpcall(handler(self.sock,self.sock.request),sharefunc.exception,_build_frame("SEND", headers, msg), nil)
    if xpcallok then
        skynet.error("_M.send success but not reply == ",xpcallok)
        return true,"success"
    else--断线重连
        if self.state ~= STATE_RECONNECTING then
            skynet.fork(handler(self,self.retryconnect)) --启动重连
            self.state = STATE_RECONNECTING
        end

        return false,tostring(self.state)
    end
    return false
end


function _M.subscribe(self, headers)
    skynet.error("SUBSCRIBE")
    local xpcallok = xpcall(handler(self.sock,self.sock.request),sharefunc.exception,_build_frame("SUBSCRIBE", headers, nil), nil)
    if xpcallok then
        return true
    else--断线重连
        if self.state ~= STATE_RECONNECTING then
            skynet.fork(handler(self,self.retryconnect)) --启动重连
            self.state = STATE_RECONNECTING
        end
        return false,tostring(self.state)
    end
    return true
end


function _M.unsubscribe(self, headers)
    skynet.error("UNSUBSCRIBE")
    local xpcallok = xpcall(handler(self.sock,self.sock.request),sharefunc.exception,_build_frame("UNSUBSCRIBE", headers, nil), nil)
    if xpcallok then
        return true
    else--断线重连
        if self.state ~= STATE_RECONNECTING then
            skynet.fork(handler(self,self.retryconnect)) --启动重连
            self.state = STATE_RECONNECTING
        end
        return false,tostring(self.state)
    end
    return true
end

-- watch mode
local watch = {}

local watchmeta = {
    __index = watch,
    __gc = function(self)
        skynet.error("watch close by gc")
        self.__sock:close()
    end,
}

local function watch_login(obj, auth)
    return function(so)
        if auth then
            local headers = {}
            headers["accept-version"] = "1.2"
            headers["login"] = auth.username
            headers["passcode"] = auth.password
            headers["host"] = auth.vhost
            local query_resp = _query_resp("CONNECT")
            local xpcallok,retSession = xpcall(handler(so,so.request),sharefunc.exception,_build_frame("CONNECT", headers, nil), query_resp)
            skynet.error("_watch_login xpcallok == ",xpcallok,retSession)
            if nil ~= retSession then
                return retSession
            end
            return false
        end
    end
end

--[[
]]
function _M.watch(self)
    local host,port = self.opts.host,self.opts.port
    skynet.error("watch host,port=",host,port)
    local obj = {
        __subscribe = {},
    }
    local serverauth = {
        username = self.opts.username,
        password = self.opts.password,
        vhost = self.opts.vhost
    }
    local channel = socketchannel.channel {
        host = host or DEFAULT_HOST,
        port = port or DEFAULT_PORT,
        auth = watch_login(obj, serverauth),
        nodelay = true,
    }
    obj.__sock = channel
    -- try connect first only once
    channel:connect(true)
    return setmetatable( obj, watchmeta )
end

function watch.disconnect(self)
    self.__sock:close()
    setmetatable(self, nil)
end

function watch.message(self)
    local data = nil
    local err = nil
    local retTable = nil
    while true do
        local xpcallok,ret = xpcall(handler(self.__sock,self.__sock.response),sharefunc.exception,_receive_data)
        if nil == xpcallok or false == xpcallok then
            break
        end
        data = ret
        if nil ~= data then
            -- print("watch.message while data = ",data)
            break
        end
    end
    local idx = find(data, "\n\n", 1)
    return sub(data, idx + 2),data
end

local function watch_func( name )
    local NAME = string.upper(name)
    -- print("NAME =====",NAME)
    watch[name] = function(self, ...)
        local so = self.__sock
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            skynet.error("watch_func name == ",NAME)
            local xpcallok = xpcall(handler(so,so.request),sharefunc.exception,_build_frame(NAME, v, nil), nil)
            if xpcallok then
                skynet.error("watch ".. NAME .." success")
                return true
            end
            return false
        end
    end
end

watch_func "subscribe"
watch_func "unsubscribe"

function _M.close(self)
    return _logout(self)
end

return _M
