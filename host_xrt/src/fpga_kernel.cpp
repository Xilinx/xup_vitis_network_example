// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#include "fpga_kernel.h"


/**
* FpgaKernel::FpgaKernel() - class constructor
*
* @param device
*  xrt::device, particular Alveo device type to connect to
* @param uuid
*  xrt::uuid, unique ID of the Alveo device
* @param kernel_name
*  string, particular kernel instance of Compute Unit name
*
* Creates an object for accessing the HW kernel
*/
FpgaKernel::FpgaKernel(const FpgaDevice &device, const std::string &kernel_name) : device(device.getDevice()) {
    this->kernel = xrt::kernel(device.getDevice(), device.getUUID(), kernel_name);
}

