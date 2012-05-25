#!/bin/sh
echo Content-type: text/html
echo

cat << EOF
<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">
var css=document.styleSheets[0];
if (null!=css.insertRule) {
css.insertRule(".label {color:black;background-color:white}", css.cssRules.length);
}
else {
css.addRule(".label", "color:black");
css.addRule(".label", "background-color:white");
}

</SCRIPT>
<DIV><center><img src="/luci-static/resources/olsr-viz/node-hna-mini.gif"> - Gateway Node,   <img src="/luci-static/resources/olsr-viz/node-mini.gif"> - Basic Node</center></DIV> 
<SCRIPT SRC="/luci-static/resources/olsr-viz.js" LANGUAGE="JavaScript1.2" TYPE="text/javascript"></SCRIPT>
<DIV ID="main"
STYLE="width: 100%; height: 83%; border: 1px solid #ccc; margin-left:auto; margin-right:auto; text-align:center; overflow: scroll">
<DIV ID="edges" STYLE="width: 1px; height: 1px; position: relative; z-index:1"></DIV>
<DIV ID="nodes" STYLE="width: 1px; height: 1px; position: relative; z-index:4"></DIV>
</DIV>
<DIV STYLE="z-index:99">
<FORM ACTION="">
<P><B TITLE="Sets the Level of Magnification.">Zoom</B>&#160;<A HREF="javascript:set_scale(scale+0.1)">+</A>&#160;<A HREF="javascript:set_scale(scale-0.1)">&ndash;</A>&#160;<INPUT ID="zoom" NAME="zoom" TYPE="text" VALUE="2.0" SIZE="5" ONCHANGE="set_scale()">&#160;
| &#160;<B TITLE="Sets the Maximum hop-distance.">Max-Hops</B>&#160;<A HREF="javascript:set_maxmetric(maxmetric+1)">+</A>&#160;<A HREF="javascript:if(0<maxmetric)set_maxmetric(maxmetric-1)">&ndash;</A>&#160;<INPUT ID="maxmetric" NAME="maxmetric" TYPE="text" VALUE="3" SIZE="4" ONCHANGE="set_maxmetric(this.value)">&#160;
| &#160;<B TITLE="Sets the node auto-spacer.">Auto-Spacer</B><INPUT ID="auto_declump" NAME="auto_declump" TYPE="checkbox" ONCHANGE="set_autodeclump(this.checked)" CHECKED="CHECKED">&#160;
| &#160;<B TITLE="Show Host Names.">Host Names</B><INPUT ID="show_hostnames" NAME="show_hostnames" TYPE="checkbox" ONCHANGE="set_showdesc(this.checked)" CHECKED="CHECKED">&#160;
| &#160;<A HREF="javascript:viz_save()" TITLE="Saves current settings in a cookie.">Save Settings</A>&#160;
| &#160;<A HREF="javascript:viz_reset()" TITLE="Resets Visualizer.">Reset</A></P>
</FORM></DIV>
<SPAN ID="debug" STYLE="visibility:hidden;"></SPAN>
<IFRAME ID="RSIFrame" NAME="RSIFrame" STYLE="border:0px; width:0px; height:0px; visibility:hidden;">
</IFRAME>
<SCRIPT LANGUAGE="JavaScript1.2" TYPE="text/javascript">

viz_setup("RSIFrame","main","nodes","edges");
viz_update();

</SCRIPT>
EOF
