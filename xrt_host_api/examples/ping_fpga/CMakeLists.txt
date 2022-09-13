# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.5)
project(setup_link CXX)

add_subdirectory(../../ "CMakeFiles/xrt_host_api")
find_package(jsoncpp REQUIRED)
get_target_property(JSON_INC_PATH jsoncpp_lib INTERFACE_INCLUDE_DIRECTORIES)

add_executable(ping_fpga ping_fpga.cpp)
target_compile_features(ping_fpga PRIVATE cxx_std_17)
target_include_directories(ping_fpga PUBLIC ${VNX_INCLUDE_PATH} ${JSON_INC_PATH})
target_link_libraries(ping_fpga PUBLIC jsoncpp_lib vnx)
