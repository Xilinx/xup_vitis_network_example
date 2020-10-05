################################################################################################
# cmac_synq false path
################################################################################################

set_false_path -through [get_nets usr_rx_reset]
set_false_path -through [get_nets usr_tx_reset]
set_false_path -through [get_nets lbus_tx_rx_restart_in]
set_false_path -through [get_nets cmac_stat_stat_rx_aligned]