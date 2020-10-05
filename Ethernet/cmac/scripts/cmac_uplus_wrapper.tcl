set project_dir "[file normalize "/tmp"]"
set project_name "vivado_project_delete_me"
set tcl_dir "[file normalize "./scripts/xilinx_ips"]"
set synthesize_ip false

set script_file "cmac_uplus_wrapper.tcl"

proc help {} {
  variable script_file
  puts "\nDescription:"
  puts "Create a Vivado IP core from this script that encapsulated the 100GbE UltraScale+ Subsystem."
  puts "Syntax:"
  puts "$script_file -tclargs --origin_dir <path> "
  puts "$script_file -tclargs --help\n"
  puts "Usage:"
  puts "Name                             Description"
  puts "-------------------------------------------------------------------------"
  puts "--origin_dir <path>              Determine working directory for relative paths.\n"
  puts "--integrated_qsfp <ninterface>   Create the wrapper for the interface number \n"
  puts "--board <board>                  Determine the development Board, supported boards are VCU118\n"
  puts "                                 <ninterface> of the hitech component (from 0 to 3).\n"
  puts "--help                           Print help information for this script\n"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc < 1 } { help }

if { $::argc == 1 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--help"         { help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

set use_integrated false
set use_board VCU118
if { $::argc > 1 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    puts "The $option is being used"
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--integrated_qsfp" { incr i; set use_integrated true; set integrated_interface [lindex $::argv $i] }
      "--board" { incr i; set use_board [lindex $::argv $i] }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

if {![info exists origin_dir]} {
  puts "ERROR: Option '--origin_dir' required, please type '$script_file -tclargs --help' for usage info.\n"
  return 1
}


if {$use_board eq "ALVEO-U50"} {
  set fpga_part "xcu50-fsvh2104-2-e"
  set fpga_board "xilinx.com:au50:part0:1.0"  

  set core_name "cmac_ALVEOu50_${integrated_interface}"
  set constraint_name "alveou50_qsfp${integrated_interface}"

} elseif {$use_board eq "ALVEO-U200"} {
  set fpga_part "xcu200-fsgd2104-2-e"
  set fpga_board "xilinx.com:au200:part0:1.0"  

  set core_name "cmac_ALVEOu200_${integrated_interface}"
  set constraint_name "alveou200_qsfp${integrated_interface}"

} elseif {$use_board eq "ALVEO-U250"} {
  set fpga_part "xcu250-figd2104-2L-e"
  set fpga_board "xilinx.com:au250:part0:1.3"  

  set core_name "cmac_ALVEOu250_${integrated_interface}"
  set constraint_name "alveou250_qsfp${integrated_interface}"

} elseif {$use_board eq "ALVEO-U280"} {
  set fpga_part "xcu280-fsvh2892-2L-e"
  set fpga_board "xilinx.com:au280:part0:1.1"  

  set core_name "cmac_ALVEOu280_${integrated_interface}"
  set constraint_name "alveou280_qsfp${integrated_interface}"

} else {
    puts "ERROR: Unknown Board.\n"
    return -1
}

create_project -force $project_name $project_dir/$project_name -part $fpga_part
#set_property board_part $fpga_board [current_project]

set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

read_verilog -sv $origin_dir/src/cmac/cmac_axi2lbus.sv
read_verilog -sv $origin_dir/src/cmac/cmac_lbus2axi.v
read_verilog -sv $origin_dir/src/cmac/cmac_lbus_aligned_2_axi.sv
read_verilog -sv $origin_dir/src/cmac/cmac_lbus_aligner.sv

read_verilog -sv $origin_dir/src/common/types.svh


# Create a cmac core
source $tcl_dir/cmac_uplus.tcl
# Create  a fifo
source $tcl_dir/lbus_fifo.tcl
source $tcl_dir/axi_fifo.tcl
#source $tcl_dir/fifo_cdc.tcl

#Include GT reference clock constraint
add_files -fileset constrs_1 -norecurse ${origin_dir}/constraints/${constraint_name}.xdc
#Include timing constraints common for all IPs
add_files -fileset constrs_1 -norecurse ${origin_dir}/constraints/cmac_false_path.xdc

set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-verilog_define ULTRASCALE_PLUS} -objects [get_runs synth_1]
set_property verilog_define ULTRASCALE_PLUS [get_filesets sources_1]
set_property verilog_define ULTRASCALE_PLUS [get_filesets sim_1]

ipx::package_project  -import_files -root_dir $origin_dir/project/$core_name -vendor xilinx.com -library cmac -taxonomy /UserIP

set_property vendor xilinx.com [ipx::current_core]
set_property library cmac [ipx::current_core]
set_property name $core_name [ipx::current_core]
set_property display_name $core_name [ipx::current_core]
set_property description $core_name [ipx::current_core]
set_property version 1 [ipx::current_core]
set_property core_revision 1 [ipx::current_core]

ipx::associate_bus_interfaces -busif AXI2LBUS -clock usr_tx_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif LBUS2AXI -clock usr_rx_clk [ipx::current_core]

set_property name AXI4_STATISTICS [ipx::get_bus_interfaces s_axi4_lite -of_objects [ipx::current_core]]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces usr_tx_clk -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces usr_rx_clk -of_objects [ipx::current_core]]
set_property value 322265625 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces usr_tx_clk -of_objects [ipx::current_core]]]
set_property value 322265625 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces usr_rx_clk -of_objects [ipx::current_core]]]

set_property supported_families {virtexuplus Pre-Production virtexuplusHBM Beta} [ipx::current_core]

set_property range 0x1000 [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi4_lite -of_objects [ipx::current_core]]]

ipx::remove_bus_interface gt_ref_clk_n [ipx::current_core]
ipx::remove_bus_interface gt_ref_clk_p [ipx::current_core]

remove_files  $origin_dir/project/$core_name/src/types.svh


ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]


close_project
