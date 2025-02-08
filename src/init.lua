local lzss = ...
_FLASH = {}
--#include "src/defines.lua"
--#include "src/drive_io.lua"
--#include "src/config.lua"
-- #include "src/microtel/init.lua"
--#include "src/parts.lua"
--#include "src/utils.lua"
-- #include "src/extra/frequest.lua"
--#include "src/extra/frequest-min.lua"
--#include "src/devs/init.lua"
-- #include "src/extra/bootsel.lua"

_BIOS = "ziptie 1.0"
_BOOT = "ziptie 1.0"
ziptie = {
	bin2addr = b2a,
	addr2bin = a2b,
	--[=[net = {
		--[[send = net_send,
		open = net_open,
		lsend = net_lsend,]]
		fget = frequest
	},]=]
	fget = frequest,
	log = log,
	cfg = {
		get = function(id)
			return config[id]
		end,
		set = function(...)
			local args = tbl.pack(...)
			for i=1, #args, 2 do
				--log(string.format("%q: %q", args[i], args[i+1]))
				config[args[i]] = args[i+1]
			end
			cfg_save()
		end
	},
	parts = {
		osdi = osdi_decode,
		mtpt = mtpt_decode,
	},
	decompress = lzss,
}
xpcall(function()
	log("ziptie 1.0")
	--check_bootsel()
	--#include "src/extra/bootsel.lua"
	local bt = config[3--[[BOOT_TYPE]]]
	bt = bt and sbyte(bt)
	if bt == 1 then
		frboot(config[1--[[BOOT_ADDRESS]]], sunpack("H", config[11--[[BOOT_PORT]]]), config[2--[[BOOT_PATH]]])
	elseif bt == 0 or not bt then
		local addr = b2a(config[1--[[BOOT_ADDRESS]]])
		local ct = cpnt.type(addr)
		die_assert(dev[ct], "unknown component "..ct)(addr, config[2])()
	end
end, function(err)
	tb = debug.traceback(err)
	--die(err)
end)
die(tb, 1)