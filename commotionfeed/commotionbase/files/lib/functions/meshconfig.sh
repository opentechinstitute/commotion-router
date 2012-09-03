. /etc/functions.sh

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_id_legacy
#   DESCRIPTION:  Creates a quasi-unqiue node indentifier based on MAC address.
#    PARAMETERS:  None
#-------------------------------------------------------------------------------

get_id_legacy ()
{
  local mac=$(uci_get wireless @wifi-device[0] macaddr 0)
  [ $mac = 0 ] && \
  logger -t get_id_legacy "Error! Could not get MAC from config file." && return 1

  echo $mac | awk -F ':' '{ printf("%d%d%d","0x"$4,"0x"$5,"0x"$6) }' && return 0

  logger -t get_id_legacy "Error! Could not generate node ID from MAC." && return 1
}	# ----------  end of function get_id_legacy  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_id_mac
#   DESCRIPTION:  Parse MAC address into alphanumeric string.
#    PARAMETERS:  None
#-------------------------------------------------------------------------------

get_id_mac ()
{
  #TODO: Implement 
  $DEBUG get_id_default
}	# ----------  end of function get_id_mac  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_id_hostid
#   DESCRIPTION:  Generate a 32-bit alphanumeric ID compatible w/ hostid utility
#    PARAMETERS:  None
#-------------------------------------------------------------------------------

get_id_hostid ()
{
  #TODO: Implement 
  $DEBUG get_id_default
}	# ----------  end of function get_id_hostid  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_id_uuid
#   DESCRIPTION:  Generate an ID using uuidgen
#    PARAMETERS:  None
#-------------------------------------------------------------------------------
get_id_uuid ()
{
  #TODO: Implement 
  $DEBUG get_id_default
}	# ----------  end of function get_id_uuid  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_id_default
#   DESCRIPTION:  Call a default ID generating function.
#    PARAMETERS:  None
#-------------------------------------------------------------------------------
get_id_default ()
{
  $DEBUG get_id_legacy
}	# ----------  end of function get_id_default  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_ipv4_mac
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
#get_ipv4_mac ()
#{
#  #TODO: Implement 
#}	# ----------  end of function get_ipv4_mac  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_ipv4_hash
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
#get_ipv4_hash ()
#{
#  #TODO: Implement 
#}	# ----------  end of function get_ipv4_hash  ----------

#---  FUNCTION  ----------------------------------------------------------------   
#          NAME:  echo_eval                                                     
#   DESCRIPTION:  For debugging purposes, echo all parameters passed to me, and then evaluate them.                                                                 
#    PARAMETERS:                                                                   
#       RETURNS:                                                                   
#-------------------------------------------------------------------------------   
echo_eval ()                                                                   
{                                                                                 
  echo ${@}
  return `eval ${@}`
}      # ----------  end of function logger  ----------                     

#---  FUNCTION  ----------------------------------------------------------------                   
#          NAME:  logger_eval                                                                        
#   DESCRIPTION:  For debugging purposes, log all parameters passed to me, and then evaluate them.
#    PARAMETERS:                                                                
#       RETURNS:                                                                
#-------------------------------------------------------------------------------  
logger_eval ()                                           
{                                                                               
  logger ${@}                                             
  return `eval ${@}`                                                                       
}      # ----------  end of function logger  ----------   

