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

#include "vnx/mac.hpp"
#include <json/json.h>

namespace {
const std::string default_mac = std::string("FF:FF:FF:FF:FF:FF");

std::string get_mac_address_from_json(Json::Value &json, std::size_t index) {
  Json::Value &macs = json["platforms"][0u]["macs"];
  Json::ArrayIndex array_index = index;
  if (!macs.isValidIndex(array_index)) {
    std::cerr << "Error finding mac address: index out of range" << std::endl;
    return default_mac;
  }

  return macs[array_index]["address"].asString();
}
} // namespace

namespace vnx {
std::string get_mac_address(xrt::device &device, std::size_t index) {
  Json::Reader reader;
  Json::Value json;
  std::string platform = device.get_info<xrt::info::device::platform>();

  bool status = reader.parse(platform, json);
  if (!status) {
    std::cerr << "Error finding mac address: failed to parse json" << std::endl;
    return default_mac;
  }

  std::string mac;

  try {
    mac = get_mac_address_from_json(json, index);
  } catch (const Json::Exception &e) {
    std::cerr << "Error finding mac address: " << e.what() << std::endl;
    return default_mac;
  }

  return mac;
}
} // namespace vnx
