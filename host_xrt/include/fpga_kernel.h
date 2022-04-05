// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#pragma once

#include <iostream>
#include <string>
#include <unordered_map>

#include "experimental/xrt_kernel.h"
#include "experimental/xrt_bo.h"

#include "fpga_device.h"


/**
*
* @brief FpgaKernel class
*
* Wrapper class over xrt::kernel
*
**/

class FpgaKernel {

protected:
    xrt::kernel kernel;
    const xrt::device &device;

public:
    FpgaKernel(const FpgaDevice &device, const std::string &kernel_name);

};