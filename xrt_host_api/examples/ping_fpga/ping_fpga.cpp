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

#include <chrono>
#include <experimental/xrt_ip.h>
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

/***************
 *    CONFIG   *
 ***************/
const char *u280_if3 = "PATH_TO_U280_XCLBIN/vnx_basic_if3.xclbin";
const char *u55c_if0 = "PATH_TO_U55c_XCLBIN/vnx_basic_if0.xclbin";
const char *u55c_if1 = "PATH_TO_U55c_XCLBIN/vnx_basic_if1.xclbin";
const char *u55c_if3 = "PATH_TO_U55c_XCLBIN/vnx_basic_if3.xclbin";

const char *hostname1 = "hostname1";
const char *hostname2 = "hostname2";
const char *hostname3 = "hostname3";

const std::map<const char *,
               const std::vector<std::pair<const char *, const char *>>>
    kernels = {{u280_if3,
                {{"cmac_0", "networklayer_0"}, {"cmac_1", "networklayer_1"}}},
               {u55c_if0, {{"cmac_0", "networklayer_0"}}},
               {u55c_if1, {{"cmac_1", "networklayer_1"}}},
               {u55c_if3,
                {{"cmac_0", "networklayer_0"}, {"cmac_1", "networklayer_1"}}}};

const std::map<std::string, const std::vector<const char *>> bitstreams = {
    {"xilinx_u280_xdma_201920_3", {u280_if3}},
    /* Use u55c_if0 and u55c_if1 when using XRT 2.13 */
    {"xilinx_u55c_gen3x16_xdma_base_3", {u55c_if0, u55c_if1}}};

const std::map<std::string, const std::vector<std::string>> ip_addresses = {
    {hostname1, {"10.1.212.101", "10.1.212.102"}},
    {hostname2, {"10.1.212.103", "10.1.212.104"}},
    {hostname3, {"10.1.212.105", "10.1.212.106"}}};
/***************
 * END CONFIG  *
 ***************/

Json::Value parse_json(const std::string &string) {
  Json::Reader reader;
  Json::Value json;
  reader.parse(string, json);
  return json;
}

int main() {
  char hostname[HOST_NAME_MAX];
  gethostname(hostname, HOST_NAME_MAX);
  xrt::device device = xrt::device(0);
  const std::string platform_json =
      device.get_info<xrt::info::device::platform>();
  const Json::Value platform_dict = parse_json(platform_json);
  const std::string platform =
      platform_dict["platforms"][0]["static_region"]["vbnv"].asString();
  std::cout << "FPGA platform: " << platform << std::endl;
  const auto paths = bitstreams.at(platform);
  std::size_t ip_index = 0;
  for (const auto &path : paths) {
    auto xclbin_uuid = device.load_xclbin(path);
    std::cout << "Loaded " << path << " onto FPGA on " << hostname << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(1));

    for (const auto &cus : kernels.at(path)) {
      auto cmac = vnx::CMAC(xrt::ip(device, xclbin_uuid,
                                    std::string(cus.first) + ":{" +
                                        std::string(cus.first) + "}"));
      auto networklayer = vnx::Networklayer(
          xrt::ip(device, xclbin_uuid,
                  "networklayer:{" + std::string(cus.second) + "}"));
      bool link_status;
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

      if (!link_status) {
        continue;
      }

      std::string ip = ip_addresses.at(hostname)[ip_index];
      ++ip_index;

      std::cout << "setting up IP " << ip << " to interface " << cus.first
                << std::endl;
      networklayer.update_ip_address(ip);
      std::this_thread::sleep_for(std::chrono::seconds(1));

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
