# Create  a fifo
create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name lbus_fifo
set_property -dict [list \
	CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
	CONFIG.Performance_Options {Standard_FIFO} \
	CONFIG.Reset_Type {Asynchronous_Reset} \
	CONFIG.Full_Flags_Reset_Value {1} \
	CONFIG.Empty_Threshold_Assert_Value {2} \
	CONFIG.Empty_Threshold_Negate_Value {3} \
	CONFIG.Input_Data_Width {544} \
	CONFIG.Input_Depth {512} \
	CONFIG.Output_Data_Width {544} \
	CONFIG.Output_Depth {512} \
	CONFIG.Data_Count_Width {9} \
	CONFIG.Write_Data_Count_Width {9} \
	CONFIG.Read_Data_Count_Width {9}\
] [get_ips lbus_fifo]
generate_target all [get_files  $project_dir/$project_name/$project_name.srcs/sources_1/ip/lbus_fifo/lbus_fifo.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $project_dir/$project_name/$project_name.srcs/sources_1/ip/lbus_fifo/lbus_fifo.xci]


# Generate the Core IPs and synthesize project
if {$synthesize_ip} {
	launch_run -jobs 4 lbus_fifo_synth_1 
	wait_on_run lbus_fifo_synth_1
}
