################################################################################################
# vcu1525_qsfp0 constraint 
################################################################################################

set_property PACKAGE_PIN K10 [get_ports gt_ref_clk_n]
set_property PACKAGE_PIN K11 [get_ports gt_ref_clk_p]
create_clock -period 6.206 [get_ports gt_ref_clk_p]