// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#include "fpga_device.h"

/**
* FpgaDevice::FpgaDevice() - class constructor
*
* @param device_idx
*  int, index of the Alveo card in the PCIe bus,
*       possibly the card PCIe ID
*
* Connects to the specified Alveo device
*/
FpgaDevice::FpgaDevice(uint32_t device_idx) {

    // create object and connect to the device
    this->device = xrt::device(device_idx);
}


/**
* FpgaDevice::loadBitfile() - configures the FPGA
*
* @param bitfile
*  string, full path to the fpga bitfile with compiled kernels
* @return
*  string, unique id of the bitfile
*
* Programs the FPGA with a specified bitfile,
* Skips if the board is already programmed
*/
std::string FpgaDevice::loadBitfile(const std::string &bitfile) {

    this->uuid = this->device.load_xclbin(bitfile);

    return this->uuid.to_string();
}