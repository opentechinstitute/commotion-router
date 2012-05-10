#===============================================================================
#
#          FILE:  commotion.sh
# 
#         USAGE:  include /lib/network
# 
#   DESCRIPTION:  This file attempts to be a clean and simple implementation of 
#                 an autoconfiguring mesh network using OpenWRT's native 
#                 network configuration methods and utilities. It implements 3
#                 new interface "protocols": meshif (mesh backhaul interface), 
#                 apif (wireless access point interface), and plugif (part of a 
#                 hot-swappable ethernet implementation switching between DHCP 
#                 gateway and DHCP server for client access). Initially uses 
#                 OLSRd and IPv4, additional options for batman-adv and IPv6 
#                 forthcoming.
# 
#       AUTHOR:  Josh King
#       CREATED:  11/19/2010 02:44:44 PM EST
#       REVISION:  ---
#       LICENSE:  GPLv3
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public
# License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA
#===============================================================================

#DEBUG="echo"

#===============================================================================
# DEFAULTS
#===============================================================================

DEFAULT_MESH_SSID="commotionwireless.net"
DEFAULT_MESH_BSSID="02:CA:FF:EE:BA:BE"
DEFAULT_MESH_CHANNEL="5"
DEFAULT_MESH_BASENAME="commotion"
DEFAULT_MESH_PREFIX="5"
DEFAULT_MESH_FWZONE="mesh"
DEFAULT_AP_PREFIX="101"
DEFAULT_AP_FWZONE="ap"
DEFAULT_LAN_PREFIX="102"
DEFAULT_LAN_FWZONE="lan"
DEFAULT_SECUREAP_PREFIX="103"
DEFAULT_SECUREAP_FWZONE="lan"
DEFAULT_SECUREAP_KEY="c0MM0t10N!r0ckS!"
DEFAULT_SECUREMESH_KEY="c0MM0t10N!r0ckS!"

#===============================================================================
# SETTING FUNCTIONS
#===============================================================================

#===  FUNCTION  ================================================================
#          NAME:  set_meshif_wireless
#   DESCRIPTION:  Sets wireless of the mesh interface based on network config
#    PARAMETERS:  Config name for network.
#       RETURNS:  0 == success, 1 == failure
#===============================================================================

set_meshif_wireless() {
  local config="$1"
  local ssid=$(uci_get mesh @network[0] ssid "$DEFAULT_MESH_SSID") 
  local bssid=$(uci_get mesh @network[0] bssid "$DEFAULT_MESH_BSSID") 
  local channel=$(uci_get mesh @network[0] channel "$DEFAULT_MESH_CHANNEL") 
  local secure=$(uci_get network "$config" secure "0")
  local key=$(uci_get network "$config" key "$DEFAULT_SECUREMESH_KEY")
  local net dev

  config_cb() {
    local type="$1"
    local name="$2"
    local network device
    case "$type" in
      wifi-iface)
        network=$(uci_get wireless "$name" network)
        device=$(uci_get wireless "$name" device)
        case "$network" in
          "$config")
            net="$name"
            dev="$device"
            ;;
        esac
        ;;
    esac
  }
  config_load wireless

  [[ -n "$wiconfig" ]] && [ "$secure" = 1 ]  && \
  uci_set wireless "$wiconfig" encryption "psk2" && uci_set wireless "$wiconfig" key "$key"

  [[ -n "$wiconfig" ]] && [ "$secure" = 0 ]  && \
  uci_remove wireless "$wiconfig" encryption && uci_remove wireless "$wiconfig" key

  [[ -n "$net" ]] && [[ -n "$dev" ]] && \
  uci_set wireless "$net" ssid "$ssid" && uci_set wireless "$net" bssid "$bssid" && \
  uci_set wireless "$dev" channel "$channel" && uci_commit wireless && return 0

  logger -t set_meshif_wireless "Error! Wireless configuration for "$config" may not exist." && return 1
}

