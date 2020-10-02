import pynq
import numpy as np
from pynq import MMIO
import ipaddress

def initSocketTable(ol, sockets, interface = 0, device = None, debug = False):
    """ 
    Populate a socket table 
    
    Parameters 
    ----------
    ol: pynq.overlay.Overlay
      Design overlay

    sockets: socket object
      object with the 16 entries

    interface: int
      Interface number, either 0 or 1

      Optionals
      ---------
      device: pynq.Device.devices
        Alveo device being used

      debug: bool
        If enables read the current status of the UDP Table
    
    Returns
    -------
    If debug is enable read the current status of the UDP Table

    """

    if (interface != 0) or (interface != 1):
        raise ValueError("Interface can only be 0 or 1")

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
    """ 
    Convert from little endian to big endian and viceversa

    Parameters 
    ----------
    num: int
      input number

    length:
      number of bytes of the input number

    Returns
    -------
    An integer with the endianness changed with respect to input number

    """
    aux = 0
    for i in range(length):
        byte_index = num >> ((length-1-i)*8) & 0xFF
        aux += (byte_index << (i*8))
    return aux

def readARPTable(ol, interface = 0, num_entries = 256, device = None):
    """ 
    Read the ARP table from the FPGA and print it out
    in a friendly way
    
    Parameters 
    ----------
    ol: pynq.overlay.Overlay
      Design overlay

    interface: int
      Interface number, either 0 or 1

      Optionals
      ---------
      num_entries: int
        number of entries in the table to be consider when printing

      device: pynq.Device.devices
        Alveo device being used
    
    Returns
    -------
    Prints the content of valid entries in the ARP in a friendly way

    """

    if (interface != 0) or (interface != 1):
        raise ValueError("Interface can only be 0 or 1")

    if num_entries < 0:
        raise ValueError("Number of entries cannot be negative.")
    elif num_entries > 256:
        raise ValueError("Number of entries cannot be bigger than 256.")

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

def getNetworkInfo(nl):
    """ 
    Gets the current interface information
    
    Parameters 
    ----------
    nl: pynq.overlay.DefaultIP
      network layer object type
    
    Returns
    -------
    A dictionary with the current configuration

    """
    mac_addr = int(nl.register_map.mac_address)
    ip_addr  = int(nl.register_map.ip_address)
    ip_gw    = int(nl.register_map.gateway)
    ip_mask  = int(nl.register_map.ip_mask)

    mac_hex = "{:012x}".format(mac_addr)
    mac_str = ":".join(mac_hex[i:i+2] for i in range(0, len(mac_hex), 2))

    config = {
        'HWaddr' : ":".join(mac_hex[i:i+2] for i in range(0, len(mac_hex), 2)),
        'inet addr' : str(ipaddress.IPv4Address(ip_addr)),
        'gateway addr' : str(ipaddress.IPv4Address(ip_gw)),
        'Mask' : str(ipaddress.IPv4Address(ip_gw))
    }

    return config

def updateIPAddress(nl, ipaddrsrt, debug = False):
    """ 
    Update IP address as well as least significant octet of the
    MAC address with the least significant octet of the IP address

    Parameters 
    ----------
    nl: pynq.overlay.DefaultIP
      network layer object type
    ipaddrsrt : string
      New IP address

    debug: bool
      if enable it will return the current configuration
    
    Returns
    -------
    Current interface configuration only if debug == True

    """
    ipaddr = int(ipaddress.IPv4Address(ipaddrsrt))
    nl.register_map.ip_address = ipaddr
    currentMAC = int(nl.register_map.mac_address)
    newMAC     = (currentMAC & 0xFFFFFFFFF00) + (ipaddr & 0xFF)
    nl.register_map.mac_address = newMAC

    if debug:
        return getNetworkInfo(nl)
    
def shiftedWord(value, position, width = 1):
    """
    Slices a width-word from an integer 
    
    Parameters 
    ----------
    value: int
      input word
    position : int
      start bit position in the output word
    width: int
      number of bits of the output word
    
    Returns
    -------
    An integer with the sliced word

    """
    return (value >> position) & ((2 ** width) - 1)


def linkStatus(cmac, debug = False):
    """ 
    Current link status. 
    
    Parameters 
    ----------
    cmac: pynq.overlay.DefaultIP
      cmac object type

    debug: bool
      if enable provides more information
    
    Returns
    -------
    A dictionary with link status, more status information
    is returned if debug == True

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