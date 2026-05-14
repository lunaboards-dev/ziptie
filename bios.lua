local function z(a)local h,b,c,e,j,i,g=a.sub,1,''while b<=#a do
e=a:byte(b)b=b+1
for k=0,7 do
g=h(a,b,b)if e>>k&1<1 and b<#a then
i=c.unpack('>H',a,b)j=1+(i>>4)g=h(c,-j,-j+(i&15)+2)b=b+1
end
b=b+1
c=c..g
end
end
return c end
load(z$[[luacomp -Lcfg.lua src/init.lua | lua utils/optmin.lua | lua utils/makezbios.lua]],"=(bios)")(z)