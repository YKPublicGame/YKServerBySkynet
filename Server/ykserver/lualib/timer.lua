local skynet = require "skynet"
local logger = require "logger"
local class  = require "class"
local Timer  = class()

function Timer:_init(func, obj)
	self._taskid      = 0
	self._expireTime  = 0
	self._repeatCount = 0
	self._func        = func
	self._obj         = obj
	self._args        = {}
	self._handleResult = function(taskid)
		if taskid ~= self._taskid then
			return
		end
		if not self._func then
			return
		end
		if self._repeatCount == 0 then
			self._expireTime = 0
			self._args = {}
			return
		end
		if self._repeatCount > 0 then
			self._repeatCount  = self._repeatCount -1
		end
		
		--local ok, err = xpcall(function()
			if self._obj then
				self._func(self._obj, table.unpack(self._args))
			else
				self._func(table.unpack(self._args))
			end
			--end, debug.tracebac)
		--if not ok then
			--logger.Errorf("Timer:_handleResult _func fatal err:%s", err)
		--end

		if self._repeatCount == 0 then
			self._args = {}
			self._expireTime = 0
		else
			skynet.timeout(self._expireTime*100, function() self._handleResult(taskid) end)
		end
	end
end

function Timer:bind(func)
	-- assert(func, "func["..func.."[ is must function")
	self._func = func
end

--[[
	@重复调用定时函数
	@count重复调用的次数,如果为nil或者为-1则是无限重复调用
]]
function Timer:repeated(seconds, count, ...)
	if not count or count == -1 then
		self._repeatCount = -1
	else
		self._repeatCount = count
	end
	self._taskid = self._taskid + 1
	self._expireTime = seconds
	self._args = table.pack(...)
	skynet.timeout(seconds*100, function() self._handleResult(self._taskid) end)
end

--[[
	@将在若干秒后调用
]]
function Timer:schedule(seconds, ...)
	local taskid = self._taskid + 1
	self._taskid = taskid
	self._expireTime = seconds
	self._repeatCount = 1
	self._args = table.pack(...)
	skynet.timeout(seconds*100, function() 
		self._handleResult(taskid)
	end)
end

--[[
	@取消定时任务
]]
function Timer:cancel(...)
	if self._repeatCount == 0 then
		return
	end
	self._repeatCount = 0
	self._args = {}
	self._expireTime = 0
end

--[[
	@定时器任务是否被取消了
]]
function Timer:isCanceled()
	return self._repeatCount == 0
end

return Timer
