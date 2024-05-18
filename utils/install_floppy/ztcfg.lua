--[[local component = require("component")
local computer = require("computer")]]

xpcall(function()
	local gpu = component.proxy(component.list("gpu")())
	local t1 = gpu.getDepth() == 1
	local function set_colors(col)
		gpu.setBackground(col[1])
		gpu.setForeground(col[2])
	end
	local gfill = gpu.fill
	local gset = gpu.set

	local chars = {
		v = "─",
		h = "│",
		cnw = "┌",
		cne = "┐",
		csw = "└",
		cse = "┘",
		ivw = "├",
		ive = "┤",
		ihn = "┬",
		ihs = "┴"
	}

	local buttons = {
		ok = "[OK]",
		cancel = "[Cancel]",
		close = "[Close]",
		save = "[Save]"
	}

	local colors = {}
	local menu_items = {}
	local next_item = {}

	if t1 then
		colors.text = {0, 1}
		colors.selected = {1, 0}
		colors.selectable = {0, 1}
		colors.disabled = {0, 1}
	else
		colors.text = {0x0000ff, 0xffffff}
		colors.selected = {0xff0000, 0xffff00}
		colors.selectable = {0x0000ff, 0xffff00}
		colors.disabled = {0x0000ff, 0x7f7f7f}
	end

	local function window(w, h, title)
		set_colors(colors.text)
		local vw, vh = gpu.getViewport()
		local dw, dh = vw-w, vh-h
		local ox, oy = dw//2, dh//2
		local tx = ox+((w//2)-(#title//2))
		gfill(ox, oy, w, h, " ")
		gfill(ox+1, oy, w-2, 1, chars.v)
		gfill(ox+1, oy+h-1, w-2, 1, chars.v)
		gfill(ox, oy+1, 1, h-2, chars.h)
		gfill(ox+w-1, oy+1, 1, h-2, chars.h)
		gset(ox, oy, chars.cnw)
		gset(ox+w-1, oy, chars.cne)
		gset(ox, oy+h-1, chars.csw)
		gset(ox+w-1, oy+h-1, chars.cse)
		gset(tx, oy, title)
		return ox+1, oy+1
	end

	local function fcall(func, ...)
		local a = table.pack(...)
		return function() return func(table.unpack(a)) end
	end

	local function clear_menu()
		for i=1, #menu_items do
			table.remove(menu_items, 1)
		end
	end

	local function key_up(k)
		while true do local evt, _, _, c = computer.pullSignal() if evt == "key_up" and (not k or c == k) then break end end
	end

	--key_up()
	local inst = 0
	local sel
	local function display_ui(def)
		sel = def or 1
		while #menu_items > 0 do
			local a = table.pack(computer.pullSignal())
			local rtn
			local fails, suc = 0, 0
			for i=1, #menu_items do
				--io.stdout:write(string.format("\r%.2d/%.2d (%.2d/%.2d)", i, #menu_items, fails, suc))
				local seld = i == sel
				local itm = menu_items[i]
				if itm then
					set_colors((seld and colors.selected) or (itm.x and colors.disabled) or colors.selectable)
					itm.r(seld)
					if #a > 0 and seld then
						rtn = itm.e(table.unpack(a))
					end
				end
			end
			if rtn == next_item then
				sel = sel + 1
				sel = (sel > #menu_items) and 1 or sel
			elseif not rtn then
				local evt, _, _, kc = table.unpack(a)
				if evt == "key_down" then
					if kc == 15 or kc == 208 then
						repeat
							if not menu_items[sel] then break end
							sel = sel + 1
							sel = math.min(math.max(1, sel), #menu_items)
						until not menu_items[sel].x
					elseif kc == 200 then
						repeat
							if not menu_items[sel] then break end
							sel = sel - 1
							sel = math.min(math.max(1, sel), #menu_items)
						until not menu_items[sel].x
					end
				end
			end
			--io.stdout:write("\r"..sel.." "..#menu_items)
			inst = inst + 1
		end
	end

	local function disable(i)
		menu_items[i or #menu_items].x = not menu_items[i or #menu_items].x
	end

	local function button(x, y, text, callback)
		local st = {v=text, x=x, y=y}
		table.insert(menu_items, {r=function(is_sel, disabled)
			--set_colors((is_sel and colors.selected) or (disabled and colors.disabled) or colors.selectable)
			local s = tostring(st.v):gsub("%s+$", "")
			gset(st.x, st.y, (#s > 0) and s or text)
		end, e=function(evt, _, key)
			if evt == "key_down" and (key == 32 or key == 13) then
				callback()
			end
		end})
		return st, #text
	end

	local function input(x, y, width, filter, def)
		local st = {v = def or "", x=x, y=y}
		table.insert(menu_items, {
			r=function(is_sel, disabled)
				gset(st.x, st.y, st.v:sub(math.max(1, #st.v-width+1))..string.rep(" ", width-#st.v))
			end, e = function(evt, _, key)
				if evt == "key_down" then
					if key == 13 then return next_item end
					if key == 8 then st.v = st.v:sub(1, #st.v-1) return true end
					local c = string.char(key)
					if c:find(filter) then
						st.v = st.v .. c
						return true
					end
				end
			end
		})
		return st, width
	end

	local function prompt(query, dev)
		clear_menu()
		local pwidth = 24
		local ox, oy = window(pwidth+6, 6, query)
		--[[set_colors(colors.selected)
		gfill(ox+2, oy+1, pwidth, 1, " ")
		set_colors(colors.selectable)
		gset(ox+bc+2, oy+3, buttons.ok)
		gset(ox+bc+4+#buttons.ok, oy+3, buttons.cancel)]]
		local bc = (pwidth-(#buttons.ok+#buttons.cancel+2))//2
		local i = input(ox+2, oy+1, pwidth, ".", dev)
		local val
		button(ox+bc+2, oy+3, buttons.ok, function()
			clear_menu()
		end)
		button(ox+bc+4+#buttons.ok, oy+3, buttons.cancel, function()
			clear_menu()
		end)
		display_ui()
		return i.v
	end

	local function combo(title, options)
		clear_menu()
		local val, dv
		local max_width = 0
		for i=1, #options do
			max_width = math.max(max_width, #options[i].l)
			if options[i].d then
				dv = i
			end
		end
		max_width = max_width + 2
		local ox, oy = window(max_width+1, #options+2, title)
		for i=1, #options do
			local opt = options[i]
			local os = (max_width-#opt.l)//2
			button(ox+os, oy+i-1, opt.l, function()
				val = opt.v
				clear_menu()
			end)
		end
		display_ui(dv)
		return val
	end

	local function cycle(x, y, vals, cb, df)
		local mw = 0
		for i=1, #vals do
			mw = math.max(#vals[i][1], mw)
		end
		local st = {v=df or 1, x=x, y=y}
		table.insert(menu_items, {
			r = function(is_sel, disabled)
				local v = vals[st.v][1]
				gpu.set(st.x, st.y, v..string.rep(" ", mw-#v))
			end,
			e = function(evt, _, _, kc)
				local rv
				if evt == "key_down" then
					if kc == 205 then
						st.v = st.v + 1
						rv = true
					elseif kc == 203 then
						st.v = st.v - 1
						rv = true
					end
					st.v = math.min(math.max(1, st.v), #vals)
					if cb and rv then
						cb(st.v)
					end
					return rv
				end
			end
		})
		return st, mw
	end

	local function add_item(item, ...)
		local a = table.pack(...)
		return function(x, y, st)
			local v, w = item(x, y, table.unpack(a))
			return v, w
		end
	end

	local devs = {}
	local function insert_devs(lab, ct)
		local dl = {}
		for dev in component.list(ct) do
			table.insert(dl, dev)
		end
		table.sort(dl)
		for i=1, #dl do
			local lbl
			if type(component.methods(dl[i]).getLabel) == "boolean" then
				lbl = component.invoke(dl[i], "getLabel")
			else
				lbl = dl[i]:sub(1,3)
			end
			local e = {
				l = string.format("%s: %s (%s)", lab, lbl, dl[i]:sub(1, 3)),
				v = dl[i]
			}
			table.insert(devs, e)
			devs[e.v] = e.l
		end
	end

	insert_devs("FS", "filesystem")
	insert_devs("Disk", "drive")
	insert_devs("EEPROM", "ossm_eeprom")
	insert_devs("Tape", "tape_drive")
	insert_devs("BIP", "modem")

	local nofunc = function()end

	local function check_dis(st, depends)
		if depends then
			for j=1, #depends do
				if not st:find(depends:sub(j,j)) then
					return true
				end
			end
		end
	end

	local kv = {
		type = 1,
		address = "",
		hostname = "mypc",
		port = "29",
		path = "init.lua",
	}

	local state = ""

	local function set_state()
		state = ((kv.type == 1) and "L" or "R") .. (kv.cfg_flash == 2 and "f" or "")
		clear_menu()
	end

	local function set_kv(k, v)
		local ov = kv[k]
		kv[k] = v
		if k == "type" or k == "cfg_flash" then
			set_state()
		end
	end

	set_state()

	local labels = {
		{"Boot type", 					"type", 		nil, add_item(cycle, {{"Local", 1}, {"Remote", 2}}, function(v) set_kv("type", v) end)},
		{"Boot device", 				"address", 		"L", add_item(button, "<select>", function() set_kv("address", combo("Boot device", devs)) end)},
		{"Boot address", 				"address", 		"R", add_item(button, "<select>", function() set_kv("address", prompt("Boot address", kv.address)) end)},
		{"Minitel hostname", 			"hostname", 	"R", add_item(button, "<select>", function() set_kv("hostname", prompt("Hostname", kv.hostname)) end)},
		{"Boot port", 					"port", 		"R", add_item(input, 5, "%n")},
		{"Boot path", 					"path", 		nil, add_item(button, "<select>", function() set_kv("path", prompt("Boot path", kv.path)) end)},
		--{"Log to network", 				"log_net", 		"R", add_item(cycle, {{"Disabled", 1}, {"Enabled", 2}}, function(v) set_kv("log_net", v) end)},
		--{"Log to screen", 				"log_screen", 	nil, add_item(cycle, {{"Disabled", 1}, {"Enabled", 2}}, function(v) set_kv("log_screen", v) end)},
		--[[{"Store config to flash", 		"cfg_flash", 	nil, add_item(cycle, {{"Disabled", 1}, {"Enabled", 2}}, function(v) set_kv("cfg_flash", v) end)},
		{"Flash config size (Blocks)",	"flash_blocks",	"f", add_item(button, "<select>", nofunc)},
		{"Flash config size (Bytes)", 	"flash_bytes",	"X", add_item(button, "<N/A>", nofunc)},
		{"Flash config start", 			"flash_start",	"f", add_item(button, "<select>", nofunc)},]]
	}

	local keys = {
		{3, "type", function(b) return b:byte()+1 end, function(v) return string.char(v-1) end},
		{1, "address", function(b, st)
			if check_dis(st, "L") then
				return ziptie.bin2addr(b)
			end
			return b
		end, function(b, st)
			if check_dis(st, "L") then
				return ziptie.addr2bin(b)
			end
			return b
		end},
		{2, "path", function(b) return b end, function(b) return b end},
		{12, "hostname", function(b) return b end, function(b) return b end},
		{11, "port", function(b) return tostring(string.unpack("H", b or "\0\0")) end, function(b) return string.pack("H", tonumber(b or 0)) end}
	}

	local function load_config()
		if not ziptie then return end
		for i=1, #keys do
			local key = keys[i]
			local v = ziptie.cfg.get(key[1])
			set_kv(key[2], key[3](v, state))
		end
	end

	local function save_config()
		for i=1, #keys do
			local key = keys[i]
			ziptie.cfg.set(key[1], key[4](kv[key[2]], state))
		end
	end

	local function display_menu()
		local dw, dh = gpu.getViewport()
		--local ox, oy = window(50, #labels*2+4, "ziptie config 0.1")
		--gset(ox+3, oy, "Boot Type")
		local quit
		while not quit do
			local st = state
			local items, mw1, mw2 = {}, 0, 0
			for i=1, #labels do
				local lbl, key, depends, add = table.unpack(labels[i])
				mw1 = math.max(#lbl, mw1)
				--set_colors(dis and colors.disabled or colors.text)
				--gset(ox+1, oy+(i*2)-1, lbl)
				--print(key)
				local s, iw = add(0+#lbl+4, 0+(i*2)-1)
				if check_dis(st, depends) then disable() end
				table.insert(items, s)
				mw2 = math.max(iw, mw2)
			end
			local ww = mw1+mw2+6
			local ox, oy = window(ww, #labels*2+4, "ziptie 0.1 config")
			for i=1, #labels do
				local lbl, key, depends, add = table.unpack(labels[i])
				set_colors(check_dis(st, depends) and colors.disabled or colors.text)
				local y = oy+(i*2)-1
				gset(ox+1, y, lbl)
				items[i].x = ox+2+mw1
				items[i].y = y
				items[i].v = kv[key]
				if type(kv[key]) == "string" then
					if #kv[key] > mw2 then
						items[i].v = kv[key]:sub(1, mw2-1).."…"
					end
				end
				--print(key, items[i].x, items[i].y)
			end
			button(ox+1, oy+#labels*2+1, buttons.close, function() quit = true clear_menu() end)
			button(ox+3+#buttons.close, oy+#labels*2+1, buttons.save, function()
				save_config()
				quit = true
				clear_menu()
			end)
			display_ui()
		end
	end
	-- display UI
	load_config()
	display_menu()
	computer.shutdown(true)
end, function(err)
	--set_colors({0, t1 and 1 or 0xffffff})
	local e = debug.traceback(err)
	for line in e:gmatch("[^\n]+") do
		ziptie.log(line:gsub("\t", "  "))
	end
end)
while true do computer.pullSignal() end