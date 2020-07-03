#!/bin/bash

if [[ -f "kernel_0.xml"  && -f "kernel_1.xml" ]]; then
	# Files exist therefore do nothing
	exit 0
fi

cp template.xml kernel_0.xml
cp template.xml kernel_1.xml

sed -i 's/name=\"placeholder\"/name=\"cmac\_0\"/g' kernel_0.xml
sed -i 's/xilinx\.com\:kernel\:placeholder/xilinx\.com\:kernel\:cmac_0/g' kernel_0.xml
sed -i 's/name=\"placeholder\"/name=\"cmac\_1\"/g' kernel_1.xml
sed -i 's/xilinx\.com\:kernel\:placeholder/xilinx\.com\:kernel\:cmac_1/g' kernel_1.xml

# Duplicate verilog
cp template_top.v cmac_top_0.v
cp template_top.v cmac_top_1.v

sed -i 's/module\ placeholder/module\ cmac_0/g' cmac_top_0.v
sed -i 's/cmac_bd\ placeholder/cmac_bd\ cmac_bd_0_i/g' cmac_top_0.v
sed -i 's/module\ placeholder/module\ cmac_1/g' cmac_top_1.v
sed -i 's/cmac_bd\ placeholder/cmac_bd\ cmac_bd_1_i/g' cmac_top_1.v