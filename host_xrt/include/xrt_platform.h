// Copyright (C) 2022 Advanced Micro Devices
//
// SPDX-License-Identifier: BSD-3-Clause

#pragma once

#ifndef _XRT_PLATFORM_
#define _XRT_PLATFORM_

#include <boost/property_tree/json_parser.hpp>
#include "experimental/xrt_device.h"
#include <string>
#include <unordered_map>
#include <vector>

/**
*
* @brief XrtPlatform class
*
* Wrapper class to access the xrt platfrom information
*
**/

class XrtPlatform {

private:
    xrt::device device;
    
    boost::property_tree::ptree pt_platform;

    std::string platform;

public:

    explicit XrtPlatform(xrt::device);

    std::string getMacAddr(uint8_t);

    std::string getPlatform(void);
    
    uint32_t getClock(std::string);
 
};

#endif
