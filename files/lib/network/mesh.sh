#===============================================================================
#
#          FILE:  mesh.sh
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
#        AUTHOR:  Josh King
#       CREATED:  11/19/2010 02:44:44 PM EST
#      REVISION:  ---
#===============================================================================

#DEBUG="echo"

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

#===  FUNCTION  ================================================================
#          NAME:  _hex2dec
#   DESCRIPTION:  A utility function for turning MAC addresses into IPv4 stanzas
#    PARAMETERS:  2, a MAC address and an argument to the 'cut' utility
#       RETURNS:  IPv4 triad
#===============================================================================

_hex2dec() {
  local mac=$1
  local i=$2
  let x=0x$(echo $mac | cut $i)
  echo $x
}

#===  FUNCTION  ================================================================
#          NAME:  _iface2ipv4_meshif
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================

_iface2ipv4_meshif() {
  local iface=$1
  ifconfig "$iface" 2>/dev/null >/dev/null && {
    local mac=`ifconfig "$iface" | grep 'Link encap:'| awk '{ print $5}'`;
    local prefix=$(uci_get mesh network mesh_prefix "5")
    echo ""$prefix"."$(_hex2dec $mac -c10-11)"."$(_hex2dec $mac -c13-14)"."$(_hex2dec $mac -c16-17)""
    return 0
  }
  return 1
}
  
#===  FUNCTION  ================================================================
#          NAME:  _iface2ipv4_apif
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
_iface2ipv4_apif() {
  local iface=$1
  local offset=$2
  ifconfig "$iface" 2>/dev/null >/dev/null && {
    local mac=`ifconfig "$iface" | grep 'Link encap:'| awk '{ print $5}'`;
    local prefix=$(uci_get mesh network ap_prefix "101")
    echo ""$prefix"."$(_hex2dec $mac -c13-14)"."$(_hex2dec $mac -c16-17)".$((1 + ${offset:- 0}))"
    return 0
  }
  return 1
}

#===  FUNCTION  ================================================================
#          NAME:  _iface2ipv4_plugif
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
_iface2ipv4_plugif() {
  local iface=$1
  local offset=$2
  ifconfig "$iface" 2>/dev/null >/dev/null && {
    local mac=`ifconfig "$iface" | grep 'Link encap:'| awk '{ print $5}'`;
    local prefix=$(uci_get mesh network ap_prefix "102")
    echo ""$prefix"."$(_hex2dec $mac -c13-14)"."$(_hex2dec $mac -c16-17)".$((1 + ${offset:- 0}))"
    return 0
  }
  return 1
}


#===  FUNCTION  ================================================================
#          NAME:  _dhcp_calc
#   DESCRIPTION:  Calculates IPv4 range values suitable for dnsmasq config.
#    PARAMETERS:  DHCP server IPv4 address
#       RETURNS:  Suitable 'limit' value for dnsmasq config
#===============================================================================

_dhcp_calc() {
  local ip="$1"
  local res=0

  while [ -n "$ip" ]; do
    part="${ip%%.*}"
    res="$(($res * 256))"
    res="$(($res + $part))"
    [ "${ip%.*}" != "$ip" ] && ip="${ip#*.}" || ip=
  done
  echo "$res"
} 

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
  local ssid=$(uci_get mesh network ssid "commotion-mesh") 
  local channel=$(uci_get mesh network channel "5") 
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

  [[ -n "$net" ]] && [[ -n "$dev" ]] && uci_set wireless "$net" ssid "$ssid" && uci_set wireless "$dev" channel "$channel" && uci_commit wireless && return 0
  logger -t set_apif_wireless "Error! Wireless configuration for "$config" may not exist." && return 1
}


#===  FUNCTION  ================================================================
#          NAME:  set_apif_wireless
#   DESCRIPTION:  Wireless settings for the AP interface based on network config
#    PARAMETERS:  Config name for the AP network.
#       RETURNS:  0 == success, 1 == failure
#===============================================================================
set_apif_wireless() {
  local iface="$1"
  local config="$2"
  local wiconfig=
  local base=$(uci_get mesh network base "commotion")
  local location=$(uci_get mesh node location)
  ifconfig "$iface" 2>/dev/null >/dev/null && {
    local mac=`ifconfig "$iface" | grep 'Link encap:'| awk '{ print $5}'`;
  } || logger -t set_apif_wireless "Error! Interface "$iface" doesn't exist!"; return 1

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
  [[ -n "$wiconfig" ]] && [[ -n "$location" ]] && uci_set wireless "$wiconfig" ssid "$base"-ap_"$location" && uci_commit wireless && return 0
  [[ -n "$wiconfig" ]] && [[ -z "$location" ]] && uci_set wireless "$wiconfig" ssid "$base"-ap_"$(_hex2dec $mac -c10-11)"_"$(_hex2dec $mac -c13-14)"_"$(_hex2dec $mac -c16-17)" && uci_commit wireless && return 0
  logger -t set_apif_wireless "Error! Wireless configuration for "$config" may not exist." && return 1
}


