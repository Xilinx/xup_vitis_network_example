// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#include <chrono>
#include <experimental/xrt_ip.h>
#include <filesystem>
#include <limits.h>
#include <map>
#include <string>
#include <sys/wait.h>
#include <thread>
#include <unistd.h>
#include <vnx/cmac.hpp>
#include <vnx/networklayer.hpp>
#include <xrt/xrt_device.h>
namespace fs = std::filesystem;

const std::vector<std::string> ip_addresses = {"10.1.212.1", "10.1.212.2"};

int main(int argc, char *argv[]) {
  if (argc < 2) {
    std::cerr << "Usage:" << argv[0] << " <XCLBIN> <INDEX>" << std::endl;
    return 1;
  }

  std::size_t ip_index = atoi(argv[2]);
  std::string binaryFile = argv[1];
  xrt::device device = xrt::device(0);
  std::cout << "Loading " << argv[1] << " onto FPGA on " << ip_index << std::endl;
  auto xclbin_uuid = device.load_xclbin(binaryFile);
  std::cout << "Done loading xclbin" << std::endl;
  
  auto cmac = vnx::CMAC(xrt::ip(device, xclbin_uuid, "cmac_0:{cmac_0}"));
  // Enable rsfec if necessary
  cmac.set_rs_fec(false);

  auto networklayer = vnx::Networklayer(xrt::ip(device, xclbin_uuid, "networklayer:{networklayer_0}"));
  bool link_status;

  // Can take a few tries before link is ready.
  for (std::size_t i = 0; i < 50; ++i) {
    auto status = cmac.link_status();
    link_status = status["rx_status"];
    std::cout << "Link " << (link_status ? "up" : "down") << std::endl;
    if (link_status) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::seconds(1));
  }

  std::cout << "RS-FEC enabled: " << (cmac.get_rs_fec() ? "true" : "false") << std::endl;

  std::string ip = ip_addresses[ip_index];

  std::cout << "setting up IP: " << ip << std::endl;
  networklayer.update_ip_address(ip);
  std::this_thread::sleep_for(std::chrono::seconds(1));

  //ARP table update for a 2-node system
  networklayer.invalidate_arp_table();

  std::size_t their_ip_index = (ip_index + 1) % 2;
  networklayer.configure_socket(0, ip_addresses.at(their_ip_index), 5000, 5000, true);
  networklayer.populate_socket_table();

  std::cout << "Starting ARP discovery..." << std::endl;
  networklayer.arp_discovery();
  std::this_thread::sleep_for(std::chrono::seconds(60));
  std::cout << "Reading ARP table..." << std::endl;
  auto arp = networklayer.read_arp_table(1);
  std::cout << "ARP Table:" << std::endl;
  for (auto &elem : arp) {
    auto index = elem.first;
    auto &entry = elem.second;
    auto &mac = entry.first;
    auto &ip = entry.second;
    std::cout << "(" << index << ") " << mac << ": " << ip << std::endl;
  }

  return 0;
}
