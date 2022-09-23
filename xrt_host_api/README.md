# Low level C++ host API
This folder contains a low level API build on top of XRT to control the network
stack from C++.

The [cmake project](CMakeLists.txt) contains a library (`vnx`) that you can link
to your project, and the bindings are described in the header files located in
[`include/vnx`](include/vnx). An example program using this API is located in
[`examples/ping_fpga`](examples/ping_fpga).
