local parser = require("argparse")()
parser:mutex(
	parser:option("-R --remove", "Removes a config option"),
	parser:option("-S --set", "Sets a config option"),
	parser:option("-G --get", "Prints a value"),
	parser:flag("-D --dump", "Dumps all values")
)

local function set_value(args, idx)
	args.type = idx
end

parser:mutex(
	parser:flag("-s --string", "Specifies a string value"):action(set_value),
	parser:flag("-u --uuid", "Specifies a UUID value"):action(set_value),
	parser:flag("-b --byte", "Specifies a byte value"):action(set_value),
	parser:flag("-H --short", "Specifies a short value"):action(set_value),
	parser:flag("-i --int", "Specifies an int value"):action(set_value),
	parser:flag("-l --long", "Specifies a long value"):action(set_value),
	parser:flag("-e --enum", "Specifies an enumerated value"):action(set_value),
	parser:flag("-x --hex", "Specifies a hex value"):action(set_value),
	parser:flag("--enable", "Enables a boolean setting (empty value)"):action(set_value)
)

parser:option("--force-endian", "Forces endianness."):choices({"little", "big"}):count("?")

parser:option("-f --file", "Specifies the config file location."):count("1+"):args(2)
parser:argument("value", "Value to write"):args("?")

local args = parser:parse()

--for k,v in pairs(args) do print(k, v) end
--#region Defines

local function die(err, exit)
	io.stderr:write(string.format("error: %s!\n", err))
	os.exit(exit or 1)
end

local function assert_die(val, err)
	if not val then die(err) end
	return val
end

local keys = {
	boot_address = 1,
	boot_path = 2,
	boot_type = 3,
	log_net = 4,
	log_net_port = 5,
	log_screen = 6,
	flash_config = 7,
	flash_start = 8,
	flash_size = 9,
	flash_bytes = 10,
	boot_port = 11,
	hostname = 12
}

local enums = {
	boot_type_normal = 0,
	boot_type_fget = 1,
	--boot_type_zlan = 2,
	--boot_type_package = 3
}

