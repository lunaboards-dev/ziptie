function dev.filesystem(addr)
	local path, buffer, prox = config[2] or "init.lua", "", cproxy(addr)
	log(sformat("fs: %s:/%s", addr:sub(1, 8), path))
	local h = prox.open(path, "r")
	while true do
		local c = prox.read(h, math.huge)
		if not c or c == "" then
			break
		end
		buffer = buffer .. c
	end
	boot(buffer, path)
end