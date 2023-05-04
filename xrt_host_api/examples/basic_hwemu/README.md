# Example hardware emulation
This example program loads a hardware emulation VNx xclbin onto the FPGA, 
tests the link on the network interface, sets the IP address to the FPGA, 
and transfers data to another emulated FPGA.

To compile and run this program first build the `basic` design targeting
hardware emulation, as follows:
```bash
make all INTERFACE=0 DESIGN=basic DEVICE=<DEVICE> BUILD_TARGET=hw_emu
```

Then run the following commands (make sure that XRT is sourced):
```bash
# Compiling the program
mkdir build
cd build
cmake ..
cmake --build .
# Running the program
XCL_EMULATION_MODE=hw_emu ./basic_hwemu <XCLBIN>
```

Note that this program depends on
[jsoncpp](https://github.com/open-source-parsers/jsoncpp), which can be
installed using `sudo apt install libjsoncpp-dev` on Ubuntu.

To enable packet routing in emulation, a software switch must be started:

```bash
PYTHONPATH=$XILINX_VIVADO/data/emulation/python/xtlm_ipc python3 hwemu_switch.py
```