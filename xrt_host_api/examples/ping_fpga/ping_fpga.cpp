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

typedef struct
{
  const char *  hostname;
  uint32_t      board_id;
  const char *  ip_address[2];
} ip_config_table_t;

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(arr) sizeof(arr)/sizeof((arr)[0])
#endif



ip_config_table_t  ip_lut[] = {
  {
    .hostname       = "hostname1",
    .board_id       =  0,
    .ip_address     = {"10.1.212.101","10.1.212.102"},
  },
  {
    .hostname       = "hostname2",
    .board_id       =  0,
   .ip_address      = {"10.1.212.103","10.1.212.104"},
  },
  {
    .hostname       = "hostname3",
    .board_id       =  0,
    .ip_address     = {"10.1.212.101","10.1.212.102"},
  },
};


ip_config_table_t * get_ip_config(std::string hostname, uint32_t board_id)
{
    ip_config_table_t * default_ip_config = &ip_lut[0]; // will set default to the first matched hostname.
    for (uint32_t  i = 0; i < ARRAY_SIZE(ip_lut); i++){
        if(std::string(ip_lut[i].hostname) ==  hostname){
            if(ip_lut[i].board_id == board_id){
                printf("Found the ip configure for host %s\n",  ip_lut[i].hostname);
                return &ip_lut[i];
            }
        }
    }
    printf("Host %s with board %d does not exist in configure\n",  hostname.c_str(), board_id);
    printf("Use default config: %s, if0 ip: %s, if1 ip: %s\n",
                              default_ip_config->hostname,
                              default_ip_config->ip_address[0],
                              default_ip_config->ip_address[1] );

    return default_ip_config;
}



enum xclbin_types {  if0, if1, if3 };

struct xclbin_path {
  std::string path;
  xclbin_types type;
};
// Map type of xclbin to contained kernels
const std::map<xclbin_types,
               const std::vector<std::pair<const char *, const char *>>>
kernels = {
            {if0, {
                    {"cmac_0", "networklayer_0"}
                  }
            },
            {if1, {
                    {"cmac_1", "networklayer_1"}
                  }
            },
            {if3, {
                    {"cmac_0", "networklayer_0"},
                    {"cmac_1", "networklayer_1"}
                }
            }
         };
/***************
 * END CONFIG  *
 ***************/

xclbin_path parse_xclbin(const std::string &platform, const char *arg) {
  // Determine content of xclbin based on filename and platform.
  xclbin_path xclbin;
  xclbin.path = arg;
  std::string filename = fs::path(arg).filename();

  bool found = false;


  if (filename == "vnx_basic_if0.xclbin") {
    xclbin.type = if0;
    found = true;
  } else if (filename == "vnx_basic_if1.xclbin") {
    xclbin.type = if1;
    found = true;
  } else if (filename == "vnx_basic_if3.xclbin") {
    xclbin.type = if3;
    found = true;
  }

  if (!found) {
    throw std::runtime_error("Unexpected xclbin file " + filename +
                              " with platform " + platform);
  }

  return xclbin;
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
  int device_id = 0;
  std::size_t ip_index = 0;

  // Read xclbin files from commandline
  std::vector<const char *> args(argv + 1, argv + argc);

  if (args.size() < 1) {
    std::cerr << "No xclbin provided" << std::endl;
    return 1;
  }

  if (args.size() >= 2) {
    device_id = std::stoi(args[1]);
    std::cerr << "Loading XRT device " << device_id << std::endl;
  }

  xrt::device device = xrt::device(device_id);
  // Collect platform info from xclbin
  const std::string platform_json =
      device.get_info<xrt::info::device::platform>();
  const Json::Value platform_dict = parse_json(platform_json);
  const std::string platform =
      platform_dict["platforms"][0]["static_region"]["vbnv"].asString();
  std::cout << "FPGA platform: " << platform << std::endl;

  const xclbin_path xclbin = parse_xclbin(platform, args[0]);
  auto xclbin_uuid = device.load_xclbin(xclbin.path);
  std::cout << "Loaded " << xclbin.path << " onto FPGA on " << hostname << std::endl;
  // Give time for xclbin to be loaded completely before attempting to read
  // the link status.
  std::this_thread::sleep_for(std::chrono::seconds(1));

  // Loop over compute units in xclbin
  for (const auto &cus : kernels.at(xclbin.type)) {
    auto cmac = vnx::CMAC(xrt::ip(device, xclbin_uuid,
                                  std::string(cus.first) + ":{" +
                                      std::string(cus.first) + "}"));
    // Enable rsfec if necessary
    cmac.set_rs_fec(false);

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
    std::cout << "RS-FEC enabled: " << (cmac.get_rs_fec() ? "true" : "false")
              << std::endl;

    // Continue to next xclbin if no link is found.
    if (!link_status) {
      continue;
    }

    std::string ip = get_ip_config(hostname, device_id)->ip_address[ip_index];

    std::cout << "setting up IP " << ip << " to interface " << cus.first
              << std::endl;
    networklayer.update_ip_address(ip);
    std::this_thread::sleep_for(std::chrono::seconds(1));



    // Create fork to run ping
    pid_t pid = fork();

    if (pid == 0) {
      const char *prog = "/bin/ping";
      char *ip_c = (char *)ip.c_str();
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
        std::cout << "Start of debug information dump"
                  << std::endl;
        networklayer.arp_discovery();
        std::this_thread::sleep_for(std::chrono::seconds(5));
        auto table = networklayer.read_arp_table(255);
        for (const auto& [id, value] : table){
          std::cout << "arp table: [" << id << "] = " << value.first << "  " <<value.second << "; "<< std::endl;
        }
        networklayer.get_icmp_in_pkts();
        networklayer.get_icmp_out_pkts();
        std::cout << "End of debug information dump"
                  << std::endl;
      } else {
        std::cout << "Success!" << std::endl;
      }
    }
    ++ip_index;
  }

  return 0;
}
