local timeout = config[13] and string.unpack("f", config[13]) or 1

--local function check_bootsel()
--do
	if gpu then
		log("Strike Tab for boot menu")
		local deadline, evt, _, c = computer.uptime()+timeout
		while computer.uptime() < deadline do
			evt, _, c = computer.pullSignal(deadline-computer.uptime())
			if evt == "key_down" and c == 9 then
				@[[if cfg.get("extended_bios") then]]
--#include "src/extra/bootselmenu.lua"
				@[[else]]
				log("a. Exit")
				local entries, cl, i = {[0] = {function()return function() end end}}, {}, 1
				for comp in component.list() do
					table.insert(cl, comp)
				end
				tbl.sort(cl)
				for j=1, math.min(#cl, 25) do
					local cdev = cl[j]
					local ctype = component.type(cdev)
					if dev[ctype] then
						if ctype == "filesystem" and component.invoke(cdev, "exists", "ztcfg.lua") then
							log(string.format("%s. Configuration tool", string.char(97+i)))
							entries[i] = {dev[ctype], cdev, "ztcfg.lua"}
						else
							local prox, adr = component.proxy(cdev), cdev:sub(1, 3)
							log(string.format("%s. %s: %s (%s)", string.char(97+i), ctype, (ctype ~= "modem" and prox.getLabel()) or adr, adr))
							--table.insert(entries, {dev[ctype], comp})
							entries[i] = {dev[ctype], cdev}
						end
						i = i + 1
					end
				end
				while 1 do
					evt, _, c = computer.pullSignal()
					if evt == "key_down" and c < 123 and c > 96 then
						local n = entries[c - 97]
						die_assert(n[1](table.unpack(n, 2)))()
						break
					end
				end
				@[[end]]
			end
		end
	end
--end
