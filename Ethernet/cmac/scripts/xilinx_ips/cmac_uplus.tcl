# Default GT reference frequency
set gt_ref_clk 156.25
if {$use_board eq "ALVEO-U50"} {
    # Possible core_selection CMACE4_X0Y3 and CMACE4_X0Y4
    set gt_ref_clk 161.1328125
    set core_selection  CMACE4_X0Y3
    set group_selection X0Y28~X0Y31
    set interface_number 0

} elseif {$use_board eq "ALVEO-U200"} {
    switch $integrated_interface {
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
} elseif {$use_board eq "ALVEO-U250"} {
    switch $integrated_interface {
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
} elseif {$use_board eq "ALVEO-U280"} {
    switch $integrated_interface {
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
    puts "unknown Board"
    return -1
}

set cmac_name cmac_uplus_${interface_number}

puts $cmac_name

# Read the files from the corresponding folder
read_verilog -sv $origin_dir/src/patch_files/cmac_connector_wrapper_${interface_number}.sv
read_verilog -sv $origin_dir/src/patch_files/cmac_connector_${interface_number}.sv
read_verilog -sv $origin_dir/src/patch_files/cmac_uplus_wrapper_${interface_number}.sv

# Create a CMAC Ultrascale Plus core

create_ip -name cmac_usplus -vendor xilinx.com -library ip -module_name ${cmac_name}

set_property -dict [list \
    CONFIG.CMAC_CAUI4_MODE           {1} \
    CONFIG.NUM_LANES                 {4x25} \
    CONFIG.GT_REF_CLK_FREQ           $gt_ref_clk \
    CONFIG.CMAC_CORE_SELECT          $core_selection \
    CONFIG.GT_GROUP_SELECT           $group_selection \
    CONFIG.INCLUDE_SHARED_LOGIC      {2} \
    CONFIG.LANE5_GT_LOC              {NA} \
    CONFIG.LANE6_GT_LOC              {NA} \
    CONFIG.LANE7_GT_LOC              {NA} \
    CONFIG.LANE8_GT_LOC              {NA} \
    CONFIG.LANE9_GT_LOC              {NA} \
    CONFIG.LANE10_GT_LOC             {NA} \
    CONFIG.OPERATING_MODE            {Duplex} \
    CONFIG.TX_FLOW_CONTROL           {0} \
    CONFIG.RX_FLOW_CONTROL           {0} \
    CONFIG.ENABLE_AXI_INTERFACE      {1} \
    CONFIG.RX_CHECK_ACK              {1} \
    CONFIG.ENABLE_TIME_STAMPING      {0} \
    CONFIG.TX_PTP_1STEP_ENABLE       {2} \
    CONFIG.PTP_TRANSPCLK_MODE        {0} \
    CONFIG.TX_PTP_LATENCY_ADJUST     {0} \
    CONFIG.ENABLE_PIPELINE_REG       {1} \
] [get_ips $cmac_name]


generate_target all [get_files  $project_dir/$project_name/$project_name.srcs/sources_1/ip/${cmac_name}/${cmac_name}.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] $project_dir/$project_name/$project_name.srcs/sources_1/ip/${cmac_name}/${cmac_name}.xci]

if {$synthesize_ip} {
    launch_run -jobs 4 ${cmac_name}_synth_1 
    wait_on_run ${cmac_name}_synth_1
}