#===  FUNCTION  ================================================================
#          NAME:  unset_meshif_fwzone
#   DESCRIPTION:  Removes an interface from the mesh firewall zone.
#    PARAMETERS:  1; config name of network
#       RETURNS:  0 on success
#===============================================================================

unset_meshif_fwzone() {
  local config="$1"
  
  config_load firewall
  config_cb() {
    local type="$1"
    local name="$2"
    case $type in
      zone)
        local oldnetworks=
        config_get oldnetworks "$name" network  
        local newnetworks=
        for net in $(sort_list "$oldnetworks" "$config"); do
          list_remove newnetworks "$net"
        done
        uci_set firewall "$name" network "$newnetworks"
        ;;
    esac
  }
  config_load firewall

  uci_commit firewall && return 0
}
  
#===  FUNCTION  ================================================================
#          NAME:  set_meshif_fwzone
#   DESCRIPTION:  Adds an interface to the mesh firewall zone.
#    PARAMETERS:  1; config name of network
#       RETURNS:  0 on success
#===============================================================================

set_meshif_fwzone() {
  local config="$1"
  local zone=$(uci_get mesh network mesh_zone "mesh")

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
            local oldnetworks=
            config_get oldnetworks "$name" network  
            local newnetworks=
            for net in $(sort_list "$oldnetworks" "$config"); do
              append newnetworks "$net"
            done
            uci_set firewall "$name" network "$newnetworks"
            ;;
        esac
        ;;
    esac
  }
  config_load firewall

  uci_commit firewall && return 0
}

#===  FUNCTION  ================================================================
#          NAME:  unset_apif_fwzone
#   DESCRIPTION:  Removes an interface from the ap firewall zone.
#    PARAMETERS:  1; config name of network
#       RETURNS:  0 on success
#===============================================================================

unset_apif_fwzone() {
  local config="$1"
 
  config_load firewall
  config_cb() {
    local type="$1"
    local name="$2"
    local fwname=
    case $type in
      zone)
        local oldnetworks=
        config_get oldnetworks "$name" network  
        local newnetworks=
        for net in $(sort_list "$oldnetworks" "$config"); do
          list_remove newnetworks "$net"
        done
        uci_set firewall "$name" network "$newnetworks"
        ;;
    esac
  }
  config_load firewall

  uci_commit firewall && return 0
}
  
#===  FUNCTION  ================================================================
#          NAME:  set_apif_fwzone
#   DESCRIPTION:  Adds an interface to the ap firewall zone.
#    PARAMETERS:  1; config name of network
#       RETURNS:  0 on success
#===============================================================================

set_apif_fwzone() {
  local config="$1"
  local zone=$(uci_get mesh network ap_zone "ap")

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
            local oldnetworks=
            config_get oldnetworks "$name" network  
            local newnetworks=
            for net in $(sort_list "$oldnetworks" "$config"); do
              append newnetworks "$net"
            done
            uci_set firewall "$name" network "$newnetworks"
            ;;
        esac
        ;;
    esac
  }
  config_load firewall

  uci_commit firewall && return 0
}

#===  FUNCTION  ================================================================
#          NAME:  unset_plugif_fwzone
#   DESCRIPTION:  Removes an interface from the plug firewall zone.
#    PARAMETERS:  1; config name of network
#       RETURNS:  0 on success
#===============================================================================

unset_plugif_fwzone() {
  local config="$1"

  config_load firewall
  config_cb() {
    local type="$1"
    local name="$2"
    local fwname=
    case $type in
      zone)
        local oldnetworks=
        config_get oldnetworks "$name" network  
        local newnetworks=
        for net in $(sort_list "$oldnetworks" "$config"); do
          list_remove newnetworks "$net"
        done
        uci_set firewall "$name" network "$newnetworks"
        ;;
    esac
  }
  config_load firewall

  uci_commit firewall && return 0
}
  
