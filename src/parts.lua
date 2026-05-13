--local osdi_hdr, mtpt_hdr = "<IIc8I3c13", ">c20c4II"
local function pdecode(hdr, fields, ...)
	local args, cv = {...}, {}
	for i=1, #args, 2 do
		table.insert(cv, {table.unpack(args, i, i+1)})
		---table.insert(cv, {select(i, ...), select(i+1, ...)})
	end
	return function(dat)
		local off, out = 1, {}
		while off < #dat do
			local list = {string.unpack(hdr, dat, off)}
			for i=1, #fields do list[fields:sub(i,i)] = list[i] end
			local nxt = table.remove(list)
			table.insert(out, list)
			off = nxt
		end
		local first = table.remove(out, 1)
		for i=1, #cv do
			if first[cv[i][1]] ~= cv[i][2] then
				return
			end
		end
		return out
	end
end
local osdi_decode, mtpt_decode = pdecode("<IIc8I3c13", "sStfn", 1, 1, 3, "OSDI\xAA\xAA\x55\x55"), pdecode(">c20c4II", "ntsS", 2, "mtpt")