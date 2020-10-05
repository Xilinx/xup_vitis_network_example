################################################################################################
# vcu118_qsfp0 constraint 
################################################################################################

set_property PACKAGE_PIN N8 [get_ports gt_ref_clk_n]
set_property PACKAGE_PIN N9 [get_ports gt_ref_clk_p]
create_clock -period 6.4 [get_ports gt_ref_clk_p]