import pynq
import numpy as np
from pynq import MMIO
import ipaddress

def initSocketTable(ol, sockets, interface = 0, device = None, debug = False):
    netlayer = 'networklayer_' + str(interface)
    network_address = ol.ip_dict[netlayer]["phys_addr"]
    udp_address_offset = ol.ip_dict[netlayer]["registers"]["udp_offset"]["address_offset"]
    udp_phy_address = network_address + udp_address_offset
    udp_handler = MMIO(udp_phy_address, 0x1000, False, device)
    # Get maximum number of sockets in hardware
    numSocketsHW = udp_handler.read(0x210)
    if (numSocketsHW is not len(sockets)):
        raise Exception('Socket list length ({}) is not equal to maximum number of sockets in hardware ({})'.format(len(sockets),numSocketsHW))
    
    
    for i in range(len(sockets)):
        ti_offset = 0x10 + i*8
        tp_offset = ti_offset + len(sockets) * 8
        mp_offset = ti_offset + len(sockets) * 8 * 2
        v_offset  = ti_offset + len(sockets) * 8 * 3
        
        udp_handler.write(ti_offset, int(sockets[i]['theirIP']))
        udp_handler.write(tp_offset, int(sockets[i]['theirPort']))
        udp_handler.write(mp_offset, int(sockets[i]['myPort']))
        udp_handler.write(v_offset , int(sockets[i]['valid']))
        

    if debug:
        print("Number of Sockets: {}" .format(udp_handler.read(0x2d0)))
        for i in range(len(sockets)):
            #print(sockets[i])
            ti_offset = 0x10 + i*8
            tp_offset = ti_offset + len(sockets) * 8
            mp_offset = ti_offset + len(sockets) * 8 * 2
            v_offset  = ti_offset + len(sockets) * 8 * 3

            ti = udp_handler.read(ti_offset)
            tp = udp_handler.read(tp_offset)
            mp = udp_handler.read(mp_offset)
            v  = udp_handler.read(v_offset)
            
            print("HW socket table[{:3d}], ti: 0x{:08x}\ttp: {:5d}\tmp: {:5d}\tv: {:1d}".format(i,ti,tp,mp,v))
    
def byteOrderingEndianess(num, length = 4):
    """ Convert from little endian to big endian
    and viceversa
    """
    aux = 0
    for i in range(length):
        byte_index = num >> ((length-1-i)*8) & 0xFF
        aux += (byte_index << (i*8))
    return aux

def readARPTable (ol, interface = 0, num_entries = 256, device = None):
    """ Read the ARP table from the FPGA and print it out
    in a friendly way
    """
    kernel = 'networklayer_' + str(interface)
    network_address = ol.ip_dict[kernel]["phys_addr"]
    arp_table = MMIO(network_address, 0x10000, False, device)   
    mac_address_offset   = ol.ip_dict[kernel]["registers"]["arp_mac_addr_offset"]["address_offset"]
    ip_address_offset    = ol.ip_dict[kernel]["registers"]["arp_ip_addr_offset"]["address_offset"]
    valid_address_offset = ol.ip_dict[kernel]["registers"]["arp_valid_offset"]["address_offset"]
    
    for i in range(num_entries):
        valid_entry  = arp_table.read(valid_address_offset  + (i//4)*4, 4) # Read 4 byte
        valid_entry  = (valid_entry >> ((i%4) * 8)) & 0x1
        if (valid_entry == 1):
            mac_addr_lsb = arp_table.read(mac_address_offset + (i*2 * 4), 4) # Read 4 bytes
            mac_addr_msb = arp_table.read(mac_address_offset + ((i*2+1) * 4), 4) # Read 4 bytes
            ip_addr      = arp_table.read(ip_address_offset  + (i * 4), 4) # Read 4 bytes
            mac_addr     = (2**32) * mac_addr_msb + mac_addr_lsb
            mac_hex = "{:012x}".format(byteOrderingEndianess(mac_addr,6))
            mac_str = ":".join(mac_hex[i:i+2] for i in range(0, len(mac_hex), 2))
            mac_addr_print = byteOrderingEndianess(mac_addr,6)
            ip_addr_print = byteOrderingEndianess(ip_addr)
            print ("Position {:3}\tMAC address {}\tIP address {}"\
                   .format(i,mac_str,ipaddress.IPv4Address(ip_addr_print)))

def updateIPAddress(nl, ipaddrsrt):
    ipaddr = int(ipaddress.IPv4Address(ipaddrsrt))
    nl.register_map.ip_address = ipaddr
    currentMAC = int(nl.register_map.mac_address)
    newMAC     = (currentMAC & 0xFFFFFFFFFF0) + (ipaddr & 0xF)
    nl.register_map.mac_address = newMAC
    
def shiftedWord(value, position, length = 1):
    return (value >> position) & ((2 ** length) - 1)


def linkStatus(cmac, debug = False):
    """ return link status. debug provides more information
    """
    cmac_status = int(cmac.register_map.led_status)
    status_dict = {}
    
    status_dict['cmac_link'] = bool(shiftedWord(cmac_status,0))
    if debug:
        status_dict['rx_busy'] = bool(shiftedWord(cmac_status,27))
        status_dict['rx_data_fail'] = bool(shiftedWord(cmac_status,23))
        status_dict['rx_done'] = bool(shiftedWord(cmac_status,19))
        status_dict['tx_busy'] = bool(shiftedWord(cmac_status,15))
        status_dict['tx_done'] = bool(shiftedWord(cmac_status,11))
        status_dict['rx_gt_locked'] = bool(shiftedWord(cmac_status,7))
        status_dict['rx_aligned'] = bool(shiftedWord(cmac_status,3))

    return status_dict

benchmark_mode = ['PRODUCER', 'LATENCY', 'LOOPBACK', 'CONSUMER']