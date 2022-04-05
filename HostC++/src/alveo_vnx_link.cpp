#include "alveo_vnx_link.h"

/**
* AlveoVnxLink::AlveoVnxLink() - class constructor
*
*
* Creates an object that combines CMAC, NetworkLayer and UDP kernels
*/
AlveoVnxLink::AlveoVnxLink(const FpgaDevice &device, uint32_t inst_id) {

    this->cmac = new AlveoVnxCmac(device, inst_id);
    this->nl = new AlveoVnxNetworkLayer(device, inst_id);
    this->rx = new AlveoVnxKrnlS2MM(device, inst_id);
    this->tx = new AlveoVnxKrnlMM2S(device, inst_id);

}


/**
* AlveoVnxLink::~AlveoVnxLink() - class destructor
*
*/
AlveoVnxLink::~AlveoVnxLink() {
    delete this->cmac;
    delete this->nl;
    delete this->tx;
    delete this->rx;
}


/**
* AlveoVnxLink::setMyAddresses() - configures VnxNetworkLayer with supplied addresses
*
* @param ip_address
*  string, IP address in format "192.168.0.1"
* @param mac_address
*  string, MAC address in format "ab:cd:ef:01:02"
* @param udp_port
*  uint16_t, UDP port as decimal or hex
* @return
*  int, 0: OK
*/
int AlveoVnxLink::setMyAddresses(const std::string &ip_address, const std::string &mac_address, uint16_t udp_port) {

    // conert IPv4 address string into 32b hex
    uint64_t a, b, c, d, e, f;
    char dot;
    std::stringstream ss_ip(ip_address);
    ss_ip >> a >> dot >> b >> dot >> c >> dot >> d;
    uint32_t ip_hex = (a << 24) | (b << 16) | (c << 8) | d;

    this->ip = ip_hex;

    this->nl->writeRegister("my_ip", ip_hex);

    // conert MAC address string into 48b hex
    std::stringstream ss_mac(mac_address);
    ss_mac >> a >> dot >> b >> dot >> c >> dot >> d >> dot >> e >> dot >> f;
    uint64_t mac_hex = (a << 40) | (b << 32) | (c << 24) | (d << 16) | (e << 8) | f;

    this->mac = mac_hex;

    this->nl->writeRegister("my_mac_msb", static_cast<uint32_t>(mac_hex >> 32));
    this->nl->writeRegister("my_mac_lsb", static_cast<uint32_t>(mac_hex & 0xffffffff));

    // assign UDP port
    this->udp = udp_port;

    return 0;
}


/**
* AlveoVnxLink::sendTo() - transfers complete set of data to destination
*                                fragments into UDP packets when needed
*                                inserts an additional header word in front with EOF flag and size
*
* @param dest_ip
*  string, destination IP address in format "192.168.0.1"
* @param dest_udp
*  uint16_t, destination UDP port as decimal or hex
* @param buffer
*  char*, pointer to previously allocated and prepared memory with the payload
* @param size
*  size_t, size of the complete payload in bytes
* @return
*  int, 0: OK
*/
int AlveoVnxLink::sendTo(const std::string &dest_ip, uint16_t dest_udp, char *buffer, size_t size) {

    this->nl->setSocket(dest_ip, dest_udp, this->udp, 0);

    this->nl->runARPDiscovery();

    // transfer the data from the buffer
    // fragment into MAX_UDP_BUFFER_SIZE packets when needed
    // add an additional data word in front of the buffer with EOF and size

    uint32_t header;
    char *pkt_buffer = new char[MAX_UDP_BUFFER_SIZE + 4];
    size_t size_left = size;
    size_t size_to_transfer = 0;
    size_t total_transferred_size = 0;

    for (int i = 0; size_left > 0; i++) {

        // EOF marker bit on MSB
        header = (size_left < MAX_UDP_BUFFER_SIZE) << 31;

        if (size_left < MAX_UDP_BUFFER_SIZE) {
            size_to_transfer = size_left;
            size_left -= size_left;
        } else {
            size_to_transfer = MAX_UDP_BUFFER_SIZE;
            size_left -= MAX_UDP_BUFFER_SIZE;
        }

        // payload size
        header = header | size_to_transfer;
        std::cout << "header " << std::hex << header << std::dec << std::endl;
        std::cout << "size left: " << size_left << " total_transferred_size " << total_transferred_size << std::endl;

        *(uint32_t *) pkt_buffer = header;
        memcpy(pkt_buffer + 4, buffer + total_transferred_size, size_to_transfer);

        total_transferred_size += size_to_transfer;

        this->tx->transferDataToKrnl(pkt_buffer, MAX_UDP_BUFFER_SIZE + 4);
        std::cout << "l0 data transfered " << size_to_transfer << " bytes" << std::endl;

        this->tx->sendPacket(0);
        std::cout << "l0 packet sent" << std::endl;

    }

    delete[] pkt_buffer;

    return 0;
}

/**
* AlveoVnxLink::receive() - receives data packets until EOF flag is received
*                                the data is reassembled and stored in external buffer
*
* @param src_ip
*  string, IP address of the sender in format "192.168.0.1"
* @param src_udp
*  uint16_t, UDP port of the sender as decimal or hex
* @param buffer
*  char*, pointer to previously allocated memory to store the received data
* @return
*  int, total size of received transaction in bytes
*/
int AlveoVnxLink::receive(const std::string &src_ip, uint16_t src_udp, char *buffer) {

    this->nl->setSocket(src_ip, src_udp, this->udp, 0);

    this->nl->runARPDiscovery();

    char *pkt_buffer = new char[MAX_UDP_BUFFER_SIZE + 4];
    size_t rx_size = 0;

    // loop for receiveing packets until EOF is recognized
    // allows to perform full transactions with payload larger that single UDP
    // no further verification is performed
    // pottenially could lead to packet mixing
    while (true) {
        this->rx->receivePacket(MAX_UDP_BUFFER_SIZE + 4);
        this->rx->transferDataToHost(pkt_buffer);

        uint32_t header = *(uint32_t *) pkt_buffer;

        bool eof = header >> 31;
        size_t pkt_size = (header & 0xffff);

        std::cout << "received header " << std::hex << header << std::dec << " eof: " << eof << " pkt_size " << pkt_size << " rx_size " << rx_size
                  << std::endl;

        memcpy(buffer + rx_size, pkt_buffer + 4, pkt_size);

        rx_size += pkt_size;

        if (eof) {
            break;
        }
    }

    delete[] pkt_buffer;

    return rx_size;
}