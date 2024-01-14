# Ziptie BIOS v0.1

_It's like duct tape but I can use to tow my car._

A small BIOS that allows booting off of multiple different types of media.

## Config Keys
| Canonical Name | Index | Type | Notes |
| --- | --- | --- | --- |
| _N/A_ | `0` | N/A | Padding/Null entry |
| `BOOT_ADDRESS` | `1` | UUID **or** String | If `BOOT_TYPE` is set to 1, this is a string, otherwise specifies the boot device. |
| `BOOT_PATH` | `2` | String | Path to file to boot from. |
| `BOOT_TYPE` | `3` | Byte | 0 = Local boot, 1 = Network boot |
| `LOG_NET` | `4` | UUID | UUID to send remote log messages to. |
| `LOG_NET_PORT` | `5` | Short | Port to send remote log messages to. |
| `LOG_SCREEN` | `6` | Any | Set to anything to log to screen. |
| `FLASH_CONFIG` | `7` | UUID | Set to the OSSM Flash device to use for extra config storage. |
| `FLASH_START` | `8` | Number | Start **block** of configuration storage. |
| `FLASH_SIZE` | `9` | Number | Size in **blocks** of configuration storage. |
| `FLASH_BYTES` | `10` | Number | Size in **bytes** of configuration storage. |
| `BOOT_PORT` | `11` | Short | Minitel port for network boot. |
| `HOSTNAME` | `12` | String | Minitel hostname. |