#===  FUNCTION  ================================================================
#          NAME:  set_plugif_fwzone_lan
#   DESCRIPTION:  Adds a pluggable interface to the lan firewall zone.
#    PARAMETERS:  1; config name of network
#       RETURNS:  0 on success
#===============================================================================

set_plugif_fwzone_lan() {
  local config="$1"
  local zone="lan"
  local zone=$(uci_get mesh network lan_zone "lan")

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
            local oldnetworks=
            config_get oldnetworks "$name" network  
            local newnetworks=
            for net in $(sort_list "$oldnetworks" "$config"); do
              append newnetworks "$net"
            done
            uci_set firewall "$name" network "$newnetworks"
            ;;
        esac
        ;;
    esac
  }
  config_load firewall

  uci_commit firewall && return 0
}

#===  FUNCTION  ================================================================
#          NAME:  set_plugif_fwzone_wan
#   DESCRIPTION:  Adds a pluggable interface to the wan firewall zone.
#    PARAMETERS:  1; config name of network
#       RETURNS:  0 on success
#===============================================================================

set_plugif_fwzone_wan() {
  local config="$1"
  local zone=$(uci_get mesh network wan_zone "wan")

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
            local oldnetworks=
            config_get oldnetworks "$name" network  
            local newnetworks=
            for net in $(sort_list "$oldnetworks" "$config"); do
              append newnetworks "$net"
            done
            uci_set firewall "$name" network "$newnetworks"
            ;;
        esac
        ;;
    esac
  }
  config_load firewall

  uci_commit firewall && return 0
}
#===  FUNCTION  ================================================================
#          NAME:  set_olsrd_if
#   DESCRIPTION:  Sets the interface stanza for the olsrd config
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================

set_olsrd_if() {
  local config="$1"
  config_cb() {
    local type="$1"
    local name="$2"

    case $type in
      Interface)
        local oldifaces=
        config_get oldifaces "$name" interface  
        local newifaces=
        for dev in $(sort_list "$oldifaces" "$config"); do
          append newifaces "$dev"
        done
        uci_set olsrd "$name" interface "$newifaces"
        ;;
    esac
  }
  config_load olsrd

  uci_commit olsrd
}


#===  FUNCTION  ================================================================
#          NAME:  unset_olsrd_if
#   DESCRIPTION:  Unsets the interface stanza for the olsrd config
#    PARAMETERS:  config name of the interface to remove
#       RETURNS:  
#===============================================================================

unset_olsrd_if() {
  local config="$1"
  
  config_load olsrd
  config_cb() {
    local type="$1"
    local name="$2"

    case $type in
      Interface)
        config_get oldifaces "$name" interface  
        local newifaces=
        for dev in $(sort_list "$oldifaces" "$config"); do
          list_remove newifaces "$dev"
        done
        uci_set olsrd "$name" interface "$newifaces"
        ;;
    esac
  }
  config_load olsrd

  uci_commit olsrd && return 0
}

#===  FUNCTION  ================================================================
#          NAME:  set_olsrd_if
#   DESCRIPTION:  Sets the interface stanza for the olsrd config
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================

set_olsrd_if() {
  local config="$1"
  config_cb() {
    local type="$1"
    local name="$2"

    case $type in
      Interface)
        config_get oldifaces "$name" interface  
        local newifaces=
        for dev in $(sort_list "$oldifaces" "$config"); do
          append newifaces "$dev"
        done
        uci_set olsrd "$name" interface "$newifaces"
        ;;
    esac
  }
  config_load olsrd

  uci_commit olsrd
}

#===  FUNCTION  ================================================================
#          NAME:  unset_olsrd_hna4
#   DESCRIPTION:  Unset HNA4 stanza in olsrd config
#    PARAMETERS:  1; IPv4 address of network to unset
#       RETURNS:  0 on success, 1 on failure
#===============================================================================

unset_olsrd_hna4() {
  local config=$1
  
  uci_remove olsrd "$config"
        
  uci_commit olsrd && return 0
}

#===  FUNCTION  ================================================================
#          NAME:  set_olsrd_hna4
#   DESCRIPTION:  Set HNA4 stanza in olsrd config
#    PARAMETERS:  2; IPv4 address and netmask to set
#       RETURNS:  0 on success, 1 on failure
#===============================================================================

