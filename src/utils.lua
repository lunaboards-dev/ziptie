local function b2a(data)return sformat(sformat("%s-%s%s",srep(_x, 4),srep(_x.._x.."-",3),srep(_x,6)),sbyte(data, 1,#data))end
local function a2b(addr)
	addr=sgsub(addr, "%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. schar(_tonumber(ssub(addr, i, i+1), 16))
	end
	return baddr
end

local net, port, screen, gpu = config[4], config[5], config[6]
if screen then
	gpu = cproxy(clist("gpu")())
	gpu.bind(clist("screen")(), true)
end
	
local function log(msg)
	if net then
		cinvoke(clist("modem")(), "send", b2a(net), sunpack("H", port), msg)
	end
	if screen then
		local w, h = gpu.getViewport()
		gpu.copy(1, 2, w, h-1, 0, -1)
		gpu.fill(1, h, w, 1, " ")
		gpu.set(1, h, msg)
	end
end

local function die(msg)
	log("panic!: "..msg)
	while true do pullsignal() end
end

local function die_assert(val, msg)
	if not val then die(msg) end return val
end

local function boot(code, path, addr)
	function com.getBootAddress()
		return addr or b2a(ziptie.cfg.get(1))
	end

	function com.setBootAddress(addr, path)
		--[[ziptie.cfg.set(1, a2b(addr))
		if path then
			ziptie.cfg.set()]]
		config[1] = a2b(addr)
		config[2] = path or "init.lua"
	end
	return die_assert(load(sgsub(code, "\0+$", ""), "="..path))
end

local function get_boot(addr, read, cap, div)
	local parts = die_assert(osdi_decode(cinvoke(addr, read, 1)) or mtpt_decode(cinvoke(addr, read, cinvoke(addr, cap)/div)), "no partition tables")
	for i=1, #parts do
		local part = parts[i]
		if part.t == "boot" or part.t == "BOOTCODE" then
			local buf = drive_read(addr, read, part.s, part.S)
			return boot(buf, "(boot)", addr)
		end
	end
end