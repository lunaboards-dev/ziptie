local pat = "<IIc8I3c13"
local drive = component.proxy(computer.getBootAddress())
local _pt = drive.readSector(1)

local function osdi_read(pos)
	local start, size, ptype, flags, label = string.unpack(pat, _pt, (i-1)*pat:packsize()+1)
	return {start=start, size=size, type=ptype, flags=flags, label=label}
end

local hdr = osdi_read(1)
if hdr.start ~= 1 or hdr.type ~= "OSDI\xAA\xAA\x55\x55" then
	error("Invalid boot disk!")
end

local installer, ztcfg

for i=1, 15 do
	local part = osdi_read(i+1)
	if part.type == "SrsInDat" then
		installer = part
	elseif part.type == "ztcfglua" then
		ztcfg = part
	end
end

local cpio = {}

function cpio:get(path)
	return ""
end

load(cpio:get("init.lua"))(cpio)