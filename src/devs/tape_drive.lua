function dev.tape_drive(addr)
	log("tape: "..addr)
	local tape = cproxy(addr)
	local size = tape.getSize()
	--local blks = size//512
	local last_blk = ((size//512)-1)*512
	local last_blk_size = size-last_blk
	--log(string.format("attempting to read blk %d (%d bytes)", last_blk, last_blk_size))
	tape.seek(last_blk-tape.getPosition())
	local dat = tape.read(last_blk_size)
	--log(string.format("sector: %q", dat))
	--die_assert(type(dat) == "string", "data is not a string: "..dat)
	local parts = die_assert(mtpt_decode(dat), "no partition tables")
	for i=1, #parts do
		if parts[i].t == "boot" then
			tape.seek(((parts[i].s-1)*512)-tape.getPosition())
			return boot(tape.read((parts[i].S)*512), "(boot)", addr)
		end
	end
	--return nil, "timeout"
	--return get_boot(addr, "read", "getSize", 512)
end