# Example Test Link

This example program loads the VNx xclbin onto the FPGA and allows testing
CMAC link with and without RS-FEC enabled.

To compile and run this program run the following commands 
(make sure that XRT is sourced):

```bash
# Compiling the program
mkdir build && cd build
/usr/bin/cmake ..
/usr/bin/cmake --build .
# Running the program
./test_link <XCLBIN> <RS-FEC (default 0)> <DEVICE ID (default 0)>
```

The arguments are as follows:

-  `XCLBIN`: path to the *.xclbin file
- `RS-FEC` (bool): `0` RS-FEC disabled (default); `1` RS-FEC enabled
- `DEVICE ID`: device ID, can be found with `xbutil examine`

Note that this program depends on
[jsoncpp](https://github.com/open-source-parsers/jsoncpp), which can be
installed using `sudo apt install libjsoncpp-dev` on Ubuntu.


------------------------------------------------------
<p align="center">Copyright&copy; 2024 Advanced Micro Devices, Inc.</p>