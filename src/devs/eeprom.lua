function dev.ossm_eeprom(addr)
	log("eeprom: "..addr)
	--local parts = die_assert(osdi_decode(cinvoke(addr, blockRead, 1)) or mtpt_decode(cinvoke(addr, blockRead, cinvoke(addr, "numBlocks"))), "no partition tables")
	return get_boot(addr, "blockRead", "numBlocks", 1)
end