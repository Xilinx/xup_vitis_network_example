/*  Copyright (c) 2020-2022, Xilinx, Inc.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1.  Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 *
 *  2.  Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *  3.  Neither the name of the copyright holder nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 *  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#pragma once

#include <cstddef>
#include <cstdint>
#include <experimental/xrt_ip.h>
#include <map>
#include <string>
#include <vector>

namespace vnx {
constexpr std::size_t max_sockets_size = 16;

constexpr std::size_t mac_address_offset = 0x0010;
constexpr std::size_t ip_address_offset = 0x0018;
constexpr std::size_t gateway_offset = 0x001C;
constexpr std::size_t arp_discovery_offset = 0x3010;
constexpr std::size_t arp_mac_addr_offset = 0x3800;
constexpr std::size_t arp_ip_addr_offset = 0x3400;
constexpr std::size_t arp_valid_offset = 0x3100;
constexpr std::size_t udp_theirIP_offset = 0x2010;
constexpr std::size_t udp_theirPort_offset = 0x2090;
constexpr std::size_t udp_myPort_offset = 0x2110;
constexpr std::size_t udp_valid_offset = 0x2190;
constexpr std::size_t udp_number_sockets = 0x2210;
constexpr std::size_t udp_in_packets = 0x10D0;
constexpr std::size_t udp_out_packets = 0x1100;
constexpr std::size_t udp_app_in_packets = 0x10E8;
constexpr std::size_t udp_app_out_packets = 0x1118;

constexpr std::size_t udp_in_bytes = 0x10C8;
constexpr std::size_t udp_out_bytes = 0x10F8;
constexpr std::size_t udp_app_in_bytes = 0x10E0;
constexpr std::size_t udp_app_out_bytes = 0x1110;

constexpr std::size_t ethhi_out_bytes = 0x1098;
constexpr std::size_t eth_out_bytes = 0x10b0;

struct socket_t {
  std::string theirIP;
  uint32_t theirIPint;
  // uint16_t theirPort = 38746; //for cpu
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
  void update_ip_address(const uint32_t ip_address);
  uint32_t update_ip_address(const std::string ip_address);
  void arp_discovery();
  std::map<int, std::pair<std::string, std::string>>
  read_arp_table(int num_entries);
  void configure_socket(int index, std::string theirIP, uint16_t theirPort,
                        uint16_t myPort, bool valid);
  socket_t get_host_socket(int index);
  std::map<int, socket_t> populate_socket_table();
  void populate_socket_table(std::vector<socket_t> &socket_table);
  void print_socket_table(const unsigned int num_sockets);
  uint32_t get_udp_in_pkts();
  uint32_t get_udp_out_pkts();
  uint32_t get_udp_app_in_pkts();
  uint32_t get_udp_app_out_pkts();

private:
  socket_t sockets[16];
  xrt::ip networklayer;
};
} // namespace vnx