# Copyright (c) 2020, Xilinx, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, 
# this list of conditions and the following disclaimer in the documentation 
# and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors 
# may be used to endorse or promote products derived from this software 
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.// Copyright (c) 2020 Xilinx, Inc.

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "xup@xilinx.com"

import pynq
import numpy as np
from pynq import MMIO
import ipaddress

class UDPTable:
    """
    UDP table class
    """

    def __init__(self):
        _socketType = np.dtype([('theirIP', np.uint32), ('theirPort', \
            np.uint16), ('myPort', np.uint16), ('valid', np.bool)])
        self.sockets = np.zeros(16, dtype=_socketType)

def initSocketTable(ol, udptable, interface = 0, device = None, \
    debug = False):
    """ 
    Populate a socket table 
    
    Parameters 
    ----------
    ol: pynq.overlay.Overlay
      Design overlay

    udptable: UDPTable object
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

    if not isinstance(ol, pynq.overlay.Overlay):
        raise ValueError("ol must be an pynq.overlay.Overlay object")

    if not isinstance(udptable, UDPTable):
        raise ValueError("udptable must be an UDPTable object")

    if interface not in [0, 1]:
        raise ValueError("Interface can only be 0 or 1")

    netlayer = 'networklayer_' + str(interface)
    network_address = ol.ip_dict[netlayer]["phys_addr"]
    udp_address_offset = ol.ip_dict[netlayer]["registers"]["udp_offset"]\
     ["address_offset"]
    udp_phy_address = network_address + udp_address_offset
    udp_handler = MMIO(udp_phy_address, 0x1000, False, device)
    sockets = udptable.sockets
    # Get maximum number of sockets in hardware
    numSocketsHW = int(udp_handler.read(0x210))
    if numSocketsHW != len(sockets):
        raise Exception('Socket list length ({}) is not equal to maximum \
            number of sockets in hardware ({})'.format(len(sockets), \
            numSocketsHW))
    
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
        print("Number of Sockets: {}" .format(numSocketsHW))
        for i in range(len(sockets)):
            ti_offset = 0x10 + i*8
            tp_offset = ti_offset + len(sockets) * 8
            mp_offset = ti_offset + len(sockets) * 8 * 2
            v_offset  = ti_offset + len(sockets) * 8 * 3

            ti = udp_handler.read(ti_offset)
            tp = udp_handler.read(tp_offset)
            mp = udp_handler.read(mp_offset)
            v  = udp_handler.read(v_offset)
            
            print("HW socket table[{:3d}], ti: 0x{:08x}\ttp: {:5d}\tmp: \
                {:5d}\tv: {:1d}".format(i,ti,tp,mp,v))
    
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
    if not isinstance(num, int):
        raise ValueError("num must be an integer")

    if not isinstance(length, int):
        raise ValueError("length must be an positive integer")
    elif length < 0:
        raise ValueError("length cannot be negative")

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

    if not isinstance(ol, pynq.overlay.Overlay):
        raise ValueError("ol must be an pynq.overlay.Overlay object")

    if interface not in [0, 1]:
        raise ValueError("Interface can only be 0 or 1")

    if not isinstance(num_entries, int):
        raise ValueError("Number of entries must be integer.")
    elif num_entries < 0:
        raise ValueError("Number of entries cannot be negative.")
    elif num_entries > 256:
        raise ValueError("Number of entries cannot be bigger than 256.")

    kernel = 'networklayer_' + str(interface)
    network_address = ol.ip_dict[kernel]["phys_addr"]
    arp_table = MMIO(network_address, 0x10000, False, device)   
    mac_address_offset   = ol.ip_dict[kernel]["registers"]\
     ["arp_mac_addr_offset"]["address_offset"]
    ip_address_offset    = ol.ip_dict[kernel]["registers"]\
     ["arp_ip_addr_offset"]["address_offset"]
    valid_address_offset = ol.ip_dict[kernel]["registers"]\
     ["arp_valid_offset"]["address_offset"]
    
    for i in range(num_entries):
         # Read 4 byte
        valid_entry  = arp_table.read(valid_address_offset  + (i//4)*4, 4)
        valid_entry  = (valid_entry >> ((i%4) * 8)) & 0x1
        if valid_entry == 1:
            mac_lsb=arp_table.read(mac_address_offset + (i*2 * 4), 4)
            mac_msb=arp_table.read(mac_address_offset + ((i*2+1) * 4), 4)
            ip_addr=arp_table.read(ip_address_offset  + (i * 4), 4)
            mac_addr=(2**32) * mac_msb + mac_lsb
            mac_hex="{:012x}".format(byteOrderingEndianess(mac_addr,6))
            mac_str=":".join(mac_hex[i:i+2] for i in range(0, len(mac_hex), 2))
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

    if not isinstance(nl, pynq.overlay.DefaultIP):
        raise ValueError("ol must be an pynq.overlay.DefaultIP object")

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
        'Mask' : str(ipaddress.IPv4Address(ip_mask))
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

    if not isinstance(nl, pynq.overlay.DefaultIP):
        raise ValueError("nl must be an pynq.overlay.DefaultIP object")

    if not isinstance(ipaddrsrt, str):
        raise ValueError("ipaddrsrt must be an string type")

    if not isinstance(debug, bool):
        raise ValueError("debug must be a bool type")

    ipaddr = int(ipaddress.IPv4Address(ipaddrsrt))
    nl.register_map.ip_address = ipaddr
    nl.register_map.gateway    = (ipaddr & 0xFFFFFF00) + 1
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

    if not isinstance(value, int):
        raise ValueError("value must be integer.")

    if not isinstance(position, int):
        raise ValueError("position must be integer.")

    if not isinstance(width, int):
        raise ValueError("width must be integer.")
    elif width < 0:
        raise ValueError("width cannot be negative.")

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

    if not isinstance(cmac, pynq.overlay.DefaultIP):
        raise ValueError("cmac must be an pynq.overlay.DefaultIP object")

    if not isinstance(debug, bool):
        raise ValueError("debug must be a bool type")

    cmac_status = int(cmac.register_map.led_status)
    status_dict = {}
    
    status_dict['cmac_link']=bool(shiftedWord(cmac_status,0))
    if debug:
        status_dict['rx_busy']=bool(shiftedWord(cmac_status,27))
        status_dict['rx_data_fail']=bool(shiftedWord(cmac_status,23))
        status_dict['rx_done']=bool(shiftedWord(cmac_status,19))
        status_dict['tx_busy']=bool(shiftedWord(cmac_status,15))
        status_dict['tx_done']=bool(shiftedWord(cmac_status,11))
        status_dict['rx_gt_locked']=bool(shiftedWord(cmac_status,7))
        status_dict['rx_aligned']=bool(shiftedWord(cmac_status,3))

    return status_dict

benchmark_mode = ['PRODUCER', 'LATENCY', 'LOOPBACK', 'CONSUMER']