set_olsrd_hna4() {
  local ipv4addr=$1
  local netmask=$2
  local config=$3

  #Remove duplicates  
  #unset_olsrd_hna4 ipv4addr

  uci_add olsrd Hna4 "$config" 
  uci_set olsrd @Hna4[-1] netaddr "$ipv4addr"
  uci_set olsrd @Hna4[-1] netmask "$netmask"

  uci_commit olsrd && return 0
} 

#===  FUNCTION  ================================================================
#          NAME:  unset_dnsmasq_if
#   DESCRIPTION:  Unset dnsmasq DHCP settings
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================

unset_dnsmasq_if() {
  local config="$1"
 
  #For some reason requires pre-load to parse options. 
  config_load dhcp
  config_cb() {
    local type="$1"
    local name="$2"
    local interface=
  
    case "$type" in
      dhcp) 
        config_get interface "$name" interface 
        case "$interface" in
          "$config")
            uci_remove dhcp "$name"
            ;; 
        esac
        ;;
    esac
  }
  config_load dhcp
  
  uci_add dhcp dhcp 
  uci_set dhcp @dhcp[-1] interface "$config"
  uci_set dhcp @dhcp[-1] ignore "1"
  uci_commit dhcp && return 0
}

#===  FUNCTION  ================================================================
#          NAME:  set_dnsmasq_if
#   DESCRIPTION:  Set dnsmasq DHCP settings
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================

set_dnsmasq_if() {
  local config="$1"
  #local ipv4addr="$2"
  
  #Possible race condition causes this check to create an erroneous interface.
  #unset_dnsmasq_if
  
  config_cb() {
    local type="$1"
    local name="$2"
    local interface=
  
    case "$type" in
      dhcp) 
        config_get interface "$name" interface 
        case "$interface" in
          "$config")
            uci_set dhcp "$name" interface "$config"
            uci_set dhcp "$name" start "2"
            uci_set dhcp "$name" limit "252"
            uci_set dhcp "$name" leasetime "12h"
            uci_set dhcp "$name" ignore "0"
            ;; 
        esac
    esac
  }
  config_load dhcp
      
  uci_commit dhcp && return 0
}

#===============================================================================
# PROTOCOL HANDLERS
#===============================================================================

#===  FUNCTION  ================================================================
#          NAME:  setup_interface_meshif
#   DESCRIPTION:  The function called by OpenWRT for proto 'meshif' interfaces.
#    PARAMETERS:  2; config name and interface
#       RETURNS:  
#===============================================================================

setup_interface_meshif() {
  local iface="$1"
  local config="$2"
  
  local ipaddr netmask reset
  config_get_bool reset "$config" reset 1
  case "$reset" in
    1)
      local ipv4=$(_iface2ipv4_meshif "$iface")    
      $DEBUG set_olsrd_if "$config"
      $DEBUG set_meshif_wireless "$config"
      $DEBUG set_meshif_fwzone "$config"
      $DEBUG uci_set network "$config" ipaddr "$ipv4"
      $DEBUG uci_set network "$config" netmask "255.0.0.0"
      $DEBUG uci_set network "$config" broadcast "255.255.255.255"
      $DEBUG uci_set network "$config" reset 0
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

  env -i ACTION="ifup" INTERFACE="$config" DEVICE="$iface" PROTO=meshif /sbin/hotplug-call "iface" &
}

#===  FUNCTION  ================================================================
#          NAME:  setup_interface_apif
#   DESCRIPTION:  The function called by OpenWRT for proto 'apif' interfaces.
#    PARAMETERS:  2; config name and interface
#       RETURNS:  
#===============================================================================

setup_interface_apif() {
  local iface="$1"
  local config="$2"
  
  local ipaddr netmask reset
  config_get_bool reset "$config" reset 1
  case "$reset" in
    1)
      local ipv4=$(_iface2ipv4_apif "$iface")    
      $DEBUG unset_olsrd_hna4 "$config"
      $DEBUG set_olsrd_hna4 "$(_iface2ipv4_apif "$iface" -1)" "255.255.255.0" "$config"
      $DEBUG set_apif_wireless "$iface" "$config"
      $DEBUG set_dnsmasq_if "$config"
      $DEBUG set_apif_fwzone "$config"
      $DEBUG uci_set network "$config" ipaddr "$ipv4"
      $DEBUG uci_set network "$config" netmask "255.255.255.0"
      $DEBUG uci_set network "$config" broadcast "$(_iface2ipv4_apif "$iface" 254)"
      $DEBUG uci_set network "$config" reset 0
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

  env -i ACTION="ifup" INTERFACE="$config" DEVICE="$iface" PROTO=apif /sbin/hotplug-call "iface" &
}


