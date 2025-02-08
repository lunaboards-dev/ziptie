# Ziptie BIOS v1.0

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

## API reference

### `ziptie.addr2bin(address:string):string`
Converts a human-readable UUID to a binary UUID.

### `ziptie.bin2addr(address:string):string`
Converts a binary UUID to a human readable UUID.

### `ziptie.cfg.get(id:integer):string`
Gets the config entry at `id` and returns the raw data. Decoding must be done on your own.

### `ziptie.cfg.load(data:string)`
Loads config data to be read from. **Do not try to set config values after using `load`!**

### `ziptie.cfg.set(id:integer, data:string, ...)`
Sets the config entries at `id`, subsequent arguments are more entries. Also writes the config. **Using this after using `ziptie.cfg.load` can cause a `no space` error!.**

### `ziptie.decompress(data:string):string`
Decompresses `data` with LZSS. **Not available when using debug builds!**

### `ziptie.fget(host:string, port:integer, path:string):string`
Fetches a file from a remote server. Will cause an error if there's no modem, and will cause a panic if it's a directory.

### `ziptie.log(msg:string)`
Logs a message to the screen. Does not support line breaks.

### `ziptie.parts.osdi(data:string):partition_table`
Decodes an OSDI partition table. Returns nil if invalid or not present. You must filter out invalid partitions yourself.

### `ziptie.parts.mtpt(data:string):partition_table`
Decodes a Minitel partition table. Returns nil if invalid or not present. You must filter out invalid partitions yourself.

### Type: `partition_table`
| Field | Type | Data |
| ----- | ---- | ---- |
| `s` | Integer | Start sector |
| `S` | Integer | Partition size |
| `t` | String | Partition type |
| `f` | Integer or nil | Partition flags. Not present on Minitel tables. |
| `n` | String | Partition name |