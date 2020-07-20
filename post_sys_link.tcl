# (c) Copyright 2019 Xilinx, Inc. All rights reserved.
#
# This file contains confidential and proprietary information
# of Xilinx, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
#
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# Xilinx, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) Xilinx shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or Xilinx had been advised of the
# possibility of the same.
#
# CRITICAL APPLICATIONS
# Xilinx products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of Xilinx products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
#
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
############################################################
#

set board_name [get_property board_part [current_project]]
set pfm_name [get_property PFM_NAME [get_files [current_bd_design].bd]]
set __TCLID "(Post-linking ${board_name} QSFP0 Tcl hook): "

# *************************************************************************
puts "${__TCLID} the name of the board is: ${board_name}"
puts "${__TCLID} get_property PFM_NAME $pfm_name"
#--------------------------------------------------------------
# Get GT port name, GT reference clock and free running clock
#--------------------------------------------------------------
set frc0 "clk_gt_freerun"
set frc1 "ip_clkwiz_ucs_freerun_00/clk_out1"
set frc2 "blp_s_aclk_freerun_ref_00"

if {[llength [get_bd_ports ${frc0}]] eq 1} {
  set __bd_free_running_clk ${frc0}
} elseif {[llength [get_bd_pins ${frc1}]] eq 1} {
  set __bd_free_running_clk ${frc1}
} elseif {[llength [get_bd_pins ${frc2}]] eq 1} {
  set __bd_free_running_clk ${frc2}
} else {
  puts "${__TCLID} WARNING no free running clock was found"
}


set io_clk_gt0 "io_clk_qsfp_refclka_00"
set io_clk_gt1 "io_clk_gtyquad_refclk0_00"

if {[llength [get_bd_intf_ports ${io_clk_gt0}]] eq 1} {
  set bd_gt_ref_clk_0_name_a "io_clk_qsfp_refclka_00"
  set bd_gt_ref_clk_0_name_b "io_clk_qsfp_refclkb_00"
  set bd_gt_ref_clk_1_name_a "io_clk_qsfp_refclka_01"
  set bd_gt_ref_clk_1_name_b "io_clk_qsfp_refclkb_01"
  set bd_gt_gtyquad_0        "io_gt_qsfp_00"
  set bd_gt_gtyquad_1        "io_gt_qsfp_01"
} elseif {[llength [get_bd_intf_ports ${io_clk_gt1}]] eq 1} {
  set bd_gt_ref_clk_0_name_a "io_clk_gtyquad_refclk0_00"
  set bd_gt_ref_clk_0_name_b "io_clk_gtyquad_refclk0_01"
  set bd_gt_ref_clk_1_name_a "io_clk_gtyquad_refclk1_00"
  set bd_gt_ref_clk_1_name_b "io_clk_gtyquad_refclk1_00"
  set bd_gt_gtyquad_0        "io_gt_gtyquad_00"
  set bd_gt_gtyquad_1        "io_gt_gtyquad_01"
} else {
  puts "${__TCLID} WARNING no GT ports were found"
}

puts "${__TCLID} the free running clock is ${__bd_free_running_clk}"
puts "${__TCLID} bd gt quad is ${bd_gt_gtyquad_0} and gt clock ref is ${bd_gt_ref_clk_0_name_b}"


