local function amx(s)
	local r = #s
	for i=1, r do
		r = r * (sbyte(s, i)+i)+i
        r = (r & 0xFF) ~ (r >> 8)
    end
    return r & 0xFF
end

local p, id, len, t
local function cfg_read(dat, tbl)
	p, tbl = 3, tbl or {}
	local count, ksum, dsum = sbyte(dat, 2), amx(ssub(dat, 2)), sbyte(dat, 1)
	if not count or ksum ~= dsum then
		_NOCFG = true
		tbl[3] = "\0"
		tbl[6] = clist("scr")()
		return tbl
	end
	--if not count then return tbl end
	--while #dat < p do
	for i=1, count do
		id = sbyte(dat, p)
		t = id & 63
		if id & 64 > 0 then
			t = t | sbyte(dat, p+1) << 6
			p = p + 1
		end
		len = sbyte(dat, p+1)
		p = p + 2
		if id & 128 > 0 then
			tbl[t] = schar(len)
		else
			tbl[t] = ssub(dat, p, p+len-1)
			p = p + len
		end
	end
	return tbl
end

-- @[[if false then]]
local function cfg_write(cfg, ...)
	local blocks, keys, args, pos, count = {""}, {}, {...}, 1, 0
	for k in _pairs(cfg) do
		tinsert(keys, k)
	end
	tbl.sort(keys)
	--[[local function write_blk()
		blocks[pos] = schar(count) .. blocks[pos]
		pos = pos + 1
		count = 0
	end]]
	for i=1, #keys do
		count = count + 1
		local k, v, ik, ov = keys[i], cfg[keys[i]]
		ik, k = k >> 6, k & 63
		if #v == 1 then
			k = k | 128
			ov = v
		else
			ov = schar(#v)..v
		end
		if ik > 0 then
			k = k | 64
			ov = schar(ik) .. ov
		end
		ov = schar(k) .. ov
		if #blocks[pos] + #ov > args[pos]-2 then
			--write_blk()
			blocks[pos] = schar(count) .. blocks[pos]
			blocks[pos] = schar(amx(blocks[pos])) .. blocks[pos]
			pos = pos + 1
			
			die_assert(args[pos], "no space")
			blocks[pos] = ov
			count = 0
		else
			blocks[pos] = blocks[pos] .. ov
		end
	end
	--write_blk()
	blocks[pos] = schar(count) .. blocks[pos]
	blocks[pos] = schar(amx(blocks[pos])) .. blocks[pos]
	--pos = pos + 1
	--count = 0

	return blocks
end
-- @[[else]]
local function cfg_write(cfg)
	local blk, count, ik, vs = "", 0
	for k, v in pairs(cfg) do
		count = count + 1
		ik, k, vs = k >> 6, k & 63, #v == 1
		if vs then
			k = k | 128
		else
			v = schar(#v)..v
		end
		if ik > 0 then
			k = k | 64
			v = schar(ik) .. v
		end
		if #blk + #v > 254 then
			die("no space")
		end
		blk = blk .. schar(k) .. v
	end
	blk = schar(count) .. blk
	blk = schar(amx(blk)) .. blk
	return {blk}
end
-- @[[end]]
local config = {}

local function cfg_save()
	local blocks = cfg_write(config, 256, config[10--[[FLASH_BYTES]]])
	cinvoke(clist("eep")(), "setData", blocks[1])
	--[=[if blocks[2] then
		local off, bc, addr, start = 1, math.ceil(#blocks[2]/64), b2a(config[7--[[FLASH_CONFIG]]]), sunpack("H", config[8--[[FLASH_START]]])
		for i=1, bc do
			cinvoke(addr, "writeSector", start+i-1, ssub(blocks[2], off, off+63))
			off = off + 64
		end
	end]=]
end

--local function cfg_load()
do
	cfg_read(cinvoke(clist("eep")(), "getData"), config)
	--[=[local addr = config[7]
	if addr then
		addr = b2a(addr)
		local st, sz = sunpack("HH", config[8--[[FLASH_START]]]..config[9--[[FLASH_SIZE]]])
		local info = drive_read(addr, st, sz)
		--_FLASH[addr].ziptie = {start = st, size = sz}
		cfg_read(info, config)
	end]=]
end
--cfg_load()