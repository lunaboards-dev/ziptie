local timeout = config[13] and sunpack("f", config[13]) or 1

--local function check_bootsel()
--do
	if gpu then
		log("Strike Tab for boot menu")
		local deadline, evt, _, c = cuptime()+timeout
		while cuptime() < deadline do
			evt, _, c = pullsignal(deadline-cuptime())
			if evt == "key_down" and c == 9 then
				log("a. Exit")
				local entries, cl, i = {[0] = {function()return function() end end}}, {}, 1
				for comp in clist() do
					tinsert(cl, comp)
				end
				tbl.sort(cl)
				for j=1, _math.min(#cl, 25) do
					local cdev = cl[j]
					local ctype = cpnt.type(cdev)
					if dev[ctype] then
						if ctype == "filesystem" and cinvoke(cdev, "exists", "ztcfg.lua") then
							log(sformat("%s. Configuration tool", schar(97+i)))
							entries[i] = {dev[ctype], cdev, "ztcfg.lua"}
						else
							local prox, adr = cproxy(cdev), ssub(cdev, 1, 3)
							log(sformat("%s. %s: %s (%s)", schar(97+i), ctype, (ctype ~= "modem" and prox.getLabel()) or adr, adr))
							--table.insert(entries, {dev[ctype], comp})
							entries[i] = {dev[ctype], cdev}
						end
						i = i + 1
					end
				end
				while true do
					evt, _, c = pullsignal()
					if evt == "key_down" and c < 123 and c > 96 then
						local n = entries[c - 97]
						die_assert(n[1](tunpack(n, 2)))()
						break
					end
				end
			end
		end
	end
--end