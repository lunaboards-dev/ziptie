local component = component or require("component")
local eeprom = component.proxy(component.list("eeprom")())
local net = component.proxy(component.list("internet")())

local function download_file(url)
	local h = net.request("https://github.com/lunaboards-dev/ziptie/releases/download/latest/install.cpio")
end