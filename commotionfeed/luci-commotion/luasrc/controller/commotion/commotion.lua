--[[
LuCI - Lua Configuration Interface

Copyright 2011 Josh King <joshking at newamerica dot net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.commotion.commotion", package.seeall)

function index()
	require("luci.i18n").loadc("commotion")
	local i18n = luci.i18n.translate

	local page  = node()
	page.lock   = true
	page.target = alias("commotion")
	page.subindex = true
	page.index = false


	local root = node()
	if not root.lock then
		root.target = alias("commotion")
		root.index = true
	end
 
  entry({"commotion"}, alias("commotion", "index"), i18n("Commotion"), 10)
	entry({"commotion", "index"}, alias("commotion", "index", "index"), i18n("Overview"), 10).index = true
	entry({"commotion", "index", "index"}, template("commotion/splash"), i18n("Front Page"), 10).ignoreindex = true
    entry({"commotion", "index", "olsr-viz"}, template("olsr-viz/olsr-viz"), _("OLSR-Viz"), 90)
  

	local config   = entry({"admin", "commotion"}, alias("admin", "commotion", "meshconfig"), i18n("Commotion"), 10)
	config.sysauth = "root"
	config.sysauth_authenticator = "htmlauth"
	config.index = true

	entry({"admin", "commotion", "meshprofile"}, cbi("commotion/meshprofile"), i18n("Mesh Configuration (Profile)"), 10)
	entry({"admin", "commotion", "meshconfig"}, cbi("commotion/meshconfig"), i18n("Mesh Configuration (Manual)"), 20)
	entry({"admin", "commotion", "frontpage"}, cbi("commotion/frontpage"), i18n("Front Page"), 30)
	entry({"admin", "commotion", "upgrade"}, cbi("commotion/upgrade"), i18n("Remote Upgrade"), 40)
end

