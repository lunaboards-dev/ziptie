function dev.modem(addr)
	local msg = "BIP negotiation..."
	local spinner = "|/-\\"
	log(msg)
	component.invoke(addr, "open", 9900)
	component.invoke(addr, "broadcast", 9900, 1)
	local deadline, i = computer.uptime()+60, 1
	while computer.uptime() < deadline do
		if gpu then
			local j, w, h = i % 4 + 1, gpu.getViewport()
			gpu.set(#msg+2, h, spinner:sub(j, j))
		end
		i = i + 1
		local evt, _, _, port, _, res, host, vport, file = computer.pullSignal(0.1)
		if evt == "modem_message" and port == 9900 then
			if res < 0 then
				log(string.format("error %d: %s", res, host))
				log(msg)
			else
				log("Found host!")
				component.invoke(addr, "close", 9900)
				return frboot(host, vport, file)
			end
		end
	end
end