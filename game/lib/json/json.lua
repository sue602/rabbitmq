local json = {}
local cjson = require("cjson")

function json.encode(var)
    local status, result = pcall(cjson.encode, var)
    if status then 
		return result 
	end
end

function json.encodeNescape(var)
    local status, result = pcall(cjson.encodeNescape, var)
    if status then 
        return result
    end
end

function json.decode(text)
    local status, result = pcall(cjson.decode, text)
    if status then 
		return result
	end
end

function json.decodec(msg,offset,sz)
    local status, result = pcall(cjson.decodec, msg,offset,sz)
    if status then 
		return result
	end
end

function json.freec(msg,offset)
    local status = pcall(cjson.freec, msg,offset)
    if not status then 
		print("json.freec error")
	end
end

function json.getInt(msg,offset,typ)
    local status,result = pcall(cjson.getInt, msg,offset,typ)
    if status then 
		return result
	end
end

function json.getUserdata(msg,offset)
    local status,result = pcall(cjson.getUserdata, msg,offset)
    if status then 
		return result
	end
end

function json.getSession(msg,offset)
    local status,result = pcall(cjson.getSession, msg,offset)
    if status then 
		return result
	end
end

function json.packFailMsg(flag,session)
    local status,result,sz = pcall(cjson.packFailMsg, flag,session)
    if status then 
		return result,sz
	end
end

function json.packSuccessMsg(flag,session,msg)
    local status,result,sz = pcall(cjson.packSuccessMsg, flag,session,msg)
    if status then
		return result,sz
	end
end

function json.packSuccessMsg2(flag,session,msg,len)
    local status,result,sz = pcall(cjson.packSuccessMsg2, flag,session,msg,len)
    if status then
        return result,sz
    end
end

function json.printmsg(msg)
    local status = pcall(cjson.printmsg, msg)
end



return json
