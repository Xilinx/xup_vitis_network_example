# Copyright (c) 2020-2021, Xilinx, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, 
# this list of conditions and the following disclaimer in the documentation 
# and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors 
# may be used to endorse or promote products derived from this software 
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# Copyright (c) 2021 Xilinx, Inc.


set board_name [get_property board_part [current_project]]
set pfm_name [get_property PFM_NAME [get_files [current_bd_design].bd]]
set __TCLID "(Post-linking ${board_name} QSFP GT pins and GT clock TCL hook): "

# *************************************************************************
puts "${__TCLID} the name of the board is: ${board_name}"
puts "${__TCLID} get_property PFM_NAME ${pfm_name}"
#--------------------------------------------------------------
# Get GT port name, GT reference clock and free running clock
#--------------------------------------------------------------

set io_clk_gt0 "io_clk_qsfp_refclka_00"
set io_clk_gt1 "io_clk_gtyquad_refclk0_00"
set io_clk_gt2 "io_clk_qsfp0_refclka_00"

if {[llength [get_bd_intf_ports ${io_clk_gt0} -quiet]] eq 1} {
  set bd_gt_ref_clk_0_name_a "io_clk_qsfp_refclka_00"
  set bd_gt_ref_clk_0_name_b "io_clk_qsfp_refclkb_00"
  set bd_gt_ref_clk_1_name_a "io_clk_qsfp_refclka_01"
  set bd_gt_ref_clk_1_name_b "io_clk_qsfp_refclkb_01"
  set bd_gt_gtyquad_0        "io_gt_qsfp_00"
  set bd_gt_gtyquad_1        "io_gt_qsfp_01"
} elseif {[llength [get_bd_intf_ports ${io_clk_gt1} -quiet]] eq 1} {
  set bd_gt_ref_clk_0_name_a "io_clk_gtyquad_refclk0_00"
  set bd_gt_ref_clk_0_name_b "io_clk_gtyquad_refclk1_00"
  set bd_gt_ref_clk_1_name_a "io_clk_gtyquad_refclk0_01"
  set bd_gt_ref_clk_1_name_b "io_clk_gtyquad_refclk1_01"
  set bd_gt_gtyquad_0        "io_gt_gtyquad_00"
  set bd_gt_gtyquad_1        "io_gt_gtyquad_01"
} elseif {[llength [get_bd_intf_ports ${io_clk_gt2} -quiet]] eq 1} {
  set bd_gt_ref_clk_0_name_a "io_clk_qsfp0_refclka_00"
  set bd_gt_ref_clk_1_name_a "io_clk_qsfp1_refclka_00"
  set bd_gt_gtyquad_0        "io_gt_qsfp0_00"
  set bd_gt_gtyquad_1        "io_gt_qsfp1_00"
} else {
  puts "${__TCLID} WARNING no GT ports were found"
}

puts "${__TCLID} bd gt quad is ${bd_gt_gtyquad_0} and gt clock ref is ${bd_gt_ref_clk_0_name_a}"
puts "${__TCLID} bd gt quad is ${bd_gt_gtyquad_1} and gt clock ref is ${bd_gt_ref_clk_1_name_a}"

# U280 -> frc0(50)
# U250 -> frc1(100 MHz)
# U50  -> frc2(100 MHz)
# U55c -> frc2(100 MHz)

set frc0 "clk_gt_freerun"
set frc1 "ii_level1_wire/ulp_m_aclk_freerun_ref_00"
set frc2 "ii_level0_wire/ulp_m_aclk_freerun_ref_00"
set frc3 "blp_s_aclk_freerun_ref_00"

if {[llength [get_bd_ports ${frc0}]] eq 1} {
  set __bd_free_running_clk ${frc0}
} elseif {[llength [get_bd_pins ${frc1}]] eq 1} {
  set __bd_free_running_clk ${frc1}
} elseif {[llength [get_bd_pins ${frc2}]] eq 1} {
  set __bd_free_running_clk ${frc2}
} elseif {[llength [get_bd_pins ${frc3}]] eq 1} {
  set __bd_free_running_clk ${frc3}
} else {
  puts "${__TCLID} WARNING no free running clock was found"
}

puts "${__TCLID} free running clock is ${__bd_free_running_clk}"

