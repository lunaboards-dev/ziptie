function dev.drive(addr)
	log("drive: "..addr)
	--[=[local parts = die_assert(osdi_decode(cinvoke(addr, readSector, 1)) or mtpt_decode(cinvoke(addr, readSector, cinvoke(addr, "getCapacity")/512)), "no partition tables")
	for i=1, #parts do
		local part = parts[i]
		if part.t == "boot" or part.t == "BOOTCODE" then
			local buf = drive_read(addr, readSector, part.s, part.S)
			--[[for j=1, part.S do
				buf = buf .. cinvoke(addr, readSector(part.s+j-1))
			end]]
			--_load(sgsub(buf, trailing_null, ""), "=(boot)")()
			boot(buf, "(boot)")
		end
	end]=]
	return get_boot(addr, "readSector", "getCapacity", 512)
end