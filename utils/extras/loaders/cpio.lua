-- Basic cpio loader for unmanaged media.
local dev = component.proxy(computer.getBootAddress())
local dtype = component.type(component.getBootAddress())

local function get_block_size()
	if dtype == "drive" then
		return dev.getBlockSize()
	elseif dtype == "tape_drive" then
		return 512
	elseif dtype == "ossm_eeprom" then
		return dev.blockSize()
	end
end

local function get_blocks()
	if dtype == "drive" then
		return dev.getCapacity()//dev.getBlockSize()
	elseif dtype == "tape_drive" then
		return dev.getSize()//512
	elseif dtype == "ossm_eeprom" then
		return dev.numBlocks()
	end
end

local function read(n)
	if dtype == "drive" then
		return dev.readSector(n)
	elseif dtype == "tape_drive" then
		local pos = n*512
		dev.seek(pos-dev.getPosition())
		return dev.read(512)
	elseif dtype == "ossm_eeprom" then
		return dev.blockRead(n)
	end
end

local function read512(n)
	local blksize = get_block_size()
	local read_count = 1
	if blksize < 512 then
		read_count = 512//blksize
	end
	local phypos = n*read_count
	local buf = ""
	for i=1, read_count do
		buf = buf .. read(phypos*(n+i-1))
	end
	return buf
end

local function die(msg)
	for line in debug.traceback("panic!: "..msg):gmatch("([^\r\n]+)") do
		ziptie.log(line:gsub("\t", "   "))
	end
	while true do computer.pullSignal() end
end

local ptypes = {
	osdi = {
		cfg = "ztcfg",
		boot = "bootcpio"
	},
	mtpt = {
		cfg = "ztcf",
		boot = "bcpi"
	}
}

ziptie.log(string.format("boot: %s (%s)", dev.address, dtype))
ziptie.log(string.format("blocks: %d blocks", get_blocks()))
ziptie.log(string.format("block size: %d bytes", get_block_size()))

local part = ziptie.osdi(read512(0))
local pt = "osdi"
if not part then
	part = ziptie.mtpt(read(get_blocks()-1))
	pt = "mtpt"
end
if not part then
	die("no valid partition table")
end

ziptie.log(string.format("table: %s", pt))

local part_type = ptypes[pt]
local bootpart, cfgpart
for i=1, #part do
	local p = part[i]
	if p.t == part_type.cfg then
		cfgpart = p
	elseif p.t == part_type.boot then
		bootpart = p
	end
end

if not bootpart then
	die("no boot partition")
end

if cfgpart then
	ziptie.log("loading config...")
	local buf = ""
	for i=1, bootpart.S do
		buf = buf .. read(bootpart.s+i-1)
	end
	ziptie.cfg.load(buf)
end

local path = ziptie.cfg.get(128) or "init.lua"

ziptie.log(string.format("boot path: %s", path))