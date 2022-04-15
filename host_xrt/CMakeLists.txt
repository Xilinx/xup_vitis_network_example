cmake_minimum_required(VERSION 3.10)
project(alveo_vnx LANGUAGES CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)

set(BUILD_SHARED_LIBS ON)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)


if(NOT DEFINED ENV{XILINX_XRT})
        message(FATAL_ERROR "XRT is not sourced")
endif()

#____________________________________________________________

add_executable(rx exec/alveo_rx.cpp)
target_link_libraries(rx PRIVATE alveo_vnx)

add_executable(tx exec/alveo_tx.cpp)
target_link_libraries(tx PRIVATE alveo_vnx)

#____________________________________________________________

file(GLOB ALL_SOURCES "src/*.cpp")
file(GLOB ALL_HEADERS "include/*.h")

add_library(alveo_vnx SHARED ${ALL_SOURCES} ${ALL_HEADERS})

target_include_directories(alveo_vnx
        PUBLIC include
        PUBLIC $ENV{XILINX_XRT}/include
        )
target_link_directories(alveo_vnx
        PUBLIC $ENV{XILINX_XRT}/lib
        )
target_link_libraries(alveo_vnx
        PUBLIC xrt_coreutil
        PUBLIC uuid
        )

#____________________________________________________________

if(NOT ALVEO_DEVICE)
        set(ALVEO_DEVICE "xilinx_u280_xdma_201920_3")
endif()

message(STATUS ${ALVEO_DEVICE})

target_compile_definitions(rx PRIVATE "ALVEO_DEVICE=\"${ALVEO_DEVICE}\"")
target_compile_definitions(tx PRIVATE "ALVEO_DEVICE=\"${ALVEO_DEVICE}\"")

unset(ALVEO_DEVICE CACHE)