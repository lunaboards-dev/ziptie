local lzss = ...
--#include "src/defines.lua"
--#include "src/config.lua"
-- #include "src/microtel/init.lua"
--#include "src/parts.lua"
--#include "src/utils.lua"
-- #include "src/extra/frequest.lua"
--#include "src/extra/frequest-min.lua"
--#include "src/devs/init.lua"
--#include "src/extra/bootsel.lua"

_FLASH = {}
_BIOS = "ziptie 0.1"
_BOOT = "ziptie 0.1"
ziptie = {
	bin2addr = b2a,
	addr2bin = a2b,
	net = {
		--[[send = net_send,
		open = net_open,
		lsend = net_lsend,]]
		fget = frequest
	},
	log = log,
	cfg = {
		get = function(id)
			return config[id]
		end,
		set = function(id, val)
			config[id] = val
			cfg_save()
		end
	},
	decompress = lzss,
}

log("ziptie 0.1")
check_bootsel()
local bt = config[3--[[BOOT_TYPE]]]
bt = bt and sbyte(bt)
if bt == 1 then
	frboot(config[1--[[BOOT_ADDRESS]]], sunpack("H", config[11--[[BOOT_PORT]]]), config[2--[[BOOT_PATH]]])
elseif bt == 0 or not bt then
	local addr = b2a(config[1--[[BOOT_ADDRESS]]])
	local ct = cpnt.type(addr)
	die_assert(dev[ct], "unknown component type "..ct)(addr, config[2])()
end