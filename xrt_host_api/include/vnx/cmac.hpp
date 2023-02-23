// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#pragma once

#include <experimental/xrt_ip.h>
#include <map>
#include <string>

namespace vnx {
struct stats_t {
  std::map<std::string, std::uint32_t> tx;
  std::map<std::string, std::uint32_t> rx;
  std::uint32_t cycle_count;
};

class CMAC {
public:
  CMAC(xrt::ip &cmac);
  CMAC(xrt::ip &&cmac);

  /**
   * Retrieves the link status from the CMAC kernel.
   *
   * Contains boolean status for the following keys:
   * rx_status
   * rx_aligned
   * rx_misaligned
   * rx_aligned_err
   * rx_hi_ber
   * rx_remote_fault
   * rx_local_fault
   * rx_got_signal_os
   * tx_local_fault
   */
  std::map<std::string, bool> link_status();

  /* Retrieves stats from the CMAC kernel. Will also copy internal registers
   * over if update_registers is true. */
  stats_t statistics(bool update_registers = false);

  /* Set GT loopback */
  void set_loopback(bool loopback);

  /* Get GT loopback */
  bool get_loopback();

  /* Set RS FEC */
  void set_rs_fec(bool rs_fec);

  /* Get RS FEC */
  bool get_rs_fec();

private:
  xrt::ip cmac;

  void update_statistics_registers();
};

// Register Map
// Extracted from Ethernet/template.xml
// CMAC
constexpr std::size_t gt_reset_reg = 0x0000;
constexpr std::size_t reset_reg = 0x0004;
constexpr std::size_t mode = 0x0008;
constexpr std::size_t conf_tx = 0x000C;
constexpr std::size_t conf_rx = 0x0014;
constexpr std::size_t core_mode = 0x0020;
constexpr std::size_t version = 0x0024;
constexpr std::size_t gt_loopback = 0x0090;
constexpr std::size_t user_reg0 = 0x00CC;
constexpr std::size_t stat_tx_status = 0x0200;
constexpr std::size_t stat_rx_status = 0x0204;
constexpr std::size_t stat_status = 0x0208;
constexpr std::size_t stat_rx_block_lock = 0x020C;
constexpr std::size_t stat_rx_lane_sync = 0x0210;
constexpr std::size_t stat_rx_lane_sync_err = 0x0214;
constexpr std::size_t stat_an_link_ctl = 0x0260;
constexpr std::size_t stat_lt_status = 0x0264;
constexpr std::size_t stat_pm_tick = 0x02B0;
constexpr std::size_t stat_cycle_count = 0x02B8;
// Tx Stats
constexpr std::size_t stat_tx_total_packets = 0x0500;
constexpr std::size_t stat_tx_total_good_packets = 0x0508;
constexpr std::size_t stat_tx_total_bytes = 0x0510;
constexpr std::size_t stat_tx_total_good_bytes = 0x0518;
constexpr std::size_t stat_tx_total_packets_64B = 0x0520;
constexpr std::size_t stat_tx_total_packets_65_127B = 0x0528;
constexpr std::size_t stat_tx_total_packets_128_255B = 0x0530;
constexpr std::size_t stat_tx_total_packets_256_511B = 0x0538;
constexpr std::size_t stat_tx_total_packets_512_1023B = 0x0540;
constexpr std::size_t stat_tx_total_packets_1024_1518B = 0x0548;
constexpr std::size_t stat_tx_total_packets_1519_1522B = 0x0550;
constexpr std::size_t stat_tx_total_packets_1523_1548B = 0x0558;
constexpr std::size_t stat_tx_total_packets_1549_2047B = 0x0560;
constexpr std::size_t stat_tx_total_packets_2048_4095B = 0x0568;
constexpr std::size_t stat_tx_total_packets_4096_8191B = 0x0570;
constexpr std::size_t stat_tx_total_packets_8192_9215B = 0x0578;
constexpr std::size_t stat_tx_total_packets_large = 0x0580;
constexpr std::size_t stat_tx_total_packets_small = 0x0588;
constexpr std::size_t stat_tx_total_bad_fcs = 0x05B8;
constexpr std::size_t stat_tx_pause = 0x05F0;
constexpr std::size_t stat_tx_user_pause = 0x05F8;
// Rx Stats
constexpr std::size_t stat_rx_total_packets = 0x0608;
constexpr std::size_t stat_rx_total_good_packets = 0x0610;
constexpr std::size_t stat_rx_total_bytes = 0x0618;
constexpr std::size_t stat_rx_total_good_bytes = 0x0620;
constexpr std::size_t stat_rx_total_packets_64B = 0x0628;
constexpr std::size_t stat_rx_total_packets_65_127B = 0x0630;
constexpr std::size_t stat_rx_total_packets_128_255B = 0x0638;
constexpr std::size_t stat_rx_total_packets_256_511B = 0x0640;
constexpr std::size_t stat_rx_total_packets_512_1023B = 0x0648;
constexpr std::size_t stat_rx_total_packets_1024_1518B = 0x0650;
constexpr std::size_t stat_rx_total_packets_1519_1522B = 0x0658;
constexpr std::size_t stat_rx_total_packets_1523_1548B = 0x0660;
constexpr std::size_t stat_rx_total_packets_1549_2047B = 0x0668;
constexpr std::size_t stat_rx_total_packets_2048_4095B = 0x0670;
constexpr std::size_t stat_rx_total_packets_4096_8191B = 0x0678;
constexpr std::size_t stat_rx_total_packets_8192_9215B = 0x0680;
constexpr std::size_t stat_rx_total_packets_large = 0x0688;
constexpr std::size_t stat_rx_total_packets_small = 0x0690;
constexpr std::size_t stat_rx_total_packets_undersize = 0x0698;
constexpr std::size_t stat_rx_total_packets_fragmented = 0x06A0;
constexpr std::size_t stat_rx_total_packets_oversize = 0x06A8;
constexpr std::size_t stat_rx_total_packets_toolong = 0x06B0;
constexpr std::size_t stat_rx_total_packets_jabber = 0x06B8;
constexpr std::size_t stat_rx_total_bad_fcs = 0x06C0;
constexpr std::size_t stat_rx_packets_bad_fcs = 0x06C8;
constexpr std::size_t stat_rx_stomped_fcs = 0x06D0;
constexpr std::size_t stat_rx_pause = 0x06F8;
constexpr std::size_t stat_rx_user_pause = 0x0700;
// FEC
constexpr std::size_t rsfec_config_ind_corr = 0x1000;
constexpr std::size_t rsfec_config_enable = 0x107C;
} // namespace vnx
