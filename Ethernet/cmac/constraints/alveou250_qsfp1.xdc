################################################################################################
# alveoU250_qsfp1 constraint 
################################################################################################

set_property PACKAGE_PIN P10 [get_ports gt_ref_clk_n]
set_property PACKAGE_PIN P11 [get_ports gt_ref_clk_p]
create_clock -period 6.206 [get_ports gt_ref_clk_p]


#set_property PACKAGE_PIN U8 [get_ports qsfp1_TX_N0]
#set_property PACKAGE_PIN U9 [get_ports qsfp1_TX_P0]
#set_property PACKAGE_PIN U3 [get_ports qsfp1_RX_N0]
#set_property PACKAGE_PIN U4 [get_ports qsfp1_RX_P0]
#set_property PACKAGE_PIN T6 [get_ports qsfp1_TX_N1]
#set_property PACKAGE_PIN T7 [get_ports qsfp1_TX_P1]
#set_property PACKAGE_PIN T1 [get_ports qsfp1_RX_N1]
#set_property PACKAGE_PIN T2 [get_ports qsfp1_RX_P1]
#set_property PACKAGE_PIN R8 [get_ports qsfp1_TX_N2]
#set_property PACKAGE_PIN R9 [get_ports qsfp1_TX_P2]
#set_property PACKAGE_PIN R3 [get_ports qsfp1_RX_N2]
#set_property PACKAGE_PIN R4 [get_ports qsfp1_RX_P2]
#set_property PACKAGE_PIN P6 [get_ports qsfp1_TX_N3]
#set_property PACKAGE_PIN P7 [get_ports qsfp1_TX_P3]
#set_property PACKAGE_PIN P1 [get_ports qsfp1_RX_N3]
#set_property PACKAGE_PIN P2 [get_ports qsfp1_RX_P3]