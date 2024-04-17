// Copyright (C) 2024 Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include <iostream>
#include <chrono>
#include <experimental/xrt_ip.h>
#include <filesystem>
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
            {if0, {
                    {"cmac_0", "networklayer_0"}
                  }
            },
            {if1, {
                    {"cmac_1", "networklayer_1"}
                  }
            },
            {if3, {
                    {"cmac_0", "networklayer_0"},
                    {"cmac_1", "networklayer_1"}
                }
            }
         };


xclbin_path parse_xclbin(const char *arg) {
    // Determine content of xclbin based on filename.
    xclbin_path xclbin;
    xclbin.path = arg;
    std::string filename = fs::path(arg).filename();

    bool found = true;

    if (filename.find("if0.xclbin") != std::string::npos)
        xclbin.type = if0;
    else if (filename.find("if1.xclbin") != std::string::npos)
        xclbin.type = if1;
    else if (filename.find("if3.xclbin") != std::string::npos)
        xclbin.type = if3;
    else
        found = false;

    if (!found)
        throw std::runtime_error("Unexpected xclbin file " + filename + ". It does not provide information about the interfaces.");

    return xclbin;
}

int main(int argc, char *argv[]) {
    // Set default device and RS-FEC status
    int device_id = 0;
    bool rs_fec = false;

    // Read xclbin files from commandline
    std::vector<const char *> args(argv + 1, argv + argc);

    if (args.size() < 1) {
        std::cerr << "No xclbin provided" << std::endl;
        std::cerr << argv[0] << " <XCLBIN> <RS-FEC (default 0)> <DEVICE ID (default 0)" << std::endl;
        return 1;
    }

    if (args.size() >= 2) {
        rs_fec = std::stoi(args[1]);
        std::cout << "Configure RS-FEC to: ";
        std::cout << (rs_fec ? "enabled" : "disabled" ) << std::endl;
    }

    if (args.size() >= 3) {
        device_id = std::stoi(args[2]);
        std::cout << "Loading XRT device " << device_id << std::endl;
    }

    xrt::device device = xrt::device(device_id);
    // Collect platform info from xclbin
    const std::string platform_json = device.get_info<xrt::info::device::platform>();

    const xclbin_path xclbin = parse_xclbin(args[0]);
    auto xclbin_uuid = device.load_xclbin(xclbin.path);
    std::cout << "Loaded " << xclbin.path << " onto FPGA" << std::endl;
    // Give time for xclbin to be loaded completely before attempting to read the link status.
    std::this_thread::sleep_for(std::chrono::seconds(1));

    // Loop over compute units in xclbin
    for (const auto &cus : kernels.at(xclbin.type)) {
        auto cmac = vnx::CMAC(xrt::ip(device, xclbin_uuid, std::string(cus.first) + ":{" + std::string(cus.first) + "}"));
        // Enable rsfec depending on user input
        cmac.set_rs_fec(rs_fec);

        bool link_status;

        // Can take a few tries before link is ready.
        for (std::size_t i = 0; i < 6; ++i) {
            auto status = cmac.link_status();
            link_status = status["rx_status"];
            if (link_status)
                break;
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
        std::cout << "Link interface " << cus.first << " link up: " << (link_status ? "true" : "false") << std::endl;
        std::cout << "RS-FEC: " << (cmac.get_rs_fec() ? "enabled" : "disabled") << std::endl;
    }
    return 0;
}
