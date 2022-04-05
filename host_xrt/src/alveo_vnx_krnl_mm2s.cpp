// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#include "alveo_vnx_krnl_mm2s.h"

/**
* AlveoVnxKrnlMM2S::AlveoVnxKrnlMM2S() - class constructor
*
* @param device
*  xrt::device, particular Alveo device type to connect to
* @param uuid
*  xrt::uuid, unique ID of the Alveo device
* @param inst_id
*  uint32_t, instance id
*
* Creates an object representing VNX UDP TX
*/

AlveoVnxKrnlMM2S::AlveoVnxKrnlMM2S(const FpgaDevice &device, uint32_t inst_id) :
        FpgaKernel::FpgaKernel(device, "krnl_mm2s:{krnl_mm2s_" + std::to_string(inst_id) + "}"), buffer_size{} {

}


/**
* AlveoVnxKrnlMM2S::transferDataToKrnl() - transfers size amount of bytes from data pointer
*
* @param data
*  char*, pointer to allocated and prepared memory
* @param size
*  size_t, amount of bytes to transfer
* @return
*  0: OK, 1: too much data
*
*  The data is transferred from the host to Alveo HBM memory channel connected to arg 0 of the kernel
*/
int AlveoVnxKrnlMM2S::transferDataToKrnl(char *data, size_t size) {

    if (size > 65536) {
        std::cerr << "ERR: AlveoVnxKrnlMM2S::transferDataToKrnl: too much data to allocate " << size << std::endl;
        return 1;
    }

    this->buffer_size = size;

    this->xrt_buffer = xrt::bo(this->device, size, this->kernel.group_id(0));

    xrt_buffer.write(data);
    xrt_buffer.sync(XCL_BO_SYNC_BO_TO_DEVICE);

    return 0;
}


/**
* AlveoVnxKrnlMM2S::sendPacket() - fires the kernel 
*
* @param dest_socket
*  uint32_t, ID of the predefined socket to use
* @return
*  0: OK
*
*  Calls the kernel to send a packet to a predefined socket
*/
int AlveoVnxKrnlMM2S::sendPacket(uint32_t dest_socket) {

    auto run = xrt::run(this->kernel);
    run.set_arg(0, this->xrt_buffer);
    run.set_arg(2, this->buffer_size);
    run.set_arg(3, dest_socket);

    // asynchronous kernel start
    run.start();
    // wait until kernel finishes
    run.wait();

    //TODO: verify that it is needed
    // for loopback the RX part can get confused
    // with hight packet throughput
    usleep(1000);

    return 0;
}