// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#pragma once

#include <iostream>
#include <string>
#include <unordered_map>

#include "experimental/xrt_ip.h"

#include "fpga_device.h"


/**
*
* @brief FpgaIP class
*
* Wrapper class over xrt::ip providing managed and unmanaged access to registers
* 
*
**/


class FpgaIP {

protected:
    xrt::ip ip;
    std::unordered_map<std::string, uint32_t> registers_map;

public:
    FpgaIP(const FpgaDevice &device, std::string ip_name);

    int writeRegister(const std::string &reg, uint32_t value);

    int writeRegisterAddr(uint32_t reg_addr, uint32_t value);

    uint32_t readRegister(const std::string &reg);

};