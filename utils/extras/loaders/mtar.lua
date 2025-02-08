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