// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#pragma once

#include <iostream>
#include <string>
#include <unordered_map>

#include "experimental/xrt_bo.h"
#include "experimental/xrt_device.h"
#include "experimental/xrt_kernel.h"
#include "experimental/xrt_ip.h"

#include "alveo_vnx_configs.h"


/**
*
* @brief FpgaDevice class
*
* Wrapper class over xrt::device providing access to the device,
* xclbin loading and fetching information
*
**/

class FpgaDevice {

private:
    xrt::device device;
    xrt::uuid uuid;

public:
    explicit FpgaDevice(uint32_t device_idx);

    std::string loadBitfile(const std::string &bitfile);

    const xrt::device &getDevice() const { return this->device; };

    const xrt::uuid &getUUID() const { return this->uuid; };

    std::string getUUIDString() { return this->uuid.to_string(); }

    std::string getName() { return this->device.get_info<xrt::info::device::name>(); }; 

    // std::string getMAC()  { return this->device.get_info<xrt::info::device::platform>(); } ;

};