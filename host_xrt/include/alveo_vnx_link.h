// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause


#pragma once

#include "alveo_vnx_cmac.h"
#include "alveo_vnx_nl.h"
#include "alveo_vnx_krnl_mm2s.h"
#include "alveo_vnx_krnl_s2mm.h"


/**
 * @brief AlveoVnxLink class
 * 
 * Encapsulates all required objects to tansmit and receive UDP packets
 * using the XUP VNx design.
 * 
 */

class AlveoVnxLink {

private:
    AlveoVnxCmac *cmac;
    AlveoVnxNetworkLayer *nl;
    AlveoVnxKrnlS2MM *rx;
    AlveoVnxKrnlMM2S *tx;

    uint32_t ip;
    uint64_t mac;
    uint16_t udp;

public:
    AlveoVnxLink(const FpgaDevice &device, uint32_t inst_id);

    ~AlveoVnxLink();

    int setMyAddresses(const std::string &ip_address, const std::string &mac_address, uint16_t udp_port);

    int sendTo(const std::string &dest_ip, uint16_t dest_udp, char *buffer, size_t size);

    int receive(const std::string &src_ip, uint16_t src_udp, char *buffer);

};