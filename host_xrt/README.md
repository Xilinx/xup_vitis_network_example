# ALVEO VNx C++ Host Code #

The project allows to access HW kernel and IPs included in this repository from any C++ application.
It runs on Xilinx Runtime Native APIs and gives the user a simplified interface to access and configure the FPGA, read and write IP registers, control kernels execution and access HBM memory buffers. To be used with Xilinx Alveo U280 accelerator cards.

# Classes composition #

* FpgaDevice: acquires handle to Alveo in the system and configures with a provided bitfile

* FpgaIP: general class for IP instances 

* FpgaKernel: general class for Kernel instances

* AlveoVnxCmac: FpgaIP type class that givess access to the CMAC IPs in VNx design, provides link status and network statistics

* AlveoVnxNetworkLayer: FpgaIP type class that gives access to NetworkLayer IP in VNx design, provides access to sockets table, network addresses, ARP discovery and statistics

* AlveoVnxKrnlS2MM: FpgaKernel type class that gives access to krnl_s2mm from Basic Kernels in VNx. When started, the kernel waits for incoming UDP packet and stores the payload in HBM memory that can be transferred to the host DDR.

* AlveoVnxKrnlMM2S: FpgaKernel type class that gives access to krnl_mm2s from Basic Kernels in VNx. The kernel reads provided amount of bytes from the HBM memory buffer and transfers to the NetworkLayer for UDP packet construction.

* AlveoVnxLink: class that encapsulates all IPs and kernels required to send and receive packets, providing user with sendTo() and receive() functions. The functions take char* as input of any size and perform fragmentation into packets when required. The original payload is preceded by one 4B word with payload size and EOF flag.

# Compilation #

* Make sure the XRT is installed in /opt/xilinx/xrt and the XRT environment settings are set:

```
source /opt/xilinx/xrt/setup.sh
```

* Create build directory and compile:

```
mkdir build; cd build
cmake ../
cmake --build .
```

* Default target device is xilinx_u280_xdma_201920_3, to change the device use:

```
cmake -DALVEO_DEVICE=<target_device> ../
```

# Example applications #

There are two example applications included:

* alveo_rx.cpp: listens on Alveo link 1 for incoming transcation and stores received payload in a binary file

* alveo_tx.cpp: connectes to Alveo link 0 and transfers the provided file content

# Requirements #

* XRT installation (tested on 2.11.634)

* FPGA bitfile (tested with vnx_basic_if3.xclbin)

# Support #

This driver has been contributed by The FPGA-FAIS group from Jagiellonian University in Cracow, for support create an issue and assign to fpgafais 
