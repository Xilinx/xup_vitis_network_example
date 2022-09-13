# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.9)

# Consider switching to PROJECT_IS_TOP_LEVEL from CMake 3.21 (2021)
# (https://cmake.org/cmake/help/latest/variable/PROJECT_IS_TOP_LEVEL.html)
get_directory_property(HAS_PARENT PARENT_DIRECTORY)

set(VNX_INCLUDE_PATH ${CMAKE_CURRENT_LIST_DIR}/include)
if (HAS_PARENT)
  set(VNX_INCLUDE_PATH ${CMAKE_CURRENT_LIST_DIR}/include PARENT_SCOPE)
endif (HAS_PARENT)

# Json
find_package(jsoncpp)

if (jsoncpp_FOUND)
  add_library(vnx OBJECT src/cmac.cpp src/networklayer.cpp src/mac.cpp)

  target_link_libraries(vnx PRIVATE jsoncpp_lib)
  get_target_property(JSON_INC_PATH jsoncpp_lib INTERFACE_INCLUDE_DIRECTORIES)
  target_include_directories(vnx PRIVATE ${JSON_INC_PATH})
else (jsoncpp_FOUND)
  message(WARNING "jsoncpp not found on the system, compiling vnx without mac address utilities.")
  add_library(vnx OBJECT src/cmac.cpp src/networklayer.cpp)
endif (jsoncpp_FOUND)

target_include_directories(vnx PUBLIC ${VNX_INCLUDE_PATH})

# XRT
if (NOT EXISTS $ENV{XILINX_XRT})
  message(FATAL_ERROR "Xilinx XRT not found, make sure to source setup.sh")
endif ()

target_link_directories(vnx PUBLIC $ENV{XILINX_XRT}/lib)
target_link_libraries(vnx PUBLIC xilinxopencl xrt_coreutil xrt_core)
target_include_directories(vnx PUBLIC $ENV{XILINX_XRT}/include)
