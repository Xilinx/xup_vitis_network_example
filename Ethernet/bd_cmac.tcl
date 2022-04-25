#   Copyright (c) 2021, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


###### Create Block Design ######
set design_name "cmac_bd"

create_bd_design ${design_name}
open_bd_design ${design_name}


##### Create and configure CMAC IP #####

# Default GT reference frequency
set gt_ref_clk 156.25
set freerunningclock 100
if {${projPart} eq "xcu50-fsvh2104-2L-e"} {
  # Possible core_selection CMACE4_X0Y3 and CMACE4_X0Y4
  set gt_ref_clk 161.1328125
  set core_selection  CMACE4_X0Y3
  set group_selection X0Y28~X0Y31
  set interface_number 0
} elseif {${projPart} eq "xcu55c-fsvh2892-2L-e"} {
  set gt_ref_clk 161.1328125
  switch ${interface} {
    "1" {
      # Possible core_selection CMACE4_X0Y3 and CMACE4_X0Y4
      set core_selection  CMACE4_X0Y4
      set group_selection X0Y28~X0Y31
      set interface_number 1
    }
    default {
      # Possible core_selection CMACE4_X0Y2; CMACE4_X0Y3; CMACE4_X0Y4
      set core_selection  CMACE4_X0Y2
      set group_selection X0Y24~X0Y27
      set interface_number 0
    }
  }
} elseif {${projPart} eq "xcu200-fsgd2104-2-e"} {
  switch ${interface} {
    "1" {
      # Possible core_selection CMACE4_X0Y6 and CMACE4_X0Y7
      set core_selection  CMACE4_X0Y6
      set group_selection X1Y44~X1Y47
      set interface_number 1
    }
    default {
      # Possible core_selection CMACE4_X0Y6; CMACE4_X0Y7 and CMACE4_X0Y8
      set core_selection  CMACE4_X0Y8
      set group_selection X1Y48~X1Y51
      set interface_number 0
    }
  }
} elseif {${projPart} eq "xcu250-figd2104-2L-e"} {
  switch ${interface} {
    "1" {
      # Possible core_selection CMACE4_X0Y6; CMACE4_X0Y7 and CMACE4_X0Y8
      set core_selection  CMACE4_X0Y6
      set group_selection X1Y40~X1Y43
      set interface_number 1
    }
    default {
      # Possible core_selection CMACE4_X0Y7 and CMACE4_X0Y8
      set core_selection  CMACE4_X0Y7
      set group_selection X1Y44~X1Y47
      set interface_number 0
    }
  }
} elseif {${projPart} eq "xcu280-fsvh2892-2L-e"} {
  set freerunningclock 50
  switch ${interface} {
    "1" {
      # Possible core_selection CMACE4_X0Y6 and CMACE4_X0Y7
      set core_selection  CMACE4_X0Y6
      set group_selection X0Y44~X0Y47
      set interface_number 1
    }
    default {
      # Possible core_selection CMACE4_X0Y5; CMACE4_X0Y6 and CMACE4_X0Y7
      set core_selection  CMACE4_X0Y5
      set group_selection X0Y40~X0Y43
      set interface_number 0
    }
  }
} else {
  puts "unknown part"
  return -1
}

set cmac_name cmac_uplus_${interface_number}
set gt_clk_freq [expr int(${gt_ref_clk} * 1000000)]
puts "Generating IPI for ${cmac_name} with GT clock running at ${gt_clk_freq} Hz"

set cmac_ip [create_bd_cell -type ip -vlnv xilinx.com:ip:cmac_usplus ${cmac_name}]
set_property -dict [ list \
  CONFIG.CMAC_CAUI4_MODE             {1} \
  CONFIG.NUM_LANES                   {4x25} \
  CONFIG.GT_REF_CLK_FREQ             $gt_ref_clk \
  CONFIG.CMAC_CORE_SELECT            $core_selection \
  CONFIG.GT_GROUP_SELECT             $group_selection \
  CONFIG.GT_DRP_CLK                  $freerunningclock \
  CONFIG.USER_INTERFACE              {AXIS} \
  CONFIG.INCLUDE_SHARED_LOGIC        {2} \
  CONFIG.LANE5_GT_LOC                {NA} \
  CONFIG.LANE6_GT_LOC                {NA} \
  CONFIG.LANE7_GT_LOC                {NA} \
  CONFIG.LANE8_GT_LOC                {NA} \
  CONFIG.LANE9_GT_LOC                {NA} \
  CONFIG.LANE10_GT_LOC               {NA} \
  CONFIG.OPERATING_MODE              {Duplex} \
  CONFIG.TX_FLOW_CONTROL             {0} \
  CONFIG.RX_FLOW_CONTROL             {0} \
  CONFIG.ENABLE_AXI_INTERFACE        {1} \
  CONFIG.INCLUDE_STATISTICS_COUNTERS {1} \
  CONFIG.RX_CHECK_ACK                {1} \
  CONFIG.ENABLE_TIME_STAMPING        {0} \
  CONFIG.TX_PTP_1STEP_ENABLE         {2} \
  CONFIG.PTP_TRANSPCLK_MODE          {0} \
  CONFIG.TX_PTP_LATENCY_ADJUST       {0} \
  CONFIG.ENABLE_PIPELINE_REG         {1} \
  CONFIG.INCLUDE_RS_FEC              {0} \
] $cmac_ip

