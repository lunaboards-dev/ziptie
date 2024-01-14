net_timeout = 60
local function net_open(address,vport)
 local st,from,port,data=cuptime()
 net_send(address,vport,"openstream")
 repeat
  _, from, port, data = com_pullSignal(0)
  if cuptime() > st+net_timeout then return false end
 until from == address and port == vport and _tonumber(data)
 vport=_tonumber(data)
 repeat
  _, from, port, data = com_pullSignal(0)
 until from == address and port == vport
 return net_socket(address,vport,data)
end