local timeout = config[13] and sunpack("f", config[13]) or 1

local function check_bootsel()
	if gpu then
		log("Strike Tab to enter boot menu")
		local deadline, evt, _, c = cuptime()+timeout
		while cuptime() < deadline do
			evt, _, c = pullsignal(deadline-cuptime())
			if evt == "key_down" and c == 9 then
				log("0. Continue")
				local i = 1
				local entries = {[0] = {function()end}}
				for comp, ctype in clist() do
					if dev[ctype] then
						if ctype == "filesystem" and cinvoke(comp, "exists", "ztcfg.lua") then
							log(sformat("%d. Configuration tool", i))
							entries[i] = {dev[ctype], comp, "ztcfg.lua"}
						else
							local prox, adr = cproxy(comp), ssub(comp, 1, 3)
							log(sformat("%d. %s: %s (%s)", i, ctype, (ctype ~= "modem" and prox.getLabel()) or adr, adr))
							--table.insert(entries, {dev[ctype], comp})
							entries[i] = {dev[ctype], comp}
						end
						i = i + 1
					end
				end
				while true do
					evt, _, c = pullsignal()
					if evt == "key_down" and c < 58 and c > 47 then
						local n = entries[c - 48]
						return die_assert(n[1](table.unpack(n, 2)))()
					end
				end
				return
			end
		end
	end
end