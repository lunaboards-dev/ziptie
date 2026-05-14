local function amax(s)
    local r = #s
    for i=1, r do
        r = r * (s:byte(i)+i)+i
        r = (r & 0xFF) ~ (r >> 8)
    end
    return r & 0xFF
end

local function amax16(s)
    local r = #s
    for i=1, r do
        r = r * (s:byte(i)+i)+i
        r = (r & 0xFFFF) ~ (r >> 16)
    end
    return r & 0xFFFF
end

local m8 = {}
local m16 = {}

local function test(v)
    local r8, r16 = amax(v), amax16(v)
    print(string.format("%q -> 8: 0x%.2x - 16: 0x%.4x", v, r8, r16))
    --[[if m8[r8] then
        io.stderr:write(string.format("collision: (%.2x)%q ~= %q\n", r8, v, m8[r8]))
        os.exit(1)
    end]]
    --[[if m16[r16] then
        io.stderr:write(string.format("collision: (%.4x) %q ~= %q\n", r16, v, m16[r16]))
        os.exit(1)
    end]]
    m8[r8] = v
    m16[r16] = v
end

test("craig")
test("craih")
test("draig")
test("crai")
test("draih")
test("craiga")

test("\0\0\0\0\0")
test("\0\0\1\0\0")
test("\xff\xff\xff\xff\xff")

local h = io.open("/dev/urandom", "r")

while true do
    test(h:read(40))
end