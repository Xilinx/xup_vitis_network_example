# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.12)
project(setup_link CXX)

# Set useful compile warnings
add_compile_options(-Wall -Wextra -Wno-unused-variable
                    -Wno-unused-but-set-variable -Wno-unused-parameter)

add_subdirectory(../../ "CMakeFiles/xrt_host_api")
#find_package(jsoncpp REQUIRED)
#get_target_property(JSON_INC_PATH jsoncpp_lib INTERFACE_INCLUDE_DIRECTORIES)

add_executable(basic_hwemu basic_hwemu.cpp)
target_compile_features(basic_hwemu PRIVATE cxx_std_17)
#target_include_directories(basic_hwemu PUBLIC ${VNX_INCLUDE_PATH} ${JSON_INC_PATH})
target_include_directories(basic_hwemu PUBLIC ${VNX_INCLUDE_PATH})
target_link_libraries(basic_hwemu PUBLIC vnx)
