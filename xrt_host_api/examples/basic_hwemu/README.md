# Example hardware emulation
This example program loads a hardware emulation VNx xclbin onto the FPGA, 
tests the link on the network interface, sets the IP address to the FPGA, 
and transfers data to another emulated FPGA.

To compile and run this program first build the `basic` design targeting
hardware emulation, as follows, from the root folder of the repository:
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
# Setting up socket directories
mkdir -p fpga0_sockets fpga1_sockets
```

To run two emulated FPGAs, set up XRT (by sourcing its `setup.sh` script) then 
run the following two commands *each in its own terminal window*:
```
XCL_EMULATION_MODE=hw_emu XTLM_IPC_SOCK_DIR=`pwd`/fpga0_sockets ./basic_hwemu <XCLBIN> 0
XCL_EMULATION_MODE=hw_emu XTLM_IPC_SOCK_DIR=`pwd`/fpga1_sockets ./basic_hwemu <XCLBIN> 1
```

To enable packet routing in emulation, a software switch must be started *from a third terminal window*:

```bash
PYTHONPATH=$XILINX_VIVADO/data/emulation/python/xtlm_ipc python hwemu_switch.py -d -n 2 --macaddr 00.00.00.00.00.01 00.00.00.00.00.02
```
