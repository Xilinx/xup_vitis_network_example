################################################################################################
# alveoU280_qsfp0 constraint 
################################################################################################

set_property PACKAGE_PIN R41 [get_ports gt_ref_clk_n]
set_property PACKAGE_PIN R40 [get_ports gt_ref_clk_p]
create_clock -period 6.206 [get_ports gt_ref_clk_p]