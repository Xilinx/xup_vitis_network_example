#include "fpga_device.h"

/**
* FpgaDevice::FpgaDevice() - class constructor
*
* @param device_idx
*  int, index of the Alveo card in the PCIe bus,
*       possibly the card PCIe ID
*
* Connects to the specified Alveo device
*/
FpgaDevice::FpgaDevice(uint32_t device_idx) {

    // create object and connect to the device
    this->device = xrt::device(device_idx);

    // fetch the string with the card name and compare to the target
    std::string name = this->getName();
    if ( name.compare(ALVEO_DEVICE) != 0) {
        std::cerr << "ERR: FpgaDevice: could not connect to the target accelerator card" << std::endl;
    }
}


/**
* FpgaDevice::loadBitfile() - configures the FPGA
*
* @param bitfile
*  string, full path to the fpga bitfile with compiled kernels
* @return
*  string, unique id of the bitfile
*
* Programs the FPGA with a specified bitfile,
* Skips if the board is already programmed
*/
std::string FpgaDevice::loadBitfile(const std::string &bitfile) {

    this->uuid = this->device.load_xclbin(bitfile);

    return this->uuid.to_string();
}