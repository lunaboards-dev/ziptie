
local function b2a(data)return string.format("%.2x%.2x%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x",data:byte(1,#data))end
local function a2b(addr)
	addr=addr:gsub("%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. string.char(tonumber(addr:sub(i, i+1), 16))
	end
	return baddr
end

local net, port, screen, gpu = config[4], config[5], config[6]
if screen then
	gpu = component.proxy(component.list("gpu")())
	gpu.bind(component.list("scr")(), true)
end
	
local function log(msg)
	if net then
		component.invoke(component.list("modem")(), "send", b2a(net), string.unpack("H", port), msg)
	end
	if screen then
		local w, h = gpu.getViewport()
		gpu.copy(1, 2, w, h-1, 0, -1)
		gpu.fill(1, h, w, 1, " ")
		gpu.set(1, h, msg)
	end
end

local function die(msg, tb)
	for line in (tb and msg or debug.traceback("panic!: "..tostring(msg))):gmatch("[^\n\r]+") do
		log(line:gsub("\t", ""))
	end
	while 1 do computer.pullSignal() end
end

local function die_assert(val, msg)
	if not val then die(msg) end return val
	--return val or die(msg)
end

local function boot(code, path, addr)
	function computer.getBootAddress()
		return b2a(config[1]), config[2] --b2a(ziptie.cfg.get(1))
	end

	function computer.setBootAddress(addr, path)
		--[[ziptie.cfg.set(1, a2b(addr))
		if path then
			ziptie.cfg.set()]]
		config[1] = a2b(addr)
		config[2] = path or "init.lua"
		cfg_save()
	end
	return die_assert(load(code:gsub("\0+$", ""), "="..path))
end

@[[if cfg.get("src_disk") or cfg.get("src_eeprom") or cfg.get("src_tape") then]]
local function get_boot(addr, read, cap, div)
	local parts = die_assert(osdi_decode(component.invoke(addr, read, 1)) or mtpt_decode(component.invoke(addr, read, component.invoke(addr, cap)/div)), "no partition tables")
	for i=1, #parts do
		local part = parts[i]
		if part.t == "boot" or (part.t == "BOOTCODE" and ((part.f or 0x200) & 0x200 > 0)) then
			local buf = drive_read(addr, read, part.s, part.S)
			return boot(buf, "(boot)", addr)
		end
	end
end
@[[end]]