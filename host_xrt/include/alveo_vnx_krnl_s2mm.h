// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause


#pragma once


#include "fpga_kernel.h"
#include "alveo_vnx_configs.h"


/**
 * @brief AlveoVnxKrnlS2MM class
 * 
 * Provides access to XUP VNx basic kernel S2MM used to receive UDP data payload
 * and store it in HBM memory
 * Extends the kernel with the xrt::bo data buffer and user functions 
 * to migrate the data and control the kernel
 * 
 */


class AlveoVnxKrnlS2MM : public FpgaKernel {

private:
    xrt::bo xrt_buffer;
    uint32_t buffer_size;

public:
    AlveoVnxKrnlS2MM(const FpgaDevice &device, uint32_t inst_id);

    int transferDataToHost(char *data);

    int receivePacket(size_t size);
};