#include "alveo_vnx_nl.h"

/**
* AlveoVnxNetworkLayer::AlveoVnxNetworkLayer() - class constructor
*
* @param device
*  xrt::device, particular Alveo device type to connect to
* @param uuid
*  xrt::uuid, unique ID of the Alveo device
* @param inst_id
*  uint32_t, instance id
*
* Creates an object representing VNX Network Layer IP
*/

AlveoVnxNetworkLayer::AlveoVnxNetworkLayer(const FpgaDevice &device, uint32_t inst_id) :
        FpgaIP::FpgaIP(device, "networklayer:{networklayer_" + std::to_string(inst_id) + "}") {

    this->registers_map["my_mac_lsb"] = 0x0010;
    this->registers_map["my_mac_msb"] = 0x0014;
    this->registers_map["my_ip"] = 0x0018;

    this->registers_map["arp_discovery"] = 0x3010;

    this->registers_map["eth_in_packets"] = 0x1010;
    this->registers_map["eth_out_packets"] = 0x10B8;

    this->registers_map["udp_theirIP_offset"] = 0x2010;
    this->registers_map["udp_theirPort_offset"] = 0x2090;
    this->registers_map["udp_myPort_offset"] = 0x2110;
    this->registers_map["udp_valid_offset"] = 0x2190;
    this->registers_map["udp_number_offset"] = 0x2210;
}


/**
* AlveoVnxNetworkLayer::addSocket() - adds an entry into the HW register region
*
* @param remote_ip
*  string, IP address of the remote partner
* @param remote_udp
*  uint32_t, UDP port number of the remote partner
* @param local_udp
*  uint32_t, UDP port number of local socket
* @param socket_index
*  int, index of the slot socket to configure
* @return
*  int, 0: OK
*
* Adds an entry into the HW register region that allows to transmit and receive UDP packets
*/
int AlveoVnxNetworkLayer::setSocket(const std::string &remote_ip, uint32_t remote_udp, uint32_t local_udp, int socket_index) {

    // conert IPv4 address string into 32b hex
    uint32_t a, b, c, d;
    char dot;
    std::stringstream ss(remote_ip);
    ss >> a >> dot >> b >> dot >> c >> dot >> d;
    uint32_t ip_hex = (a << 24) | (b << 16) | (c << 8) | d;

    // store the socket addresses in socket region with concecutive index
    this->writeRegisterAddr(this->registers_map["udp_theirIP_offset"] + socket_index * 8, ip_hex);
    this->writeRegisterAddr(this->registers_map["udp_theirPort_offset"] + socket_index * 8, remote_udp);
    this->writeRegisterAddr(this->registers_map["udp_myPort_offset"] + socket_index * 8, local_udp);
    this->writeRegisterAddr(this->registers_map["udp_valid_offset"] + socket_index * 8, 1);

    return 0;
}


/**
* AlveoVnxNetworkLayer::runARPDiscovery() - fires the ARP procedure
*
* @return
*  int, 0: done
*
*/
int AlveoVnxNetworkLayer::runARPDiscovery() {
    this->writeRegister("arp_discovery", 0);
    this->writeRegister("arp_discovery", 1);
    this->writeRegister("arp_discovery", 0);

    return 0;
}