
################################################################
# This is a generated script based on design: network_layer_bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source network_layer_bd_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# axi4stream_sinker, bandwith_reg, bandwith_reg, bandwith_reg, bandwith_reg, bandwith_reg, bandwith_reg, bandwith_reg, bandwith_reg, interface_settings, performance_debug_reg, bandwith_reg, bandwith_reg, bandwith_reg, bandwith_reg

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcu280-fsvh2892-2L-e
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name network_layer_bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axis_register_slice:1.1\
xilinx.com:ip:axis_switch:1.1\
xilinx.com:hls:ethernet_header_inserter:1.0\
xilinx.com:hls:packet_handler:1.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:hls:udp:1.0\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:hls:arp_server:1.0\
xilinx.com:hls:icmp_server:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
axi4stream_sinker\
bandwith_reg\
bandwith_reg\
bandwith_reg\
bandwith_reg\
bandwith_reg\
bandwith_reg\
bandwith_reg\
bandwith_reg\
interface_settings\
performance_debug_reg\
bandwith_reg\
bandwith_reg\
bandwith_reg\
bandwith_reg\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: icmp
proc create_hier_cell_icmp { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_icmp() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 IN_DBG

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS


  # Create pins
  create_bd_pin -dir I -type clk ap_clk
  create_bd_pin -dir I -type rst ap_rst_n
  create_bd_pin -dir O -from 191 -to 0 debug_slot_in
  create_bd_pin -dir O -from 191 -to 0 debug_slot_out
  create_bd_pin -dir I -from 31 -to 0 -type data myIpAddress_V
  create_bd_pin -dir I -type rst user_rst_n

  # Create instance: asr_icmp_in, and set properties
  set asr_icmp_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_icmp_in ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_icmp_in

  # Create instance: asr_icmp_out, and set properties
  set asr_icmp_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_icmp_out ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_icmp_out

  # Create instance: bandwith_icmp_in, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_icmp_in
  if { [catch {set bandwith_icmp_in [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_icmp_in eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_icmp_in

  # Create instance: bandwith_icmp_out, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_icmp_out
  if { [catch {set bandwith_icmp_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_icmp_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_icmp_out

  # Create instance: icmp_server_0, and set properties
  set icmp_server_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:icmp_server:1.0 icmp_server_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net asr_icmp_in_M_AXIS [get_bd_intf_pins asr_icmp_in/M_AXIS] [get_bd_intf_pins icmp_server_0/s_axis_icmp]
  connect_bd_intf_net -intf_net asr_icmp_out_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins asr_icmp_out/M_AXIS]
  connect_bd_intf_net -intf_net axis_switch_0_M01_AXIS [get_bd_intf_pins IN_DBG] [get_bd_intf_pins bandwith_icmp_in/IN_DBG]
  connect_bd_intf_net -intf_net bandwith_icmp_in_OUT_DBG [get_bd_intf_pins asr_icmp_in/S_AXIS] [get_bd_intf_pins bandwith_icmp_in/OUT_DBG]
  connect_bd_intf_net -intf_net bandwith_icmp_out_OUT_DBG [get_bd_intf_pins asr_icmp_out/S_AXIS] [get_bd_intf_pins bandwith_icmp_out/OUT_DBG]
  connect_bd_intf_net -intf_net icmp_server_0_m_axis_icmp [get_bd_intf_pins bandwith_icmp_out/IN_DBG] [get_bd_intf_pins icmp_server_0/m_axis_icmp]

  # Create port connections
  connect_bd_net -net bandwith_eth_in_debug_slot [get_bd_pins user_rst_n] [get_bd_pins bandwith_icmp_in/user_rst_n] [get_bd_pins bandwith_icmp_out/user_rst_n]
  connect_bd_net -net bandwith_icmp_in_debug_slot [get_bd_pins debug_slot_out] [get_bd_pins bandwith_icmp_in/debug_slot]
  connect_bd_net -net bandwith_icmp_out_debug_slot [get_bd_pins debug_slot_in] [get_bd_pins bandwith_icmp_out/debug_slot]
  connect_bd_net -net interface_settings_0_my_ip_address [get_bd_pins myIpAddress_V] [get_bd_pins icmp_server_0/myIpAddress_V]
  connect_bd_net -net s_aclk_0_1 [get_bd_pins ap_clk] [get_bd_pins asr_icmp_in/aclk] [get_bd_pins asr_icmp_out/aclk] [get_bd_pins bandwith_icmp_in/S_AXI_ACLK] [get_bd_pins bandwith_icmp_out/S_AXI_ACLK] [get_bd_pins icmp_server_0/ap_clk]
  connect_bd_net -net s_aresetn_0_1 [get_bd_pins ap_rst_n] [get_bd_pins asr_icmp_in/aresetn] [get_bd_pins asr_icmp_out/aresetn] [get_bd_pins bandwith_icmp_in/S_AXI_ARESETN] [get_bd_pins bandwith_icmp_out/S_AXI_ARESETN] [get_bd_pins icmp_server_0/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: arp
proc create_hier_cell_arp { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_arp() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 IN_DBG

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 macIpEncode_req_V_V

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 macIpEncode_rsp_V

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axilite


  # Create pins
  create_bd_pin -dir I -type clk ap_clk
  create_bd_pin -dir I -type rst ap_rst_n
  create_bd_pin -dir O -from 191 -to 0 debug_slot_in
  create_bd_pin -dir O -from 191 -to 0 debug_slot_out
  create_bd_pin -dir I -from 31 -to 0 -type data gatewayIP_V
  create_bd_pin -dir I -from 31 -to 0 -type data myIpAddress_V
  create_bd_pin -dir I -from 47 -to 0 -type data myMacAddress_V
  create_bd_pin -dir I -from 31 -to 0 -type data networkMask_V
  create_bd_pin -dir I -type rst user_rst_n

  # Create instance: arp_server_0, and set properties
  set arp_server_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:arp_server:1.0 arp_server_0 ]

  # Create instance: asr_arp_in, and set properties
  set asr_arp_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_arp_in ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_arp_in

  # Create instance: asr_arp_in1, and set properties
  set asr_arp_in1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_arp_in1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_arp_in1

  # Create instance: bandwith_arp_in, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_arp_in
  if { [catch {set bandwith_arp_in [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_arp_in eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_arp_in

  # Create instance: bandwith_arp_out, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_arp_out
  if { [catch {set bandwith_arp_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_arp_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_arp_out

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins s_axilite] [get_bd_intf_pins arp_server_0/s_axi_s_axilite]
  connect_bd_intf_net -intf_net arp_server_0_arpDataOut [get_bd_intf_pins arp_server_0/arpDataOut] [get_bd_intf_pins bandwith_arp_out/IN_DBG]
  connect_bd_intf_net -intf_net arp_server_0_macIpEncode_rsp_V [get_bd_intf_pins macIpEncode_rsp_V] [get_bd_intf_pins arp_server_0/macIpEncode_rsp_V]
  connect_bd_intf_net -intf_net asr_arp_in1_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins asr_arp_in1/M_AXIS]
  connect_bd_intf_net -intf_net asr_arp_in_M_AXIS [get_bd_intf_pins arp_server_0/arpDataIn] [get_bd_intf_pins asr_arp_in/M_AXIS]
  connect_bd_intf_net -intf_net axis_switch_0_M00_AXIS [get_bd_intf_pins IN_DBG] [get_bd_intf_pins bandwith_arp_in/IN_DBG]
  connect_bd_intf_net -intf_net bandwith_arp_in1_OUT_DBG [get_bd_intf_pins asr_arp_in1/S_AXIS] [get_bd_intf_pins bandwith_arp_out/OUT_DBG]
  connect_bd_intf_net -intf_net bandwith_arp_in_OUT_DBG [get_bd_intf_pins asr_arp_in/S_AXIS] [get_bd_intf_pins bandwith_arp_in/OUT_DBG]
  connect_bd_intf_net -intf_net ethernet_header_inse_0_arpTableRequest_V_V [get_bd_intf_pins macIpEncode_req_V_V] [get_bd_intf_pins arp_server_0/macIpEncode_req_V_V]

  # Create port connections
  connect_bd_net -net bandwith_arp_in_debug_slot [get_bd_pins debug_slot_in] [get_bd_pins bandwith_arp_in/debug_slot]
  connect_bd_net -net bandwith_arp_out_debug_slot [get_bd_pins debug_slot_out] [get_bd_pins bandwith_arp_out/debug_slot]
  connect_bd_net -net interface_settings_0_my_gateway [get_bd_pins gatewayIP_V] [get_bd_pins arp_server_0/gatewayIP_V]
  connect_bd_net -net interface_settings_0_my_ip_address [get_bd_pins myIpAddress_V] [get_bd_pins arp_server_0/myIpAddress_V]
  connect_bd_net -net interface_settings_0_my_ip_subnet_mask [get_bd_pins networkMask_V] [get_bd_pins arp_server_0/networkMask_V]
  connect_bd_net -net interface_settings_0_my_mac [get_bd_pins myMacAddress_V] [get_bd_pins arp_server_0/myMacAddress_V]
  connect_bd_net -net performance_debug_reg_0_user_rst_n [get_bd_pins user_rst_n] [get_bd_pins bandwith_arp_in/user_rst_n] [get_bd_pins bandwith_arp_out/user_rst_n]
  connect_bd_net -net s_aclk_0_1 [get_bd_pins ap_clk] [get_bd_pins arp_server_0/ap_clk] [get_bd_pins asr_arp_in/aclk] [get_bd_pins asr_arp_in1/aclk] [get_bd_pins bandwith_arp_in/S_AXI_ACLK] [get_bd_pins bandwith_arp_out/S_AXI_ACLK]
  connect_bd_net -net s_aresetn_0_1 [get_bd_pins ap_rst_n] [get_bd_pins arp_server_0/ap_rst_n] [get_bd_pins asr_arp_in/aresetn] [get_bd_pins asr_arp_in1/aresetn] [get_bd_pins bandwith_arp_in/S_AXI_ARESETN] [get_bd_pins bandwith_arp_out/S_AXI_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set M_AXIS_nl2eth [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_nl2eth ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $M_AXIS_nl2eth

  set M_AXIS_nl2sk [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_nl2sk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $M_AXIS_nl2sk

  set S_AXIL_nl [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXIL_nl ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {16} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S_AXIL_nl

  set S_AXIS_eth2nl [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_eth2nl ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S_AXIS_eth2nl

  set S_AXIS_sk2nl [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_sk2nl ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {16} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S_AXIS_sk2nl


  # Create ports
  set ap_clk [ create_bd_port -dir I -type clk -freq_hz 300000000 ap_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M_AXIS_nl2sk:S_AXIS_eth2nl:M_AXIS_nl2eth:S_AXIL_nl:S_AXIS_sk2nl} \
   CONFIG.ASSOCIATED_RESET {ap_rst_n} \
 ] $ap_clk
  set ap_rst_n [ create_bd_port -dir I -type rst ap_rst_n ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $ap_rst_n

  # Create instance: arp
  create_hier_cell_arp [current_bd_instance .] arp

  # Create instance: asr_eth_in, and set properties
  set asr_eth_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_eth_in ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_eth_in

  # Create instance: asr_eth_out, and set properties
  set asr_eth_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_eth_out ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_eth_out

  # Create instance: asr_headerin_out, and set properties
  set asr_headerin_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_headerin_out ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_headerin_out

  # Create instance: asr_pkth_out, and set properties
  set asr_pkth_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_pkth_out ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {3} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_pkth_out

  # Create instance: asr_udp_in, and set properties
  set asr_udp_in [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_udp_in ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {3} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_udp_in

  # Create instance: asr_udp_out, and set properties
  set asr_udp_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 asr_udp_out ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.REG_CONFIG {8} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {3} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $asr_udp_out

  # Create instance: axi4stream_sinker_0, and set properties
  set block_name axi4stream_sinker
  set block_cell_name axi4stream_sinker_0
  if { [catch {set axi4stream_sinker_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi4stream_sinker_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_switch_0, and set properties
  set axis_switch_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 axis_switch_0 ]
  set_property -dict [ list \
   CONFIG.DECODER_REG {1} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.NUM_MI {4} \
   CONFIG.NUM_SI {1} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $axis_switch_0

  # Create instance: bandwith_app_in, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_app_in
  if { [catch {set bandwith_app_in [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_app_in eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {16} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_app_in

  # Create instance: bandwith_app_out, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_app_out
  if { [catch {set bandwith_app_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_app_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {16} \
   CONFIG.TUSER_WIDTH {96} \
 ] $bandwith_app_out

  # Create instance: bandwith_eth_in, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_eth_in
  if { [catch {set bandwith_eth_in [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_eth_in eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_eth_in

  # Create instance: bandwith_eth_out, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_eth_out
  if { [catch {set bandwith_eth_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_eth_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_eth_out

  # Create instance: bandwith_headerin_out, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_headerin_out
  if { [catch {set bandwith_headerin_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_headerin_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_headerin_out

  # Create instance: bandwith_pkth_out, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_pkth_out
  if { [catch {set bandwith_pkth_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_pkth_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {3} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_pkth_out

  # Create instance: bandwith_udp_in, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_udp_in
  if { [catch {set bandwith_udp_in [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_udp_in eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {3} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_udp_in

  # Create instance: bandwith_udp_out, and set properties
  set block_name bandwith_reg
  set block_cell_name bandwith_udp_out
  if { [catch {set bandwith_udp_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bandwith_udp_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.TDEST_WIDTH {3} \
   CONFIG.TUSER_WIDTH {0} \
 ] $bandwith_udp_out

  # Create instance: eth_level_merger, and set properties
  set eth_level_merger [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 eth_level_merger ]
  set_property -dict [ list \
   CONFIG.ARB_ON_MAX_XFERS {0} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.DECODER_REG {0} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $eth_level_merger

  # Create instance: ethernet_header_inse_0, and set properties
  set ethernet_header_inse_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:ethernet_header_inserter:1.0 ethernet_header_inse_0 ]

  # Create instance: icmp
  create_hier_cell_icmp [current_bd_instance .] icmp

  # Create instance: interface_settings_0, and set properties
  set block_name interface_settings
  set block_cell_name interface_settings_0
  if { [catch {set interface_settings_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $interface_settings_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ip_level_merger, and set properties
  set ip_level_merger [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 ip_level_merger ]
  set_property -dict [ list \
   CONFIG.ARB_ON_MAX_XFERS {0} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.DECODER_REG {0} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {2} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
 ] $ip_level_merger

  # Create instance: packet_handler_0, and set properties
  set packet_handler_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:packet_handler:1.0 packet_handler_0 ]

  # Create instance: performance_debug_reg_0, and set properties
  set block_name performance_debug_reg
  set block_cell_name performance_debug_reg_0
  if { [catch {set performance_debug_reg_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $performance_debug_reg_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.CLOCK_FREQUENCY {250000000} \
 ] $performance_debug_reg_0

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {4} \
 ] $smartconnect_0

  # Create instance: udp_0, and set properties
  set udp_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:udp:1.0 udp_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {2} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIL_nl_1 [get_bd_intf_ports S_AXIL_nl] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S_AXIS_eth2nl_1 [get_bd_intf_ports S_AXIS_eth2nl] [get_bd_intf_pins bandwith_eth_in/IN_DBG]
  connect_bd_intf_net -intf_net S_AXIS_sk2nl_1 [get_bd_intf_ports S_AXIS_sk2nl] [get_bd_intf_pins bandwith_app_in/IN_DBG]
  connect_bd_intf_net -intf_net arp_server_0_macIpEncode_rsp_V [get_bd_intf_pins arp/macIpEncode_rsp_V] [get_bd_intf_pins ethernet_header_inse_0/arpTableReplay_V]
  connect_bd_intf_net -intf_net asr_arp_in1_M_AXIS [get_bd_intf_pins arp/M_AXIS] [get_bd_intf_pins eth_level_merger/S01_AXIS]
  connect_bd_intf_net -intf_net asr_eth_in1_M_AXIS [get_bd_intf_pins asr_pkth_out/M_AXIS] [get_bd_intf_pins axis_switch_0/S00_AXIS]
  connect_bd_intf_net -intf_net asr_eth_in1_M_AXIS1 [get_bd_intf_pins asr_headerin_out/M_AXIS] [get_bd_intf_pins eth_level_merger/S00_AXIS]
  connect_bd_intf_net -intf_net asr_eth_in_M_AXIS [get_bd_intf_pins asr_eth_in/M_AXIS] [get_bd_intf_pins packet_handler_0/s_axis]
  connect_bd_intf_net -intf_net asr_eth_out_M_AXIS [get_bd_intf_ports M_AXIS_nl2eth] [get_bd_intf_pins asr_eth_out/M_AXIS]
  connect_bd_intf_net -intf_net asr_udp_in_M_AXIS [get_bd_intf_pins asr_udp_in/M_AXIS] [get_bd_intf_pins udp_0/rxUdpDataIn]
  connect_bd_intf_net -intf_net asr_udp_out_M_AXIS [get_bd_intf_pins asr_udp_out/M_AXIS] [get_bd_intf_pins ip_level_merger/S00_AXIS]
  connect_bd_intf_net -intf_net axis_switch_0_M00_AXIS [get_bd_intf_pins arp/IN_DBG] [get_bd_intf_pins axis_switch_0/M00_AXIS]
  connect_bd_intf_net -intf_net axis_switch_0_M01_AXIS [get_bd_intf_pins axis_switch_0/M01_AXIS] [get_bd_intf_pins icmp/IN_DBG]
  connect_bd_intf_net -intf_net axis_switch_0_M02_AXIS [get_bd_intf_pins axi4stream_sinker_0/S_AXIS] [get_bd_intf_pins axis_switch_0/M02_AXIS]
  connect_bd_intf_net -intf_net axis_switch_0_M03_AXIS [get_bd_intf_pins axis_switch_0/M03_AXIS] [get_bd_intf_pins bandwith_udp_in/IN_DBG]
  connect_bd_intf_net -intf_net bandwith_app_in_OUT_DBG [get_bd_intf_pins bandwith_app_in/OUT_DBG] [get_bd_intf_pins udp_0/DataInApp]
  connect_bd_intf_net -intf_net bandwith_app_out_OUT_DBG [get_bd_intf_ports M_AXIS_nl2sk] [get_bd_intf_pins bandwith_app_out/OUT_DBG]
  connect_bd_intf_net -intf_net bandwith_eth_in1_OUT_DBG [get_bd_intf_pins asr_headerin_out/S_AXIS] [get_bd_intf_pins bandwith_headerin_out/OUT_DBG]
  connect_bd_intf_net -intf_net bandwith_eth_in_OUT_DBG [get_bd_intf_pins asr_eth_in/S_AXIS] [get_bd_intf_pins bandwith_eth_in/OUT_DBG]
  connect_bd_intf_net -intf_net bandwith_eth_out_OUT_DBG [get_bd_intf_pins asr_eth_out/S_AXIS] [get_bd_intf_pins bandwith_eth_out/OUT_DBG]
  connect_bd_intf_net -intf_net bandwith_pkth_out_OUT_DBG [get_bd_intf_pins asr_pkth_out/S_AXIS] [get_bd_intf_pins bandwith_pkth_out/OUT_DBG]
  connect_bd_intf_net -intf_net bandwith_udp_in_OUT_DBG [get_bd_intf_pins asr_udp_in/S_AXIS] [get_bd_intf_pins bandwith_udp_in/OUT_DBG]
  connect_bd_intf_net -intf_net bandwith_udp_out_OUT_DBG [get_bd_intf_pins asr_udp_out/S_AXIS] [get_bd_intf_pins bandwith_udp_out/OUT_DBG]
  connect_bd_intf_net -intf_net eth_level_merger_M00_AXIS [get_bd_intf_pins bandwith_eth_out/IN_DBG] [get_bd_intf_pins eth_level_merger/M00_AXIS]
  connect_bd_intf_net -intf_net ethernet_header_inse_0_arpTableRequest_V_V [get_bd_intf_pins arp/macIpEncode_req_V_V] [get_bd_intf_pins ethernet_header_inse_0/arpTableRequest_V_V]
  connect_bd_intf_net -intf_net ethernet_header_inse_0_dataOut [get_bd_intf_pins bandwith_headerin_out/IN_DBG] [get_bd_intf_pins ethernet_header_inse_0/dataOut]
  connect_bd_intf_net -intf_net icmp_M_AXIS [get_bd_intf_pins icmp/M_AXIS] [get_bd_intf_pins ip_level_merger/S01_AXIS]
  connect_bd_intf_net -intf_net ip_level_merger_M00_AXIS [get_bd_intf_pins ethernet_header_inse_0/dataIn] [get_bd_intf_pins ip_level_merger/M00_AXIS]
  connect_bd_intf_net -intf_net packet_handler_0_m_axis [get_bd_intf_pins bandwith_pkth_out/IN_DBG] [get_bd_intf_pins packet_handler_0/m_axis]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins performance_debug_reg_0/S_AXI] [get_bd_intf_pins smartconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_arp_s_axilite [get_bd_intf_pins arp/s_axilite] [get_bd_intf_pins smartconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect_interface_settings [get_bd_intf_pins interface_settings_0/S_AXI] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_udp_s_axilite [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins udp_0/s_axi_s_axilite]
  connect_bd_intf_net -intf_net udp_0_DataOutApp [get_bd_intf_pins bandwith_app_out/IN_DBG] [get_bd_intf_pins udp_0/DataOutApp]
  connect_bd_intf_net -intf_net udp_0_txUdpDataOut [get_bd_intf_pins bandwith_udp_out/IN_DBG] [get_bd_intf_pins udp_0/txUdpDataOut]

  # Create port connections
  connect_bd_net -net bandwith_app_in1_debug_slot [get_bd_pins bandwith_app_out/debug_slot] [get_bd_pins performance_debug_reg_0/PORT11]
  connect_bd_net -net bandwith_app_in_debug_slot [get_bd_pins bandwith_app_in/debug_slot] [get_bd_pins performance_debug_reg_0/PORT9]
  connect_bd_net -net bandwith_arp_in_debug_slot [get_bd_pins arp/debug_slot_in] [get_bd_pins performance_debug_reg_0/PORT2]
  connect_bd_net -net bandwith_arp_out_debug_slot [get_bd_pins arp/debug_slot_out] [get_bd_pins performance_debug_reg_0/PORT3]
  connect_bd_net -net bandwith_eth_in1_debug_slot [get_bd_pins bandwith_headerin_out/debug_slot] [get_bd_pins performance_debug_reg_0/PORT6]
  connect_bd_net -net bandwith_eth_in_debug_slot [get_bd_pins bandwith_eth_in/debug_slot] [get_bd_pins performance_debug_reg_0/PORT0]
  connect_bd_net -net bandwith_eth_out_debug_slot [get_bd_pins bandwith_eth_out/debug_slot] [get_bd_pins performance_debug_reg_0/PORT7]
  connect_bd_net -net bandwith_icmp_in_debug_slot [get_bd_pins icmp/debug_slot_out] [get_bd_pins performance_debug_reg_0/PORT4]
  connect_bd_net -net bandwith_icmp_out_debug_slot [get_bd_pins icmp/debug_slot_in] [get_bd_pins performance_debug_reg_0/PORT5]
  connect_bd_net -net bandwith_pkth_out_debug_slot [get_bd_pins bandwith_pkth_out/debug_slot] [get_bd_pins performance_debug_reg_0/PORT1]
  connect_bd_net -net bandwith_udp_in_debug_slot [get_bd_pins bandwith_udp_in/debug_slot] [get_bd_pins performance_debug_reg_0/PORT8]
  connect_bd_net -net bandwith_udp_out_debug_slot [get_bd_pins bandwith_udp_out/debug_slot] [get_bd_pins performance_debug_reg_0/PORT10]
  connect_bd_net -net interface_settings_0_my_gateway [get_bd_pins arp/gatewayIP_V] [get_bd_pins ethernet_header_inse_0/regDefaultGateway_V] [get_bd_pins interface_settings_0/my_gateway]
  connect_bd_net -net interface_settings_0_my_ip_address [get_bd_pins arp/myIpAddress_V] [get_bd_pins icmp/myIpAddress_V] [get_bd_pins interface_settings_0/my_ip_address] [get_bd_pins udp_0/myIpAddress_V]
  connect_bd_net -net interface_settings_0_my_ip_subnet_mask [get_bd_pins arp/networkMask_V] [get_bd_pins ethernet_header_inse_0/regSubNetMask_V] [get_bd_pins interface_settings_0/my_ip_subnet_mask]
  connect_bd_net -net interface_settings_0_my_mac [get_bd_pins arp/myMacAddress_V] [get_bd_pins ethernet_header_inse_0/myMacAddress_V] [get_bd_pins interface_settings_0/my_mac]
  connect_bd_net -net performance_debug_reg_0_user_rst_n [get_bd_pins arp/user_rst_n] [get_bd_pins bandwith_app_in/user_rst_n] [get_bd_pins bandwith_app_out/user_rst_n] [get_bd_pins bandwith_eth_in/user_rst_n] [get_bd_pins bandwith_eth_out/user_rst_n] [get_bd_pins bandwith_headerin_out/user_rst_n] [get_bd_pins bandwith_pkth_out/user_rst_n] [get_bd_pins bandwith_udp_in/user_rst_n] [get_bd_pins bandwith_udp_out/user_rst_n] [get_bd_pins performance_debug_reg_0/user_rst_n] [get_bd_pins icmp/user_rst_n]
  connect_bd_net -net s_aclk_0_1 [get_bd_ports ap_clk] [get_bd_pins arp/ap_clk] [get_bd_pins asr_eth_in/aclk] [get_bd_pins asr_eth_out/aclk] [get_bd_pins asr_headerin_out/aclk] [get_bd_pins asr_pkth_out/aclk] [get_bd_pins asr_udp_in/aclk] [get_bd_pins asr_udp_out/aclk] [get_bd_pins axi4stream_sinker_0/CLK] [get_bd_pins axis_switch_0/aclk] [get_bd_pins bandwith_app_in/S_AXI_ACLK] [get_bd_pins bandwith_app_out/S_AXI_ACLK] [get_bd_pins bandwith_eth_in/S_AXI_ACLK] [get_bd_pins bandwith_eth_out/S_AXI_ACLK] [get_bd_pins bandwith_headerin_out/S_AXI_ACLK] [get_bd_pins bandwith_pkth_out/S_AXI_ACLK] [get_bd_pins bandwith_udp_in/S_AXI_ACLK] [get_bd_pins bandwith_udp_out/S_AXI_ACLK] [get_bd_pins eth_level_merger/aclk] [get_bd_pins ethernet_header_inse_0/ap_clk] [get_bd_pins icmp/ap_clk] [get_bd_pins interface_settings_0/S_AXI_ACLK] [get_bd_pins ip_level_merger/aclk] [get_bd_pins packet_handler_0/ap_clk] [get_bd_pins performance_debug_reg_0/S_AXI_ACLK] [get_bd_pins smartconnect_0/aclk] [get_bd_pins udp_0/ap_clk]
  connect_bd_net -net s_aresetn_0_1 [get_bd_ports ap_rst_n] [get_bd_pins arp/ap_rst_n] [get_bd_pins asr_eth_in/aresetn] [get_bd_pins asr_eth_out/aresetn] [get_bd_pins asr_headerin_out/aresetn] [get_bd_pins asr_pkth_out/aresetn] [get_bd_pins asr_udp_in/aresetn] [get_bd_pins asr_udp_out/aresetn] [get_bd_pins axi4stream_sinker_0/RST_N] [get_bd_pins axis_switch_0/aresetn] [get_bd_pins bandwith_app_in/S_AXI_ARESETN] [get_bd_pins bandwith_app_out/S_AXI_ARESETN] [get_bd_pins bandwith_eth_in/S_AXI_ARESETN] [get_bd_pins bandwith_eth_out/S_AXI_ARESETN] [get_bd_pins bandwith_headerin_out/S_AXI_ARESETN] [get_bd_pins bandwith_pkth_out/S_AXI_ARESETN] [get_bd_pins bandwith_udp_in/S_AXI_ARESETN] [get_bd_pins bandwith_udp_out/S_AXI_ARESETN] [get_bd_pins eth_level_merger/aresetn] [get_bd_pins ethernet_header_inse_0/ap_rst_n] [get_bd_pins icmp/ap_rst_n] [get_bd_pins interface_settings_0/S_AXI_ARESETN] [get_bd_pins ip_level_merger/aresetn] [get_bd_pins packet_handler_0/ap_rst_n] [get_bd_pins performance_debug_reg_0/S_AXI_ARESETN] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins udp_0/ap_rst_n]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins eth_level_merger/s_req_suppress] [get_bd_pins ip_level_merger/s_req_suppress] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  assign_bd_address -offset 0x00004000 -range 0x00002000 -target_address_space [get_bd_addr_spaces S_AXIL_nl] [get_bd_addr_segs arp/arp_server_0/s_axi_s_axilite/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00000080 -target_address_space [get_bd_addr_spaces S_AXIL_nl] [get_bd_addr_segs interface_settings_0/S_AXI/reg0] -force
  assign_bd_address -offset 0x00001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXIL_nl] [get_bd_addr_segs performance_debug_reg_0/S_AXI/reg0] -force
  assign_bd_address -offset 0x00002000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXIL_nl] [get_bd_addr_segs udp_0/s_axi_s_axilite/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


