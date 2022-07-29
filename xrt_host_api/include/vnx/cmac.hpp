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
