--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local map, section, net = ...

local reset, secure, key

reset = s:taboption("advanced", Flag, "reset", translate("Reset"), translate("Set the flag to regenerate configuration. IF SET, PLEASE RESTART ROUTER."))
reset.optional    = true
reset.enabled  = "1"
reset.disabled = "0"
reset.default  = reset.disabled
reset:depends("proto", "apif")

secure = s:taboption("advanced", Flag, "secure", translate("Secure"), translate("Set the flag to set this access point to use WPA when the configuration is reset."))
secure.optional    = true
secure.enabled  = "1"
secure.disabled = "0"
secure.default  = secure.disabled
secure:depends("proto", "apif")
 
key = s:taboption("advanced", Value, "key", translate("WPA Key"), translate("Set the WPA key to be used for this interface when the configuration is reset."))
key.optional    = true
key.placeholder = "c0MM0t10N!"
key:depends("proto", "apif")
key:depends("secure", "1")

