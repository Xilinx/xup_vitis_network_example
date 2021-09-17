# Copyright (c) 2020, Xilinx, Inc.
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
# Copyright (c) 2020 Xilinx, Inc.

## Get variables
if { $::argc != 3 } {
    puts "ERROR: Program \"$::argv0\" requires 3 arguments!, (${argc} given)\n"
    puts "Usage: $::argv0 <xoname> <krnl_name> <device>\n"
    exit
}

set xoname  [lindex $::argv 0]
set krnl_name [lindex $::argv 1]
set device    [lindex $::argv 2]

set suffix "${krnl_name}_${device}"

puts "INFO: xoname-> ${xoname}\n      krnl_name-> ${krnl_name}\n      device-> ${device}\n"

set projName kernel_pack
set root_dir "[file normalize "."]"
set path_to_hdl "${root_dir}/src"
set path_to_hdl_debug "${root_dir}/../NetLayers/src"
set path_to_packaged "./packaged_kernel_${suffix}"
set path_to_tmp_project "./tmp_${suffix}"

#get projPart
source platform.tcl

## Create Vivado project and add IP cores
create_project -force $projName $path_to_tmp_project -part $projPart

add_files -norecurse ${path_to_hdl}
add_files -norecurse ${path_to_hdl_debug}/bandwidth_reg.v
add_files -norecurse ${path_to_hdl_debug}/6to3_reducer.vhd
add_files -norecurse ${path_to_hdl_debug}/counter_64_7_v3.vhd

set_property top traffic_generator [current_fileset]
update_compile_order -fileset sources_1

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
ipx::associate_bus_interfaces -busif S_AXIS_n2k -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif M_AXIS_k2n -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif M_AXIS_summary -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif S_AXIL -clock ap_clk [ipx::current_core]


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

package_xo -xo_path ${xoname} -kernel_name ${krnl_name} -ip_directory ./packaged_kernel_${suffix} -kernel_xml ./kernel.xml
