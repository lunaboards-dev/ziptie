cfg = {}

local keys = {}
local loaded = {}

function cfg.key(key, desc, default)
    table.insert(keys, {key=key, desc=desc, def=default})
    rawset(loaded, key, default)
end

function cfg.get(key)
    return loaded[key]
end

cfg.key("target_kib", "Output target BIOS size in KiB.", 4)
cfg.key("compact_fget", "Compact implementation of fget protocol.", true)
cfg.key("src_disk", "Allow booting from disks.", true)
cfg.key("src_eeprom", "Allow booting from EEPROM.", true)
cfg.key("src_net", "Allow booting from the network.", true)
cfg.key("src_tape", "Allow booting from tape drives.", true)
cfg.key("split_config", "Allow splitting of the config between EEPROM and flash.", false)
cfg.key("mini_config", "Include mini config tool.", false)
cfg.key("better_boot_selection", "Include a better boot selection.", false)

local cfgok
do
    local func, err = loadfile("bios.config", "t", loaded)
    if not func then
        io.stderr:write("WARNING: Failed to read config: "..err.."\n")
        goto fail
    end
    local ok, err = pcall(func)
    if not ok then
        io.stderr:write("WARNING: Failed to read config: "..err.."\n")
        goto fail
    end
    cfgok = true
    ::fail::
end

if cfgok then
    local f = io.open("bios.config", "w")
    for i=1, #keys do
        f:write("-- ", keys[i].key, "\n")
        f:write("-- ", keys[i].desc, "\n")
        f:write("-- Default: ",string.format("%q\n", keys[i].def))
        f:write(string.format("%s = %q\n\n", keys[i].key, loaded[keys[i].key]))
    end
end