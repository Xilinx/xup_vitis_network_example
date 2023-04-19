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

if { $::argc != 5 } {
    puts "ERROR: Program \"$::argv0\" requires 5 arguments!, (${argc} given)\n"
    puts "Usage: $::argv0 <xoname> <krnl_name> <device> <interface> <padding_mode>\n"
    exit
}

set xoname  [lindex $::argv 0]
set krnl_name [lindex $::argv 1]
set device    [lindex $::argv 2]
set interface [lindex $::argv 3]
set padding_mode [lindex $::argv 4]

set suffix "${krnl_name}_${device}"

puts "INFO: xoname-> ${xoname}\n      krnl_name-> ${krnl_name}\n      device-> ${device}\n      interface-> ${interface}\n      padding_mode-> ${padding_mode}"

set projName kernel_pack
set bd_name cmac_bd
set root_dir "[file normalize "."]"
set path_to_hdl "./src"
set path_to_packaged "./packaged_kernel_${suffix}"
set path_to_tmp_project "./tmp_${suffix}"

#get projPart
source platform.tcl

if {${projPart} eq "xcu50-fsvh2104-2L-e"} {
    if {$interface != 0} {
        catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "Alveo U50 only has one interface (0)"}
        return 1
    }
}

## Create Vivado project and add IP cores
create_project -force $projName $path_to_tmp_project -part $projPart
add_files -norecurse [glob ${root_dir}/src/cmac_top_${interface}.v]
add_files -norecurse [glob ${root_dir}/src/cmac_0_axi4_lite_user_if.v]
add_files -norecurse [glob ${root_dir}/src/cmac_sync.v]
add_files -norecurse [glob ${root_dir}/src/rx_sync.v]
add_files -norecurse [glob ${root_dir}/src/frame_padding.v]
add_files -fileset constrs_1 -norecurse [glob ${root_dir}/src/cmac_synq_false_path.xdc]

update_compile_order -fileset sources_1

source ${root_dir}/bd_cmac.tcl
update_compile_order -fileset sources_1


generate_target all [get_files  ${path_to_tmp_project}/${projName}.srcs/sources_1/bd/${bd_name}/${bd_name}.bd]
export_ip_user_files -of_objects [get_files ${path_to_tmp_project}/${projName}.srcs/sources_1/bd/${bd_name}/${bd_name}.bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ${path_to_tmp_project}/${projName}.srcs/sources_1/bd/${bd_name}/${bd_name}.bd]
update_compile_order -fileset sources_1
set_property top cmac_${interface} [current_fileset]


set gt_name "gt_serial_port${interface}"
set refclkIntfName "gt_refclk${interface}"
# Package IP

