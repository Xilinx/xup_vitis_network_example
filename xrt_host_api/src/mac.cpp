// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#include "vnx/mac.hpp"
#include <json/json.h>

namespace {
const std::string default_mac = std::string("FF:FF:FF:FF:FF:FF");

std::string get_mac_address_from_json(Json::Value &json, std::size_t index) {
  // Read mac addresses from first platform
  Json::Value &macs = json["platforms"][0u]["macs"];
  Json::ArrayIndex array_index = index;
  if (!macs.isValidIndex(array_index)) {
    std::cerr << "Error finding mac address: index out of range" << std::endl;
    return default_mac;
  }

  // Return mac address at correct index.
  return macs[array_index]["address"].asString();
}
} // namespace

namespace vnx {
std::string get_mac_address(xrt::device &device, std::size_t index) {
  Json::Reader reader;
  Json::Value json;
  std::string platform = device.get_info<xrt::info::device::platform>();

  // Parse platform string as JSON.
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
