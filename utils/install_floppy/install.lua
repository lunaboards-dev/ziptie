local computer = computer or require("computer")
local component = component or require("component")

for fs in component.list("filesystem") do
	if component.invoke(fs, "exists", "ziptie.bin") then
		computer.setBootAddress(fs)
		if computer.getBootAddress(fs) ~= fs then
			error("Cannot set boot address!")
		end
		computer.shutdown(true)
	end
end