#===  FUNCTION  ================================================================
#          NAME:  set_apif_wireless
#   DESCRIPTION:  Wireless settings for the AP interface based on network config
#    PARAMETERS:  Config name for the AP network.
#       RETURNS:  0 == success, 1 == failure
#===============================================================================
set_apif_wireless() {
  local config="$1"
  local wiconfig=
  local basename=$(uci_get mesh @network[0] basename "$DEFAULT_MESH_BASENAME")
  local location=$(uci_get system @system[0] location)
  local nodeid=$(uci_get system @system[0] nodeid)
  local secure=$(uci_get network "$config" secure "0")
  local key=$(uci_get network "$config" key "$DEFAULT_SECUREAP_KEY")

  config_cb() {
    local type="$1"
    local name="$2"
    case "$type" in
      wifi-iface)
        network=$(uci_get wireless "$name" network)
        case "$network" in
          "$config")
            wiconfig="$name"
            ;;
        esac
        ;;
    esac
  }
  config_load wireless

  [[ -n "$wiconfig" ]] && [ "$secure" = 1 ]  && \
  uci_set wireless "$wiconfig" encryption "psk2" && uci_set wireless "$wiconfig" key "$key"

  [[ -n "$wiconfig" ]] && [ "$secure" = 0 ]  && \
  uci_remove wireless "$wiconfig" encryption && uci_remove wireless "$wiconfig" key

  [[ -n "$wiconfig" ]] && [[ -n "$location" ]] && \
  uci_set wireless "$wiconfig" ssid "$basename"_"$location"_"$config" && uci_commit wireless && return 0

  [[ -n "$wiconfig" ]] && [[ -z "$location" ]] && \
  uci_set wireless "$wiconfig" ssid "$basename"_"$nodeid"_"$config" && uci_commit wireless && return 0

  logger -t set_apif_wireless "Error! Wireless configuration for "$config" may not exist." && return 1
}

#===  FUNCTION  ================================================================
#          NAME:  unset_fwzone
#   DESCRIPTION:  Removes an interface from the firewall zone.
#    PARAMETERS:  1; config name of network
#       RETURNS:  0 on success
#===============================================================================

unset_fwzone() {
  local config="$1"
  
  reset_cb
  config_load firewall
  config_cb() {
    local type="$1"
    local name="$2"
    case $type in
      zone)
        local networks="$(uci_get firewall "$name" network)"
        uci_remove firewall "$name" network
        for net in $networks; do
          [ "$net" != "$config" ] && uci add_list firewall."$name".network="$net"
        done
        ;;
    esac
  }
  config_load firewall

  return 0
}
  
#===  FUNCTION  ================================================================
#          NAME:  set_fwzone
#   DESCRIPTION:  Adds an interface to the mesh firewall zone.
#    PARAMETERS:  2; config name of network and firewall zone to set it to.
#       RETURNS:  0 on success
#===============================================================================

set_fwzone() {
  local config="$1"
  local zone="$2"

  reset_cb 
  config_load firewall
  config_cb() {
    local type="$1"
    local name="$2"
    local fwname=
    case $type in
      zone)
        local fwname=$(uci_get firewall "$name" name)
        case "$fwname" in
          "$zone")
            uci add_list firewall."$name".network="$config"
            ;;
        esac
        ;;
    esac
  }
  config_load firewall

  return 0
}

#===============================================================================
# PROTOCOL HANDLERS
#===============================================================================

#===  FUNCTION  ================================================================
#          NAME:  setup_interface_meshif
#   DESCRIPTION:  The function called by OpenWRT for proto 'meshif' interfaces.
#    PARAMETERS:  2; interface and config name
#===============================================================================

