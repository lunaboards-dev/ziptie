function dev.tape_drive(addr)
	log("tape: "..addr)
	local tape = cproxy(addr)
	local size = tape.getSize()
	local blks = size//512
	local last_blk = (blks-1)*512
	local last_blk_size = size-(last_blk*512)
	tape.seek(last_blk)
	local parts = die_assert(mtpt_decode(tape.read(last_blk_size)), "no partition tables")
	for i=1, #parts do
		if parts[i].t == "boot" then
			tape.seek(((parts[i].s-1)*512)-tape.getPosition())
			boot(tape.read((parts[i].S)*512), "(boot)")
		end
	end
end