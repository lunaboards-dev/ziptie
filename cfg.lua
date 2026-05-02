local cfg = {}

local keys = {}
local loaded = {}
do
    local func, err = loadfile("bios.config", "t", loaded)
    if not func then
        io.stderr:write("WARNING: Failed to read config: "..err.."\n")
    end
    local ok, err = pcall(func)
    if not ok then
        io.stderr:write("WARNING: Failed to read config: "..err.."\n")
    end
end

function cfg.key(key, desc, default)
    table.insert(keys, {key=key, desc=desc, def=default})
end

function cfg.get(key)
    return loaded[key]
end

return cfg