ipx::package_project -root_dir ${path_to_packaged} -vendor xilinx.com -library RTLKernel -taxonomy /KernelIP -import_files -set_current false
ipx::unload_core ${path_to_packaged}/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory ${path_to_packaged} ${path_to_packaged}/component.xml
set_property core_revision 1 [ipx::current_core]
foreach up [ipx::get_user_parameters] {
  ipx::remove_user_parameter [get_property NAME $up] [ipx::current_core]
}
set_property sdx_kernel true [ipx::current_core]
set_property sdx_kernel_type rtl [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::add_bus_interface ap_clk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces ap_clk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces ap_clk -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces ap_clk -of_objects [ipx::current_core]]
set_property physical_name ap_clk [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces ap_clk -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif S_AXIS -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif M_AXIS -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif S_AXILITE -clock ap_clk [ipx::current_core]

ipx::add_bus_interface ${gt_name} [ipx::current_core]
set_property interface_mode master [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:gt_rtl:1.0 [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:gt:1.0 [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]
ipx::add_port_map GRX_P [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]
set_property physical_name gt_rxp_in [ipx::get_port_maps GRX_P -of_objects [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]]
ipx::add_port_map GRX_N [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]
set_property physical_name gt_rxn_in [ipx::get_port_maps GRX_N -of_objects [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]]
ipx::add_port_map GTX_P [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]
set_property physical_name gt_txp_out [ipx::get_port_maps GTX_P -of_objects [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]]
ipx::add_port_map GTX_N [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]
set_property physical_name gt_txn_out [ipx::get_port_maps GTX_N -of_objects [ipx::get_bus_interfaces ${gt_name} -of_objects [ipx::current_core]]]

# GT Differential Reference Clock
ipx::add_bus_interface ${refclkIntfName} [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:diff_clock_rtl:1.0 [ipx::get_bus_interfaces ${refclkIntfName} -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:diff_clock:1.0 [ipx::get_bus_interfaces ${refclkIntfName} -of_objects [ipx::current_core]]
ipx::add_port_map CLK_P [ipx::get_bus_interfaces ${refclkIntfName} -of_objects [ipx::current_core]]
set_property physical_name ${refclkIntfName}_p [ipx::get_port_maps CLK_P -of_objects [ipx::get_bus_interfaces ${refclkIntfName} -of_objects [ipx::current_core]]]
ipx::add_port_map CLK_N [ipx::get_bus_interfaces ${refclkIntfName} -of_objects [ipx::current_core]]
set_property physical_name ${refclkIntfName}_n [ipx::get_port_maps CLK_N -of_objects [ipx::get_bus_interfaces ${refclkIntfName} -of_objects [ipx::current_core]]]

# config for TLM sim
# Adding tlm Read socket
set rd_socket [ipx::add_tlm_port S_AXILITE_rd_socket [ipx::current_core]]
set_property type_name "xtlm::xtlm_aximm_target_socket" $rd_socket
set_property type_definitions [list "xtlm.h"] $rd_socket
set_property min_connections 1 $rd_socket
set_property max_connections 1 $rd_socket
set_property service_initiative "provides" $rd_socket
set_property service_type_name "tlm" $rd_socket
set_property value "rd_socket" [ipx::add_service_parameter "name" $rd_socket]
set_property value 32 [ipx::add_service_parameter "width" $rd_socket]

# Adding tlm Write socket
set wr_socket [ipx::add_tlm_port S_AXILITE_wr_socket [ipx::current_core]]
set_property type_name "xtlm::xtlm_aximm_target_socket" $wr_socket
set_property type_definitions [list "xtlm.h"] $wr_socket
set_property min_connections 1 $wr_socket
set_property max_connections 1 $wr_socket
set_property service_initiative "provides" $wr_socket
set_property service_type_name "tlm" $wr_socket
set_property value "wr_socket" [ipx::add_service_parameter "name" $wr_socket]
set_property value 32 [ipx::add_service_parameter "width" $wr_socket]

# Add tlm interface...
set s_axi_tlm [ipx::add_tlm_interface S_AXILITE_TLM [ipx::current_core]]
set_property bus_type_vlnv "xilinx.com:interface:aximm:1.0" $s_axi_tlm
set_property abstraction_type_vlnv "xilinx.com:interface:aximm_tlm:1.0" $s_axi_tlm
set_property physical_name S_AXILITE_rd_socket [ipx::add_port_map "AXIMM_READ_SOCKET" $s_axi_tlm]
set_property physical_name S_AXILITE_wr_socket [ipx::add_port_map "AXIMM_WRITE_SOCKET" $s_axi_tlm]
set_property interface_mode slave $s_axi_tlm

# Adding tlm master stream socket
set socket [ipx::add_tlm_port M_AXIS_socket [ipx::current_core]]
set_property type_name "xtlm::xtlm_axis_initiator_socket" $socket
set_property type_definitions [list "xtlm.h"] $socket
set_property min_connections 1 $socket
set_property max_connections 1 $socket
set_property service_initiative "requires" $socket
set_property service_type_name "tlm" $socket
set_property value "socket" [ipx::add_service_parameter "name" $socket]
set_property value 512 [ipx::add_service_parameter "width" $socket]

# Add tlm interface...
set s_axi_tlm [ipx::add_tlm_interface M_AXIS_TLM [ipx::current_core]]
set_property bus_type_vlnv "xilinx.com:interface:axis:1.0" $s_axi_tlm
set_property abstraction_type_vlnv "xilinx.com:interface:axis_tlm:1.0" $s_axi_tlm
set_property physical_name M_AXIS_socket [ipx::add_port_map "AXIS_SOCKET" $s_axi_tlm]
set_property interface_mode master $s_axi_tlm

# Adding tlm slave stream socket
set socket [ipx::add_tlm_port S_AXIS_socket [ipx::current_core]]
set_property type_name "xtlm::xtlm_axis_target_socket" $socket
set_property type_definitions [list "xtlm.h"] $socket
set_property min_connections 1 $socket
set_property max_connections 1 $socket
set_property service_initiative "provides" $socket
set_property service_type_name "tlm" $socket
set_property value "socket" [ipx::add_service_parameter "name" $socket]
set_property value 512 [ipx::add_service_parameter "width" $socket]

# Add tlm interface...
set s_axi_tlm [ipx::add_tlm_interface S_AXIS_TLM [ipx::current_core]]
set_property bus_type_vlnv "xilinx.com:interface:axis:1.0" $s_axi_tlm
set_property abstraction_type_vlnv "xilinx.com:interface:axis_tlm:1.0" $s_axi_tlm
set_property physical_name S_AXIS_socket [ipx::add_port_map "AXIS_SOCKET" $s_axi_tlm]
set_property interface_mode slave $s_axi_tlm

# TODO width parameters

# Add SystemC file group
set filegroup [ipx::add_file_group -type systemc:simulation {} [ipx::current_core]]
set_property model_name $krnl_name $filegroup
set_property sim_type "tlm" $filegroup

# Add SystemC include file
set inc [ipx::add_file sysc/cmac.h $filegroup]
set_property type systemCSource $inc
set_property is_include "true" $inc

# Add SystemC source file
set file [ipx::add_file sysc/cmac.cpp $filegroup]
set_property type systemCSource $file

# Add SystemC libraries
set_property systemc_libraries { xtlm xtlm_ap_ctrl_v1_0 } [ipx::current_core]

# Copy SystemC files into IP folder
file copy -force ./src/sysc ./packaged_kernel_${suffix}


set_property xpm_libraries {XPM_CDC XPM_MEMORY XPM_FIFO} [ipx::current_core]
set_property supported_families { } [ipx::current_core]
set_property auto_family_support_level level_2 [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
close_project -delete

## Generate XO
if {[file exists "${xoname}"]} {
    file delete -force "${xoname}"
}

package_xo -xo_path ${xoname} -kernel_name ${krnl_name} -ip_directory ./packaged_kernel_${suffix} -kernel_xml ./kernel_${interface}.xml


