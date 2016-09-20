local function lenfromflags(flags)
	if type(flags) == "table" then
		return flags.valuelen, ""
	else
		return flags
	end
end

local function writeasstring(v, flags)
	io.write(tostring(v):setlen(lenfromflags(flags)))
end

local _write = io.write

io.write = {
	number = writeasstring,
	boolean = writeasstring,
	thread = writeasstring,
	userdata = writeasstring,
	["nil"] = writeasstring,
	["function"] = writeasstring,
	string = function(v, flags)
		io.write(("\""..v.."\""):setlen(lenfromflags(flags)))
	end,
}

setmetatable(io.write, {__call = function(_, ...) _write(...) end})

function io.write.table(t, flags, depth)
	depth = depth or 1
	if depth < 0 then
		writeasstring(tostring(t), flags)
		return
	end
	flags = flags or {}
	flags.history = flags.history or {}
	flags.tabstr = flags.tabstr or "  "
	if not flags.history[t] and (not flags.maxdepth or depth <= flags.maxdepth) then
		flags.history[t] = true
		io.write(tostring(t)..":")
		if flags.showmetatables then
			local mt = getmetatable(t)
			if mt then
				print()
				io.write(string.rep(flags.tabstr, depth))
				io.write(("metatable"):setlen(flags.keylen).. " = ")
				io.write[type(mt)](mt, flags, depth + 1)
			end
		end
		for k, v in ipairs(t) do
			print()
			io.write(string.rep(flags.tabstr, depth))
			io.write("<")
			io.write[type(k)](k, flags.keylen and flags.keylen - 2, -1)
			io.write("> = ")
			io.write[type(v)](v, flags, depth + 1)
		end
		for k, v in pairs(t) do
			if type(k) ~= "number" or k < 1 or k > #t then
				print()
				io.write(string.rep(flags.tabstr, depth))
				io.write("[")
				io.write[type(k)](k, flags.keylen and flags.keylen - 2, -1)
				io.write("] = ")
				io.write[type(v)](v, flags, depth + 1)
			end
		end
	else
		io.write(tostring(t))
	end
end

function table.print(t, flags)
	io.write.table(t, flags)
	print()
end

function unpackfunc(iter, ...)
	local i = iter(...)
	if i then
		return i, unpackfunc(iter, ...)
	end
	return nil
end

getmetatable("").__index = function(s, k)
	if type(k) == "number" then
		return s:sub(k, k)
	else
		return string[k]
	end
end

function string:split(delim)
	delim = delim or ' '
	local i = 0
	return function()
		if i > #self then return nil end
		local token = ""
		i = i + 1
		local c = self[i]
		while c ~= delim do
			token = token..c
			i = i + 1
			if i > #self then return token end
			c = self[i]
		end
		return token
	end
end

function string:setlen(newlen, pad)
	self = tostring(self)
	if not newlen then return self end
	pad = pad or " "
	local len = #self
	if len > newlen then
		return self:sub(1, newlen)
	else
		if #pad ~= 0 then
			return self..(pad:rep(math.ceil(newlen - len) / #pad):sub(1, newlen - len))
		else
			return self
		end
	end
end
