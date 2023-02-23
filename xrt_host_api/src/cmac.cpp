// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#include "vnx/cmac.hpp"
#include <bitset>
#include <map>
#include <string>

namespace vnx {
CMAC::CMAC(xrt::ip &cmac) : cmac(cmac) {}
CMAC::CMAC(xrt::ip &&cmac) : cmac(cmac) {}

std::map<std::string, bool> CMAC::link_status() {
  std::map<std::string, bool> status_dict;

  uint32_t l_rxStatus = cmac.read_register(stat_rx_status);
  std::bitset<32> l_rxBits(l_rxStatus);
  uint32_t l_txStatus = cmac.read_register(stat_tx_status);
  std::bitset<32> l_txBits(l_txStatus);
  status_dict.insert({"rx_status", l_rxBits.test(0)});
  status_dict.insert({"rx_aligned", l_rxBits.test(1)});
  status_dict.insert({"rx_misaligned", l_rxBits.test(2)});
  status_dict.insert({"rx_aligned_err", l_rxBits.test(3)});
  status_dict.insert({"rx_hi_ber", l_rxBits.test(4)});
  status_dict.insert({"rx_remote_fault", l_rxBits.test(5)});
  status_dict.insert({"rx_local_fault", l_rxBits.test(6)});
  status_dict.insert({"rx_got_signal_os", l_rxBits.test(14)});
  status_dict.insert({"tx_local_fault", l_txBits.test(0)});
  return status_dict;
}

stats_t CMAC::statistics(bool update_reg) {
  stats_t stats{};

  if (update_reg) {
    update_statistics_registers();
  }

  stats.cycle_count = cmac.read_register(stat_cycle_count);

  stats.tx.insert({"packets", cmac.read_register(stat_tx_total_packets)});
  stats.tx.insert({"good_packets", cmac.read_register(stat_tx_total_good_packets)});
  stats.tx.insert({"bytes", cmac.read_register(stat_tx_total_bytes)});
  stats.tx.insert({"good_bytes", cmac.read_register(stat_tx_total_good_bytes)});
  stats.tx.insert({"packets_64B", cmac.read_register(stat_tx_total_packets_64B)});
  stats.tx.insert({"packets_65_127B", cmac.read_register(stat_tx_total_packets_65_127B)});
  stats.tx.insert({"packets_128_255B", cmac.read_register(stat_tx_total_packets_128_255B)});
  stats.tx.insert({"packets_256_511B", cmac.read_register(stat_tx_total_packets_256_511B)});
  stats.tx.insert({"packets_512_1023B", cmac.read_register(stat_tx_total_packets_512_1023B)});
  stats.tx.insert({"packets_1024_1518B", cmac.read_register(stat_tx_total_packets_1024_1518B)});
  stats.tx.insert({"packets_1519_1522B", cmac.read_register(stat_tx_total_packets_1519_1522B)});
  stats.tx.insert({"packets_1523_1548B", cmac.read_register(stat_tx_total_packets_1523_1548B)});
  stats.tx.insert({"packets_1549_2047B", cmac.read_register(stat_tx_total_packets_1549_2047B)});
  stats.tx.insert({"packets_2048_4095B", cmac.read_register(stat_tx_total_packets_2048_4095B)});
  stats.tx.insert({"packets_4096_8191B", cmac.read_register(stat_tx_total_packets_4096_8191B)});
  stats.tx.insert({"packets_8192_9215B", cmac.read_register(stat_tx_total_packets_8192_9215B)});
  stats.tx.insert({"packets_large", cmac.read_register(stat_tx_total_packets_large)});
  stats.tx.insert({"packets_small", cmac.read_register(stat_tx_total_packets_small)});
  stats.tx.insert({"bad_fcs", cmac.read_register(stat_tx_total_bad_fcs)});
  stats.tx.insert({"pause", cmac.read_register(stat_tx_pause)});
  stats.tx.insert({"user_pause", cmac.read_register(stat_tx_user_pause)});

  stats.rx.insert({"packets", cmac.read_register(stat_rx_total_packets)});
  stats.rx.insert({"good_packets", cmac.read_register(stat_rx_total_good_packets)});
  stats.rx.insert({"bytes", cmac.read_register(stat_rx_total_bytes)});
  stats.rx.insert({"good_bytes", cmac.read_register(stat_rx_total_good_bytes)});
  stats.rx.insert({"packets_64B", cmac.read_register(stat_rx_total_packets_64B)});
  stats.rx.insert({"packets_65_127B", cmac.read_register(stat_rx_total_packets_65_127B)});
  stats.rx.insert({"packets_128_255B", cmac.read_register(stat_rx_total_packets_128_255B)});
  stats.rx.insert({"packets_256_511B", cmac.read_register(stat_rx_total_packets_256_511B)});
  stats.rx.insert({"packets_512_1023B", cmac.read_register(stat_rx_total_packets_512_1023B)});
  stats.rx.insert({"packets_1024_1518B", cmac.read_register(stat_rx_total_packets_1024_1518B)});
  stats.rx.insert({"packets_1519_1522B", cmac.read_register(stat_rx_total_packets_1519_1522B)});
  stats.rx.insert({"packets_1523_1548B", cmac.read_register(stat_rx_total_packets_1523_1548B)});
  stats.rx.insert({"packets_1549_2047B", cmac.read_register(stat_rx_total_packets_1549_2047B)});
  stats.rx.insert({"packets_2048_4095B", cmac.read_register(stat_rx_total_packets_2048_4095B)});
  stats.rx.insert({"packets_4096_8191B", cmac.read_register(stat_rx_total_packets_4096_8191B)});
  stats.rx.insert({"packets_8192_9215B", cmac.read_register(stat_rx_total_packets_8192_9215B)});
  stats.rx.insert({"packets_large", cmac.read_register(stat_rx_total_packets_large)});
  stats.rx.insert({"packets_small", cmac.read_register(stat_rx_total_packets_small)});
  stats.rx.insert({"packets_undersize", cmac.read_register(stat_rx_total_packets_undersize)});
  stats.rx.insert({"packets_fragmented", cmac.read_register(stat_rx_total_packets_fragmented)});
  stats.rx.insert({"packets_oversize", cmac.read_register(stat_rx_total_packets_oversize)});
  stats.rx.insert({"packets_toolong", cmac.read_register(stat_rx_total_packets_toolong)});
  stats.rx.insert({"packets_jabber", cmac.read_register(stat_rx_total_packets_jabber)});
  stats.rx.insert({"bad_fcs", cmac.read_register(stat_rx_total_bad_fcs)});
  stats.rx.insert({"packets_bad_fcs", cmac.read_register(stat_rx_total_bad_fcs)});
  stats.rx.insert({"stomped_fcs", cmac.read_register(stat_rx_stomped_fcs)});
  stats.rx.insert({"pause", cmac.read_register(stat_rx_pause)});
  stats.rx.insert({"user_pause", cmac.read_register(stat_rx_user_pause)});

  return stats;
}

void CMAC::set_loopback(bool loopback) {
  cmac.write_register(gt_loopback, loopback ? 0x1 : 0x0);
}

bool CMAC::get_loopback() {
  return cmac.read_register(gt_loopback) == 0x1;
}

void CMAC::set_rs_fec(bool rs_fec) {
  cmac.write_register(rsfec_config_enable, rs_fec ? 0x3 : 0x0);
  cmac.write_register(rsfec_config_ind_corr, rs_fec ? 0x7 : 0x0);
  cmac.write_register(reset_reg, 0xC0000000);
  cmac.write_register(reset_reg, 0);
}

bool CMAC::get_rs_fec() {
  return cmac.read_register(rsfec_config_enable) == 0x3;
}

void CMAC::update_statistics_registers() {
  cmac.write_register(stat_pm_tick, 0x1);
}
} // namespace vnx
