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