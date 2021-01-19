--
-- Author: SuYinXiang (sue602@163.com)
-- Date: 2016-05-04 11:01:43
--


OPT_TIME_OUT = 5

--make some local variable
local skynet = require "skynet"
local mathfloor = math.floor
local osdate = os.date
local tostr = tostring
local debugtraceback = debug.traceback


sharefunc = {}

--是否是调试模式
sharefunc.DEBUG = true --默认是调试模式

function sharefunc.exception(mErrorMsg)
    skynet.error("===========================================================")
    skynet.error("LUA EXCEPTION: " .. tostr(mErrorMsg) .. "\n")
    skynet.error(debugtraceback("", 2))
    skynet.error("===========================================================")
end

local function getLogPrefix(tag)
    local time = osdate("%Y-%m-%d %H:%M:%S", sharefunc.systemTime())
    local str = time
    str = str .. "[".. tostr(tag) .."]"
    return str
end

-- print error
function sharefunc.printError(...)
    skynet.error("----------------------------------------------")
    skynet.error(getLogPrefix("ERR"), ...)
    skynet.error(debugtraceback("", 2))
    skynet.error("----------------------------------------------")
end

-- print Info
function sharefunc.printInfo(...)
    skynet.error(getLogPrefix("INFO"), ...)
end

-- print Info
function sharefunc.debugPrint(...)
    if not sharefunc.DEBUG then
        return
    end
    skynet.error(getLogPrefix("INFO"), ...)
end

-- dump error
function sharefunc.dumpError(value, desciption, nesting)
    if not sharefunc.DEBUG then
        return
    end
    local line = "----------------------------------------------"
    local log = line .. "\n"
    if desciption then
        desciption = getLogPrefix("ERR") .. desciption
    end
    
    log = log .. desciption .. "\n"
    log = log .. tbl2str(value, desciption, nesting) .. "\n"
    log = log .. debugtraceback("", 2) .. "\n"
    log = log .. line
    skynet.error(log)
end

-- dump info
function sharefunc.dumpInfo(value, desciption, nesting)
    if not sharefunc.DEBUG then
        return
    end

    if desciption then
        desciption = getLogPrefix("INFO") .. desciption
    end
    skynet.error(tbl2str(value, desciption, nesting))
end

-- 获取系统时间
function sharefunc.systemTime()
    return os.time()
end

-- 获取某一时间当天零时UTC
function sharefunc.getTodayZeroHourUTC(time)
    time = time or os.time()
    -- 获取当前时间的时分秒
    local h = tonumber(os.date("%H", time))
    local m = tonumber(os.date("%M", time))
    local s = tonumber(os.date("%S", time))
    return time - ( h * 3600 + m * 60 + s )
end

-- 获取星期天数
-- 1,2,3 ... 表示星期一、二、三...
function sharefunc.getWeekDay(time)
    time = time or os.time()
    local weekDay = tonumber(os.date("%w", time))
    if weekDay == 0 then
        weekDay = 7
    end
    return weekDay
end

--[[
    获取本周某个星期的UTC零时
    1,2,3 ... 表示星期一、二、三...
--]]
function sharefunc.getCurWeekDayUTC(curWeekDay)
    if "number" ~= type(curWeekDay) or curWeekDay < 1 or curWeekDay > 7 then
        return nil
    end

    -- 获取当前时间 00:00:00 时的秒数
    local curTimeZero = sharefunc.getTodayZeroHourUTC()
    local secOfOneDay = 24 * 60 * 60

    local weekDay = sharefunc.getWeekDay(curTimeZero)
    if curWeekDay == weekDay then
        return curTimeZero
    elseif weekDay < curWeekDay then
        return curTimeZero + secOfOneDay * (curWeekDay - weekDay)
    elseif weekDay > curWeekDay then
        return curTimeZero - secOfOneDay * (weekDay - curWeekDay )
    end
end

--[[
    获取上个星期的UTC零时
    1,2,3 ... 表示星期一、二、三...
--]]
function sharefunc.getPreWeekDayUTC(preWeekDay)
    if "number" ~= type(preWeekDay) or preWeekDay < 1 or preWeekDay > 7 then
        return nil
    end

    -- 获取当前时间第二天 00:00:00 时的秒数
    local sec0 = sharefunc.getTodayZeroHourUTC()
    local secOfOneDay = 24 * 60 * 60

    local weekDay = sharefunc.getWeekDay(sec0)
    if preWeekDay == weekDay then
        return sec0
    elseif weekDay < preWeekDay then
        return sec0 - secOfOneDay * (gWeekDay.SUNDAY - preWeekDay + weekDay )
    elseif weekDay > preWeekDay then
        return sec0 - secOfOneDay * (weekDay - preWeekDay)
    end
end

-- 两个时间对比，是否在同一天
-- time2 默认为当前时间
function sharefunc.isSameDay( time1, time2 )
    time2 = time2 or os.time()

    local day1 = os.date("%d", time1)
    local day2 = os.date("%d", time2)
    if day1 ~= day2 then
        return false
    end

    local mon1 = os.date("%m", time1)
    local mon2 = os.date("%m", time2)
    if mon1 ~= mon2 then
        return false
    end

    local year1 = os.date("%Y", time1)
    local year2 = os.date("%Y", time2)
    if year1 ~= year2 then
        return false
    end

    return true
end

--[[
设置为只读表
]]
function sharefunc.readonly(tab)
   return setmetatable({}, {
     __index = tab,
     __newindex = function(tab, key, value)
                    error("Attempt to modify read-only table")
                  end,
     __metatable = false
   });
end

-- 获取dump字符串
function sharefunc.transformT2S(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)
    return table.concat(result, "\n")
end

--- 返回skynet.call发送函数闭包
function sharefunc.call(traceid)
    return function(svr,...)
        return skynet.call(svr,skynet.PTYPE_LUA,traceid,...)
    end
end

--- 返回skynet.send发送函数闭包
function sharefunc.send(traceid)
    return function(svr,...)
        skynet.send(svr,skynet.PTYPE_LUA,traceid,...)
    end
end

function sharefunc.log(traceid)
    return function(...)
        skynet.error(traceid,...)
    end
end