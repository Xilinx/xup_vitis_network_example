// Copyright (C) FPGA-FAIS at Jagiellonian University Cracow
//
// SPDX-License-Identifier: BSD-3-Clause



#include "fpga_ip.h"


/**
* FpgaIP::FpgaIP() - class constructor
*
* @param device
*  xrt::device, particular Alveo device type to connect to
* @param uuid
*  xrt::uuid, unique ID of the Alveo device
* @param ip_name
*  string, particular IP instance of Compute Unit name
*
* Creates an object for accessing the HW RTL IPs
*/
FpgaIP::FpgaIP(const FpgaDevice &device, std::string ip_name) {
    this->ip = xrt::ip(device.getDevice(), device.getUUID(), ip_name);
}


/**
* FpgaIP::writeRegister() - writes a value to a specified 
*                               register in HW memory space
*
* @param reg
*  string, name of the register to fetch from the map
* @param value
*  uint32_t, hex value of the register
* @return
*  int, 0 OK, EINVAL register name not found in the map
*
* Searches declared registers and writes a value if it exists
*/
int FpgaIP::writeRegister(const std::string &reg, uint32_t value) {

    if (this->registers_map.find(reg) == this->registers_map.end()) {
        std::cerr << "ERR: FpgaIP: register " << reg << " not found in the registers map" << std::endl;
        return EINVAL;
    } else {
        this->ip.write_register(this->registers_map[reg], value);
        return 0;
    }
}

/**
* FpgaIP::writeRegisterAddr() - writes a value to a specified 
*                                   address in HW memory space
*
* @param reg_addr
*  uint32_t, register address to write to
* @param value
*  uint32_t, hex value of the register
* @return
*  int, 0 OK
*
* Writes a value directly to HW register space
*
* USE WITH CAUTION:
* Unsecure, can disrupt the FPGA operation
*/
int FpgaIP::writeRegisterAddr(uint32_t reg_addr, uint32_t value) {
    this->ip.write_register(reg_addr, value);
    return 0;
}

/**
* FpgaIP::readRegister() - reads a value from a specified 
*                              register in HW memory space
*
* @param reg
*  string, name of the register to fetch from the map
* @return
*  int, 0 OK, EINVAL register name not found in the map
*
*/
uint32_t FpgaIP::readRegister(const std::string &reg) {

    if (this->registers_map.find(reg) == this->registers_map.end()) {
        std::cerr << "ERR: FpgaIP: register " << reg << " not found in the registers map" << std::endl;
        return EINVAL;
    } else {
        return this->ip.read_register(this->registers_map[reg]);
    }
}