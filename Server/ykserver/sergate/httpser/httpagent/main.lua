local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local string = string
local errorCode = require("errorCode")
local utils = require("utils")
local modes = {
    wxlogin = require("handlehttp.handlerWXLogin"),
    account = require("handlehttp.handlerAccount")
}

local OriginMode = {
    wxlogin = 1,
    account = 1,
}

local cjson = require("cjson")

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end
skynet.start(function()
    skynet.dispatch("lua", function(_, _, id)
        socket.start(id)  -- 开始接收一个 socket
        -- limit request body size to 8192 (you can pass nil to unlimit)
        -- 一般的业务不需要处理大量上行数据，为了防止攻击，做了一个 8K 限制。这个限制可以去掉。
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192 * 4)

        if code then
            if code ~= 200 then
                -- 如果协议解析有问题，就回应一个错误码 code 。
                response(id, code)
            else
                local respHeader = {}
                local resData = {}
                local path, query = urllib.parse(url)
                local reqdata = urllib.parse_query(query)
                local modeName, apiname = reqdata["modeName"], reqdata["api"]
                local tmpHeader
                if query and modeName and apiname
                        and modes[modeName][apiname] then
                    local func = modes[modeName][apiname]
                    local ec, data
                    local ok, ermsg = xpcall(function()
                        ec, data, tmpHeader = func(reqdata, body, header)
                    end, debug.traceback)
                    if ok then
                        resData.errorcode = ec or 0
                        resData.data = data
                    else
                        resData.errorcode = errorCode.SystemError.argument
                        resData.data = ermsg
                    end

                else
                    skynet.error(type(errorCode))
                    resData.errorcode = errorCode.SystemError.argument
                    resData.data = reqdata
                end
                resData.msg = errorCode[resData.errorcode].message
                if OriginMode[modeName] then
                    local origin = header["origin"]
                    if origin and header["x-real-ip"] then
                        origin = string.gsub(origin,"localhost",header["x-real-ip"])
                    end
                    respHeader["Access-Control-Allow-Origin"] = origin
                end
                if tmpHeader then
                    for i, v in pairs(tmpHeader) do
                        respHeader[i] = v
                    end
                end
                response(id, code, cjson.encode(resData), respHeader) --返回状态码200，并且跟上内容
            end
        else
            -- 如果抛出的异常是 sockethelper.socket_error 表示是客户端网络断开了。
            if url == sockethelper.socket_error then
                skynet.error("socket closed")
            else
                skynet.error(url)
            end
        end
        socket.close(id)
    end)
end)