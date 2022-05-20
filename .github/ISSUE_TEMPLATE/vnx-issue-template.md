---
name: VNx issues
about: Please only open issues that pertain to VNx
title: ''
labels: ''
assignees: ''

---

**For Vivado questions, please use [Vivado forum](
https://forums.xilinx.com/t5/Vivado-RTL-Development/ct-p/DESIGN)**

**For Vitis questions, please use [the Vitis forum](
https://forums.xilinx.com/t5/Vitis-Acceleration-SDAccel-SDSoC/bd-p/tools_v)**

**For Vitis questions, please use [the Vitis forum](
https://forums.xilinx.com/t5/Alveo-Accelerator-Cards/bd-p/alveo)**

**For pynq questions, please use [the PYNQ discussion forum](
https://discuss.pynq.io/).**

**Usign Vitis 2021.2 or older? Make sure the [Y2K22 patch is applied](
https://support.xilinx.com/s/article/76960?language=en_US)**

If you still want to raise an issue here, please give us as much detail as
possible to the issue you are seeing. We have listed some helpful fields below.

- Please, use [code snippets](https://docs.github.com/en/github/writing-on-github/creating-and-highlighting-code-blocks) to provide textual content instead of images.

### Build Issues

1. OS version, e.g. `lsb_release -a`
1. Vitis version `vitis -version`
   1. If Vitis is 2021.2 or older. Is the [Y2K22 patch applied](https://support.xilinx.com/s/article/76960?language=en_US)?
1. XRT version `xbutil version`

### Run Time Issues

1. OS version `lsb_release -a`
1. XRT version `xbutil version`
1. pynq version `pynq version`
1. JupyterLab and Dask version if applicable