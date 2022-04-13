// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#pragma once

#include <sstream>

#include "fpga_ip.h"


/**
*
* @brief AlveoVnxNetworkLayer class
*
* Wrapper over xrt::ip class that provides access to NetworkLayer RTL module in XUP VNx
* It contains a register map with network addresses and some basic statistics
*
**/

class AlveoVnxNetworkLayer : public FpgaIP {

public:
    AlveoVnxNetworkLayer(const FpgaDevice &device, uint32_t inst_id);

    int setSocket(const std::string &remote_ip, uint32_t remote_udp, uint32_t local_udp, int socket_index);

    int runARPDiscovery();

};