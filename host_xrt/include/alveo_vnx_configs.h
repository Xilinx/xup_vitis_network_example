// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause


#pragma once


/**
 * @brief Target Xilinx Alveo device type and shell version
 * 
 */
#define ALVEO_DEVICE "xilinx_u280_xdma_201920_3"


/**
 * @brief UDP Payload size (max 65536 reduced by header and rounded for 512b word alignment)
 * 
 */
#define MAX_UDP_BUFFER_SIZE 65532