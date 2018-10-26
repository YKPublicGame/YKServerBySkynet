local aes = require "bgcrypto"
local crypt = require "skynet.crypt"

local cbc_encrypt = aes.cbc_encrypter()
local cbc_decrypt = aes.cbc_decrypter()
local data = crypt.base64decode("+idNMabSYQHqmADLWIHrOc+I1ZyEgKrKTzzPQ+v8uQB1XRGlaHo/PaEtfjlqfFKDtABb+iqQXG/hZYZwZFClYykWoZr8VVWohAueAn2vE+GWFCyvAZfEIVPV14LlspLsqOhfIgb2OL553n8DnceV02lsRHbk3u1AmQ1ZKDXyw/8xyCkr7NRZ90GWniMLmN2uEOX2/9G705wQ5u8zwi5iDTGDczmPbXm6bu0bfmLsbUW+LXdn5twXtb2+Mr64QeB4iYuegcukUBiCR4PXy0ezTga+5Hm2L+RxfwbMSN3PGNg/dQ4qOo8vIGWo5TCUp+ptTpUAHMRMwvxJMUhPVd6iwHAM9QMRCrtn5oW/Sefe0TtW1s05O34q//vMMjlZQUUqiNk+n92bVm/1SutGwJhqytXnboa4MZJ3SEX6LFYK4miBVWU3YD1KyzLMtPqwkCOevoLD5sLDI75nVraO3x8YDXREqHxRNV3DXB5aQKGDWQo=")
local key =  crypt.base64decode("MAnQvk4fW9n7MxAhk2YL1w==")
--key = { string.byte(key, 1, #key) }
local _iv =  crypt.base64decode("zmfxQKrf6b6K3YU8+74rrg==")
--_iv = { string.byte(_iv, 1, #_iv) }
assert(cbc_decrypt:open(key, _iv))
local decrypt = assert(cbc_decrypt:write(data))
print("解密完成："..decrypt)