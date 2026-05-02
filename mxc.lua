local function axc(s)
    local r = #s
    for i=1, r do
        r = r * (s:byte(i)+i)
        r = (r & 0xFF) ~ (r >> 8)
    end
    return r & 0xFF
end

print(axc("craig"))
print(axc("craih"))
print(axc("draig"))
print(axc("crai"))
print(axc("draih"))

print(axc("\0\0\0\0\0"))
print(axc("\0\0\1\0\0"))