set __gt_k_list {}
set __gt_intf_width 0
# Make sure the kernel key in the config_info dict exists
if {[dict exists ${config_info} kernels]} {
  puts "${__TCLID} got config_info which is: ${config_info}"
  set __k_list [dict get ${config_info} kernels]
  puts "${__TCLID} {__k_list}: ${__k_list}"
  # Make sure that list of kernels is populated  
  if {[llength ${__k_list}] > 0} {
    # Iterate over each kernel
    foreach __k_inst ${__k_list} {
      puts "${__TCLID} K Inst: ${__k_inst}"
      set __cu_bd_cell_list [get_bd_cells -quiet -filter "VLNV=~*:*:${__k_inst}:*"]
      # Iterate over each compute unit for the current kernel
      foreach __cu_bd_cell $__cu_bd_cell_list {
        puts "${__TCLID} CU Cell: ${__cu_bd_cell}"
        set __cu_bd_cell_sub [string range ${__cu_bd_cell} 1 [string length ${__cu_bd_cell}]]
        #Create a list of GT capable kernels. 
        set __gt_pins [get_bd_intf_pins -quiet -of_objects [get_bd_cells ${__cu_bd_cell_sub}] -filter {VLNV=~*gt_rtl*}]
        if {[llength ${__gt_pins} ] > 0} {
          puts "${__TCLID} found GT interface on ${__cu_bd_cell_sub}"
          lappend __gt_k_list ${__cu_bd_cell_sub}
        }
      }
    }
  } else {
    puts "${__TCLID} kernel list 0"
  }
  puts "${__TCLID} list of GT kernels ${__gt_k_list}"

  if {[llength ${__gt_k_list}] > 2} {
    puts "${__TCLID} More than 2 GT interfaces are not supported."
    exit
  }

  if {[llength $__gt_k_list] > 0} {
    puts "${__TCLID} Iterating over kernels"
    if {[info exists bd_gt_gtyquad_0] eq 0} {
      puts "${__TCLID} ERROR this platform (${pfm_name}) does not have GT support or the GT port names are unknown"
      # The line below will always give an error and it is used to stop vpl process
      connect_bd_intf_net error error
    }

    puts "${__TCLID} GT Kernel List ${__gt_k_list}"
    foreach __k_inst ${__gt_k_list} {
      # Look for a gt capable interface
      set __gt_intf [get_bd_intf_pins -quiet -of_objects [get_bd_cells ${__k_inst}] -filter {VLNV=~*gt_rtl*}]
      puts "${__TCLID} found GT capable interface: ${__gt_intf}"
      if {[string first "gt_serial_port0" ${__gt_intf}] != -1} {
        puts "${__TCLID} connecting GT quad ${bd_gt_gtyquad_0} <-> ${__gt_intf}"
        connect_bd_intf_net [get_bd_intf_ports ${bd_gt_gtyquad_0}] ${__gt_intf}
      } 
      if {[string first "gt_serial_port1" ${__gt_intf}] != -1} {
        puts "${__TCLID} connecting GT quad ${bd_gt_gtyquad_1} <-> ${__gt_intf}"
        connect_bd_intf_net [get_bd_intf_ports ${bd_gt_gtyquad_1}] ${__gt_intf}
      }
      # Look for a gt clock capable interface
      set __refclk0_intf [get_bd_intf_pins -of_objects [get_bd_cells ${__k_inst}] -filter {NAME =~ "gt_refclk0*"} -quiet]
      if {[llength ${__refclk0_intf}] > 0} {
        puts "${__TCLID} connecting GT reference clock ${bd_gt_ref_clk_0_name_a} -> ${__k_inst}/gt_refclk0"
        connect_bd_intf_net [get_bd_intf_ports ${bd_gt_ref_clk_0_name_a}] ${__refclk0_intf}
      }
      set __refclk1_intf [get_bd_intf_pins -of_objects [get_bd_cells ${__k_inst}] -filter {NAME =~ "gt_refclk1*"} -quiet]
      if {[llength ${__refclk1_intf}] > 0} {
        puts "${__TCLID} connecting GT reference clock ${bd_gt_ref_clk_1_name_a} -> ${__k_inst}/gt_refclk1"
        connect_bd_intf_net [get_bd_intf_ports ${bd_gt_ref_clk_1_name_a}] ${__refclk1_intf}
      }
      # Get Free running clock pin name and connection if any
      set __kernel_freerunclk_pins [get_bd_pins -of_objects [get_bd_cells ${__k_inst}] -filter {NAME =~ "clk_gt_freerun"}]
      set __freerunclk_connection [get_bd_nets -of_objects [get_bd_pins -of_objects [get_bd_cells ${__k_inst}] -filter {NAME =~ "clk_gt_freerun"}]]
      puts "${__TCLID} kernel free running clock pin: ${__kernel_freerunclk_pins}"

      if {[llength ${__kernel_freerunclk_pins}] ne 1} {
        puts "${__TCLID} ERROR - No clk_gt_freerun pin found"
      } else {
        if {[llength ${__freerunclk_connection}] ne 0} {
          puts "${__TCLID} ${__kernel_freerunclk_pins} was connected to ${__freerunclk_connection}. Connection was removed"
          disconnect_bd_net ${__freerunclk_connection} [get_bd_pins ${__kernel_freerunclk_pins}]
        }
        puts "${__TCLID} connecting free running clock ${__bd_free_running_clk} -> ${__kernel_freerunclk_pins}"
        connect_bd_net [get_bd_pins ${__bd_free_running_clk}] [get_bd_pins ${__kernel_freerunclk_pins}]
      }      
    }
  }
}

puts "${__TCLID} QSFP GT pins TCL hook DONE!"