###### Create interface ports ######

set clk_gt_freerun [ create_bd_port -dir I -type clk -freq_hz [expr ${freerunningclock} * 1000000] clk_gt_freerun ]

set M_AXIS [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS ]
set_property -dict [ list \
  CONFIG.FREQ_HZ {300000000} \
] $M_AXIS

set S_AXILITE [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXILITE ]
set_property -dict [ list \
  CONFIG.ADDR_WIDTH {13} \
  CONFIG.ARUSER_WIDTH {0} \
  CONFIG.AWUSER_WIDTH {0} \
  CONFIG.BUSER_WIDTH {0} \
  CONFIG.DATA_WIDTH {32} \
  CONFIG.FREQ_HZ {300000000} \
  CONFIG.HAS_BRESP {1} \
  CONFIG.HAS_BURST {0} \
  CONFIG.HAS_CACHE {0} \
  CONFIG.HAS_LOCK {0} \
  CONFIG.HAS_PROT {0} \
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
  CONFIG.FREQ_HZ $gt_clk_freq \
] $gt_ref_clk

set gt_serial_port [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 gt_serial_port ]


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

###### Add IP ######

# Create instance: acc_kernel_tx_cdc, and set properties
set acc_kernel_tx_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter acc_kernel_tx_cdc ]
set_property -dict [ list \
  CONFIG.HAS_TKEEP {1} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.IS_ACLK_ASYNC {1} \
  CONFIG.TDATA_NUM_BYTES {64} \
  CONFIG.TUSER_WIDTH.VALUE_SRC USER \
  CONFIG.TUSER_WIDTH {0} \
] $acc_kernel_tx_cdc

# Create instance: fifo_cmac_rx_cdc, and set properties
set fifo_cmac_rx_cdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator fifo_cmac_rx_cdc ]
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
set fifo_cmac_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator fifo_cmac_tx ]
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

# Create instance: cmac_sync, and set properties
set cmac_sync [ create_bd_cell -type module -reference cmac_sync cmac_sync ]

# Create instance: util_vector_logic_0, and set properties
set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_0 ]
set_property -dict [ list \
  CONFIG.C_OPERATION {not} \
  CONFIG.C_SIZE {1} \
  CONFIG.LOGO_FILE {data/sym_notgate.png} \
] $util_vector_logic_0

# Create instance: util_vector_logic_1, and set properties
set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_1 ]
set_property -dict [ list \
  CONFIG.C_OPERATION {not} \
  CONFIG.C_SIZE {1} \
  CONFIG.LOGO_FILE {data/sym_notgate.png} \
] $util_vector_logic_1

# Create instance: util_vector_logic_2, and set properties
set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_2 ]
set_property -dict [ list \
  CONFIG.C_OPERATION {not} \
  CONFIG.C_SIZE {1} \
  CONFIG.LOGO_FILE {data/sym_notgate.png} \
] $util_vector_logic_2

# Create instance: xlconstant_0, and set properties
set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant: xlconstant_0 ]
set_property -dict [ list \
  CONFIG.CONST_VAL {0} \
] $xlconstant_0

# Create instance: smartconnect, and set properties
set smartconnect [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect]
set_property -dict [list \
  CONFIG.NUM_SI {2} \
  CONFIG.NUM_MI {1} \
] [get_bd_cells smartconnect]

# Create instance: frame_padding, and set properties
set frame_padding [ create_bd_cell -type module -reference frame_padding frame_padding ]

# Create interface connections
connect_bd_intf_net -intf_net S_AXILITE_1 -boundary_type lower [get_bd_intf_ports S_AXILITE] [get_bd_intf_pins smartconnect/S00_AXI]
connect_bd_intf_net -intf_net smartconnect_M00_AXI -boundary_type lower [get_bd_intf_pins smartconnect/M00_AXI] [get_bd_intf_pins ${cmac_name}/s_axi]
connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_ports S_AXIS] [get_bd_intf_pins frame_padding/S_AXIS]
connect_bd_intf_net -intf_net frame_padding_M_AXIS [get_bd_intf_pins frame_padding/M_AXIS] [get_bd_intf_pins acc_kernel_tx_cdc/S_AXIS]
connect_bd_intf_net -intf_net acc_kernel_tx_cdc_M_AXIS [get_bd_intf_pins acc_kernel_tx_cdc/M_AXIS] [get_bd_intf_pins fifo_cmac_tx/S_AXIS]
connect_bd_intf_net -intf_net ${cmac_name}_axis_rx [get_bd_intf_pins ${cmac_name}/axis_rx] [get_bd_intf_pins fifo_cmac_rx_cdc/S_AXIS]
connect_bd_intf_net -intf_net ${cmac_name}_gt_serial_port [get_bd_intf_ports gt_serial_port] [get_bd_intf_pins ${cmac_name}/gt_serial_port]
connect_bd_intf_net -intf_net fifo_cmac_rx_cdc_M_AXIS [get_bd_intf_ports M_AXIS] [get_bd_intf_pins fifo_cmac_rx_cdc/M_AXIS]
connect_bd_intf_net -intf_net fifo_cmac_tx_M_AXIS [get_bd_intf_pins ${cmac_name}/axis_tx] [get_bd_intf_pins fifo_cmac_tx/M_AXIS]
connect_bd_intf_net -intf_net gt_ref_clk_1 [get_bd_intf_ports gt_ref_clk] [get_bd_intf_pins ${cmac_name}/gt_ref_clk]
connect_bd_intf_net -intf_net cmac_sync_s_axi [get_bd_intf_pins cmac_sync/s_axi] [get_bd_intf_pins smartconnect/S01_AXI]

