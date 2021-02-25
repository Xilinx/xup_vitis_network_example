
################################################################
# This is a generated script based on design: cmac_bd
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
# source bd_cmac.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# axi4lite

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.


# CHANGE DESIGN NAME HERE
variable design_name
set design_name cmac_bd

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
xilinx.com:ip:axis_clock_converter:1.1\
xilinx.com:cmac:cmac_${cmac_name}:1\   
xilinx.com:cmac:cmac_sync:1\
xilinx.com:ip:fifo_generator:13.2\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:vio:3.0\
xilinx.com:ip:xlconstant:1.1\
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
axi4lite\
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



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name
  variable cmac_name

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
  set M_AXIS [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $M_AXIS

  set S_AXILITE [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXILITE ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {14} \
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
   ] $S_AXILITE

  set S_AXIS [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS ]
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
   CONFIG.TUSER_WIDTH {16} \
   ] $S_AXIS

  set gt_ref_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_ref_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   ] $gt_ref_clk

  set gt_rx [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:gt_rtl:1.0 gt_rx ]

  set gt_tx [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 gt_tx ]


  # Create ports
  set ap_clk [ create_bd_port -dir I -type clk -freq_hz 300000000 ap_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXIS:M_AXIS:S_AXILITE} \
   CONFIG.ASSOCIATED_RESET {ap_rst_n} \
 ] $ap_clk
  set ap_rst_n [ create_bd_port -dir I -type rst ap_rst_n ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $ap_rst_n

  # Create instance: acc_kernel_tx_cdc, and set properties
  set acc_kernel_tx_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 acc_kernel_tx_cdc ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.IS_ACLK_ASYNC {1} \
   CONFIG.TDATA_NUM_BYTES {64} \
 ] $acc_kernel_tx_cdc

  # Create instance: axi4lite_0, and set properties
  set block_name axi4lite
  set block_cell_name axi4lite_0
  if { [catch {set axi4lite_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi4lite_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: cmac_0, and set properties
  set cmac_0 [ create_bd_cell -type ip -vlnv xilinx.com:cmac:cmac_${cmac_name}:1 cmac_0 ]

  # Create instance: cmac_sync_0, and set properties
  set cmac_sync_0 [ create_bd_cell -type ip -vlnv xilinx.com:cmac:cmac_sync:1 cmac_sync_0 ]
  set_property -dict [ list \
   CONFIG.SLAVE_CMAC_BASEADDR {0x00001000} \
   CONFIG.ULTRASCALE_PLUS {true} \
 ] $cmac_sync_0

  # Create instance: fifo_cmac_rx_cdc, and set properties
  set fifo_cmac_rx_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_cmac_rx_cdc ]
  set_property -dict [ list \
   CONFIG.Clock_Type_AXI {Independent_Clock} \
   CONFIG.Empty_Threshold_Assert_Value_axis {509} \
   CONFIG.Empty_Threshold_Assert_Value_rach {13} \
   CONFIG.Empty_Threshold_Assert_Value_rdch {1018} \
   CONFIG.Empty_Threshold_Assert_Value_wach {13} \
   CONFIG.Empty_Threshold_Assert_Value_wdch {1018} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {13} \
   CONFIG.Enable_TLAST {true} \
   CONFIG.FIFO_Implementation_axis {Independent_Clocks_Block_RAM} \
   CONFIG.FIFO_Implementation_rach {Independent_Clocks_Distributed_RAM} \
   CONFIG.FIFO_Implementation_rdch {Independent_Clocks_Builtin_FIFO} \
   CONFIG.FIFO_Implementation_wach {Independent_Clocks_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wdch {Independent_Clocks_Builtin_FIFO} \
   CONFIG.FIFO_Implementation_wrch {Independent_Clocks_Distributed_RAM} \
   CONFIG.Full_Threshold_Assert_Value_axis {511} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.HAS_TKEEP {true} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Input_Depth_axis {512} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TKEEP_WIDTH {64} \
   CONFIG.TSTRB_WIDTH {64} \
   CONFIG.TUSER_WIDTH {0} \
 ] $fifo_cmac_rx_cdc

  # Create instance: fifo_cmac_tx, and set properties
  set fifo_cmac_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_cmac_tx ]
  set_property -dict [ list \
   CONFIG.Clock_Type_AXI {Common_Clock} \
   CONFIG.Empty_Threshold_Assert_Value_axis {510} \
   CONFIG.Empty_Threshold_Assert_Value_rach {14} \
   CONFIG.Empty_Threshold_Assert_Value_rdch {1022} \
   CONFIG.Empty_Threshold_Assert_Value_wach {14} \
   CONFIG.Empty_Threshold_Assert_Value_wdch {1022} \
   CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
   CONFIG.Enable_TLAST {true} \
   CONFIG.FIFO_Application_Type_axis {Packet_FIFO} \
   CONFIG.FIFO_Implementation_axis {Common_Clock_Block_RAM} \
   CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_rdch {Common_Clock_Builtin_FIFO} \
   CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
   CONFIG.FIFO_Implementation_wdch {Common_Clock_Builtin_FIFO} \
   CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
   CONFIG.Full_Threshold_Assert_Value_axis {511} \
   CONFIG.Full_Threshold_Assert_Value_rach {15} \
   CONFIG.Full_Threshold_Assert_Value_wach {15} \
   CONFIG.Full_Threshold_Assert_Value_wrch {15} \
   CONFIG.HAS_TKEEP {true} \
   CONFIG.INTERFACE_TYPE {AXI_STREAM} \
   CONFIG.Input_Depth_axis {512} \
   CONFIG.Reset_Type {Asynchronous_Reset} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TKEEP_WIDTH {64} \
   CONFIG.TSTRB_WIDTH {64} \
   CONFIG.TUSER_WIDTH {0} \
 ] $fifo_cmac_tx

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {2} \
 ] $smartconnect_0

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_1

  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_2

  # Create instance: vio_0, and set properties
  set vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_0 ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_IN {8} \
   CONFIG.C_NUM_PROBE_OUT {0} \
 ] $vio_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXILITE_1 [get_bd_intf_ports S_AXILITE] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_ports S_AXIS] [get_bd_intf_pins acc_kernel_tx_cdc/S_AXIS]
  connect_bd_intf_net -intf_net acc_kernel_tx_cdc_M_AXIS [get_bd_intf_pins acc_kernel_tx_cdc/M_AXIS] [get_bd_intf_pins fifo_cmac_tx/S_AXIS]
  connect_bd_intf_net -intf_net cmac_0_LBUS2AXI [get_bd_intf_pins cmac_0/LBUS2AXI] [get_bd_intf_pins fifo_cmac_rx_cdc/S_AXIS]
  connect_bd_intf_net -intf_net cmac_0_gt_tx [get_bd_intf_ports gt_tx] [get_bd_intf_pins cmac_0/gt_tx]
  connect_bd_intf_net -intf_net cmac_s_axi [get_bd_intf_pins cmac_sync_0/s_axi] [get_bd_intf_pins smartconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net fifo_cmac_rx_cdc_M_AXIS [get_bd_intf_ports M_AXIS] [get_bd_intf_pins fifo_cmac_rx_cdc/M_AXIS]
  connect_bd_intf_net -intf_net fifo_cmac_tx_M_AXIS [get_bd_intf_pins cmac_0/AXI2LBUS] [get_bd_intf_pins fifo_cmac_tx/M_AXIS]
  connect_bd_intf_net -intf_net gt_ref_clk_1 [get_bd_intf_ports gt_ref_clk] [get_bd_intf_pins cmac_0/gt_ref_clk]
  connect_bd_intf_net -intf_net gt_rx_0_1 [get_bd_intf_ports gt_rx] [get_bd_intf_pins cmac_0/gt_rx]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins cmac_0/AXI4_STATISTICS] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins axi4lite_0/S_AXIL] [get_bd_intf_pins smartconnect_0/M01_AXI]

  # Create port connections
  connect_bd_net -net ap_rst_n_1 [get_bd_ports ap_rst_n] [get_bd_pins acc_kernel_tx_cdc/s_axis_aresetn] [get_bd_pins axi4lite_0/S_AXIL_ARESETN] [get_bd_pins cmac_0/s_axi_reset_n] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net cmac_0_CMAC_STAT_stat_rx_aligned [get_bd_pins cmac_0/CMAC_STAT_stat_rx_aligned] [get_bd_pins cmac_sync_0/cmac_stat_stat_rx_aligned]
  connect_bd_net -net cmac_0_rx_rst [get_bd_pins cmac_0/rx_rst] [get_bd_pins cmac_sync_0/usr_rx_reset] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net cmac_0_tx_rst [get_bd_pins cmac_0/tx_rst] [get_bd_pins cmac_sync_0/usr_tx_reset] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net cmac_0_usr_rx_clk [get_bd_pins cmac_0/usr_rx_clk] [get_bd_pins fifo_cmac_rx_cdc/s_aclk]
  connect_bd_net -net cmac_0_usr_tx_clk [get_bd_pins acc_kernel_tx_cdc/m_axis_aclk] [get_bd_pins cmac_0/usr_tx_clk] [get_bd_pins fifo_cmac_tx/s_aclk]
  connect_bd_net -net cmac_sync_0_cmac_aligned_sync [get_bd_pins axi4lite_0/cmac_aligned_sync] [get_bd_pins cmac_sync_0/cmac_aligned_sync] [get_bd_pins vio_0/probe_in7]
  connect_bd_net -net cmac_sync_0_rx_aligned_led [get_bd_pins axi4lite_0/rx_aligned_led] [get_bd_pins cmac_sync_0/rx_aligned_led] [get_bd_pins vio_0/probe_in3]
  connect_bd_net -net cmac_sync_0_rx_busy_led [get_bd_pins axi4lite_0/rx_busy_led] [get_bd_pins cmac_sync_0/rx_busy_led] [get_bd_pins vio_0/probe_in6]
  connect_bd_net -net cmac_sync_0_rx_data_fail_led [get_bd_pins axi4lite_0/rx_data_fail_led] [get_bd_pins cmac_sync_0/rx_data_fail_led] [get_bd_pins vio_0/probe_in5]
  connect_bd_net -net cmac_sync_0_rx_done_led [get_bd_pins axi4lite_0/rx_done_led] [get_bd_pins cmac_sync_0/rx_done_led] [get_bd_pins vio_0/probe_in4]
  connect_bd_net -net cmac_sync_0_rx_gt_locked_led [get_bd_pins axi4lite_0/rx_gt_locked_led] [get_bd_pins cmac_sync_0/rx_gt_locked_led] [get_bd_pins vio_0/probe_in2]
  connect_bd_net -net cmac_sync_0_tx_busy_led [get_bd_pins axi4lite_0/tx_busy_led] [get_bd_pins cmac_sync_0/tx_busy_led] [get_bd_pins vio_0/probe_in1]
  connect_bd_net -net cmac_sync_0_tx_done_led [get_bd_pins axi4lite_0/tx_done_led] [get_bd_pins cmac_sync_0/tx_done_led] [get_bd_pins vio_0/probe_in0]
  connect_bd_net -net s_aclk_0_1 [get_bd_ports ap_clk] [get_bd_pins acc_kernel_tx_cdc/s_axis_aclk] [get_bd_pins axi4lite_0/S_AXIL_ACLK] [get_bd_pins cmac_0/s_axi_aclk] [get_bd_pins cmac_sync_0/s_axi_aclk] [get_bd_pins fifo_cmac_rx_cdc/m_aclk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins vio_0/clk]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins fifo_cmac_rx_cdc/s_aresetn] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins cmac_sync_0/s_axi_sreset] [get_bd_pins util_vector_logic_1/Res]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_pins acc_kernel_tx_cdc/m_axis_aresetn] [get_bd_pins fifo_cmac_tx/s_aresetn] [get_bd_pins util_vector_logic_2/Res]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins cmac_sync_0/lbus_tx_rx_restart_in] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  assign_bd_address -offset 0x00001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces cmac_sync_0/s_axi] [get_bd_addr_segs cmac_0/s_axi4_lite/reg0] -force
  assign_bd_address -offset 0x00000080 -range 0x00000080 -target_address_space [get_bd_addr_spaces S_AXILITE] [get_bd_addr_segs axi4lite_0/S_AXIL/reg0] -force
  assign_bd_address -offset 0x00001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S_AXILITE] [get_bd_addr_segs cmac_0/s_axi4_lite/reg0] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x00000080 -range 0x00000080 -target_address_space [get_bd_addr_spaces cmac_sync_0/s_axi] [get_bd_addr_segs axi4lite_0/S_AXIL/reg0]


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


