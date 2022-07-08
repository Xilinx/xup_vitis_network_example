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

#include "networklayer.hpp"
#include <cmath>
#include <iostream>
#include <sstream>

namespace vnx {
Networklayer::Networklayer(xrt::ip &networklayer)
    : networklayer(networklayer) {}
Networklayer::Networklayer(xrt::ip &&networklayer)
    : networklayer(networklayer) {}

uint32_t encode_ip_address(const std::string decoded_ip) {
  std::vector<std::string> l_ipAddrVec;
  std::stringstream l_str(decoded_ip);
  std::string l_ipAddrStr;
  if (std::getline(l_str, l_ipAddrStr, '.').fail()) {
    throw std::runtime_error("IP address is ill-formed.");
    return 0;
  } else {
    l_ipAddrVec.push_back(l_ipAddrStr);
  }
  while (std::getline(l_str, l_ipAddrStr, '.')) {
    l_ipAddrVec.push_back(l_ipAddrStr);
  }
  if (l_ipAddrVec.size() != 4) {
    throw std::runtime_error("IP address is ill-formed.");
    return 0;
  }
  uint32_t l_ipAddr = 0;
  for (auto i = 0; i < 4; ++i) {
    l_ipAddr = l_ipAddr << 8;
    uint32_t l_val = std::stoi(l_ipAddrVec[i]);
    if (l_val > 255) {
      std::string l_errStr = l_ipAddrVec[i] + " should be less than 255.";
      throw std::runtime_error(l_errStr);
      return 0;
    }
    l_ipAddr += l_val;
  }
  return l_ipAddr;
}

std::string decode_ip_address(const uint32_t encoded_ip) {
  std::string l_ipStr;
  for (auto i = 0; i < 4; ++i) {
    uint32_t l_ipAddr = encoded_ip;
    l_ipAddr = l_ipAddr >> (4 - i - 1) * 8;
    uint8_t l_digit = l_ipAddr & 0xff;
    l_ipStr = l_ipStr + std::to_string(l_digit);
    if (i != 3) {
      l_ipStr += ".";
    }
  }
  return l_ipStr;
}

void Networklayer::update_ip_address(const uint32_t ip_address) {
  networklayer.write_register(ip_address_offset, ip_address);
  uint32_t l_gatewayAddr = (ip_address & 0xFFFFFF00) + 1;
  networklayer.write_register(gateway_offset, l_gatewayAddr);
  uint32_t l_curMacAddr;
  l_curMacAddr = networklayer.read_register(mac_address_offset);
  uint32_t l_newMacAddr = (l_curMacAddr & 0xFFFFFFFFFF00) + (ip_address & 0xFF);
  networklayer.write_register(mac_address_offset, l_newMacAddr);
}

uint32_t Networklayer::update_ip_address(const std::string ip_address) {
  uint32_t ip_address_encoded = encode_ip_address(ip_address);
  update_ip_address(ip_address_encoded);
  return ip_address_encoded;
}

void Networklayer::arp_discovery() {
  networklayer.write_register(arp_discovery_offset, 0);
  networklayer.write_register(arp_discovery_offset, 1);
  networklayer.write_register(arp_discovery_offset, 0);
}

unsigned long long _byte_ordering_endianess(unsigned long long num,
                                            int length = 4) {
  unsigned long long aux = 0;
  for (int i = 0; i < length; i++) {
    unsigned long long byte_index = num >> ((length - 1 - i) * 8) & 0xFF;
    aux += byte_index << (i * 8);
  }
  return aux;
}

/*
 * Read the ARP table from the FPGA return a map
 */
std::map<int, std::pair<std::string, std::string>>
Networklayer::read_arp_table(int num_entries) {
  uint32_t mac_addr_offset = arp_mac_addr_offset;
  uint32_t ip_addr_offset = arp_ip_addr_offset;
  uint32_t valid_addr_offset = arp_valid_offset;
  std::map<int, std::pair<std::string, std::string>> table;
  unsigned long long valid_entry;

  for (int i = 0; i < num_entries; i++) {
    if ((i % 4) == 0) {
      valid_entry = networklayer.read_register(valid_addr_offset + (i / 4) * 4);
    }
    unsigned long long isvalid = (valid_entry >> ((i % 4) * 8)) & 0x1;
    if (isvalid) {
      unsigned long long mac_lsb =
          networklayer.read_register(mac_addr_offset + (i * 2 * 4));
      unsigned long long mac_msb =
          networklayer.read_register(mac_addr_offset + ((i * 2 + 1) * 4));
      unsigned long long ip_addr =
          networklayer.read_register(ip_addr_offset + (i * 4));
      unsigned long long mac_addr = pow(2, 32) * mac_msb + mac_lsb;
      unsigned long long mac_hex = _byte_ordering_endianess(mac_addr, 6);
      std::stringstream mac_hex_stringstream;
      mac_hex_stringstream << std::hex << mac_hex << std::dec;
      std::string mac_hex_string = mac_hex_stringstream.str();
      mac_hex_string =
          std::string(12 - mac_hex_string.length(), '0') + mac_hex_string;
      std::string mac_str = "";
      for (int j = 0; j < (int)mac_hex_string.length(); j++) {
        mac_str = mac_str + mac_hex_string.at(j);
        if ((j % 2 != 0) && (j != (int)mac_hex_string.length() - 1)) {
          mac_str = mac_str + ":";
        }
      }
      unsigned long long ip_addr_print = _byte_ordering_endianess(ip_addr);
      unsigned char ipBytes[4];
      ipBytes[0] = ip_addr_print & 0xFF;
      ipBytes[1] = (ip_addr_print >> 8) & 0xFF;
      ipBytes[2] = (ip_addr_print >> 16) & 0xFF;
      ipBytes[3] = (ip_addr_print >> 24) & 0xFF;
      std::stringstream ip_addr_printstream;
      ip_addr_printstream << int(ipBytes[3]) << "." << int(ipBytes[2]) << "."
                          << int(ipBytes[1]) << "." << int(ipBytes[0]);
      std::string ip_addr_print_string = ip_addr_printstream.str();
      table.insert({i, {mac_str, ip_addr_print_string}});
    }
  }
  return table;
}

void Networklayer::configure_socket(int index, std::string theirIP,
                                    uint16_t theirPort, uint16_t myPort,
                                    bool valid) {
  socket_t l_socket = {theirIP, encode_ip_address(theirIP), theirPort, myPort,
                       valid};
  this->sockets[index] = l_socket;
}

socket_t Networklayer::get_host_socket(int index) {
  return this->sockets[index];
}

std::map<int, socket_t> Networklayer::populate_socket_table() {
  uint32_t theirIP_offset = udp_theirIP_offset;
  uint16_t theirPort_offset = udp_theirPort_offset;
  uint16_t myPort_offset = udp_myPort_offset;
  uint16_t valid_offset = udp_valid_offset;

  int num_sockets_hw = networklayer.read_register(udp_number_sockets);

  if (num_sockets_hw < max_sockets_size) {
    std::string errMsg = "Socket list length " +
                         std::to_string(max_sockets_size) +
                         " is bigger than the number of sockets in hardware " +
                         std::to_string(num_sockets_hw);
    throw std::runtime_error(errMsg);
  }

  for (int i = 0; i < num_sockets_hw; i++) {
    uint32_t ti_offset = theirIP_offset + i * 8;
    uint32_t tp_offset = theirPort_offset + i * 8;
    uint32_t mp_offset = myPort_offset + i * 8;
    uint32_t v_offset = valid_offset + i * 8;

    uint32_t theirIP = 0;
    if (!this->sockets[i].theirIP.empty()) {
      theirIP = this->sockets[i].theirIPint;
    }
    networklayer.write_register(ti_offset, theirIP);
    networklayer.write_register(tp_offset, this->sockets[i].theirPort);
    networklayer.write_register(mp_offset, this->sockets[i].myPort);
    networklayer.write_register(v_offset, this->sockets[i].valid);
  }

  std::map<int, socket_t> socket_dict;

  for (int i = 0; i < num_sockets_hw; i++) {
    uint32_t ti_offset = theirIP_offset + i * 8;
    uint32_t tp_offset = theirPort_offset + i * 8;
    uint32_t mp_offset = myPort_offset + i * 8;
    uint32_t v_offset = valid_offset + i * 8;
    uint32_t isvalid = networklayer.read_register(v_offset);
    if (isvalid) {
      uint32_t ti = networklayer.read_register(ti_offset);
      uint32_t tp = networklayer.read_register(tp_offset);
      uint32_t mp = networklayer.read_register(mp_offset);

      unsigned char ipBytes[4];
      ipBytes[0] = ti & 0xFF;
      ipBytes[1] = (ti >> 8) & 0xFF;
      ipBytes[2] = (ti >> 16) & 0xFF;
      ipBytes[3] = (ti >> 24) & 0xFF;
      std::stringstream ti_printstream;
      ti_printstream << int(ipBytes[3]) << "." << int(ipBytes[2]) << "."
                     << int(ipBytes[1]) << "." << int(ipBytes[0]);
      socket_t l_socket = {ti_printstream.str(), ti, static_cast<uint16_t>(tp),
                           static_cast<uint16_t>(mp), true};
      socket_dict.insert({i, l_socket});
    }
  }

  return socket_dict;
}

void Networklayer::print_socket_table(const unsigned int num_sockets) {
  uint32_t theirIP_offset = udp_theirIP_offset;
  uint16_t theirPort_offset = udp_theirPort_offset;
  uint16_t myPort_offset = udp_myPort_offset;
  uint16_t valid_offset = udp_valid_offset;
  for (unsigned int i = 0; i < num_sockets; ++i) {
    uint32_t ti_offset = theirIP_offset + i * 8;
    uint32_t tp_offset = theirPort_offset + i * 8;
    uint32_t mp_offset = myPort_offset + i * 8;
    uint32_t v_offset = valid_offset + i * 8;
    uint32_t isValid = networklayer.read_register(v_offset);
    if (isValid == 0) {
      throw std::runtime_error("Socket not set properly.");
    } else {
      uint32_t ti = networklayer.read_register(ti_offset);
      uint32_t tp = networklayer.read_register(tp_offset);
      uint32_t mp = networklayer.read_register(mp_offset);

      unsigned char ipBytes[4];
      ipBytes[0] = ti & 0xFF;
      ipBytes[1] = (ti >> 8) & 0xFF;
      ipBytes[2] = (ti >> 16) & 0xFF;
      ipBytes[3] = (ti >> 24) & 0xFF;
      std::stringstream ti_printstream;
      ti_printstream << int(ipBytes[3]) << "." << int(ipBytes[2]) << "."
                     << int(ipBytes[1]) << "." << int(ipBytes[0]);
      std::cout << "Socket " << i << ": ";
      std::cout << " theirIP = " << ti_printstream.str();
      std::cout << " theirPort = " << tp;
      std::cout << " myPort = " << mp << std::endl;
    }
  }
}

void Networklayer::populate_socket_table(std::vector<socket_t> &socket_table) {
  uint32_t theirIP_offset = udp_theirIP_offset;
  uint16_t theirPort_offset = udp_theirPort_offset;
  uint16_t myPort_offset = udp_myPort_offset;
  uint16_t valid_offset = udp_valid_offset;

  int num_sockets_hw = networklayer.read_register(udp_number_sockets);

  int l_socketTBsize = socket_table.size();
  if (num_sockets_hw < l_socketTBsize) {
    std::string errMsg = "Socket list length " +
                         std::to_string(l_socketTBsize) +
                         " is bigger than the number of sockets in hardware " +
                         std::to_string(num_sockets_hw);
    throw std::runtime_error(errMsg);
  }

  for (int i = 0; i < l_socketTBsize; i++) {
    uint32_t ti_offset = theirIP_offset + i * 8;
    uint32_t tp_offset = theirPort_offset + i * 8;
    uint32_t mp_offset = myPort_offset + i * 8;
    uint32_t v_offset = valid_offset + i * 8;

    uint32_t theirIP = socket_table[i].theirIPint;
    networklayer.write_register(ti_offset, theirIP);
    networklayer.write_register(tp_offset, socket_table[i].theirPort);
    networklayer.write_register(mp_offset, socket_table[i].myPort);
    networklayer.write_register(v_offset, socket_table[i].valid);
  }
}

uint32_t Networklayer::get_udp_in_pkts() {
  uint32_t l_res = networklayer.read_register(udp_in_packets);
  uint32_t l_bytes = networklayer.read_register(udp_in_bytes);
  std::cout << "udp in bytes = " << l_bytes << std::endl;
  return l_res;
}
uint32_t Networklayer::get_udp_out_pkts() {
  uint32_t l_res = networklayer.read_register(udp_out_packets);
  uint32_t l_bytes = networklayer.read_register(udp_out_bytes);
  std::cout << "udp out bytes = " << l_bytes << std::endl;
  l_bytes = networklayer.read_register(ethhi_out_bytes);
  std::cout << "ethhi_out_bytes = " << l_bytes << std::endl;
  l_bytes = networklayer.read_register(eth_out_bytes);
  std::cout << "eth_out_bytes = " << l_bytes << std::endl;
  return l_res;
}
uint32_t Networklayer::get_udp_app_in_pkts() {
  uint32_t l_res = networklayer.read_register(udp_app_in_packets);
  uint32_t l_bytes = networklayer.read_register(udp_app_in_bytes);
  std::cout << "udp app in bytes = " << l_bytes << std::endl;
  return l_res;
}
uint32_t Networklayer::get_udp_app_out_pkts() {
  uint32_t l_res = networklayer.read_register(udp_app_out_packets);
  uint32_t l_bytes = networklayer.read_register(udp_app_out_bytes);
  std::cout << "udp app out bytes = " << l_bytes << std::endl;
  return l_res;
}

} // namespace vnx
