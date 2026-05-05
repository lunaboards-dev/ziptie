local dev = {}

--#include "src/devs/fs.lua"

@[[if cfg.get("src_disk") then]]
--#include "src/devs/disk.lua"
@[[end]]

@[[if cfg.get("src_eeprom") then]]
--#include "src/devs/eeprom.lua"
@[[end]]

@[[if cfg.get("src_tape") then]]
--#include "src/devs/tape_drive.lua"
@[[end]]

@[[if cfg.get("src_net") then]]
--#include "src/devs/modem.lua"
@[[end]]