################################################################################################
# vcu1525_qsfp1 constraint 
################################################################################################

set_property PACKAGE_PIN P10 [get_ports gt_ref_clk_n]
set_property PACKAGE_PIN P11 [get_ports gt_ref_clk_p]
create_clock -period 6.206 [get_ports gt_ref_clk_p]