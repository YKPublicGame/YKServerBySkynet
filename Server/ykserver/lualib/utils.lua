local skynet = require "skynet"
local this = {}

function this.tonum(v, base)
    return tonumber(v, base) or 0
end

function this.toint(v)
    return math.round(tonum(v))
end

function this.tobool(v)
    return (v ~= nil and v ~= false)
end

function this.totable(v)
    if type(v) ~= "table" then v = {} end
    return v
end

function this.isset(arr, key)
    local t = type(arr)
    return (t == "table" or t == "userdata") and arr[key] ~= nil
end

function this.clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function this.copy(object)
    if not object then return object end
     local new = {}
     for k, v in pairs(object) do
        local t = type(v)
        if t == "table" then
            new[k] = this.copy(v)
        elseif t == "userdata" then
            new[k] = this.copy(v)
        else
            new[k] = v
        end
     end
    return new

end

--正向迭代器(key从小到大)
function this.Iterator(t)
    local a = {}
    for n in pairs(t) do
        a[#a+1] = n
    end
    table.sort(a)
    local i = 0
    return function()
        i = i + 1
        return a[i], t[a[i]]
    end
end

--反向迭代器(key从大到小)
function this.rIterator(t)
    local a = {}
    for n in pairs(t) do
        a[#a+1] = n
    end
    table.sort(a, function(m, n) return m > n end)
    local i = 0
    return function()
        i = i + 1
        return a[i], t[a[i]]
    end
end

function table.maxn(t)
    local a = {}
    for key, v in pairs(t) do
        a[#a+1] = key
    end
    table.sort(a)
    return a[#a]
end

function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.empty(t)
    return _G.next(t) == nil
end

function table.keys(t)
    local keys = {}
    for k, v in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(t)
    local values = {}
    for k, v in pairs(t) do
        values[#values + 1] = v
    end
    return values
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--[[
    table.zero(t, len) ==> memset(&t, 0, len)
]]
function table.zero(t, len)
    assert(type(t) == "table")
    for i=1, len do
        t[i] = 0
    end
end

--[[
    table.malloc(len) ==> malloc(len)
]]
function table.malloc(len)
    local t = {}
    table.zero(t, len)
    return t
end

--[[--

insert list.

**Usage:**

    local dest = {1, 2, 3}
    local src  = {4, 5, 6}
    table.insertto(dest, src)
    -- dest = {1, 2, 3, 4, 5, 6}
    dest = {1, 2, 3}
    table.insertto(dest, src, 5)
    -- dest = {1, 2, 3, nil, 4, 5, 6}


@param table dest
@param table src
@param table begin insert position for dest
]]
function table.insertto(dest, src, begin)
    begin = tonumber(begin)
    if begin == nil then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

--[[
search target index at list.

@param table list
@param * target
@param int from idx, default 1
@param bool useNaxN, the len use table.maxn(true) or #(false) default:false
@param return index of target at list, if not return -1
]]
function table.indexof(list, target, from, useMaxN)
    local len = (useMaxN and #list) or table.maxn(list)
    if from == nil then
        from = 1
    end
    for i = from, len do
        if list[i] == target then
            return i
        end
    end
    return -1
end

function table.indexofKey(list, key, value, from, useMaxN)
    local len = (useMaxN and #list) or table.maxn(list)
    if from == nil then
        from = 1
    end
    local item = nil
    for i = from, len do
        item = list[i]
        if item ~= nil and item[key] == value then
            return i
        end
    end
    return -1
end

function table.removeItem(t, item, removeAll)
    for i = #t, 1, -1 do
        if t[i] == item then
            table.remove(t, i)
            if not removeAll then break end
        end
    end
end

--[[--

remove array(only in array not table).

**Usage:**

    local dest = {1, 2, 3}
    table.removeAll(dest)
    -- dest = {}

@param table t
]]
function table.removeAll(t)
    for i = #t, 1, -1 do
        table.remove(t, i)
    end
end


--[[--

remove array(can in table).

**Usage:**

    local dest = {1, 2, 3}
    table.removeAll(dest)
    -- dest = {}

@param table t
]]
function table.clear(t)
    for k, v in pairs(t) do
        t[k] = nil
    end
end


--[[--

create map by table.

**Usage:**

    local dest = {1, 2}
    table.map(dest, function(a, b) return {key=a, value=b} end)
    -- dest = {
        [1] = {key=1, value=1}
        [2] = {key=2, value=2}
    }

@param table t
]]
function table.map(t, fun)
    for k,v in pairs(t) do
        t[k] = fun(v, k)
    end
end

function table.walk(t, fun)
    for k,v in pairs(t) do
        fun(v, k)
    end
end

function table.filter(t, fun)
    for k,v in pairs(t) do
        if not fun(v, k) then
            t[k] = nil
        end
    end
end

function table.find(t, item)
    return table.keyOfItem(t, item) ~= nil
end

function table.unique(t)
    local r = {}
    local n = {}
    for i = #t, 1, -1 do
        local v = t[i]
        if not r[v] then
            r[v] = true
            n[#n + 1] = v
        end
    end
    return n
end

function table.keyOfItem(t, item)
    for k,v in pairs(t) do
        if v == item then return k end
    end
    return nil
end

--二分查找
function table.bsearch(elements, x, field, low, high)
    local meta = getmetatable(elements)
    low = low or 1
    high = high or (meta and meta.__len(elements) or #elements)
    if low > high then
        return -1
    end
 
    local mid = math.ceil((low + high) / 2)
    local element = elements[mid]
    local value = field and element[field] or element
    
    if x == value then
        while mid > 1 do
            local prev = elements[mid - 1]
            value = field and prev[field] or prev
            if x ~= value then
                break
            end
            mid = mid - 1
            element = prev
        end
        return mid
    end
 
    if x < value then
        return table.bsearch(elements, x, field, low, mid - 1)
    end
 
    if x > value then
        return table.bsearch(elements, x, field, mid + 1, high)
    end
end

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end
string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialcharsDecode(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

function string.split(str, delimiter)
    str = tostring(str)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

function string.ltrim(str)
    return string.gsub(str, "^[ \t\n\r]+", "")
end

function string.rtrim(str)
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function string.trim(str)
    str = string.gsub(str, "^[ \t\n\r]+", "")
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function string.ucfirst(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

local function urlencodeChar(char)
    return "%" .. string.format("%02X", string.byte(c))
end

function string.urlencode(str)
    -- convert line endings
    str = string.gsub(tostring(str), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    str = string.gsub(str, "([^%w%.%- ])", urlencodeChar)
    -- convert spaces to "+" symbols
    return string.gsub(str, " ", "+")
end

function string.urldecode(str)
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonum(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
end

function string.utf8len(str)
    local len  = #str
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(str, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.utf8sub(str, start, last)
    if start > last then
        return ""
    end
    local len  = #str
    local left = len
    local cnt  = 0
    local startByte = len + 1
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(str, -left)
        local i   = #arr        
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
        if cnt == start then
            startByte = len - (left + i) + 1
        end
        if cnt == last then
            return string.sub(str, startByte, len - left)
        end
    end
    return string.sub(str, startByte, len)
end

function string.formatNumberThousands(num)
    local formatted = tostring(this.tonum(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end


--[[
    从字符串创建表
]]
function table.fromString(str)
    local func = load(str)
    assert(func, string.format("chunk is invalid:%s", str))
    return func()
end

function math.round(num)
    return math.floor(num + 0.5)
end

function math.pow(num, n)
    return num ^ n
end


--[[
    随机函数
    @param beginValue
    @param endValue
]]
--local useMt19937   = skynet.getenv("useMt19937")
local useMt19937   = false
local mt19937      = nil
local __randomseed = nil
function math.rand(...)
    --是否使用mt19937
    if useMt19937 then
        local i,j = ...
         --初始化随机种
        if not mt19937 then
            mt19937 = require "mt19937"
            mt19937.init(tostring(os.time()):reverse():sub(1, 6))
        end

        if j == nil then
            --mt19937.randi(1,n)的返回值范围是[1,n)
            return mt19937.randi(1, i+1)
        else
            return mt19937.randi(i, j+1)
        end
        return nil
    else
        if not __randomseed then
            __randomseed = os.time()
        end
        __randomseed = __randomseed + 1
        
        --把随机数种倒过来
        math.randomseed(tostring(__randomseed):reverse():sub(1, 6))
        --math.randomseed(__randomseed)
        return math.random(...)
    end

   
end

--随机打乱一个数组
function math.random_shuffle(tb)
    local array = copy(tb)
    local length = #array
    local function swap(i, j)
        local tmp = clone(array[i])
        array[i] = array[j]
        array[j] = tmp
    end
    for i=1, length-1 do
        local j = math.rand(i+1, length)
        swap(i, j)
    end
    return array
end

function math.random_one(tb)
    local length = #tb
    return tb[math.rand(length)]
end

function this.GetDateTime(datetime)
    if not datetime then
        datetime = os.time()
    end
    return os.date("%Y-%m-%d %H:%M:%S", datetime)
end

--[[function class(classname, super)
    local cls
	if super then
		cls = {}
		setmetatable(cls, {__index = super})
		cls.super = super
	else
		cls = {ctor = function() end}
	end
	cls.__cname = classname
	cls.__ctype = 2 -- lua
	cls.__index = cls
	function cls.new(...)
		local instance = setmetatable({}, cls)
		instance.class = cls
		instance:ctor(...)
		return instance
	end
   return cls
end]]

--class = require "class"

function this.tableToString(root)
    if root == nil then
        return "nil"
    elseif type(root) == "boolean" then
        return tostring(root)
    elseif type(root) == "number" then
        return tostring(root)
    elseif type(root) == "string" then
        return root
    end
    local cache = {  [root] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
            else
                if type(v) == "string" then
                    table.insert(temp,"+" .. key .. " [\"" .. tostring(v).."\"]")
                else
                    table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
                end
                
            end
        end
        return table.concat(temp,"\n"..space)
    end
    return (_dump(root, "",""))
end

function this.bufferToHexstring(byte)
    return ({byte:gsub(".", function(c) return string.format("%02x", c:byte(1)) end)})[1]
end

--local serverid
--local uuid
--function CreateUUID()
--    if not serverid then
--        serverid = skynet.getenv("serverid")
--    end
--    if not uuid then
--        uuid = require "uuid"
--    end
--    return uuid()..string.format("%02d", serverid)
--end

--到目标时间还有多少s
--targetTime("12:00")
--return sec
function this.getIntervalFromNow(targetTime)
    local hour, min = string.match(targetTime, "(%d+):(%d+)")
    hour = tonumber(hour)
    min  = tonumber(min)
    local dt   = os.date("*t", os.time())
    --当天的12:00
    local endTime = os.time({ 
        year= dt.year, 
        month = dt.month, 
        day = dt.day, 
        hour = hour, 
        min = min, 
        sec = 0
    })
    --当前时间
    local interval = dt.hour * 60 + dt.min
    --目标的时间
    local targetInerval = hour * 60 + min
    if interval < targetInerval then
        return endTime - os.time()
    else
        return 86400 - (os.time() - endTime)
    end
end

return this
