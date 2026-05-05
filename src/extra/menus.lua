local function menu_setup(entries)

end

local function button(name, pos, onclick)

end

local function label(text, pos)

end

local function combo(text, pos, options)

end

local function toggle(text, pos, options)

end

local function input(title, pos)

local function key(tbl, val)
    return {set=function()return tbl[val]end, function(v)tbl[val]=v end}
end