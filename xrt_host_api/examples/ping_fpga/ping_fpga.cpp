// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#include <chrono>
#include <experimental/xrt_ip.h>
#include <filesystem>
#include <json/json.h>
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

/***************
 *    CONFIG   *
 ***************/
enum xclbin_types { u280_if3, u55c_if0, u55c_if1, u55c_if3 };

struct xclbin_path {
  std::string path;
  xclbin_types type;
};

const char *hostname1 = "hostname1";
const char *hostname2 = "hostname2";
const char *hostname3 = "hostname3";

const std::map<std::string, const std::vector<std::string>> ip_addresses = {
    {hostname1, {"10.1.212.101", "10.1.212.102"}},
    {hostname2, {"10.1.212.103", "10.1.212.104"}},
    {hostname3, {"10.1.212.105", "10.1.212.106"}}};

// Map type of xclbin to contained kernels
const std::map<xclbin_types,
               const std::vector<std::pair<const char *, const char *>>>
    kernels = {{u280_if3,
                {{"cmac_0", "networklayer_0"}, {"cmac_1", "networklayer_1"}}},
               {u55c_if0, {{"cmac_0", "networklayer_0"}}},
               {u55c_if1, {{"cmac_1", "networklayer_1"}}},
               {u55c_if3,
                {{"cmac_0", "networklayer_0"}, {"cmac_1", "networklayer_1"}}}};
/***************
 * END CONFIG  *
 ***************/

std::vector<xclbin_path> parse_xclbins(const std::string &platform,
                                       std::vector<const char *> &args) {
  // Determine content of xclbin based on filename and platform.
  std::vector<xclbin_path> xclbins{};
  for (const auto &arg : args) {
    xclbin_path xclbin;
    xclbin.path = arg;
    std::string filename = fs::path(arg).filename();

    bool found = false;
    if (platform == "xilinx_u280_xdma_201920_3") {
      if (filename == "vnx_basic_if3.xclbin") {
        xclbin.type = u280_if3;
        found = true;
      }
    } else if (platform == "xilinx_u55c_gen3x16_xdma_base_3") {
      if (filename == "vnx_basic_if0.xclbin") {
        xclbin.type = u55c_if0;
        found = true;
      } else if (filename == "vnx_basic_if1.xclbin") {
        xclbin.type = u55c_if1;
        found = true;
      } else if (filename == "vnx_basic_if3.xclbin") {
        xclbin.type = u55c_if3;
        found = true;
      }
    }

    if (!found) {
      throw std::runtime_error("Unexpected xclbin file " + filename +
                               " with platform " + platform);
    }

    xclbins.push_back(xclbin);
  }

  return xclbins;
}

Json::Value parse_json(const std::string &string) {
  Json::Reader reader;
  Json::Value json;
  reader.parse(string, json);
  return json;
}

int main(int argc, char *argv[]) {
  // Retrieve host and device information
  char hostname[HOST_NAME_MAX];
  gethostname(hostname, HOST_NAME_MAX);
  char *env = std::getenv("XRT_DEVICE");
  int device_id = 0;
  if (env) {
    device_id = std::stoi(env);
  }
  xrt::device device = xrt::device(device_id);
  // Collect platform info from xclbin
  const std::string platform_json =
      device.get_info<xrt::info::device::platform>();
  const Json::Value platform_dict = parse_json(platform_json);
  const std::string platform =
      platform_dict["platforms"][0]["static_region"]["vbnv"].asString();
  std::cout << "FPGA platform: " << platform << std::endl;

  // Read xclbin files from commandline
  std::vector<const char *> args(argv + 1, argv + argc);
  const std::vector<xclbin_path> xclbins = parse_xclbins(platform, args);
  std::size_t ip_index = 0;

  // Loop over xclbins
  for (const xclbin_path &xclbin : xclbins) {
    const std::string &path = xclbin.path;
    const xclbin_types type = xclbin.type;
    auto xclbin_uuid = device.load_xclbin(path);
    std::cout << "Loaded " << path << " onto FPGA on " << hostname << std::endl;
    // Give time for xclbin to be loaded completely before attempting to read
    // the link status.
    std::this_thread::sleep_for(std::chrono::seconds(1));

    // Loop over compute units in xclbin
    for (const auto &cus : kernels.at(type)) {
      auto cmac = vnx::CMAC(xrt::ip(device, xclbin_uuid,
                                    std::string(cus.first) + ":{" +
                                        std::string(cus.first) + "}"));
      auto networklayer = vnx::Networklayer(
          xrt::ip(device, xclbin_uuid,
                  "networklayer:{" + std::string(cus.second) + "}"));
      bool link_status;

      // Can take a few tries before link is ready.
      for (std::size_t i = 0; i < 5; ++i) {
        auto status = cmac.link_status();
        link_status = status["rx_status"];
        if (link_status) {
          break;
        }
        std::this_thread::sleep_for(std::chrono::seconds(1));
      }
      std::cout << "Link interface " << cus.first << ": "
                << (link_status ? "true" : "false") << std::endl;

      // Continue to next xclbin if no link is found.
      if (!link_status) {
        continue;
      }

      if (ip_addresses.count(hostname) < 1) {
        throw std::runtime_error("Couldn't find ip address for host " +
                                 std::string(hostname));
      }

      std::string ip = ip_addresses.at(hostname)[ip_index];
      ++ip_index;

      std::cout << "setting up IP " << ip << " to interface " << cus.first
                << std::endl;
      networklayer.update_ip_address(ip);
      std::this_thread::sleep_for(std::chrono::seconds(1));

      // Create fork to run ping
      pid_t pid = fork();

      if (pid == 0) {
        const char *prog = "/bin/ping";
        char *ip_c = &ip[0];
        char *const argv[] = {"/bin/ping", "-c5", "-i0.8", ip_c, nullptr};
        char *const envp[] = {nullptr};
        execve(prog, argv, envp);
      } else {
        std::cout << "Pinging the Alveo card on interface " << cus.first
                  << ", this takes 4s..." << std::endl;
        // Wait for child process to finish
        int status;
        wait(&status);
        status = WEXITSTATUS(status);
        if (status) {
          std::cout << "Interface " << cus.first << " is unreachable."
                    << std::endl;
        } else {
          std::cout << "Success!" << std::endl;
        }
      }
    }
  }

  return 0;
}
