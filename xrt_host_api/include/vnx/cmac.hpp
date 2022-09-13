// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#pragma once

#include <experimental/xrt_ip.h>
#include <map>
#include <string>

namespace vnx {
constexpr size_t stat_tx_status = 0x0200;
constexpr size_t stat_rx_status = 0x0204;

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

  // TODO: implement this function
  stats_t statistics();

private:
  xrt::ip cmac;
};
} // namespace vnx
