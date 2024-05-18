function dev.modem(addr)
	local msg = "BIP negotiation..."
	local spinner = "|/-\\"
	log(msg)
	cinvoke(addr, "open", 9900)
	cinvoke(addr, "broadcast", 9900, 1)
	local deadline, i = cuptime()+60, 1
	while cuptime() < deadline do
		if gpu then
			local j, w, h = i % 4 + 1, gpu.getViewport()
			gpu.set(#msg+2, h, ssub(spinner, j, j))
		end
		i = i + 1
		local evt, _, _, port, _, res, host, vport, file = pullsignal(0.1)
		if evt == "modem_message" and port == 9900 then
			if res < 0 then
				log(sformat("error %d: %s", res, host))
				log(msg)
			else
				log("Found host!")
				cinvoke(addr, "close", 9900)
				return frboot(host, vport, file)
			end
		end
	end
end