###### Create port connections ######

connect_bd_net -net ap_rst_n [get_bd_ports ap_rst_n] [get_bd_pins acc_kernel_tx_cdc/s_axis_aresetn] [get_bd_pins util_vector_logic_1/Op1] [get_bd_pins smartconnect/aresetn] [get_bd_pins frame_padding/S_AXI_ARESETN]
connect_bd_net -net s_aclk_0_1 [get_bd_ports ap_clk] [get_bd_pins acc_kernel_tx_cdc/s_axis_aclk] [get_bd_pins ${cmac_name}/s_axi_aclk] [get_bd_pins fifo_cmac_rx_cdc/m_aclk] [get_bd_pins smartconnect/aclk] [get_bd_pins cmac_sync/s_axi_aclk] [get_bd_pins frame_padding/S_AXI_ACLK]
connect_bd_net -net usr_rx_reset [get_bd_pins ${cmac_name}/usr_rx_reset] [get_bd_pins util_vector_logic_0/Op1] [get_bd_pins cmac_sync/usr_rx_reset]
connect_bd_net -net usr_tx_reset [get_bd_pins ${cmac_name}/usr_tx_reset] [get_bd_pins util_vector_logic_2/Op1] [get_bd_pins cmac_sync/usr_tx_reset]
connect_bd_net -net ${cmac_name}_usr_rx_clk [get_bd_pins ${cmac_name}/gt_rxusrclk2] [get_bd_pins fifo_cmac_rx_cdc/s_aclk] [get_bd_pins ${cmac_name}/rx_clk]
connect_bd_net -net ${cmac_name}_usr_tx_clk [get_bd_pins acc_kernel_tx_cdc/m_axis_aclk] [get_bd_pins ${cmac_name}/gt_txusrclk2] [get_bd_pins fifo_cmac_tx/s_aclk]
connect_bd_net -net clk_gt_freerun_net [get_bd_ports clk_gt_freerun] [get_bd_pins ${cmac_name}/init_clk]
connect_bd_net -net util_vector_logic_0_Res [get_bd_pins fifo_cmac_rx_cdc/s_aresetn] [get_bd_pins util_vector_logic_0/Res]
connect_bd_net -net util_vector_logic_1_Res [get_bd_pins util_vector_logic_1/Res] [get_bd_pins ${cmac_name}/sys_reset] [get_bd_pins ${cmac_name}/s_axi_sreset] [get_bd_pins cmac_sync/s_axi_sreset]
connect_bd_net -net util_vector_logic_2_Res [get_bd_pins acc_kernel_tx_cdc/m_axis_aresetn] [get_bd_pins fifo_cmac_tx/s_aresetn] [get_bd_pins util_vector_logic_2/Res]
connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_pins ${cmac_name}/core_rx_reset] [get_bd_pins ${cmac_name}/pm_tick] [get_bd_pins ${cmac_name}/gtwiz_reset_tx_datapath] [get_bd_pins ${cmac_name}/gtwiz_reset_rx_datapath] [get_bd_pins ${cmac_name}/core_tx_reset] [get_bd_pins ${cmac_name}/core_drp_reset] [get_bd_pins ${cmac_name}/drp_clk]
connect_bd_net -net cmac_stat_rx_aligned [get_bd_pins ${cmac_name}/stat_rx_aligned] [get_bd_pins cmac_sync/stat_rx_aligned]

###### Create address segments ######

assign_bd_address -target_address_space [get_bd_addr_spaces S_AXILITE] [get_bd_addr_segs ${cmac_name}/s_axi/Reg0] -force
assign_bd_address -target_address_space [get_bd_addr_spaces cmac_sync/s_axi] [get_bd_addr_segs ${cmac_name}/s_axi/Reg0] -force

###### Validate and save the IPI ######

validate_bd_design
save_bd_design


delete_bd_objs [get_bd_intf_nets S_AXIS_1] [get_bd_intf_nets frame_padding_M_AXIS] [get_bd_cells frame_padding]
connect_bd_intf_net [get_bd_intf_ports S_AXIS] [get_bd_intf_pins acc_kernel_tx_cdc/S_AXIS]
validate_bd_design
save_bd_design