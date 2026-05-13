function dev.filesystem(addr, path)
	local path, buffer, prox = path or "init.lua", "", component.proxy(addr)
	log(string.format("fs: %s:/%s", addr:sub(1, 8), path))
	local h = prox.open(path, "r")
	if not h then return nil, "not found" end
	while 1 do
		local c = prox.read(h, math.huge)
		if not c or c == "" then
			break
		end
		buffer = buffer .. c
	end
	return boot(buffer, path, addr)
end