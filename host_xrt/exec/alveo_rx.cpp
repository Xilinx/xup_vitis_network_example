// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause

#include <iostream>
#include <fstream>
#include <string>
#include <unistd.h>

#include "fpga_device.h"
#include "alveo_vnx_link.h"


int main(int argc, char *argv[]) {

    auto u280 = FpgaDevice(0);
    std::cout << "Device created: " << u280.getName()<<std::endl;

    auto uuid = u280.loadBitfile("vnx_basic_if3.xclbin");
    std::cout << "Bitfile loaded " << uuid << std::endl;
    
    
    auto l1 = AlveoVnxLink(u280, 1);
    l1.setMyAddresses("192.168.0.2", "ab:cd:ef:02:02", 10001);

    std::cout << "l1 created" << std::endl;

    char *rx_buf = new char[1000000];
    size_t size = l1.receive("192.168.0.1", 10000, rx_buf);

    std::cout << "Packet received " << size << " bytes" << std::endl;

    std::ofstream outfile("a.bin", std::ios::binary | std::ios::ate);
    outfile.write(rx_buf, size);
    outfile.close();


    return 0;
}
