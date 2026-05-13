local function drive_read(addr, call, st, size)
	local buf = ""
	for i=1, size do
		buf = buf .. component.invoke(addr, call, st+i-1)
	end
	return buf
end