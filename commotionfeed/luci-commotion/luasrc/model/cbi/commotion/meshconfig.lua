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


m = Map("mesh", translate("Configuration"), translate("This configuration wizard will assist you in setting up your router " ..
	"for a Commotion network. It is suggested to reboot your node after changing these settings."))

e = m:section(TypedSection, "network", translate("Network-wide Settings"))
e.anonymous = true

e:option(Value, "basename", translate("Base-name"), translate("The one-word name of the network, used to create SSIDs and hostnames."))
e:option(Value, "ssid", translate("Mesh SSID"), translate("The backhaul SSID of the mesh network."))
e:option(Value, "bssid", translate("Mesh BSSID"), translate("The backhaul BSSID of the mesh network, must be statically set for ad-hoc Wi-Fi."))
c = e:option(ListValue, "channel", translate("Channel"), translate("The backhaul channel of the mesh network."))
for i=1, 14 do
	c:value(i, i .. " (2.4 GHz)")
end


m2 = Map("system")
o = m2:section(TypedSection, "system", translate("Settings specific to this node"))
o.anonymous = true

o:option(Value, "location", translate("Location"), translate("Human-readable location, optionally used to generate hostname/SSID. No spaces or underscores."))
o:option(Value, "homepage", translate("Homepage"), translate("Homepage for this node or network, used in the splash screen."))
--[[
LatLon and OpenStreetMap implementation borrowed from Freifunk.
]]--
lat = o:option(Value, "latitude", translate("Latitude"), translate("e.g.") .. " 40.11143")
lat.datatype = "float"

lon = o:option(Value, "longitude", translate("Longitude"), translate("e.g.") .. " -88.20723")
lon.datatype = "float"

--[[
Opens an OpenStreetMap iframe or popup
Makes use of resources/OSMLatLon.htm and htdocs/resources/osm.js
]]--

local class = util.class

local deflat = uci:get_first("system", "system", "latitude") or 40
local deflon = uci:get_first("system", "system", "longitude") or -88
local zoom = 12
if ( deflat == 40 and deflon == -88 ) then
	zoom = 4
end

OpenStreetMapLonLat = luci.util.class(AbstractValue)
    
function OpenStreetMapLonLat.__init__(self, ...)
	AbstractValue.__init__(self, ...)
	self.template = "cbi/osmll_value"
	self.latfield = nil
	self.lonfield = nil
	self.centerlat = ""
	self.centerlon = ""
	self.zoom = "0"
	self.width = "100%" --popups will ignore the %-symbol, "100%" is interpreted as "100"
	self.height = "600"
	self.popup = false
	self.displaytext="OpenStreetMap" --text on button, that loads and displays the OSMap
	self.hidetext="X" -- text on button, that hides OSMap
end

	osm = o:option(OpenStreetMapLonLat, "latlon", translate("Find your coordinates with OpenStreetMap"), translate("Select your location with a mouse click on the map. The map will only show up if you are connected to the Internet."))
	osm.latfield = "latitude"
	osm.lonfield = "longitude"
	osm.centerlat = uci:get_first("system", "system", "latitude") or deflat
	osm.centerlon = uci:get_first("system", "system", "longitude") or deflon
	osm.zoom = zoom
	osm.width = "100%"
	osm.height = "600"
	osm.popup = false
	osm.displaytext=translate("Show OpenStreetMap")
	osm.hidetext=translate("Hide OpenStreetMap")

return m, m2
