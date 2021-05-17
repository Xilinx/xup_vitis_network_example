#!/bin/bash

# Copyright (c) 2020, Xilinx, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, 
# this list of conditions and the following disclaimer in the documentation 
# and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors 
# may be used to endorse or promote products derived from this software 
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.// Copyright (c) 2020 Xilinx, Inc.

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
cp src/template_top.v src/cmac_top_0.v
cp src/template_top.v src/cmac_top_1.v

sed -i 's/module\ placeholder/module\ cmac_0/g' src/cmac_top_0.v
sed -i 's/cmac_bd\ placeholder/cmac_bd\ cmac_bd_0_i/g' src/cmac_top_0.v
sed -i 's/gt_placeholder_clk/gt_refclk0/g' src/cmac_top_0.v

sed -i 's/module\ placeholder/module\ cmac_1/g' src/cmac_top_1.v
sed -i 's/cmac_bd\ placeholder/cmac_bd\ cmac_bd_1_i/g' src/cmac_top_1.v
sed -i 's/gt_placeholder_clk/gt_refclk1/g' src/cmac_top_1.v