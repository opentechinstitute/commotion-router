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
local http = require "luci.http"
local nixiofs = require "nixio.fs"

local roles = {}
local options = {}


m = Map("system", translate("Profiles"), translate("If your node includes configuration profiles for multiple Commotion networks, " ..
	"this form allows you to set your defaults. It is suggested to reboot your node after changing these settings."))

s = m:section(TypedSection, "system")
s.anonymous = true

c = s:option(ListValue, "community", translate("Community"), translate("The community network you want this node to join."))
c.default = "default"
local communities = nixio.fs.dir("/etc/meshconfig")
if communities then
  local i
  for i in communities do
    local o
    c:value(i)
    o = s:option(ListValue, "role_" .. i, translate("Role"), translate("The role this node plays in the network."))
    o.optional = true
    o:depends("community", i)
    function o.cfgvalue(self, section)
    	return m.uci:get("system", section, "role")
    end
    function o.write(self, section, value)
    	return m.uci:set("system", section, "role", value)
    end
    for r in nixio.fs.dir("/etc/meshconfig/" .. i) do
    	o:value(r)
    end
    options[i] = o
  end
end

return m
