local fs = component.proxy(computer.getBootAddress())
local eeprom = component.proxy(component.list("eeprom")())
local gpu = component.proxy(component.list("gpu")())
local screen = component.list("screen")()
gpu.bind(screen)

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

local function a2b(addr)
	addr=string.gsub(addr, "%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. string.char(tonumber(string.sub(addr, i, i+1), 16))
	end
	return baddr
end

local function log(msg)
	local w, h = gpu.getViewport()
	gpu.copy(1, 2, w, h-1, 0, -1)
	gpu.fill(1, h, w, 1, " ")
	gpu.set(1, h, msg)
end

local function readfile(path)
	log("Loading "..path.."...")
	local b, c = ""
	local h = fs.open(path, "r")
	while true do
		c = fs.read(h, math.huge)
		if not c or c == "" then return b end
		b = b .. c
	end
end

local cfg = load(readfile("cfgtool.lua"))()
local bios = readfile("ziptie.bin")
--local ztcfg = load(readfile("ztcfg.lua"))

local config = {
	boot_address = a2b(computer.getBootAddress()),
	boot_path = "ztcfg.lua",
	boot_type = "\0",
	log_screen = "\1"
}

local newcfg = cfg()
for k, v in pairs(config) do
	--log(string.format("%s (%.2x) = %s", k, keys[k], string.format(string.rep("%.2x", #v), v:byte(1, #v))))
	newcfg:set(keys[k], v)
end

log("Writing EEPROM...")
eeprom.set(bios)
log("Writing config...")
eeprom.setData(newcfg:save(256))
log("Install complete! Rebooting into config...")
local dl = computer.uptime()+3
while computer.uptime() < dl do computer.pullSignal(0) end
computer.shutdown(true)