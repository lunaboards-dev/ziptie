
xpcall(function()
local str, cpnt, tbl, com, _tonumber, _pairs, _nil = string, component, table, computer, tonumber, pairs
local ssub, sbyte, cproxy, cinvoke, clist, sgsub, sunpack, srep, sformat, tinsert, tremove, schar, cuptime, tunpack =
str.sub, str.byte, cpnt.proxy, cpnt.invoke, cpnt.list, str.gsub, str.unpack, str.rep, str.format, tbl.insert, tbl.remove, str.char, com.uptime, tbl.unpack

local _x = "%.2x"
local p, id, len, t
local function cfg_read(dat, tbl)
	p, tbl = 2, tbl or {}
	local count = sbyte(dat, 1)
	--while #dat < p do
	for i=1, count do
		id = sbyte(dat, p)
		t = id & 63
		if id & 64 > 0 then
			t = t | sbyte(dat, p+1) << 8
			p = p + 1
		end
		len = sbyte(dat, p+1)
		p = p + 2
		if id & 128 > 0 then
			tbl[t] = schar(len)
		else
			tbl[t] = ssub(dat, p, p+len-1)
			p = p + len
		end
	end
	return tbl
end

local function cfg_write(cfg, ...)
	local blocks, keys, args, pos, count = {""}, {}, {...}, 1, 0
	for k in _pairs(cfg) do
		tinsert(keys, k)
	end
	tbl.sort(keys)
	--[[local function write_blk()
		blocks[pos] = schar(count) .. blocks[pos]
		pos = pos + 1
		count = 0
	end]]
	for i=1, #keys do
		count = count + 1
		local k, v, ik, ov = keys[i], cfg[keys[i]]
		ik, k = k >> 6, k & 63
		if #v == 1 then
			k = k | 128
			ov = v
		else
			ov = schar(#v)..v
		end
		if ik > 0 then
			k = k | 64
			ov = schar(ik) .. ov
		end
		ov = schar(k) .. ov
		if #blocks[pos] + #ov > args[pos]-1 then
			--write_blk()
			blocks[pos] = schar(count) .. blocks[pos]
			pos = pos + 1
			count = 0

			die_assert(args[pos], "out of room for config!")
			blocks[pos] = ov
			count = 0
		else
			blocks[pos] = blocks[pos] .. ov
		end
	end
	--write_blk()
	blocks[pos] = schar(count) .. blocks[pos]
	pos = pos + 1
	count = 0

	return blocks
end
local config = {}

local function cfg_save()
	local blocks = cfg_write(config, 256, config[10--[[FLASH_BYTES]]])
	cinvoke(clist("eep")(), "setData", blocks[1])
	if blocks[2] then
		local off, bc, addr, start = 1, math.ceil(#blocks[2]/64), b2a(config[7--[[FLASH_CONFIG]]]), sunpack("H", config[8--[[FLASH_START]]])
		for i=1, bc do
			cinvoke(addr, "writeSector", start+i-1, ssub(blocks[2], off, off+63))
			off = off + 64
		end
	end
end

local function cfg_load()
	cfg_read(cinvoke(clist("eep")(), "getData"), config)
	local addr = config[7]
	if addr then
		addr = b2a(addr)
		local st, sz = sunpack("HH", config[8--[[FLASH_START]]]..config[9--[[FLASH_SIZE]]])
		local info = drive_read(addr, st, sz)
		_FLASH[addr].ziptie = {start = st, size = sz}
		cfg_read(info, config)
	end
end
cfg_load()
local net_port,net_hostname,net_route,net_hook, net_send=4096,config[12] or ssub(com.address(),1,8),true,{}

do
local modems,packetQueue,packetCache,routeCache = {},{},{},{}
for a in clist("modem") do
 modems[a] = cproxy(a)
 modems[a].open(net_port)
end

local function genPacketID()
 local packetID = ""
 for i = 1, 16 do
  packetID = packetID .. schar(math.random(32,126))
 end
 return packetID
end

local function rawSendPacket(packetID,packetType,to,from,vport,data)
 if routeCache[to] then
  modems[routeCache[to][1]].send(routeCache[to][2],net_port,packetID,packetType,to,from,vport,data)
 else
  for k,v in _pairs(modems) do
   v.broadcast(net_port,packetID,packetType,to,from,vport,data)
  end
 end
end

local function sendPacket(packetID,packetType,to,vport,data)
 packetCache[packetID] = cuptime()
 rawSendPacket(packetID,packetType,to,net_hostname,vport,data)
end

net_send = function(to,vport,data,packetType,packetID)
 packetType,packetID = packetType or 1, packetID or genPacketID()
 packetQueue[packetID] = {packetType,to,vport,data,0}
 sendPacket(packetID,packetType,to,vport,data)
end

local function checkCache(packetID)
 for k,v in _pairs(packetCache) do
  if k == packetID then
   return false--1<0--false
  end
 end
 return true--1>0--true
end

local realComputerPullSignal = com.pullSignal
function com.pullSignal(t)
 local eventTab = {realComputerPullSignal(t)}
 for k,v in _pairs(net_hook) do
  pcall(v,tunpack(eventTab))
 end
 for k,v in _pairs(packetCache) do
  if cuptime() > v+30 then
   packetCache[k] = _nil
  end
 end
 for k,v in _pairs(routeCache) do
  if cuptime() > v[3]+30 then
   routeCache[k] = _nil
  end
 end
 if eventTab[1] == "modem_message" and (eventTab[4] == net_port or eventTab[4] == 0) and checkCache(eventTab[6]) then
  routeCache[eventTab[9]] = {eventTab[2],eventTab[3],cuptime()}
  if eventTab[8] == net_hostname then
   if eventTab[7] ~= 2 then
    com.pushSignal("net_msg",eventTab[9],eventTab[10],eventTab[11])
    if eventTab[7] == 1 then
     sendPacket(genPacketID(),2,eventTab[9],eventTab[10],eventTab[6])
    end
   else
    packetQueue[eventTab[11]] = _nil
   end
  elseif net_route and checkCache(eventTab[6]) then
   rawSendPacket(eventTab[6],eventTab[7],eventTab[8],eventTab[9],eventTab[10],eventTab[11])
  end
  packetCache[eventTab[6]] = cuptime()
 end
 for k,v in _pairs(packetQueue) do
  if cuptime() > v[5] then
   sendPacket(k,tunpack(v))
   v[5]=cuptime()+30
  end
 end
 return tunpack(eventTab)
end

end

local com_pullSignal = com.pullSignal
local net_mtu = 4096
local function net_lsend(to,vport,ldata)
 local tdata = {}
 for i = 1, #ldata, net_mtu do
  tdata[#tdata+1] = ssub(ldata, 1,net.mtu)
  ldata = ssub(ldata, net.mtu+1)
 end
 for k,v in ipairs(tdata) do
  net_send(to,vport,v)
 end
end
local function net_socket(address, port, sclose)
	local conn, rb = {}, ""
	--conn.state, conn.buffer, conn.port, conn.address = "o", "", _tonumber(port), address
	conn.state, conn.buffer, conn.port, conn.address = "o", "", _tonumber(port), address
	function conn.r(self,l)
	 rb=ssub(self.buffer, 1,l)
	 self.buffer=ssub(self.buffer, l+1)
	 return rb
	end
	function conn.w(self,data)
	 net_lsend(self.address,self.port,data)
	end
	function conn.c(s)
	 net_send(conn.address,conn.port,sclose)
	end
	function h(etype, from, port, data)
	 if from == conn.address and port == conn.port then
	  if data == sclose then
	   net_hook[sclose] = nil
	   conn.state = "c"
	   return
	  end
	  conn.buffer = conn.buffer..data
	 end
	end
	net_hook[sclose] = h
	return conn
   end
net_timeout = 60
local function net_open(address,vport)
 local st,from,port,data=cuptime()
 net_send(address,vport,"openstream")
 repeat
  _, from, port, data = com_pullSignal(0.5)
  if cuptime() > st+net_timeout then return false end
 until from == address and port == vport and _tonumber(data)
 vport=_tonumber(data)
 repeat
  _, from, port, data = com_pullSignal(0.5)
 until from == address and port == vport
 return net_socket(address,vport,data)
end

local osdi_hdr, mtpt_hdr = "<IIc8I3c13", ">c20c4II"
local function pdecode(hdr, fields, ...)
	local args, cv = {...}, {n=0}
	for i=1, #args, 2 do
		tinsert(cv, {args[i], args[i+1]})
	end
	return function(dat)
		local off, out = 0, {}
		while off < #dat do
			local list = tbl.pack(sunpack(hdr, off))
			for i=1, #fields do list[ssub(fields, i,i)] = list[i] end
			local nxt = tremove(list)
			tinsert(out, list)
			off = nxt
		end
		local first = tremove(out, 1)
		for i=1, #cv do
			if first[cv[i][1]] ~= cv[i][2] then
				return _nil
			end
		end
		return out
	end
end
local osdi_decode, mtpt_decode = pdecode(osdi_hdr, "sStfn", 1, 1, 3, "OSDI\xAA\xAA\x55\x55"), pdecode(mtpt_hdr, "ntsS", 2, "mtpt")
local function b2a(data)return sformat(sformat("%s-%s%s",srep(_x, 4),srep(_x.._x.."-",3),srep(_x,6)),sbyte(data, 1,#data))end
local function a2b(addr)
	addr=sgsub(addr, "%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. schar(_tonumber(ssub(addr, i, i+1), 16))
	end
	return baddr
end

local net, port, screen, gpu = config[4], config[5], config[6]
if screen then
	gpu = cproxy(clist("gpu")())
	gpu.bind(clist("screen")(), true)
end
	
local function log(msg)
	if net then
		cinvoke(clist("modem")(), "send", b2a(net), sunpack("H", port), msg)
	end
	if screen then
		local w, h = gpu.getViewport()
		gpu.copy(1, 2, w, h-1, 0, -1)
		gpu.fill(1, h, w, 1, " ")
		gpu.set(1, h, msg)
	end
end

local function die(msg)
	log("panic!: "..msg)
	while true do com_pullSignal() end
end

local function die_assert(val, msg)
	if not val then die(msg) end return val
end

local function boot(code, path)
	function com.getBootAddress()
		return b2a(ziptie.cfg.get(1))
	end

	function com.setBootAddress(addr)
		ziptie.cfg.set(1, a2b(addr))
	end
	load(sgsub(code, "\0+$", ""), "="..path)()
end

local function get_boot(addr, read, cap, div)
	local parts = die_assert(osdi_decode(cinvoke(addr, read, 1)) or mtpt_decode(cinvoke(addr, read, cinvoke(addr, cap)/div)), "no partition tables")
	for i=1, #parts do
		local part = parts[i]
		if part.t == "boot" or part.t == "BOOTCODE" then
			local buf = drive_read(addr, read, part.s, part.S)
			boot(buf, "(boot)")
		end
	end
end
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
local dev = {}

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
function dev.drive(addr)
	log("drive: "..addr)
	--[=[local parts = die_assert(osdi_decode(cinvoke(addr, readSector, 1)) or mtpt_decode(cinvoke(addr, readSector, cinvoke(addr, "getCapacity")/512)), "no partition tables")
	for i=1, #parts do
		local part = parts[i]
		if part.t == "boot" or part.t == "BOOTCODE" then
			local buf = drive_read(addr, readSector, part.s, part.S)
			--[[for j=1, part.S do
				buf = buf .. cinvoke(addr, readSector(part.s+j-1))
			end]]
			--_load(sgsub(buf, trailing_null, ""), "=(boot)")()
			boot(buf, "(boot)")
		end
	end]=]
	get_boot(addr, "readSector", "getCapacity", 512)
end
function dev.ossm_eeprom(addr)
	log("eeprom: "..addr)
	--local parts = die_assert(osdi_decode(cinvoke(addr, blockRead, 1)) or mtpt_decode(cinvoke(addr, blockRead, cinvoke(addr, "numBlocks"))), "no partition tables")
	get_boot(addr, "blockRead", "numBlocks", 1)
end
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



_FLASH = {}
_BIOS = "ziptie 0.1"
_BOOT = "ziptie 0.1"
ziptie = {
	bin2addr = b2a,
	addr2bin = a2b,
	net = {
		send = net_send,
		open = net_open,
		lsend = net_lsend,
		fget = frequest
	},
	log = log,
	cfg = {
		get = function(id)
			return config[id]
		end,
		set = function(id, val)
			config[id] = val
			cfg_save()
		end
	}
}

log("ziptie 0.1")
local bt = config[3--[[BOOT_TYPE]]]
bt = bt and bt:byte()
if bt == 1 then
	frequest(config[1--[[BOOT_ADDRESS]]], sunpack("H", config[11--[[BOOT_PORT]]]), config[2--[[BOOT_PATH]]])
elseif bt == 0 or not bt then
	local addr = b2a(config[1--[[BOOT_ADDRESS]]])
	local ct = cpnt.type(addr)
	die_assert(dev[ct], "unknown component type "..ct)(addr)
end
end, function(err)
	local em = debug.traceback(err)
	for line in em:gmatch("[^\r\n]+") do
		component.proxy(component.list("ocelot")()).log((line:gsub("\t", "    ")))
	end
end)