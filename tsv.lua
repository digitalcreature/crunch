require "util"

tsv = {}

tsv.Data = {} do

	local base = tsv.Data

	setmetatable(tsv.Data, {
		__call = function(base, ...)
			local new = {}
			setmetatable(new, base)
			return new, new:init(...)
		end
	})

	base.__index = base

	function base:init(fname, nums)
		self.columns = {}
		self.rows = {}
		if type(nums) ~= "table" then
			nums = {}
		end
		self.nums = nums
		if type(fname) == "string" then
			local file = io.open(fname)
			if file then
				local lines = file:lines()
				for c in lines():split('\t') do
					self:addcolumn(c)
				end
				for line in lines do
					local r = self:addrow()
					local c = 1
					for v in line:split('\t') do
						self:set(r, c, v)
						c = c + 1
					end
				end
				file:close()
			else
				return "could not open file \'"..fname.."\'"
			end
		else
			if fname then
				return "provided filename is of type \'"..type(fname).."\', should be \'string\'"
			end
		end
	end

	function base:addcolumn(name)
		local id = #self.columns + 1
		local c = {name = name, id = id}
		self.columns[id] = c
		self.columns[name] = c
		self.columns[c] = c
		return c
	end

	function base:setcolumnvalues(c, other)
		return function (...)
			c = self.columns[c]
			c.values = {}
			for i = 1, select("#", ...) do
				local v = select(i, ...)
				c.values[v] = v
				table.insert(c.values, v)
			end
			if other then
				self:markothers(c, other)(...)
				c.values[other] = true
				table.insert(c.values, other)
			end
		end
	end

	function base:markothers(c, other)
		return function(...)
			local valueset = {}
			for i = 1, select("#", ...) do
				valueset[select(i, ...)] = true
			end
			c = self.columns[c]
			for r, v in ipairs(c) do
				if not valueset[v] then
					self:set(r, c, other)
				end
			end
		end
	end

	function base:addrow(...)
		local id = #self.rows + 1
		local r = {id = id}
		self.rows[r] = r
		self.rows[id] = r
		for c = 1, select("#", ...) do
				self:set(r, c, select(c, ...))
		end
		return r
	end

	function base:set(r, c, v)
		r = self.rows[r]
		c = self.columns[c]
		if r and c then
			r[c] = v
			r[c.id] = v
			r[c.name] = v
			c[r] = v
			c[r.id] = v
		end
	end

	function base:printcolumn(c, leftlen)
		leftlen = leftlen or 32
		c = self.columns[c]
		if c then
			for r, v in ipairs(c) do
				print(v)
			end
		end
	end

	function base:printrow(r, leftlen)
		leftlen = leftlen or 32
		r = self.rows[r]
		if r then
			for _, c in ipairs(self.columns) do
				io.write(c.name:setlen(leftlen))
				print(" | "..tostring(r[c]))
			end
		end
	end

	function base:average(c)
		local sum = 0
		local count = 0
		for _, r in ipairs(self.rows) do
			local v = r[c]
			v = self.nums[v] or tonumber(v)
			if v then
				sum = sum + v
				count = count + 1
			end
		end
		return sum / count
	end

	function base:histogram(c, leftlen, values)
		c = self.columns[c]
		print(c.name)
		values = values or c.values
		if values then
			if not leftlen then
				leftlen = 0
				for _, v in ipairs(values) do
					local len = #tostring(v)
					if len > leftlen then
						leftlen = len
					end
				end
			end
			for _, v in ipairs(values) do
				io.write(v:setlen(leftlen).."|")
				local count = 0
				for _, r in ipairs(self.rows) do
					if r[c] == v then
						io.write("#")
						count = count + 1
					end
				end
				io.write(" "..count.."\n")
			end
		end
	end

end
