// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#pragma once

#include <cstddef>
#include <cstdint>
#include <experimental/xrt_ip.h>
#include <map>
#include <string>
#include <vector>

namespace vnx {
constexpr std::size_t max_sockets_size = 16;

// Register offsets
constexpr std::size_t mac_address_offset = 0x0010;
constexpr std::size_t ip_address_offset = 0x0018;
constexpr std::size_t gateway_offset = 0x001C;
constexpr std::size_t arp_discovery_offset = 0x1010;
constexpr std::size_t arp_mac_addr_offset = 0x1800;
constexpr std::size_t arp_ip_addr_offset = 0x1400;
constexpr std::size_t arp_valid_offset = 0x1100;
constexpr std::size_t udp_theirIP_offset = 0x810;
constexpr std::size_t udp_theirPort_offset = 0x890;
constexpr std::size_t udp_myPort_offset = 0x910;
constexpr std::size_t udp_valid_offset = 0x990;
constexpr std::size_t udp_number_sockets = 0xa10;
constexpr std::size_t udp_in_packets = 0x4D0;
constexpr std::size_t udp_out_packets = 0x500;
constexpr std::size_t udp_app_in_packets = 0x518;
constexpr std::size_t udp_app_out_packets = 0x4E8;

constexpr std::size_t udp_in_bytes = 0x4C8;
constexpr std::size_t udp_out_bytes = 0x4F8;
constexpr std::size_t udp_app_in_bytes = 0x510;
constexpr std::size_t udp_app_out_bytes = 0x4E0;

constexpr std::size_t ethhi_out_bytes = 0x498;
constexpr std::size_t eth_out_bytes = 0x4b0;

struct socket_t {
  std::string theirIP;
  uint32_t theirIPint;
  uint16_t theirPort = 62781;
  uint16_t myPort = 62781;
  bool valid = false;
};

uint32_t encode_ip_address(const std::string decoded_ip);
std::string decode_ip_address(const uint32_t encoded_ip);

class Networklayer {
public:
  Networklayer(xrt::ip &networklayer);
  Networklayer(xrt::ip &&networklayer);

  /* Updates the IP address of the networklayer based on the encoded ip address.
   */
  void update_ip_address(const uint32_t ip_address);
  /* Updates the IP address of the networklayer based on the decoded ip address.
   */
  uint32_t update_ip_address(const std::string ip_address);

  /* Runs the arp discovery */
  void arp_discovery();

  /* Read out the arp table on the FPGA */
  std::map<int, std::pair<std::string, std::string>>
  read_arp_table(int num_entries);

  /* Configure the socket at the given index. Run populate_socket_table to write
   * the information to the FPGA. */
  void configure_socket(int index, std::string theirIP, uint16_t theirPort,
                        uint16_t myPort, bool valid);

  /* Get socket configuration at given index. */
  socket_t get_host_socket(int index);

  /* Populate the socket table on the FPGA based on local configuration. */
  std::map<int, socket_t> populate_socket_table();
  /* Populate the socket table on the FPGA based on provided configuration. */
  void populate_socket_table(std::vector<socket_t> &socket_table);

  /* Print the first num_sockets entries of the socket_table. */
  void print_socket_table(const unsigned int num_sockets);

  /* Statistic functions. */
  uint32_t get_udp_in_pkts();
  uint32_t get_udp_out_pkts();
  uint32_t get_udp_app_in_pkts();
  uint32_t get_udp_app_out_pkts();

private:
  socket_t sockets[max_sockets_size];
  xrt::ip networklayer;
};
} // namespace vnx
