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