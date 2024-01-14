function dev.tape(addr)
	log("tape: "..addr)
	local tape = cproxy(addr)
	local size = tape.getSize()
	local blks = math.floor(size/512)
	local last_blk = (blks-1)*512
	local last_blk_size = size-last_blk
	tape.seek(last_blk+1)
	local parts = die_assert(mtpt_decode(tape.read(last_blk_size)), "no partition tables")
	for i=1, #parts do
		if parts[i].t == "boot" then
			tape.seek(parts[i].s-tape.getPosition())
			boot(tape.read(parts[i].S*512), "(boot)")
		end
	end
end