#===  FUNCTION  ================================================================
#          NAME:  setup_interface_plugif
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================

setup_interface_plugif() {
  local iface="$1"
  local config="$2"

  # kill running udhcpc instance                                                                            
  local pidfile="/var/run/dhcp-${iface}.pid"                                                                
  $DEBUG service_kill udhcpc "$pidfile"                                                                            

  $DEBUG unset_dnsmasq_if "$config"
  $DEBUG /etc/init.d/dnsmasq restart
  
  udhcpc -i eth1 -n -q -R
  case "$?" in
    1)
      $DEBUG uci_set_state network "$config" ipaddr "$(_iface2ipv4_plugif "$iface")"
      $DEBUG uci_set_state network "$config" netmask "255.255.255.0"
      $DEBUG uci_set_state network "$config" broadcast "$(_iface2ipv4_plugif "$iface" 254)"
      local ipaddr="$(uci_get_state network "$config" ipaddr)"
      local netmask="$(uci_get_state network "$config" netmask)"
      local broadcast="$(uci_get_state network "$config" broadcast)"
      local dns="$(uci_get_state network "$config" dns)"
      [ -z "$ipaddr" ] || ifconfig "$iface" inet "$ipaddr" netmask "$netmask" broadcast "${broadcast:-+}"
      [ -z "$dns" ] || add_dns "$config" $dns
      
      $DEBUG set_plugif_fwzone_lan "$config"
      $DEBUG unset_olsrd_hna4 "$config"
      $DEBUG set_olsrd_hna4 "$(_iface2ipv4_plugif "$iface" -1)" "$netmask" "$config"
      $DEBUG /etc/init.d/olsrd restart
      $DEBUG set_dnsmasq_if "$config"
      $DEBUG /etc/init.d/dnsmasq restart
      env -i ACTION="ifup" INTERFACE="$config" DEVICE="$iface" PROTO=plugif /sbin/hotplug-call "iface" &
      ;;
    0)
      local ipaddr netmask hostname proto1 clientid vendorid broadcast                                          
      config_get ipaddr "$config" ipaddr                                                                        
      config_get netmask "$config" netmask                            
      config_get hostname "$config" hostname                          
      config_get proto1 "$config" proto                               
      config_get clientid "$config" clientid                          
      config_get vendorid "$config" vendorid                          
      config_get_bool broadcast "$config" broadcast 0                 
                                                                     
      [ -z "$ipaddr" ] || \                                           
      $DEBUG ifconfig "$iface" "$ipaddr" ${netmask:+netmask "$netmask"}

      set_plugif_fwzone_wan "$config"
                                                                                                
      # don't stay running in background if dhcp is not the main proto on the interface (e.g. when using pptp)
      local dhcpopts="-n -q"                                                         
      [ "$broadcast" = 1 ] && broadcast="-O broadcast" || broadcast=                                          
                                                                                                                               
      eval udhcpc -t 0 -i "$iface" \                                                                   
      ${ipaddr:+-r $ipaddr} \                                                                         
      ${hostname:+-H $hostname} \                                                                     
      ${clientid:+-c $clientid} \                                                                     
      ${vendorid:+-V $vendorid} \                                                                     
      -b -p "$pidfile" $broadcast \                                                                   
      ${dhcpopts:- -O rootpath -R &}
      ;;
  esac
}


#===  FUNCTION  ================================================================
#          NAME:  stop_interface_plugif
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================

stop_interface_plugif() {
  local config="$1"
  local ifname=
  
  #Remove from OLSRd config.
  config_get ifname "$config" ifname
  $DEBUG unset_olsrd_hna4 "$(_iface2ipv4_plugif "$ifname" -1)"
  $DEBUG /etc/init.d/olsrd restart

  #Remove from dnsmasq config.
  $DEBUG unset_dnsmasq_if "$config"
  $DEBUG /etc/init.d/dnsmasq restart
  
  #Remove from firewall config.
  $DEBUG unset_plugif_fwzone "$config"
  $DEBUG /etc/init.d/firewall restart

  #Reset network and udhcpc state.
  local ifname
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
  
  env -i ACTION="ifdown" INTERFACE="$config" DEVICE="$iface" PROTO=plugif /sbin/hotplug-call "iface" &
}
