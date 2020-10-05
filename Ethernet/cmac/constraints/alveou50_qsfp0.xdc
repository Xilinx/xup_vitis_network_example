################################################################################################
# alveoU50_qsfp0 constraint 
################################################################################################

set_property PACKAGE_PIN N36 [get_ports gt_ref_clk_n]
set_property PACKAGE_PIN N73 [get_ports gt_ref_clk_p]
create_clock -period 6.206 [get_ports gt_ref_clk_p]


#set_property PACKAGE_PIN D42 [get_ports qsfp0_TX_P0]
#set_property PACKAGE_PIN D43 [get_ports qsfp0_TX_N0]
#set_property PACKAGE_PIN J45 [get_ports qsfp0_RX_P0]
#set_property PACKAGE_PIN J46 [get_ports qsfp0_RX_N0]
#set_property PACKAGE_PIN C40 [get_ports qsfp0_TX_P1]
#set_property PACKAGE_PIN C41 [get_ports qsfp0_TX_N1]
#set_property PACKAGE_PIN G45 [get_ports qsfp0_RX_P1]
#set_property PACKAGE_PIN G46 [get_ports qsfp0_RX_N1]
#set_property PACKAGE_PIN B42 [get_ports qsfp0_TX_P2]
#set_property PACKAGE_PIN B43 [get_ports qsfp0_TX_N2]
#set_property PACKAGE_PIN F43 [get_ports qsfp0_RX_P2]
#set_property PACKAGE_PIN F44 [get_ports qsfp0_RX_N2]
#set_property PACKAGE_PIN A40 [get_ports qsfp0_TX_P3]
#set_property PACKAGE_PIN A41 [get_ports qsfp0_TX_N3]
#set_property PACKAGE_PIN E45 [get_ports qsfp0_RX_P3]
#set_property PACKAGE_PIN E46 [get_ports qsfp0_RX_N3]