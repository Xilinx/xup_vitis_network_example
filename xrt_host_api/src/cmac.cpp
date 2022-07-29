/*  Copyright (c) 2020-2022, Xilinx, Inc.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1.  Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 *
 *  2.  Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *  3.  Neither the name of the copyright holder nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 *  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
