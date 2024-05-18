function dev.filesystem(addr, path)
	local path, buffer, prox = path or "init.lua", "", cproxy(addr)
	log(sformat("fs: %s:/%s", ssub(addr, 1, 8), path))
	local h = prox.open(path, "r")
	if not h then return nil, "not found" end
	while true do
		local c = prox.read(h, math.huge)
		if not c or c == "" then
			break
		end
		buffer = buffer .. c
	end
	return boot(buffer, path, addr)
end