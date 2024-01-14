local function frequest(host, port, path)
	local sock, status, s = net_open(host, port), "", ""
	sock:w("t"..path.."\n")
	while status == "" do
		com_pullSignal(0.5)
		status = sock:r(1)
	end
	die_assert(status ~= "y", "not a file!")
	status = ""
	repeat
		com_pullSignal(0.5)
		s = sock:r(1024)
		status = status .. s
	until sock.state == "c" and s == ""
	return status--load(status, "="..path)()
end

local function frboot(a, b, c)
	log(sformat("fget: %s:%d/%s", a, b, c))
	--load(frequest(a, b, c), "="..c)()
	boot(frequest(a, b, c), c)
end