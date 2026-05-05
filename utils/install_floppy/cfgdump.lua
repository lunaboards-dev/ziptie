if not ziptie then
    io.stderr:write("This tool only works on a system booted with ziptie BIOS.\n")
    os.exit(1)
end

local keys = {}

local function add_key(key, name, decode)
    if type(decode) == "string" then
        local _dec = decode
        decode = function(v)
            return (_dec:unpack(v))
        end
    elseif not decode then
        decode = function(v)
            return v
        end
    end
    table.insert(keys, {
        key = key,
        name = name,
        decode = decode
    })
end

local function a2b(addr)
	addr=string.gsub(addr, "%-", "")
	local baddr = ""
	for i=1, #addr, 2 do
		baddr = baddr .. string.char(tonumber(string.sub(addr, i, i+1), 16))
	end
	return baddr
end

local _x = "%.2x"
local function b2a(data)
	return string.format(
		string.format(
			"%s-%s%s",
			string.rep(_x, 4),
			string.rep(_x.._x.."-",3),
			string.rep(_x,6)
		),
		string.byte(data, 1,#data)
	)
end

add_key(1, "Boot address", function(v)
    if ziptie.cfg.get(3) == "\0" then
        return b2a(v)
    else
        return v
    end
end)
add_key(2, "Boot path")
add_key(3, "Boot type", function(v)
    return (v ~= "\0") and "Remote" or "Local"
end)
add_key(4, "Netlog address", b2a)
add_key(5, "Netlog port", "H")
add_key(6, "Log to screen", function(v)
    return (v ~= "\0") and "Enabled" or "Disabled"
end)
add_key(11, "Boot port", "H")
add_key(12, "Minitel hostname")
add_key(13, "Timeout", "f")

for i=1, #keys do
    local key = keys[i]
    local val = ziptie.cfg.get(key.key)
    if val then
        print(key.name, key.decode(val))
    end
end