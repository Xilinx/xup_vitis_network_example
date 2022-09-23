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

stats_t CMAC::statistics() {
  stats_t stats{};

  // TODO: implement function

  return stats;
}
} // namespace vnx
