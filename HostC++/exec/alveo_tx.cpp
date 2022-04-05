#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
#include <unistd.h>

#include "fpga_device.h"
#include "alveo_vnx_link.h"


int main(int argc, char *argv[]) {

    auto u280 = FpgaDevice(0);
    std::cout << "Device created: " << u280.getName()<<std::endl;

    auto uuid = u280.loadBitfile("vnx_basic_if3.xclbin");
    std::cout << "Bitfile loaded: " << uuid << std::endl;
    

    auto l0 = AlveoVnxLink(u280, 0);
    l0.setMyAddresses("192.168.0.1", "ab:cd:ef:01:01", 10000);

    std::cout << "l0 created" << std::endl;


    std::ifstream infile("vnx_bin_transfer", std::ios::binary | std::ios::ate);
    size_t infile_size = infile.tellg();
    infile.seekg(0, std::ios::beg);

    char *tx_buf = new char[infile_size];
    infile.read(tx_buf, infile_size);
    infile.close();

    // char* tx_buf = new char[210];
    // for (int i = 0; i < 210; i++) {
    //     tx_buf[i] =  0xf;
    // }

    l0.sendTo("192.168.0.2", 10001, tx_buf, infile_size);

    std::cout << "Packet sent" << std::endl;

    return 0;
}
