// Copyright (C) 2022 Advanced Micro Devices
//
// SPDX-License-Identifier: BSD-3-Clause

#include "xrt_platform.h"
#ifdef INFO_PLATFORM

/**
* XrtPlatform::XrtPlatform() - class constructor
*
* @param device
*  xrt::device, xrt device
*
*/
XrtPlatform::XrtPlatform(xrt::device device) {
    std::stringstream platform_ss;
    this->device = device;
    this->platform = device.get_info<xrt::info::device::platform>();
    platform_ss << this->platform;
    boost::property_tree::read_json(platform_ss, this->pt_platform);
}

/**
* XrtPlatform::getMacAddr() - gets the MAC address
*
* @param index
*  uint8_t, index of the MAC address to retrieve
*
* @return
*  Returns an std::string with the MAC address based on the provided index
*
*/
std::string XrtPlatform::getMacAddr(uint8_t index) {
    boost::property_tree::ptree empty_ptree;
    const boost::property_tree::ptree& platforms = this->pt_platform.get_child("platforms", empty_ptree);
    std::vector<std::string> mac_addr;
    uint8_t idx;

    for(auto& kp : platforms) {
        const boost::property_tree::ptree& pt_platforms = kp.second;
        const boost::property_tree::ptree& macs = pt_platforms.get_child("macs", empty_ptree);
        if(!macs.empty()) {
            for(auto& km : macs) {
                const boost::property_tree::ptree& pt_mac = km.second;
                mac_addr.push_back(pt_mac.get<std::string>("address"));
            }
        }
    }

    if (mac_addr.empty()){
        std::cout << "Mac address empty" << std::endl;
        return std::string("d3:a0:07:87:fa:27");
    }
    idx = (index > mac_addr.size()) ? mac_addr.size() -1 : index;
    return mac_addr[idx];
}

/**
* XrtPlatform::getPlatform() - gets the xrt platform
*
* @return
*  Returns an xrt::info::device::platform platfrom
*
*/
std::string XrtPlatform::getPlatform(void) {
    return this->platform;
}

/**
* XrtPlatform::getClock() - gets the MAC address
*
* @param clock_id
*  std::string, clock ID
*
* @return
*  Returns clock frequency for a given clock id in MHz
*
*/
uint32_t XrtPlatform::getClock(std::string clock_id) {
    boost::property_tree::ptree empty_ptree;
    const boost::property_tree::ptree& platforms = this->pt_platform.get_child("platforms", empty_ptree);
    std::unordered_map<std::string, int> clock_freq;

    for(auto& kp : platforms) {
        const boost::property_tree::ptree& pt_platforms = kp.second;
        const boost::property_tree::ptree& clocks = pt_platforms.get_child("clocks", empty_ptree);
        if(!clocks.empty()) {
            for(auto& km : clocks) {
                const boost::property_tree::ptree& pt_clock = km.second;
                std::string id = pt_clock.get<std::string>("id");
                clock_freq[id] = atoi(pt_clock.get<std::string>("freq_mhz").c_str());
            }
        }
    }
    
    return clock_freq[clock_id];
}

#endif
