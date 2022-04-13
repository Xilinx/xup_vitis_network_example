// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause


#pragma once


#include "fpga_kernel.h"
#include "alveo_vnx_configs.h"



/**
 * @brief AlveoVnxKrnlMM2S
 * 
 * Provides access to XUP VNx basic kernel MM2S used to send UDP data payload
 * from the HBM memory channel
 * Extends the kernel with the xrt::bo data buffer and user functions 
 * to migrate the data and control the kernel
 * 
 */

class AlveoVnxKrnlMM2S : public FpgaKernel {

private:
    xrt::bo xrt_buffer;
    size_t buffer_size;

public:
    AlveoVnxKrnlMM2S(const FpgaDevice &device, uint32_t inst_id);

    int transferDataToKrnl(char *data, size_t size);

    int sendPacket(uint32_t dest_socket);

};