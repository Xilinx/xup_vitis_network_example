# Create  a fifo
create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name axi_fifo
set_property -dict [list \
	 CONFIG.INTERFACE_TYPE {AXI_STREAM} \
	 CONFIG.TDATA_NUM_BYTES {64} \
	 CONFIG.Enable_TLAST {true} \
	 CONFIG.HAS_TSTRB {true} \
	 CONFIG.TUSER_WIDTH {0} \
	 CONFIG.FIFO_Implementation_axis {Common_Clock_Builtin_FIFO} \
	 CONFIG.Programmable_Full_Type_axis {Single_Programmable_Full_Threshold_Constant} \
	 CONFIG.Full_Threshold_Assert_Value_axis {460} \
	 CONFIG.Reset_Type {Asynchronous_Reset} \
	 CONFIG.TSTRB_WIDTH {64} \
	 CONFIG.TKEEP_WIDTH {64} \
	 CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} \
	 CONFIG.Full_Threshold_Assert_Value_wach {15} \
	 CONFIG.Empty_Threshold_Assert_Value_wach {14} \
	 CONFIG.FIFO_Implementation_wdch {Common_Clock_Builtin_FIFO} \
	 CONFIG.Input_Depth_wdch {512} \
	 CONFIG.Full_Threshold_Assert_Value_wdch {511} \
	 CONFIG.Empty_Threshold_Assert_Value_wdch {510} \
	 CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} \
	 CONFIG.Full_Threshold_Assert_Value_wrch {15} \
	 CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
	 CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} \
	 CONFIG.Full_Threshold_Assert_Value_rach {15} \
	 CONFIG.Empty_Threshold_Assert_Value_rach {14} \
	 CONFIG.FIFO_Implementation_rdch {Common_Clock_Builtin_FIFO} \
	 CONFIG.Input_Depth_rdch {512} \
	 CONFIG.Full_Threshold_Assert_Value_rdch {511} \
	 CONFIG.Empty_Threshold_Assert_Value_rdch {510} \
	 CONFIG.Input_Depth_axis {512} \
] [get_ips axi_fifo] 

generate_target all [get_files  $project_dir/$project_name/$project_name.srcs/sources_1/ip/axi_fifo/axi_fifo.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $project_dir/$project_name/$project_name.srcs/sources_1/ip/axi_fifo/axi_fifo.xci]


# Generate the Core IPs and synthesize project
if {$synthesize_ip} {
    launch_run -jobs 4 axi_fifo_synth_1 
    wait_on_run axi_fifo_synth_1
}
