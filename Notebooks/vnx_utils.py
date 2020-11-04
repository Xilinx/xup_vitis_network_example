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
__copyright__ = "Copyright 2020, Xilinx Inc."
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
        _socketType = np.dtype([('theirIP', np.unicode_, 16), ('theirPort', \
            np.uint16), ('myPort', np.uint16), ('valid', np.bool)])
        self.sockets = np.zeros(16, dtype=_socketType)

def initSocketTable(nl, udptable, debug = False):
    """ 
    Populate a socket table 
    
    Parameters 
    ----------
    nl: pynq.overlay.DefaultIP
      network layer object type

    udptable: UDPTable object
      object with the 16 entries

    interface: int
      Interface number, either 0 or 1

      Optionals
      ---------
      debug: bool
        If enables read the current status of the UDP Table
    
    Returns
    -------
    If debug is enable read the current status of the UDP Table

    """

    if not isinstance(nl, pynq.overlay.DefaultIP):
        raise ValueError("nl must be a pynq.overlay.DefaultIP object")

    if not isinstance(udptable, UDPTable):
        raise ValueError("udptable must be an UDPTable object")

    sockets = udptable.sockets

    offset = nl.register_map.udp_offset.address
    numSocketsHW = int(nl.read(offset + 0x210))

    if numSocketsHW < len(sockets):
        raise Exception('Socket list length ({}) is bigger than the \
            number of sockets in hardware ({})'.format(len(sockets), \
            numSocketsHW))

    # Iterate over the socket object
    for i in range(len(sockets)):
        ti_offset = offset + 0x10 + i*8
        tp_offset = ti_offset + len(sockets) * 8
        mp_offset = ti_offset + len(sockets) * 8 * 2
        v_offset  = ti_offset + len(sockets) * 8 * 3
        
        theirIP = 0
        if sockets[i]['theirIP']:
            theirIP = int(ipaddress.IPv4Address(sockets[i]['theirIP']))

        nl.write(ti_offset, theirIP)
        nl.write(tp_offset, int(sockets[i]['theirPort']))
        nl.write(mp_offset, int(sockets[i]['myPort']))
        nl.write(v_offset , int(sockets[i]['valid']))
        
    if debug:
        print("Number of Sockets: {}" .format(numSocketsHW))
        # Iterate over all the UDP table
        for i in range(numSocketsHW):
            ti_offset = offset + 0x10 + i*8
            tp_offset = ti_offset + numSocketsHW * 8
            mp_offset = ti_offset + numSocketsHW * 8 * 2
            v_offset  = ti_offset + numSocketsHW * 8 * 3

            ti = nl.read(ti_offset)
            tp = nl.read(tp_offset)
            mp = nl.read(mp_offset)
            v  = nl.read(v_offset)
            
            print("HW socket table[{:3d}], ti: {}\ttp: {:5d}\tmp: {:5d}\t\
                v: {:1d}".format(i,str(ipaddress.IPv4Address(ti)),tp,mp,v))
    
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

