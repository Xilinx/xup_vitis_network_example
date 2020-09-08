# Vitis Network Layer

This repository contains example designs to provide network support using the GT Kernel option present in most Alveo shells

## Clone this repository

The repository is made of several submodules, therefore, use `--recursive` to clone it.

```sh
git clone https://gitenterprise.xilinx.com/mruiznog/vitis_network_layer.git --recursive
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
| U250  | Not supported yet |
| U280  | xilinx_u280_xdma_201920_3 |


## Generate XCLBIN

Run 
```sh
make all DEVICE=<full platform path> INTERFACE=<interface number> DESING=<design name>
```

* Interface can be 0, 1 or 3 (use both interfaces)
* The basic configuration file is pulled from [config_files](config_files) and complete with `userPostSysLinkOverlayTcl` in the make process
* The `XCLBIN` will be generated in the folder \<DESIGN\>.intf\<INTERFACE\>.\<(short)DEVICE\>

### Limitations: 

- Only `xilinx_u280_xdma_201920_3` and `xilinx_u50_gen3x16_xdma_201920_3` closes timing
- `xilinx_u50_gen3x16_xdma_201920_3` is giving link against a mellanox NIC, but not against U280
- `DESING` only support the following strings `basic` and `benchmark` if you use something different, `benchmark` will be implemented


## Basic Design Block Diagram

The following figure depicts the different kernels and their interconnection in the Vitis project.

![](img/udp_network_basic.jpg)