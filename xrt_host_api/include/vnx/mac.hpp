// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#pragma once

#include <cstddef>
#include <xrt/xrt_device.h>

namespace vnx {
/**
 * Get the mac address of the FPGA. Retrieves the first mac address by default.
 */
std::string get_mac_address(xrt::device &device, std::size_t index = 0);
} // namespace vnx
