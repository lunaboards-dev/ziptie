local cfg = {}

function cfg:set(key, value)
	self[key] = value
end

function cfg:get(key)
	return self[key]
end

--[[
	7 6 5 4 3 2 1 0    7 6 5 4 3 2 1 0    7 6 5 4 3 2 1 0
	I X L L L L L L - [H H H H H H H H] - Z Z Z Z Z Z Z Z ...
	| | | | | | | | -  | | | | | | | |  - | | | | | | | |
	| | | | | | | | -  | | | | | | | |  - +-+-+-+-+-+-+-+- Size/Inline value byte
	| | | | | | | | -  +-+-+-+-+-+-+-+-------------------- High ID byte (optional)
	| | +-+-+-+-+-+--------------------------------------- Low ID bits
	| +--------------------------------------------------- Extended ID flag
	+----------------------------------------------------- Inline value flag
]]

function cfg:save(...)
	local devsizes = {...}
	local blocks = {""}
	local keys = {}
	for k, v in pairs(self) do
		table.insert(keys, k)
	end
	table.sort(keys)
	local count = 0
	for i=1, #keys do
		count = count + 1
		local block = #blocks
		local dz = devsizes[block]
		local k, ik = keys[i]
		local v, ov = self[k]
		-- ik is for longer key IDs (over ID 63)
		ik, k = k >> 6, k & 63

		-- Check if it's small enough to inline
		if #v == 1 then
			k = k | 128
			ov = v
		else
			ov = string.char(#v)..v
		end

		-- Set flag if ID is over 63
		if ik > 0 then
			k = k | 64
			ov = string.char(ik) .. ov
		end
		ov = string.char(k) .. ov

		if #blocks[block] + #ov > devsizes[block]-1 then
			blocks[block] = string.char(count) .. blocks[block]
			blocks[block+1] = ov
			count = 0
			assert(devsizes[block+1], "out of room for config")
		else
			blocks[block] = blocks[block] .. ov
		end
	end
	blocks[#blocks] = string.char(count) .. blocks[#blocks]

	return table.unpack(blocks)
end

local function new_cfg(...)
	local blocks = {...}
	local t = {}
	for b=1, #blocks do
		local block = blocks[b]
		local count, pos = block:byte(1), 2
		for i=1, count do
			local id = block:byte(pos)
			local k = id & 63
			if id & 64 > 0 then
				k = k | block:byte(pos+1) << 6
				pos = pos + 1
			end
			local len = block:byte(pos+1)
			pos = pos + 2
			if id & 128 > 0 then
				t[k] = string.char(len)
			else
				t[k] = block:sub(pos, pos+len-1)
				pos = pos + len
			end
		end
	end
	return setmetatable(t, {__index=cfg})
end
if require then
	-- OpenOS program
else
	-- Library
	return new_cfg
end