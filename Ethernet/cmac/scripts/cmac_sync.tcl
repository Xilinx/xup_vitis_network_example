set project_dir "[file normalize "/tmp"]"
set project_name "vivado_project_delete_me"
set synthesize_ip false


if {$argc != 1} {
	puts "Expected one argument with the path to the sources. Have you forgotten how to execute me? Try"
	puts "   vivado -mode batch -source package_ip.tcl -tclargs path_to_the_directory_with_sources"
	exit -1
}
set project_controller [lindex $argv 0]
set core_name "cmac_sync"


create_project -force $project_name $project_dir/$project_name   -part xcvu095-ffva2104-2-e


read_verilog -sv $project_controller/src/cmac_sync/cmac_sync.sv
read_verilog -sv $project_controller/src/cmac_sync/cmac_sync_wrapper.sv
read_verilog -sv $project_controller/src/cmac_sync/cmac_0_axi4_lite_user_if.v
read_verilog -sv $project_controller/src/cmac_sync/rx_sync.v
read_verilog -sv $project_controller/src/cmac_sync/tx_sync.v
read_verilog -sv $project_controller/src/common/cmac_0_cdc.v
read_verilog -sv $project_controller/src/common/types.svh

add_files -fileset constrs_1 -norecurse $project_controller/constraints/cmac_synq_false_path.xdc

set_property top cmac_sync_wrapper [current_fileset]



ipx::package_project  -import_files -root_dir $project_controller/project/$core_name -vendor xilinx.com -library cmac -taxonomy /UserIP

set_property vendor xilinx.com [ipx::current_core]
set_property library cmac [ipx::current_core]
set_property name $core_name [ipx::current_core]
set_property display_name $core_name [ipx::current_core]
set_property description $core_name [ipx::current_core]
set_property version 1 [ipx::current_core]
set_property core_revision 1 [ipx::current_core]

set_property display_name {Ultrascale_Plus} [ipgui::get_guiparamspec -name "ULTRASCALE_PLUS" -component [ipx::current_core] ]
set_property widget {checkBox} [ipgui::get_guiparamspec -name "ULTRASCALE_PLUS" -component [ipx::current_core] ]
set_property value false [ipx::get_user_parameters ULTRASCALE_PLUS -of_objects [ipx::current_core]]
set_property value false [ipx::get_hdl_parameters ULTRASCALE_PLUS -of_objects [ipx::current_core]]
set_property value_format bool [ipx::get_user_parameters ULTRASCALE_PLUS -of_objects [ipx::current_core]]
set_property value_format bool [ipx::get_hdl_parameters ULTRASCALE_PLUS -of_objects [ipx::current_core]]

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]


close_project
