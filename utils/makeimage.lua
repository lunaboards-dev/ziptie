local function osdi_entry(start, size, type, flags, label)
	return (string.pack("<IIc8I3c13", start, size, type, flags, label))
end

local flag_active = 0x200

local function readfile(path)
	local h = io.open(path, "r")
	local dat = h:read("*a")
	h:close()
	return dat
end

local function pad512(dat)
	local mod512 = #dat % 512
	if mod512 == 0 then return dat end
	return dat .. string.rep("\0", 512-mod512)
end

--local bootstrap, installer, ztcfg = arg[1], arg[2], arg[3]
local bootstrap = readfile(arg[1])
local installer = readfile(arg[2])
local ztcfg = readfile(arg[3])

local sec = {
	osdi_entry(1, 0, "OSDI\xAA\xAA\x55\x55", 0, "SiriusInstall"),
}
local idat = {

}

local offset_sec = 2
local function add_partition(dat, type, flags, label)
	local pdat = pad512(dat)
	local size = #pdat//512
	table.insert(sec, osdi_entry(offset_sec, size, type, flags, label))
	table.insert(idat, pdat)
	offset_sec = offset_sec + size
end

add_partition(bootstrap, "BOOTCODE", flag_active, "Bootstrap")
add_partition(installer, "SrsInDat", 0, "Install CPIO")
add_partition(ztcfg, "ztcfglua", 0, "Config tool")

io.stdout:write(pad512(table.concat(sec)))
io.stdout:write(table.concat(idat))