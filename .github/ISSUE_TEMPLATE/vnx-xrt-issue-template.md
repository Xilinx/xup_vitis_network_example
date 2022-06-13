---
name: XRT issues
about: Please only open issues that pertain to the XRT host application
title: '[XRT] '
labels: ''
assignees: 
   - fpgafais
---

<!-- please remove what does not apply -->

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

### XRT Compile Issues

1. OS version, e.g. `lsb_release -a`
1. Vitis version `vitis -version`
1. XRT version `xbutil version`
1. CMake version `cmake --version`

### XRT Runtime Issues

1. OS version `lsb_release -a`
1. XRT version `xbutil version`
1. Alveo card you are targeting and shell

   If using U250 is the second partition programmed? [DFX two-stage](https://support.xilinx.com/s/article/75975?language=en_US)

   Using a design with the two interfaces and XRT 2.13.xyz? https://github.com/Xilinx/xup_vitis_network_example/issues/65

1. How did you excecuted the code? Please provide the command(s)
1. Provide `dmesg` log


<!-- please keep the @ below-->

Can @fpgafais please have a look?