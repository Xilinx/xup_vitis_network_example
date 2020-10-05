################################################################################################
# alveoU250_qsfp0 constraint 
################################################################################################

set_property PACKAGE_PIN K10 [get_ports gt_ref_clk_n]
set_property PACKAGE_PIN K11 [get_ports gt_ref_clk_p]
create_clock -period 6.206 [get_ports gt_ref_clk_p]


#set_property PACKAGE_PIN N8 [get_ports qsfp0_TX_N0]
#set_property PACKAGE_PIN N9 [get_ports qsfp0_TX_P0]
#set_property PACKAGE_PIN N3 [get_ports qsfp0_RX_N0]
#set_property PACKAGE_PIN N4 [get_ports qsfp0_RX_P0]
#set_property PACKAGE_PIN M6 [get_ports qsfp0_TX_N1]
#set_property PACKAGE_PIN M7 [get_ports qsfp0_TX_P1]
#set_property PACKAGE_PIN M1 [get_ports qsfp0_RX_N1]
#set_property PACKAGE_PIN M2 [get_ports qsfp0_RX_P1]
#set_property PACKAGE_PIN L8 [get_ports qsfp0_TX_N2]
#set_property PACKAGE_PIN L9 [get_ports qsfp0_TX_P2]
#set_property PACKAGE_PIN L3 [get_ports qsfp0_RX_N2]
#set_property PACKAGE_PIN L4 [get_ports qsfp0_RX_P2]
#set_property PACKAGE_PIN K6 [get_ports qsfp0_TX_N3]
#set_property PACKAGE_PIN K7 [get_ports qsfp0_TX_P3]
#set_property PACKAGE_PIN K1 [get_ports qsfp0_RX_N3]
#set_property PACKAGE_PIN K2 [get_ports qsfp0_RX_P3]