set __gt_k_list {}
set __gt_intf_width 0
# Make sure the kernel key in the config_info dict exists
if {[dict exists $config_info kernels]} {
  puts "${__TCLID} got config_info which is: ${config_info}"
  set __k_list [dict get $config_info kernels]
  puts "${__TCLID} __k_list: ${__k_list}"
  # Make sure that list of kernels is populated  
  if {[llength $__k_list] > 0} {
    # Iterate over each kernel
    foreach __k_inst $__k_list {
      puts "${__TCLID} K Inst: ${__k_inst}"
      set __cu_bd_cell_list [get_bd_cells -quiet -filter "VLNV=~*:*:${__k_inst}:*"]
      # Iterate over each compute unit for the current kernel
      foreach __cu_bd_cell $__cu_bd_cell_list {
        puts "${__TCLID} CU Cell: ${__cu_bd_cell}"
        set __cu_bd_cell_sub [string range $__cu_bd_cell 1 [string length $__cu_bd_cell]]
        #Create a list of GT capable kernels. 
        set __gt_pins [get_bd_intf_pins -quiet -of_objects [get_bd_cells $__cu_bd_cell_sub] -filter {VLNV=~*gt_rtl*}]
        if {[llength ${__gt_pins} ] > 0} {
          puts "${__TCLID} found gt interface on $__cu_bd_cell_sub"
          lappend __gt_k_list $__cu_bd_cell_sub
        }
      }
    }
  } else {
    puts "${__TCLID} kernel list 0"
  }
  puts "${__TCLID} list of gt kernels ${__gt_k_list}"

  if {[llength ${__gt_k_list}] > 2} {
    puts "${__TCLID} More than 1 GT interface is not supported. A single GT interface of max width 4 must be provided."
    exit
  }

  if {[llength $__gt_k_list] > 0} {
    puts "${__TCLID} Iterating over kernels"
    if {[info exist bd_gt_gtyquad_0] eq 0} {
      puts "${__TCLID} ERROR this shell does not have gt support or the gt port names are unknown"
      # The line below will always give an error and it is indeded to stop vpl process
      connect_bd_intf_net error error
    }

    puts "${__TCLID} GT Kernel List $__gt_k_list"
    foreach __k_inst $__gt_k_list {
      # Loof for a gt capable interface
      set __gt_intf [get_bd_intf_pins -quiet -of_objects [get_bd_cells $__k_inst] -filter {VLNV=~*gt_rtl*}]
      puts "${__TCLID} found GT caplable interface: ${__gt_intf}"
      if {[string first "gt_serial_port0" ${__gt_intf}] != -1} {
        puts "${__TCLID} connecting GT quad ${bd_gt_gtyquad_0} <-> ${__gt_intf}"
        connect_bd_intf_net [get_bd_intf_ports ${bd_gt_gtyquad_0}] ${__gt_intf}
      } 
      if {[string first "gt_serial_port1" ${__gt_intf}] != -1} {
        puts "${__TCLID} connecting GT quad ${bd_gt_gtyquad_1} <-> ${__gt_intf}"
        connect_bd_intf_net [get_bd_intf_ports ${bd_gt_gtyquad_1}] ${__gt_intf}
      }
      # Loof for a gt clock capable interface
      set __refclk0_pins [get_bd_pins -of_objects [get_bd_cells ${__k_inst}] -filter {NAME =~ "gt_refclk0*"}]
      if {[llength $__refclk0_pins] > 0} {
        puts "${__TCLID} connecting ${bd_gt_ref_clk_0_name_a} -> ${__k_inst}/gt_refclk0"
        connect_bd_net [get_bd_ports ${bd_gt_ref_clk_0_name_a}_clk_n] [get_bd_pins ${__k_inst}/gt_refclk0_n]
        connect_bd_net [get_bd_ports ${bd_gt_ref_clk_0_name_a}_clk_p] [get_bd_pins ${__k_inst}/gt_refclk0_p]
      }
      set __refclk1_pins [get_bd_pins -of_objects [get_bd_cells ${__k_inst}] -filter {NAME =~ "gt_refclk1*"}]
      if {[llength $__refclk1_pins] > 0} {
        puts "${__TCLID} connecting ${bd_gt_ref_clk_1_name_a} -> ${__k_inst}/gt_refclk1"
        connect_bd_net [get_bd_ports ${bd_gt_ref_clk_1_name_a}_clk_n] [get_bd_pins ${__k_inst}/gt_refclk1_n]
        connect_bd_net [get_bd_ports ${bd_gt_ref_clk_1_name_a}_clk_p] [get_bd_pins ${__k_inst}/gt_refclk1_p]
      }
      # Get Free runninc clock pin name and connection if any
      set __kernel_freerunclk_pins [get_bd_pins -of_objects [get_bd_cells ${__k_inst}] -filter {NAME =~ "clk_gt_freerun"}]
      set __freerunclk_connection [get_bd_nets -of_objects [get_bd_pins -of_objects [get_bd_cells ${__k_inst}] -filter {NAME =~ "clk_gt_freerun"}]]
      puts "${__TCLID} kernel free running clock pin ${__kernel_freerunclk_pins}"

      if {[llength ${__kernel_freerunclk_pins}] ne 1} {
        puts "${__TCLID} ERROR - No clk_gt_freerun pin found"
      } else {
        if {[llength ${__freerunclk_connection}] ne 0} {
          puts "${__TCLID} ${__kernel_freerunclk_pins} was connected to ${__freerunclk_connection}. Connection was removed"
          disconnect_bd_net ${__freerunclk_connection} [get_bd_pins ${__kernel_freerunclk_pins}]
        }
        puts "${__TCLID} connecting ${__kernel_freerunclk_pins} -> ${__bd_free_running_clk}"
        connect_bd_net [get_bd_pins ${__bd_free_running_clk}] [get_bd_pins ${__kernel_freerunclk_pins}]
      }
    }
  }
}