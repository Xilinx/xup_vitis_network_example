################################################################################################
# vcu118_qsfp0 constraint 
################################################################################################

set_property PACKAGE_PIN U8 [get_ports gt_ref_clk_n]
set_property PACKAGE_PIN U9 [get_ports gt_ref_clk_p]
create_clock -period 6.4 [get_ports gt_ref_clk_p]