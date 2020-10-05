# Create  a fifo
create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_cdc
set_property -dict [list \
	CONFIG.Component_Name {fifo_cdc} \
	CONFIG.Fifo_Implementation {Independent_Clocks_Distributed_RAM} \
	CONFIG.Performance_Options {First_Word_Fall_Through} \
	CONFIG.Input_Data_Width {64} \
	CONFIG.Input_Depth {16} \
	CONFIG.Output_Data_Width {64} \
	CONFIG.Output_Depth {16} \
	CONFIG.Use_Embedded_Registers {false} \
	CONFIG.Reset_Pin {true} \
	CONFIG.Reset_Type {Asynchronous_Reset} \
	CONFIG.Full_Flags_Reset_Value {1} \
	CONFIG.Use_Dout_Reset {true} \
	CONFIG.Data_Count_Width {4} \
	CONFIG.Write_Data_Count_Width {4} \
	CONFIG.Read_Data_Count_Width {4} \
	CONFIG.Full_Threshold_Assert_Value {15} \
	CONFIG.Full_Threshold_Negate_Value {14} \
	CONFIG.Empty_Threshold_Assert_Value {4} \
	CONFIG.Empty_Threshold_Negate_Value {5} \
] [get_ips fifo_cdc] 

generate_target all [get_files  $project_dir/$project_name/$project_name.srcs/sources_1/ip/fifo_cdc/fifo_cdc.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $project_dir/$project_name/$project_name.srcs/sources_1/ip/fifo_cdc/fifo_cdc.xci]


# Generate the Core IPs and synthesize project
if {$synthesize_ip} {
    launch_run -jobs 4 fifo_cdc_synth_1 
    wait_on_run fifo_cdc_synth_1
}