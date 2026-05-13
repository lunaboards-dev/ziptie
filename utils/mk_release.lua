require("cfg")
local function step_print(step)
	print("\27[1m:: "..step.."\27[0m")
end

local function getsize(file)
	local h = io.open(file, "r")
	local size = h:seek("end", 0)
	h:close()
	return size
end

step_print("Creating directories")

os.execute("rm -r test")
os.execute("mkdir test")

step_print("Building BIOS")

os.execute("luacomp src/init.lua -g -L cfg.lua -O test/debug.lua")
os.execute("luacomp bios.lua -L cfg.lua -O ziptie.bios 2>/dev/null")

local size = getsize("ziptie.bios")

print(string.format("BIOS size: \27[36m%d bytes\27[0m", size))
if size > cfg.get("target_kib")*1024 then
	io.stderr:write(string.format("\27[91mBIOS too large! (%d bytes > %d bytes)\27[0m\n", size//1, cfg.get("target_kib")*1024))
	os.exit(1)
end

step_print("Creating install floppy")
os.execute("cp -r utils/install_floppy test/floppy")
os.execute("cp ziptie.bios test/floppy/ziptie.bin")
os.execute("cd test/floppy; find | sed \"s/\\.\\///\" | cpio -oF ../install.cpio")

size = getsize("test/install.cpio")
print(string.format("Install floppy size: \27[36m%d bytes\27[0m", size))

step_print("Creating install image")
os.execute("lua utils/makeimage.lua utils/install_image/bootstrap.lua test/install.cpio test/floppy/ztcfg.lua > test/install.img")

size = getsize("test/install.img")
print(string.format("Install image size: \27[36m%d bytes\27[0m", size))