local _x = "%.2x"
local function b2a(data)
	return string.format(
		string.format(
			"%s-%s%s",
			string.rep(_x, 4),
			string.rep(_x.._x.."-",3),
			string.rep(_x,6)
		),
		string.byte(data, 1,#data)
	)
end

local function a2b(addr)
	addr=string.gsub(addr, "%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. string.char(tonumber(string.sub(addr, i, i+1), 16))
	end
	return baddr
end

local function vtype(enc, dec)
	return {
		enc = enc,
		dec = dec
	}
end

local endian = {
	little = "<",
	big = ">",
	system = "="
}

local en = args.force_endian and endian[args.force_endian] or ""

local function int(packstr)
	packstr = en .. packstr
	return vtype(function(v)
		return packstr:pack(tonumber(v))
	end, function(v)
		return packstr:unpack(v)
	end)
end

local types = {
	uuid = vtype(a2b, b2a),
	string = vtype(function(v) return v end, function(v) return v end),
	byte = vtype(function(v)
		return string.char(assert_die(tonumber(v), "not a number!"))
	end, string.byte),
	short = int("H"),
	int = int("I"),
	long = int("l"),
	enum = vtype(function(v)
		return string.char(enums[v])
	end, function(v)
		return string.byte(v)
	end),
	hex = vtype(function(v)
		assert_die(#v % 2 == 0, "length of value must be a multiple of 2!")
		local rstr = ""
		for i=1, #v, 2 do
			local part = v:sub(i, i+1)
			rstr = rstr .. string.char(tonumber(part, 16))
		end
		return rstr
	end, function(v)
		if #v == 0 then return "" end
		return string.format(string.rep(_x, #v), v:byte(1, #v))
	end),
	enable = vtype(function(v)
		return ""
	end, function(v)
		return "<set>"
	end)
}

local function cfg_read(dat, tbl)
	local p = 2
	tbl = tbl or {}
	local count = dat:byte(1)
	--while #dat < p do
	for i=1, count do
		local id = dat:byte(p)
		local t = id & 63
		if id & 64 > 0 then
			t = t | dat:byte(p+1) << 8
			p = p + 1
		end
		local len = dat:byte(p+1)
		p = p + 2
		if id & 128 > 0 then
			tbl[t] = string.char(len)
		else
			tbl[t] = dat:sub(p, p+len-1)
			p = p + len
		end
	end
	return tbl
end

local function cfg_write(cfg, ...)
	local blocks, keys, args, pos, count = {""}, {}, {...}, 1, 0
	for k in pairs(cfg) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for i=1, #keys do
		count = count + 1
		local k, v, ik, ov = keys[i], cfg[keys[i]]
		ik, k = k >> 6, k & 63
		if #v == 1 then
			k = k | 128
			ov = v
		else
			ov = string.char(#v)..v
		end
		if ik > 0 then
			k = k | 64
			ov = string.char(ik) .. ov
		end
		ov = string.char(k) .. ov
		if #blocks[pos] + #ov > args[pos]-1 then
			blocks[pos] = string.char(count) .. blocks[pos]
			pos = pos + 1
			count = 0

			assert(args[pos], "out of room for config!")
			blocks[pos] = ov
			count = 0
		else
			blocks[pos] = blocks[pos] .. ov
		end
	end
	blocks[pos] = string.char(count) .. blocks[pos]
	pos = pos + 1
	count = 0

	return blocks
end
--#endregion Defines
if args.set or args.get then
	assert_die(args.type, "need a type for set or get!")
end
if args.set and args.type ~= "enable" then
	assert_die(args.value, "no value!")
end
local id = args.set or args.get or args.remove
if (id) then
	if keys[id:lower()] then
		id = keys[id:lower()]
	else
		id = assert_die(tonumber(id), "unknown id!")
	end
end

local files, sizes, cfg = {}, {}, {}
for i=1, #args.file do
	local file = args.file[i]
	sizes[i] = file[2]
	do
		local h = io.open(file[1], "rb")
		if h then
			cfg_read(h:read("*a"), cfg)
			h:close()
		end
		if (args.set or args.remove) then
			files[i] = assert_die(io.open(file[1], "wb"))
		end
	end
end

local function write_out()
	local blocks = cfg_write(cfg, table.unpack(sizes))
	for i=1, #files do
		local str = blocks[i] or ""
		str = str .. string.rep("\0", sizes[i]-#str)
		files[i]:write(str)
		files[i]:close()
	end
end

local function rev_lookup(key)
	for k, v in pairs(keys) do
		if v == key then
			return k:upper()
		end
	end
	return string.format("UNKNOWN<%X>", key)
end

local function print_value(key, sval)
	local key_name = rev_lookup(key)
	if not sval then
		print(string.format("%s = <unset>", key_name))
		return
	end
	print(string.format("%s = %s", key_name, sval))
end

if args.set then
	cfg[id] = types[args.type].enc(args.value)
	write_out()
elseif args.remove then
	cfg[id] = nil
	write_out()
elseif args.get then
	local v = cfg[id]
	if v then
		v = types[args.type].dec(v)
	end
	print_value(id, v)
elseif args.dump then
	print("DUMP (types are a guess)")
	local keyl = {}
	for k, v in pairs(cfg) do
		table.insert(keyl, k)
	end
	table.sort(keyl)
	for i=1, #keyl do
		local k = keyl[i]
		local val = cfg[k]
		if #val == 1 then -- byte
			print_value(k, string.format("0x%.1x (byte)", types.byte.dec(val)))
		elseif #val == 2 then -- short
			print_value(k, string.format("0x%.2x (short)", types.short.dec(val)))
		elseif #val == 4 then -- int
			print_value(k, string.format("0x%.4x (int)", types.int.dec(val)))
		elseif #val == 8 then -- byte
			print_value(k, string.format("0x%.8x (long)", types.long.dec(val)))
		elseif #val == 16 then -- byte
			print_value(k, string.format("%s (UUID)", types.uuid.dec(val)))
		elseif #val == 0 then
			print_value(k, "<set>")
		elseif val:find("%c") then
			print_value(k, string.format("%s (unknown)", types.hex.dec(val)))
		else
			print_value(k, string.format("%q (string)", val))
		end
	end
end