setup_interface_meshif() {
  local iface="$1"
  local config="$2"

  env -i ACTION="preup" INTERFACE="$config" DEVICE="$iface" PROTO=meshif /sbin/hotplug-call "services" &
  
  local ipaddr netmask reset
  config_get_bool reset "$config" reset 1
  case "$reset" in
    1)
      local prefix=$(uci_get mesh @network[0] mesh_prefix "$DEFAULT_MESH_PREFIX")
      local mac=$(uci_get wireless @wifi-device[0] macaddr 0)
      [ $mac = 0 ] && \
      logger -t setup_interface_meshif "Error! Could not get MAC from config file."
      $DEBUG unset_fwzone "$config"
      $DEBUG set_fwzone "$config" $(uci_get mesh @network[0] mesh_zone "$DEFAULT_MESH_FWZONE")
      $DEBUG uci_commit firewall
      $DEBUG uci_set network "$config" ipaddr $( echo $mac | \
      awk -v p=$prefix -F ':' '{ printf(p".%d.%d.%d","0x"$4,"0x"$5,"0x"$6) }' )
      $DEBUG uci_set network "$config" netmask "255.0.0.0"
      $DEBUG uci_set network "$config" broadcast "255.255.255.255"
      $DEBUG uci_set network "$config" reset 0
      [ "$(uci_get_state network "$config" boot)" = 1 ] || set_meshif_wireless "$config" 
      $DEBUG uci_set_state network "$config" boot 0
      uci_commit network
      scan_interfaces
      ;;
  esac

  config_get ipaddr "$config" ipaddr
  config_get netmask "$config" netmask
  config_get bcast "$config" broadcast
  config_get dns "$config" dns
  [ -z "$ipaddr" ] || $DEBUG ifconfig "$iface" "$ipaddr" netmask "$netmask" broadcast "${bcast:-+}"
  [ -z "$dns" ] || add_dns "$config" $dns

  config_get type "$config" TYPE
  [ "$type" = "alias" ] && return 0

  env -i ACTION="ifup" INTERFACE="$config" DEVICE="$iface" PROTO=meshif RESET="$reset" /sbin/hotplug-call "iface" &
}

#===  FUNCTION  ================================================================
#          NAME:  coldplug_interface_meshif
#   DESCRIPTION:  Early loading of meshif wireless configuration.
#    PARAMETERS:  1; Config name of interface
#===============================================================================

coldplug_interface_meshif() {
  local config="$1"
  local reset=0
  local wireless=0
  local ifname ifnames

  [ "$(config_get_bool reset "$config" reset 1)" = 0 ] && return 0

  $DEBUG config_get type "$config" TYPE
  [ "$type" = "alias" ] && return 0
  [ "$type" = "bridge" ] && \
  $DEBUG config_get ifnames "$config" ifnames
  $DEBUG config_get ifname "$config" ifname
  for ifn in $ifname $ifnames; do 
    $DEBUG cat /proc/net/wireless | grep -q "$ifn"
    [ "$?" = "0" ] && wireless=1
  done
  [ "$wireless" = "1" ] && $DEBUG set_meshif_wireless "$config" && $DEBUG /sbin/wifi 
  $DEBUG uci_set_state network "$config" boot 1
  $DEBUG setup_interface_meshif "$config"
}

#===  FUNCTION  ================================================================
#          NAME:  stop_interface_meshif
#   DESCRIPTION:  Stops meshif interfaces, calls postdown service hooks.
#    PARAMETERS:  1; Config name of interface
#===============================================================================

stop_interface_meshif() {
  local config="$1"
  local ifname=
  
  config_get ifname "$config" ifname
  env -i ACTION="postdown" INTERFACE="$config" DEVICE="$iface" PROTO=meshif /sbin/hotplug-call "services" &
}

#===  FUNCTION  ================================================================
#          NAME:  setup_interface_apif
#   DESCRIPTION:  The function called by OpenWRT for proto 'apif' interfaces.
#    PARAMETERS:  2; interface and config name
#===============================================================================

