-- This is too big to fit in the normal EEPROM. Boowomp :(

local timeout = config[13] and sunpack("f", config[13]) or 1

local function check_bootsel()
	if gpu then
		log("Strike Tab to enter boot menu")
		local deadline, evt, _, c = cuptime()+timeout
		while cuptime() < deadline do
			evt, _, c = pullsignal(deadline-cuptime())
			if evt == "key_down" and c == 9 then
				local entries = {{n = "Continue", f = {function()return function()end end}}}
				local mw, w, h = #entries[1].n, gpu.getViewport()
				for comp, ctype in clist() do
					if dev[ctype] then
						local prox, adr = cproxy(comp), ssub(comp, 1, 3)
						--log(sformat("%d. %s: %s (%s)", i, ctype, (ctype ~= "modem" and prox.getLabel()) or adr, adr))
						local e = sformat("%s: %s (%s)", ctype, (ctype ~= "modem" and prox.getLabel()) or adr, adr)
						if #e > mw then mw = #e end
						tinsert(entries, {
							n = e,
							f = {dev[ctype], comp}
						})
						if ctype == "filesystem" and cinvoke(comp, "exists", "ztcfg.lua") then
							tinsert(entries, 2, {n = "Configuration tool", f = {dev[ctype], comp, "ztcfg.lua"}})
						end
					end
				end

				local s, o = 1, 0
				gpu.set(1, 1, "Boot menu")
				while true do
					for i=1, #entries-o do
						if (i < h-1) then
							break
						elseif i == s then
							gpu.setBackground(0xFFFFFF)
							gpu.setForeground(0)
						else
							gpu.setBackground(0)
							gpu.setForeground(0xFFFFFF)
						end
						local n = entries[i+o].n
						gpu.set(1, i+1, n..srep(" ", mw-#n))
					end
					evt, _, _, c = pullsignal()
					if evt == "key_down" then
						if c == 200 then
							s = s - 1
							if s == 0 then
								o = o - 1
								s = 0
							end
						elseif c == 208 then
							s = s + 1
							if s == h then
								s = h-1
								o = o + 1
							end
						elseif c == 28 then
							local ent = entries[s+o].f
							return die_assert(ent[1](tunpack(ent, 2)))()
						end
					end
					o = mmax(0, _math.min(o, #entries-h+1))
				end
			end
		end
	end
end