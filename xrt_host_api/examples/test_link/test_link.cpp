// Copyright (C) 2024 Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include <iostream>
#include <chrono>
#include <experimental/xrt_ip.h>
#include <filesystem>
#include <json/json.h>
#include <limits.h>
#include <map>
#include <string>
#include <sys/wait.h>
#include <thread>
#include <unistd.h>
#include <vnx/cmac.hpp>
#include <xrt/xrt_device.h>
namespace fs = std::filesystem;


enum xclbin_types {  if0, if1, if3 };

struct xclbin_path {
    std::string path;
    xclbin_types type;
};
// Map type of xclbin to contained kernels
const std::map<xclbin_types,
               const std::vector<std::pair<const char *, const char *>>>
kernels = {
            {if0, {{"cmac_0"}}},
            {if1, {{"cmac_1"}}},
            {if3, {{"cmac_0"}, {"cmac_1"}}}
         };


xclbin_path parse_xclbin(const std::string &platform, const char *arg) {
    // Determine content of xclbin based on filename and platform.
    xclbin_path xclbin;
    xclbin.path = arg;
    std::string filename = fs::path(arg).filename();

    bool found = true;

    if (filename.find("if0.xclbin") != std::string::npos) {
        xclbin.type = if0;
    } else if (filename.find("if1.xclbin") != std::string::npos) {
        xclbin.type = if1;
    } else if (filename.find("if3.xclbin") != std::string::npos) {
        xclbin.type = if3;
    }
    else{
        found = false;
    }

    if (!found) {
    throw std::runtime_error("Unexpected xclbin file " + filename +
                                " with platform " + platform);
    }

    return xclbin;
}

Json::Value parse_json(const std::string &string) {
    Json::Reader reader;
    Json::Value json;
    reader.parse(string, json);
    return json;
}

int main(int argc, char *argv[]) {
    // Retrieve host and device information
    char hostname[HOST_NAME_MAX];
    gethostname(hostname, HOST_NAME_MAX);
    int device_id = 0;
    std::size_t ip_index = 0;

    // Read xclbin files from commandline
    std::vector<const char *> args(argv + 1, argv + argc);

    if (args.size() < 1) {
        std::cerr << "No xclbin provided" << std::endl;
        return 1;
    }

    if (args.size() >= 2) {
        device_id = std::stoi(args[1]);
        std::cerr << "Loading XRT device " << device_id << std::endl;
    }

    xrt::device device = xrt::device(device_id);
    // Collect platform info from xclbin
    const std::string platform_json =
    device.get_info<xrt::info::device::platform>();
    const Json::Value platform_dict = parse_json(platform_json);
    const std::string platform =
    platform_dict["platforms"][0]["static_region"]["vbnv"].asString();
    std::cout << "FPGA platform: " << platform << std::endl;

    const xclbin_path xclbin = parse_xclbin(platform, args[0]);
    auto xclbin_uuid = device.load_xclbin(xclbin.path);
    std::cout << "Loaded " << xclbin.path << " onto FPGA on " << hostname << std::endl;
    // Give time for xclbin to be loaded completely before attempting to read
    // the link status.
    std::this_thread::sleep_for(std::chrono::seconds(0.5));

    // Loop over compute units in xclbin
    for (const auto &cus : kernels.at(xclbin.type)) {
        auto cmac = vnx::CMAC(xrt::ip(device, xclbin_uuid,
                    std::string(cus.first) + ":{" +
                    std::string(cus.first) + "}"));
        // Enable rsfec if necessary
        cmac.set_rs_fec(false);

        bool link_status;

        // Can take a few tries before link is ready.
        for (std::size_t i = 0; i < 5; ++i) {
            auto status = cmac.link_status();
            link_status = status["rx_status"];
            if (link_status) {
                break;
            }
            std::this_thread::sleep_for(std::chrono::seconds(1));
            }
        std::cout << "Link interface " << cus.first << ": "
                  << (link_status ? "true" : "false") << std::endl;

        std::cout << "RS-FEC enabled: " << (cmac.get_rs_fec() ? "true" : "false")
                  << std::endl;
    }
    return 0;
}
