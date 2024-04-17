# Copyright (C) 2024 Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.12)
project(setup_link CXX)

# Set useful compile warnings
add_compile_options(-Wall -Wextra -Wno-unused-variable
                    -Wno-unused-but-set-variable -Wno-unused-parameter)

add_subdirectory(../../ "CMakeFiles/xrt_host_api")

add_executable(test_link test_link.cpp)
target_compile_features(test_link PRIVATE cxx_std_17)
target_include_directories(test_link PUBLIC ${VNX_INCLUDE_PATH})
target_link_libraries(test_link PUBLIC vnx)
