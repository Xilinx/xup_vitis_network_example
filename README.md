# Vitis Network Example (VNx)

VNx repository contains example designs to provide network support at 100 Gbit/s using the GT kernel capability present in most Alveo shells, [see supported shells below](#alveo-cards). GT kernel capability exposes the GT pins to the dynamic region of the shell, and, therefore GT capable kernels can be connected to such pins. To know more check out [Designing a Transceiver-based Application with Vitis](https://developer.xilinx.com/en/articles/designing-a-transceiver-based-application-with-vitus.html).

Currently, this repository only provides UDP examples.

## Clone this repository

The repository is based on [Limago](https://github.com/hpcn-uam/Limago), and uses its underlying infrastructure as a submodule, therefore, use `--recursive` to clone it.

```sh
git clone https://github.com/Xilinx/xup_vitis_network_example.git --recursive
```

## Support

### Tools

| Vitis  | XRT       |
|--------|-----------|
| 2020.1 | 2.6.655   |

### Alveo Cards

| Alveo | Shell(s) |
|-------|----------|
| U50   | xilinx_u50_gen3x16_xdma_201920_3 |
| U200  | Not supported yet |
| U250  | xilinx-u250-gen3x16-xdma-2.1-202010 <br/> xilinx-u250-gen3x16-qdma-2.1-202010 |
| U280  | xilinx_u280_xdma_201920_3 |


## Generate XCLBIN

Run 
```sh
make all DEVICE=<full platform path> INTERFACE=<interface number> DESING=<design name>
```

* Interface can be 0, 1 or 3. If `INTERFACE=3`, both interfaces will be used.
* `DESING` only support the following strings `basic` and `benchmark`. If you use something different, `benchmark` will be implemented
* The basic configuration file is pulled from [config_files](config_files) folder and complete with `userPostSysLinkOverlayTcl` parameter and in the make process.
* [post_sys_link.tcl](post_sys_link.tcl) is automatically called from `v++` after system link. It is used to connect the GT capable pins.
* The `XCLBIN` will be generated in the folder \<DESIGN\>.intf\<INTERFACE\>.\<(short)DEVICE\>

### Requirements

In order to generate this design you will need a valid [UltraScale+ Integrated 100G Ethernet Subsystem](https://www.xilinx.com/products/intellectual-property/cmac_usplus.html) license set up in Vivado.

### Limitations: 

- `xilinx_u50_gen3x16_xdma_201920_3` is giving link against a NIC, but not against U280

## Common infrastructure

This section provides a brief overview of the common infrastructure needed for the examples to work.

Currently, only UDP is supported. The examples rely on the same underlying infrastructure, which is `cmac` and `network_layer` kernels.

### cmac kernel

It contains an UltraScale+ Integrated 100G Ethernet Subsystem. This kernel is configured according to the `INTERFACE` and `DEVICE` arguments passed to make. It exposes two 512-bit AXI4-Stream interfaces (S_AXIS and M_AXIS) to the user logic, which run at the same frequency as the kernel, internally it has CDC logic to convert from kernel clock to the 100G Ethernet Subsystem clock. It also provides and AXI4-Lite interface to check *cmac* statistics.

### network_layer kernel

It is a collection of HLS modules to provide basic network functionality. It exposes two 512-bit (with 16-bit TDEST) AXI4-Stream to the application, S_AXIS_sk2nl and M_AXIS_nl2sk.

#### ARP
It provides a translation between IP addresses and MAC addresses. This table has 256 elements and it is accessible using AXI4-Lite. It also has ARP discovery capability to map IP addresses on its subnetwork.

```C
struct arpTableEntry {
  ap_uint<48> macAddress;
  ap_uint<32> ipAddress;
  ap_uint<1>  valid;
}
```

#### ICMP
It provides ping capability. It is useful to check if the design is *up* when using standard network equipment such as, routers or NICs.

#### UDP

It provides UDP transport layer functionality. It has a 16-element socket table, which must be filled from the host side in order to receive and send data. 

```C
struct socket_table {
  ap_uint<32>     theirIP;
  ap_uint<16>     theirPort;
  ap_uint<16>     myPort;
  ap_uint< 1>     valid;
}
```

The application communicates with this module using the *S_AXIS_sk2nl* and *M_AXIS_nl2sk* AXI4-Stream interfaces with the following structure:

```C
struct my_axis_udp {
  ap_uint<512>    data;
  ap_uint< 64>    keep;
  ap_uint<16>     dest;
  ap_uint< 1>     last;
}
```

In the transmitting side, the application sends the payload identifying the socket using `dest`. If the socket is valid, an UDP packet containing the payload is populated to the network. If the socket is not valid, the payload is dropped.

In the receiving side UDP packets are parsed and the socket information is compared against the socket table. If the socket information is valid, the UDP will populate the payload to the application setting `dest` accordingly.

Currently to simplify the receiver side logic, valid incoming connections must be fully specified in the socket table. 


## Examples

### Basic

The following figure depicts the different kernels and their interconnection in the Vitis project for the basic example.

![](img/udp_network_basic.png)

> **_NOTE:_** the reference clock frequency can change depending on the Alveo card.

*cmac* and *network layer* kernels are explained in the section above. In this example the application is split into two kernels, memory mapped to stream (mm2s) and stream to memory mapped (s2mm).

* [mm2s](Kernels/src/krnl_mm2s.cpp): pulls data from global memory and converts it to a 512-bit stream. It chunks the data into 1408-Byte packets, meaning that *last* is asserted. It also asserts *last* when there is no more data to send. The *dest* is set according to the argument with the same name.

* [s2mm](Kernels/src/krnl_s2mm.cpp): gets payload from the UDP module and push the payload to global memory. *dest* and *last* are ignored in this module.

The current limitation of this *application* is that the size of the data must be multiple of 64-Byte to work properly.

Check out [basicExample_NIC_FPGA](Notebooks/basicExample_NIC_FPGA.ipynb) to see how to run this example using PYNQ.

### Benchmark

The following figure depicts the benchmark design, which contains four *benchmark* kernels. Each benchmark kernel has two modules, traffic generator and collector

![](img/udp_network_benchmark.png)

> **_NOTE:_** the reference clock frequency can change depending on the Alveo card.

More information about the benchmark kernel in [Benchmark_kernel/README.md](Benchmark_kernel/README.md)

## Repository structure

~~~
├── Basic_kernels
│   └── src
├── Benchmark_kernel
│   └── src
├── config_files
├── Ethernet
│   └── cmac
├── img
├── NetLayers
│   ├── 100G-fpga-network-stack-core
│   └── src
└── Notebooks
~~~

* Basic_kernels: this folder contains the code for the basic application (*mm2s* and *s2mm*)
* Benchmark_kernel: this folder contains the benchmark application
* config_files: this folder contains the different configuration files for the different examples and flavors
* Ethernet: this folder contains the logic to generate the *cmac* kernel for the different Alveo cards and interfaces
* img: this folder contains images 
* NetLayers: this folder contains the logic to generate the *network\_layer* kernel, using the submodule `100G-fpga-network-stack-core`
* Notebooks: this folder contains companion Jupyter notebooks to show how to run the different examples

---------------------------------------
<center> Copyright&copy; 2020 Xilinx </center>