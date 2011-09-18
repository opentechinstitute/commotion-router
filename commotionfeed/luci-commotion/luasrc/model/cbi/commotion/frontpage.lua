--[[
LuCI - Lua Configuration Interface

Copyright 2011 Josh King <joshking at newamerica dot net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local fs = require "nixio.fs"
local file = "/www/luci-static/commotion_index.html"

m = Map("mesh", translate("Edit front page"), translate("You can display additional content on the public index page by inserting valid XHTML in the form below.<br />Headlines should be enclosed between &lt;h2&gt; and &lt;/h2&gt;."))

s = m:section(TypedSection, "network")
s.anonymous = true

t = s:option(TextValue, "_text")
t.rmempty = true
t.rows = 20

function t.cfgvalue()
        return fs.readfile(file) or ""
end

function t.write(self, section, value)
        return fs.writefile(file, value)
end

function t.remove(self, section)
        return fs.unlink(file)
end

return m