setup_interface_apif() {
  local iface="$1"
  local config="$2"
  
  env -i ACTION="preup" INTERFACE="$config" DEVICE="$iface" PROTO=apif /sbin/hotplug-call "services" &

  local ipaddr netmask reset initialized
  config_get_bool reset "$config" reset 1
  case "$reset" in
    1)
      local prefix
      case "$(uci_get network "$config" secure 0)" in
        0)
          $DEBUG unset_fwzone "$config"
          $DEBUG set_fwzone "$config" $(uci_get mesh @network[0] ap_zone "$DEFAULT_AP_FWZONE")
          $DEBUG uci_commit firewall
          prefix=$(uci_get mesh @network[0] ap_prefix "$DEFAULT_AP_PREFIX")
          ;;
        1)
          $DEBUG unset_fwzone "$config"
          $DEBUG set_fwzone "$config" $(uci_get mesh @network[0] secureap_zone "$DEFAULT_SECUREAP_FWZONE")
          $DEBUG uci_commit firewall
          prefix=$(uci_get mesh @network[0] secureap_prefix "$DEFAULT_SECUREAP_PREFIX")
          ;;
      esac
      local mac=$(uci_get wireless @wifi-device[0] macaddr 0)
      [ $mac = 0 ] && \
      logger -t setup_interface_apif "Error! Could not get MAC from config file."
      $DEBUG uci_set network "$config" ipaddr $( echo $mac | \
      awk -v p=$prefix -F ':' '{ printf(p".%d.%d.1","0x"$5,"0x"$6) }' )
      $DEBUG uci_set network "$config" netmask "255.255.255.0"
      $DEBUG uci_set network "$config" broadcast $( echo $mac | \
      awk -v p=$prefix -F ':' '{ printf(p".%d.%d.255","0x"$5,"0x"$6) }' )
      $DEBUG uci_set network "$config" reset 0
      [ "$(uci_get_state network "$config" boot)" = 1 ] || set_apif_wireless "$config"
      $DEBUG uci_set_state network "$config" boot 0
      uci_commit network
      scan_interfaces
      ;;
  esac

  config_get ipaddr "$config" ipaddr
  config_get netmask "$config" netmask
  config_get bcast "$config" broadcast
  config_get dns "$config" dns
  [ -z "$ipaddr" ] || $DEBUG ifconfig "$iface" "$ipaddr" netmask "$netmask" broadcast "${bcast:-+}"
  [ -z "$dns" ] || add_dns "$config" $dns

  config_get type "$config" TYPE
  [ "$type" = "alias" ] && return 0
      
  env -i ACTION="ifup" INTERFACE="$config" DEVICE="$iface" PROTO=apif RESET="$reset" /sbin/hotplug-call "iface" &
}

#===  FUNCTION  ================================================================
#          NAME:  coldplug_interface_apif
#   DESCRIPTION:  Early loading of apif wireless configuration.
#    PARAMETERS:  1; Config name of interface
#===============================================================================

coldplug_interface_apif() {
  local config="$1"
  local reset=0

  [ "$(config_get_bool reset "$config" reset 1)" = 0 ] && return 0
  $DEBUG config_get type "$config" TYPE
  [ "$type" = "alias" ] && return 0
  [ "$type" = "bridge" ] && \
  $DEBUG config_get ifnames "$config" ifnames
  $DEBUG config_get ifname "$config" ifname
  for ifn in $ifname $ifnames; do 
    $DEBUG cat /proc/net/wireless | grep -q "$ifn"
    [ "$?" = "0" ] && wireless=1
  done
  [ "$wireless" = "1" ] && $DEBUG set_apif_wireless "$config" && $DEBUG /sbin/wifi 
  $DEBUG uci_set_state network "$config" boot 1
  $DEBUG setup_interface_apif "$ifname" "$config"
}

#===  FUNCTION  ================================================================
#          NAME:  stop_interface_apif
#   DESCRIPTION:  Stops apif interfaces, calls postdown service hooks.
#    PARAMETERS:  1; Config name of interface
#===============================================================================

stop_interface_apif() {
  local config="$1"
  local ifname=
  
  config_get ifname "$config" ifname
  env -i ACTION="postdown" INTERFACE="$config" DEVICE="$iface" PROTO=apif /sbin/hotplug-call "services" &
}

#===  FUNCTION  ================================================================
#          NAME:  setup_interface_plugif
#   DESCRIPTION:  The function called by OpenWRT for proto 'plugif' interfaces.
#    PARAMETERS:  2; interface and config name
#===============================================================================

