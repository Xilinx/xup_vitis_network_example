# Copyright (C) 2025 Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Get the root folder
set root_folder [lindex $argv 2]
# Get project name from the arguments
set proj_name [lindex $argv 3]
# Get device part
set device [lindex $argv 4]
# Create project

#get proj_part
source platform.tcl

open_project ${proj_name}

set_top ${proj_name}

add_files ${root_folder}/src/${proj_name}.cpp
add_files -tb ${root_folder}/src/${proj_name}_tb.cpp

open_solution "solution1"
set_part ${proj_part}
create_clock -period 2.2 -name default
set_clock_uncertainty 0.2

csynth_design
export_design -rtl verilog -format ip_catalog

exit