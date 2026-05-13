
local cl = {}
local function bootent(addr, ctype)
    return function()
        
    end
end
for comp, ctype in clist() do
    if dev[ctype] then
        tinsert(cl, {
            addr = comp,
            ctype = ctype
        })
    end
end