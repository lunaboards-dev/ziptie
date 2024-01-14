local net_mtu = 4096
local function net_lsend(to,vport,ldata)
 local tdata = {}
 for i = 1, #ldata, net_mtu do
  tdata[#tdata+1] = ssub(ldata, 1,net_mtu)
  ldata = ssub(ldata, net_mtu+1)
 end
 for k,v in ipairs(tdata) do
  net_send(to,vport,v)
 end
end