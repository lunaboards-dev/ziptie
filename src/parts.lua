--local osdi_hdr, mtpt_hdr = "<IIc8I3c13", ">c20c4II"
local function pdecode(hdr, fields, ...)
	local args, cv = {...}, {n=0}
	for i=1, #args, 2 do
		tinsert(cv, {args[i], args[i+1]})
	end
	return function(dat)
		local off, out = 1, {}
		while off < #dat do
			local list = tbl.pack(sunpack(hdr, dat, off))
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
local osdi_decode, mtpt_decode = pdecode("<IIc8I3c13", "sStfn", 1, 1, 3, "OSDI\xAA\xAA\x55\x55"), pdecode(">c20c4II", "ntsS", 2, "mtpt")