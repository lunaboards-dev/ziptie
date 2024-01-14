@[[
	local gt = {}
	local f = io.open("src/constants.lua", "r")
	local d = f:read("*a")
	f:close()
	load(d, "=constants.lua", "t", gt)()
	local kl, vl = {}, {}
	for k, v in pairs(gt) do
		table.insert(kl, k)
		--table.insert(vl, string.format("%q", v))
	end
	table.sort(kl)
	for i=1, #kl do
		table.insert(vl, string.format("%q", gt[kl[i] ]))
	end
]]

local str, cpnt, tbl, com, _tonumber, _pairs, _nil = string, component, table, computer, tonumber, pairs
local ssub, sbyte, cproxy, cinvoke, clist, sgsub, sunpack, srep, sformat, tinsert, tremove, schar, cuptime, tunpack =
str.sub, str.byte, cpnt.proxy, cpnt.invoke, cpnt.list, str.gsub, str.unpack, str.rep, str.format, tbl.insert, tbl.remove, str.char, com.uptime, tbl.unpack

local @[{table.concat(kl, ",")}] = @[{table.concat(vl, ",")}]