def readARPTable(nl, num_entries = 256):
    """ 
    Read the ARP table from the FPGA and print it out
    in a friendly way
    
    Parameters 
    ----------
    nl: pynq.overlay.DefaultIP
      network layer object type

      Optionals
      ---------
      num_entries: int
        number of entries in the table to be consider when printing

    Returns
    -------
    Prints the content of valid entries in the ARP in a friendly way

    """

    if not isinstance(nl, pynq.overlay.DefaultIP):
        raise ValueError("nl must be a pynq.overlay.DefaultIP object")

    if not isinstance(num_entries, int):
        raise ValueError("Number of entries must be integer.")
    elif num_entries < 0:
        raise ValueError("Number of entries cannot be negative.")
    elif num_entries > 256:
        raise ValueError("Number of entries cannot be bigger than 256.")

    mac_addr_offset   = nl.register_map.arp_mac_addr_offset.address
    ip_addr_offset    = nl.register_map.arp_ip_addr_offset.address
    valid_addr_offset = nl.register_map.arp_valid_offset.address

    for i in range(num_entries):
        valid_entry  = nl.read(valid_addr_offset  + (i//4)*4)
        valid_entry  = (valid_entry >> ((i%4) * 8)) & 0x1
        if valid_entry == 1:
            mac_lsb=nl.read(mac_addr_offset + (i*2 * 4))
            mac_msb=nl.read(mac_addr_offset + ((i*2+1) * 4))
            ip_addr=nl.read(ip_addr_offset  + (i * 4))
            mac_addr=(2**32) * mac_msb + mac_lsb
            mac_hex="{:012x}".format(byteOrderingEndianess(mac_addr,6))
            mac_str=":".join(mac_hex[i:i+2] for i in range(0, len(mac_hex), 2))
            ip_addr_print = byteOrderingEndianess(ip_addr)
            print ("Position {:3}\tMAC address {}\tIP address {}"\
                   .format(i,mac_str,ipaddress.IPv4Address(ip_addr_print)))


def invalidateARPTable(nl):
    """ 
    Clear the ARP table
    
    Parameters 
    ----------
    nl: pynq.overlay.DefaultIP
      network layer object type

    Returns
    -------
    None

    """

    if not isinstance(nl, pynq.overlay.DefaultIP):
        raise ValueError("nl must be a pynq.overlay.DefaultIP object")

    valid_addr_offset = nl.register_map.arp_valid_offset.address

    for i in range(256):
        nl.write(valid_addr_offset  + (i//4)*4 , 0)

def arpDiscovery(nl):
    """ 
    Launch ARP discovery

    Parameters 
    ----------
    nl: pynq.overlay.DefaultIP
      network layer object type
    
    Returns
    -------
    None

    """
    
    if not isinstance(nl, pynq.overlay.DefaultIP):
        raise ValueError("nl must be a pynq.overlay.DefaultIP object")

    # The ARP discovery is trigger with the rising edge
    nl.register_map.arp_discovery = 0
    nl.register_map.arp_discovery = 1
    nl.register_map.arp_discovery = 0

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
        raise ValueError("ol must be a pynq.overlay.DefaultIP object")

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

def updateIPAddress(nl, ipaddrsrt, gwaddr='None', debug = False):
    """ 
    Update IP address as well as least significant octet of the
    MAC address with the least significant octet of the IP address

    Parameters 
    ----------
    nl: pynq.overlay.DefaultIP
      network layer object type
    ipaddrsrt : string
      New IP address

    gwaddr : string
        New IP gateway address, if not defined a default gateway is used
    debug: bool
      if enable it will return the current configuration
    
    Returns
    -------
    Current interface configuration only if debug == True

    """

    if not isinstance(nl, pynq.overlay.DefaultIP):
        raise ValueError("nl must be a pynq.overlay.DefaultIP object")

    if not isinstance(ipaddrsrt, str):
        raise ValueError("ipaddrsrt must be an string type")

    if not isinstance(gwaddr, str):
        raise ValueError("gwaddr must be an string type")

    if not isinstance(debug, bool):
        raise ValueError("debug must be a bool type")

    ipaddr = int(ipaddress.IPv4Address(ipaddrsrt))
    nl.register_map.ip_address = ipaddr
    if gwaddr is 'None':
        nl.register_map.gateway = (ipaddr & 0xFFFFFF00) + 1
    else:
        nl.register_map.gateway = int(ipaddress.IPv4Address(gwaddr))

    currentMAC = int(nl.register_map.mac_address)
    newMAC     = (currentMAC & 0xFFFFFFFFF00) + (ipaddr & 0xFF)
    nl.register_map.mac_address = newMAC

    if debug:
        return getNetworkInfo(nl)

def updateGateway(nl, gwaddr, debug = False):
    """ 
    Update IP address as well as least significant octet of the
    MAC address with the least significant octet of the IP address

    Parameters 
    ----------
    nl: pynq.overlay.DefaultIP
      network layer object type
    gwaddr : string
      New IP gateway address

    debug: bool
      if enable it will return the current configuration
    
    Returns
    -------
    Current interface configuration only if debug == True

    """

    if not isinstance(nl, pynq.overlay.DefaultIP):
        raise ValueError("nl must be a pynq.overlay.DefaultIP object")

    if not isinstance(gwaddr, str):
        raise ValueError("gwaddr must be an string type")

    if not isinstance(debug, bool):
        raise ValueError("debug must be a bool type")

    nl.register_map.gateway = int(ipaddress.IPv4Address(gwaddr))

    if debug:
        return getNetworkInfo(nl)
    
def shiftedWord(value, index, width = 1):
    """
    Slices a width-word from an integer 
    
    Parameters 
    ----------
    value: int
      input word
    index : int
      start bit index in the output word
    width: int
      number of bits of the output word
    
    Returns
    -------
    An integer with the sliced word

    """

    if not isinstance(value, int):
        raise ValueError("value must be integer.")

    if not isinstance(index, int):
        raise ValueError("index must be integer.")

    if not isinstance(width, int):
        raise ValueError("width must be integer.")
    elif width < 0:
        raise ValueError("width cannot be negative.")

    return (value >> index) & ((2 ** width) - 1)


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
        status_dict['rx_busy']=bool(shiftedWord(cmac_status,28))
        status_dict['rx_data_fail']=bool(shiftedWord(cmac_status,24))
        status_dict['rx_done']=bool(shiftedWord(cmac_status,20))
        status_dict['tx_busy']=bool(shiftedWord(cmac_status,16))
        status_dict['tx_done']=bool(shiftedWord(cmac_status,12))
        status_dict['rx_gt_locked']=bool(shiftedWord(cmac_status,8))
        status_dict['rx_aligned']=bool(shiftedWord(cmac_status,4))

    return status_dict

def computeThroughputApp(tg, freq = 300.0, direction = 'rx'):
    """ 
    Read the application monitoring registers and compute
    throughput, it also returns other useful information

    Parameters 
    ----------
    tg: pynq.overlay.DefaultIP
      traffic generator object type

      Optionals
      ---------
      freq : float or int
        Kernel's frequency
  
      direction: string
        'rx' or 'tx'
    
    Returns
    -------
    Total number of packets seen by the monitoring probe, 
    throughput and total time
    """

    if not isinstance(tg, pynq.overlay.DefaultIP):
        raise ValueError("tg must be a pynq.overlay.DefaultIP object")

    if not isinstance(freq, float) and not isinstance(freq, int):
        raise ValueError("freq must be a either an integer or a float")
    elif freq <= 0:
        raise ValueError("freq must be bigger than zero")

    if direction not in ['rx', 'tx']:
        raise ValueError("Only 'rx' and 'tx' strings are supported \
            on direction argument")
    
    if direction is 'rx':
        tot_bytes  = int(tg.register_map.in_traffic_bytes) 
        tot_cycles = int(tg.register_map.in_traffic_cycles)
        tot_pkts   = int(tg.register_map.in_traffic_packets)
    else:
        tot_bytes  = int(tg.register_map.out_traffic_bytes) 
        tot_cycles = int(tg.register_map.out_traffic_cycles)
        tot_pkts   = int(tg.register_map.out_traffic_packets)

    tot_time   = (1 / (freq*10**6)) * tot_cycles
    thr_bs     = (tot_bytes * 8) / tot_time

    return tot_pkts, thr_bs/(10**9), tot_time

benchmark_mode = ['PRODUCER', 'LATENCY', 'LOOPBACK', 'CONSUMER']