setup_interface_plugif() {
  local iface="$1"
  local config="$2"
      
  env -i ACTION="preup" INTERFACE="$config" DEVICE="$iface" PROTO=plugif /sbin/hotplug-call "services" &

  # kill running udhcpc instance                                                                            
  local pidfile="/var/run/dhcp-${iface}.pid"                                                                
  [ -e "$pidfile" ] && \
  $DEBUG service_kill udhcpc "$pidfile"                                                                            

  #Attempt to acquire address.
  local ipaddr netmask hostname proto1 clientid vendorid broadcast                                          
  config_get ipaddr "$config" ipaddr                                                                        
  config_get netmask "$config" netmask                            
  config_get hostname "$config" hostname                          
  config_get proto1 "$config" proto                               
  config_get clientid "$config" clientid                          
  config_get vendorid "$config" vendorid                          
  config_get_bool broadcast "$config" broadcast 0                 
                                                                     
  [ -z "$ipaddr" ] || $DEBUG ifconfig "$iface" "$ipaddr" ${netmask:+netmask "$netmask"}
  $DEBUG unset_fwzone "$config"
  $DEBUG set_fwzone "$config" $(uci_get mesh @network[0] wan_zone "wan")
                                                                                                
  # don't stay running in background.
  local dhcpopts="-n -q"                                                         
  [ "$broadcast" = 1 ] && broadcast="-O broadcast" || broadcast=                                          
                                                                                                                               
	$DEBUG eval udhcpc -i "$iface" \
		${ipaddr:+-r $ipaddr} \
		${hostname:+-H $hostname} \
		${clientid:+-c $clientid} \
		${vendorid:+-V $vendorid} \
		-p "$pidfile" $broadcast \
		${dhcpopts:- -O rootpath -R &}

  case "$?" in
    1)
      local prefix=$(uci_get mesh @network[0] lan_prefix "$DEFAULT_LAN_PREFIX")
      local mac=$(uci_get wireless @wifi-device[0] macaddr 0)
      [ $mac = 0 ] && \
      logger -t setup_interface_apif "Error! Could not get MAC from config file."
      $DEBUG uci_set_state network "$config" ipaddr $( echo $mac | \
      awk -v p=$prefix -F ':' '{ printf(p".%d.%d.1","0x"$5,"0x"$6) }' )
      $DEBUG uci_set_state network "$config" netmask "255.255.255.0"
      $DEBUG uci_set_state network "$config" broadcast $( echo $mac | \
      awk -v p=$prefix -F ':' '{ printf(p".%d.%d.255","0x"$5,"0x"$6) }' )
      local ipaddr="$(uci_get_state network "$config" ipaddr)"
      local netmask="$(uci_get_state network "$config" netmask)"
      local broadcast="$(uci_get_state network "$config" broadcast)"
      local dns="$(uci_get_state network "$config" dns)"
      [ -z "$ipaddr" ] || ifconfig "$iface" inet "$ipaddr" netmask "$netmask" broadcast "${broadcast:-+}"
      [ -z "$dns" ] || add_dns "$config" $dns
      
      $DEBUG unset_fwzone "$config"
      $DEBUG set_fwzone "$config" $(uci_get mesh @network[0] lan_zone "$DEFAULT_LAN_FWZONE")
      $DEBUG uci_commit firewall
      $DEBUG uci_set_state network "$config" plug "1"
      ;;
    0)
      $DEBUG uci_set_state network "$config" plug "0"
      $DEBUG uci_commit firewall
      ;;
  esac
  env -i ACTION="ifup" INTERFACE="$config" DEVICE="$iface" PROTO=plugif /sbin/hotplug-call "iface" &
}

#===  FUNCTION  ================================================================
#          NAME:  stop_interface_plugif
#   DESCRIPTION:  Stops plugif interfaces, clears configs.
#    PARAMETERS:  1; Config name of interface
#===============================================================================

stop_interface_plugif() {
  local config="$1"
  local ifname=
  
  #Remove from firewall config.
  $DEBUG unset_fwzone "$config"
  $DEBUG /etc/init.d/firewall restart

  #Reset network and udhcpc state.
  config_get ifname "$config" ifname

  local lock="/var/lock/dhcp-${ifname}"
  [ -f "$lock" ] && lock -u "$lock"

  remove_dns "$config"

  local pidfile="/var/run/dhcp-${ifname}.pid"
  local pid="$(cat "$pidfile" 2>/dev/null)"
  [ -d "/proc/$pid" ] && {
    grep -qs udhcpc "/proc/$pid/cmdline" && $DEBUG kill -TERM $pid && \
      while grep -qs udhcpc "/proc/$pid/cmdline"; do sleep 1; done
    $DEBUG rm -f "$pidfile"
  }

  uci -P /var/state revert "network.$config"
  
  env -i ACTION="postdown" INTERFACE="$config" DEVICE="$iface" PROTO=plugif /sbin/hotplug-call "services" &
}
