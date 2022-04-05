// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#include "alveo_vnx_cmac.h"

/**
* AlveoVnxCmac::AlveoVnxCmac() - class constructor
*
* @param device
*  xrt::device, particular Alveo device type to connect to
* @param uuid
*  xrt::uuid, unique ID of the Alveo device
* @param inst_id
*  uint32_t, instance id
*
* Creates an object representing VNX CMAC IP
*/
AlveoVnxCmac::AlveoVnxCmac(const FpgaDevice &device, uint32_t inst_id) :
        FpgaIP::FpgaIP(device, "cmac_" + std::to_string(inst_id)) {

    this->registers_map["stat_rx_status"] = 0x0204;
    this->registers_map["stat_rx_total_packets"] = 0x0608;
}
