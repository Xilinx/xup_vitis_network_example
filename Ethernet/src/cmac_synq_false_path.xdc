################################################################################################
# cmac_synq false path
################################################################################################

set_false_path -through [get_nets cmac_bd_*/usr_rx_reset]
set_false_path -through [get_nets cmac_bd_*/usr_tx_reset]
set_false_path -through [get_nets cmac_bd_*/cmac_stat_rx_aligned]