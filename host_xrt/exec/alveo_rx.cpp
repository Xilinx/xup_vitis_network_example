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

    std::string xclbin;
    int alveo_id;


    if (argc != 3) {
        std::cout << "Usage: ./rx <xclbin_file> <alveo_id>" << std::endl;
        return EXIT_FAILURE;
    }
    else {
        std::ifstream f(argv[1]);
        if (f.good() == false) {
            std::cout << "Make sure the path to the bitfile <xclbin_file> is correct" << std::endl;
            return EXIT_FAILURE;
        }
        f.close();
        xclbin = std::string(argv[1]);            

        alveo_id = atoi(argv[2]);
        if ( alveo_id < 0 || alveo_id > 15 ) {
            std::cout << "Make sure Alveo ID is a correct number" << std::endl;
            return EXIT_FAILURE;
        }
    }

    auto u280 = FpgaDevice(alveo_id);

    // fetch the string with the card name and compare to the target
    std::string name = u280.getName();
    if ( name.compare(ALVEO_DEVICE) != 0) {
        std::cerr << "ERR: FpgaDevice: could not connect to the target accelerator card" << std::endl;
        return EINVAL;
    }

    std::cout << "Device created: " << u280.getName()<<std::endl;


    auto uuid = u280.loadBitfile(xclbin);
    std::cout << "Bitfile loaded " << uuid << std::endl;
    
    
    auto l1 = AlveoVnxLink(u280, 1);
    l1.setMyAddresses("192.168.0.2", "ab:cd:ef:02:02", 10001);

    std::cout << "l1 created" << std::endl;

    char *rx_buf = new char[1000000];
    size_t size = l1.receive("192.168.0.1", 10000, rx_buf);

    std::cout << "Packet received " << size << " bytes" << std::endl;

    std::ofstream outfile("out.bin", std::ios::binary | std::ios::ate);
    outfile.write(rx_buf, size);
    outfile.close();


    return 0;
}
