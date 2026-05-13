local mdm = component.list("modem")()
local frequest = function()error("no modem") end
if mdm then
	local hostname = computer.address():sub(1, 6)
	local modem = computer.proxy(mdm)
	modem.open(4096)
	frequest = function(host, port, name)
		local target
		local timeout = 60
		local function net_send(data, pkt_id, ptype, vport)
			if not pkt_id then
				pkt_id = tostring(math.random())
			end
			if target then
				modem.send(target, 4096, pkt_id, ptype or 1, host, hostname, vport or port, data)
			else
				modem.broadcast(4096, pkt_id, ptype or 1, host, hostname, vport or port, data)
				
			end
		end
		local function recv_pkt()
			local deadline = computer.uptime()+timeout
			while 1 do
				local evt, _, _addr, _port, _, pkt_id, pkt_type, to, from, vport, data = computer.pullSignal(deadline-computer.uptime())
				if evt == "modem_message" and _port == 4096 and from == host and vport == port and to == hostname then
					if pkt_type == 1 then
						net_send(pkt_id, nil, 2, vport)
						return data, _addr
					end
				end
				if computer.uptime() > deadline then
					return nil, "timeout"
				end
			end
		end
		--net_send(host, port, "openstream")
		net_send("openstream")
		port, target = recv_pkt()
		port = tonumber(port)
		local close_data = recv_pkt()
		if not close_data then die(target) end
		--net_send(host, port, "t"..name.."\n", target, nil, 1)
		net_send("t"..name.."\n")
		local buffer = ""
		local res
		while 1 do
			local dat, e = recv_pkt()
			if not dat then die(e) end
			if dat == close_data then
				return buffer
			end
			buffer = buffer .. dat
			if not res then
				if buffer:sub(1,1) ~= "y" then
					net_send(close_data)
					die("not a file!")
				end
				res = 1
				buffer = buffer:sub(2)
			end
		end
	end
end

local function frboot(a, b, c)
	log(string.format("fget: %s:%d/%s", a, b, c))
	--load(frequest(a, b, c), "="..c)()
	return boot(frequest(a, b, c), c)
end