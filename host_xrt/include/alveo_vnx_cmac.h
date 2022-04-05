// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause


#pragma once

#include "fpga_ip.h"


/**
*
* AlveoVnxCmac class
*
* Wrapper over xrt::ip class that provides access to CMAC RTL module in XUP VNx
* It contains a register map with some basic statistics.
* Not mandatory to be used in application, can be used to check link status
*
**/

class AlveoVnxCmac : public FpgaIP {

public:
    AlveoVnxCmac(const FpgaDevice &device, uint32_t inst_id);

};