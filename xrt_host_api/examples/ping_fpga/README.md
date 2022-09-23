# Example ping program
This example program loads the VNx xclbin onto the FPGA, tests the link on the
network interface, sets the IP address to the FPGA, and pings the FPGA from the
host.

To compile and run this program first make sure that the config at the start of
`ping_fpga.cpp` contains the the correct hostnames. Then run the following
commands (make sure that XRT is sourced):
```bash
# Compiling the program
mkdir build
cd build
cmake ..
cmake --build .
# Running the program
./ping_fpga <XCLBIN> <DEVICE ID (default 0)>
```

Note that this program depends on
[jsoncpp](https://github.com/open-source-parsers/jsoncpp), which can be
installed using `sudo apt install libjsoncpp-dev` on Ubuntu.
