local net_port,net_hostname,net_route,net_hook,realComputerPullSignal, net_send=4096,config[12] or ssub(com.address(),1,8),true,{},com.pullSignal

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