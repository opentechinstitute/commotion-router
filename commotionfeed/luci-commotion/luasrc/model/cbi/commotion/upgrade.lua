--[[
LuCI - Lua Configuration Interface

Copyright 2011 Josh King <joshking at newamerica dot net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"
local util = require "luci.util"


m = Map("system", translate("Remote Upgrades"), translate("This page will let you set up your Commotion node for remote updates using the Freifunk Remote-Update utility. It is suggested to reboot your node after changing these settings."))

u = m:section(TypedSection, "upgrade")
u.anonymous = true

auto = u:option(Flag, "auto", translate("Upgrade automatically"), translate("Check this box to upgrade automatically when updates become available. ONLY CHECK IF YOU KNOW WHAT YOU'RE DOING."))
auto.enabled = "1"
auto.disabled = "0"
auto.default = auto.disabled
auto.default = 0
repo = u:option(Value, "repository", translate("Repository"), translate("The location where upgrade images can be found. Must be a valid URL."))
repo:depends("auto", "1") 
nobackup = u:option(Flag, "nobackup", translate("Overwrite Configuration"), translate("Check this box to overwrite all configurations on upgrade. Note: the configuration on this page will be overwritten with defaults."))
nobackup.enabled = "1"
nobackup.disabled = "0"
nobackup.default = nobackup.disabled
nobackup:depends("auto", "1") 
noverify = u:option(Flag, "noverify", translate("Skip Verification"), translate("Check this box to skip image verification."))
noverify.enabled = "1"
noverify.disabled = "0"
noverify.default = noverify.disabled
noverify:depends("auto", "1") 
return m
