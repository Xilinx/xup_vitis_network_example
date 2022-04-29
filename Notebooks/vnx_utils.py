#   Copyright (c) 2020-2022, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2020-2022, Xilinx Inc."
__email__ = "xup@xilinx.com"

from pynq import DefaultIP
from pynq.utils import ReprDict
import numpy as np
import ipaddress
from enum import Enum


def _shiftedWord(value, index, width=1):
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


_cmac_modes = {
        0: 'CAUI10',
        1: 'CAUI4',
        2: 'Runtime Switchable CAUI10',
        3: 'Runtime Switchable CAUI4'
    }


class CMAC(DefaultIP):
    """This class wrapps the common function of the CMAC IP
    """

    bindto = ["xilinx.com:kernel:cmac_0:1.0",
              "xilinx.com:kernel:cmac_1:1.0"]

    def __init__(self, description):
        super().__init__(description=description)
        self._fullpath = description['fullpath']
        self.start = self.start_sw = self.start_none = \
            self.start_ert = self.call

    def _setup_packet_prototype(self):
        pass

    def call(self, *args, **kwargs):
        raise RuntimeError("{} is a free running kernel and cannot be "
                           "starter or called".format(self._fullpath))

    def linkStatus(self, debug: bool=False) -> dict:
        """Current CMAC link status

        Parameters
        ----------
        debug: bool
        if enable provides more information

        Returns
        -------
        A dictionary with link status, more status information
        is returned if debug == True
        """

        if not isinstance(debug, bool):
            raise ValueError("debug must be a bool type")

        # The first time these registers are not populated properly,
        # read them twice to get real value
        for _ in range(2):
            rx_status = int(self.register_map.stat_rx_status)
            tx_status = int(self.register_map.stat_tx_status)

        status_dict = {}
        status_dict["cmac_link"] = bool(_shiftedWord(rx_status, 0))
        if debug:
            status_dict["rx_status"] = bool(_shiftedWord(rx_status, 0))
            status_dict["rx_aligned"] = bool(_shiftedWord(rx_status, 1))
            status_dict["rx_misaligned"] = bool(_shiftedWord(rx_status, 2))
            status_dict["rx_aligned_err"] = bool(_shiftedWord(rx_status, 3))
            status_dict["rx_hi_ber"] = bool(_shiftedWord(rx_status, 4))
            status_dict["rx_remote_fault"] = bool(_shiftedWord(rx_status, 5))
            status_dict["rx_local_fault"] = bool(_shiftedWord(rx_status, 6))
            status_dict["rx_got_signal_os"] = bool(_shiftedWord(rx_status, 14))
            status_dict["tx_local_fault"] = bool(_shiftedWord(tx_status, 0))

        return status_dict

    def copyStats(self) -> None:
        """Triggers a snapshot of CMAC Statistics

        Triggers a snapshot of all the Statistics counters into their
        readable register. The bit self-clears.
        """

        self.register_map.stat_pm_tick = 1

    def getStats(self, update_reg: bool=True) -> dict:
        """ Return a dictionary with the CMAC stats

        Parameters
        ----------
        debug: bool
        if enabled, the CMAC registers are copied from internal counters

        Returns
        -------
        A dictionary with the CMAC statistics
        """
        if update_reg:
            self.copyStats()

        rmap = self.register_map
        stats_dict = dict()
        stats_dict['tx'] = dict()
        stats_dict['rx'] = dict()
        stats_dict['cycle_count'] = int(rmap.stat_cycle_count)
        # Tx
        stats_dict['tx'] = {
            "packets": int(rmap.stat_tx_total_packets),
            "good_packets": int(rmap.stat_tx_total_good_packets),
            "bytes": int(rmap.stat_tx_total_bytes),
            "good_bytes": int(rmap.stat_tx_total_good_bytes),
            "packets_64B": int(rmap.stat_tx_total_packets_64B),
            "packets_65_127B": int(rmap.stat_tx_total_packets_65_127B),
            "packets_128_255B": int(rmap.stat_tx_total_packets_128_255B),
            "packets_256_511B": int(rmap.stat_tx_total_packets_256_511B),
            "packets_512_1023B": int(rmap.stat_tx_total_packets_512_1023B),
            "packets_1024_1518B": int(rmap.stat_tx_total_packets_1024_1518B),
            "packets_1519_1522B": int(rmap.stat_tx_total_packets_1519_1522B),
            "packets_1523_1548B": int(rmap.stat_tx_total_packets_1523_1548B),
            "packets_1549_2047B": int(rmap.stat_tx_total_packets_1549_2047B),
            "packets_2048_4095B": int(rmap.stat_tx_total_packets_2048_4095B),
            "packets_4096_8191B": int(rmap.stat_tx_total_packets_4096_8191B),
            "packets_8192_9215B": int(rmap.stat_tx_total_packets_8192_9215B),
            "packets_large": int(rmap.stat_tx_total_packets_large),
            "packets_small": int(rmap.stat_tx_total_packets_small),
            "bad_fcs": int(rmap.stat_tx_total_bad_fcs),
            "pause": int(rmap.stat_tx_pause),
            "user_pause": int(rmap.stat_tx_user_pause),
        }

        stats_dict['rx'] = {
            "packets": int(rmap.stat_rx_total_packets),
            "good_packets": int(rmap.stat_rx_total_good_packets),
            "bytes": int(rmap.stat_rx_total_bytes),
            "good_bytes": int(rmap.stat_rx_total_good_bytes),
            "packets_64B": int(rmap.stat_rx_total_packets_64B),
            "packets_65_127B": int(rmap.stat_rx_total_packets_65_127B),
            "packets_128_255B": int(rmap.stat_rx_total_packets_128_255B),
            "packets_256_511B": int(rmap.stat_rx_total_packets_256_511B),
            "packets_512_1023B": int(rmap.stat_rx_total_packets_512_1023B),
            "packets_1024_1518B": int(rmap.stat_rx_total_packets_1024_1518B),
            "packets_1519_1522B": int(rmap.stat_rx_total_packets_1519_1522B),
            "packets_1523_1548B": int(rmap.stat_rx_total_packets_1523_1548B),
            "packets_1549_2047B": int(rmap.stat_rx_total_packets_1549_2047B),
            "packets_2048_4095B": int(rmap.stat_rx_total_packets_2048_4095B),
            "packets_4096_8191B": int(rmap.stat_rx_total_packets_4096_8191B),
            "packets_8192_9215B": int(rmap.stat_rx_total_packets_8192_9215B),
            "packets_large": int(rmap.stat_rx_total_packets_large),
            "packets_small": int(rmap.stat_rx_total_packets_small),
            "packets_undersize": int(rmap.stat_rx_total_packets_undersize),
            "packets_fragmented": int(rmap.stat_rx_total_packets_fragmented),
            "packets_oversize": int(rmap.stat_rx_total_packets_oversize),
            "packets_toolong": int(rmap.stat_rx_total_packets_toolong),
            "packets_jabber": int(rmap.stat_rx_total_packets_jabber),
            "bad_fcs": int(rmap.stat_rx_total_bad_fcs),
            "packets_bad_fcs": int(rmap.stat_rx_packets_bad_fcs),
            "stomped_fcs": int(rmap.stat_rx_stomped_fcs),
            "pause": int(rmap.stat_rx_pause),
            "user_pause": int(rmap.stat_rx_user_pause),
        }

        return stats_dict

    @property
    def version(self):
        """Returns the CMAC Core version
        """

        version = int(self.register_map.version)
        return str(_shiftedWord(version, 8, 8)) + '.' \
            + str(_shiftedWord(version, 0, 8))

    @property
    def mode(self):
        """Returns the CMAC Core mode
        """
        mode = int(self.register_map.core_mode) & 0x3
        return _cmac_modes[mode]

    @property
    def loopback(self):
        """ GT Loopback

        False: normal operation
        True: GT internal loopback
        """
        return bool(int(self.register_map.gt_loopback) & 0x1)

    @loopback.setter
    def loopback(self, operation):
        if not isinstance(operation, (int, bool)):
            raise ValueError("operation must be int or bool")
        self.register_map.gt_loopback = int(bool(operation))


def _byteOrderingEndianess(num, length=4):
    """
    Convert from little endian to big endian and vice versa

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
        byte_index = num >> ((length - 1 - i) * 8) & 0xFF
        aux += byte_index << (i * 8)
    return aux


class NetworkLayer(DefaultIP):
    """This class wraps the common function of the Network Layer IP

    """

    bindto = ["xilinx.com:kernel:networklayer:1.0"]

    _socketType = np.dtype(
        [
            ("theirIP", np.unicode_, 16),
            ("theirPort", np.uint16),
            ("myPort", np.uint16),
            ("valid", np.bool),
        ]
    )

    def __init__(self, description):
        super().__init__(description=description)
        self._fullpath = description['fullpath']
        self.start = self.start_sw = self.start_none = \
            self.start_ert = self.call
        self.sockets = np.zeros(16, dtype=self._socketType)
        self.freq = None

    def _setup_packet_prototype(self):
        pass

    def call(self, *args, **kwargs):
        raise RuntimeError("{} is a free running kernel and cannot be "
                           "starter or called".format(self._fullpath))

    def populateSocketTable(self, debug=False):
        """
        Populate a socket table

        Optionals
        ---------
        debug: bool
            If enables read the current status of the UDP Table

        Returns
        -------
        If debug is enable read the current status of the UDP Table

        """

        theirIP_offset = self.register_map.udp_theirIP_offset.address
        theirPort_offset = self.register_map.udp_theirPort_offset.address
        udp_myPort_offset = self.register_map.udp_myPort_offset.address
        udp_valid_offset = self.register_map.udp_valid_offset.address
        numSocketsHW = int(self.register_map.udp_number_sockets)

        if numSocketsHW < len(self.sockets):
            raise Exception(
                "Socket list length ({}) is bigger than the \
                number of sockets in hardware ({})".format(
                    len(self.sockets), numSocketsHW
                )
            )

        # Iterate over the socket object
        for i in range(numSocketsHW):
            ti_offset = theirIP_offset + i * 8
            tp_offset = theirPort_offset + i * 8
            mp_offset = udp_myPort_offset + i * 8
            v_offset = udp_valid_offset + i * 8

            theirIP = 0
            if self.sockets[i]["theirIP"]:
                theirIP = int(ipaddress.IPv4Address(self.sockets[i]
                                                    ["theirIP"]))

            self.write(ti_offset, theirIP)
            self.write(tp_offset, int(self.sockets[i]["theirPort"]))
            self.write(mp_offset, int(self.sockets[i]["myPort"]))
            self.write(v_offset, int(self.sockets[i]["valid"]))

        if debug:
            socket_dict = dict()
            socket_dict['Number of Sockets'] = numSocketsHW
            socket_dict['socket'] = dict()
            # Iterate over all the UDP table
            for i in range(numSocketsHW):
                ti_offset = theirIP_offset + i * 8
                tp_offset = theirPort_offset + i * 8
                mp_offset = udp_myPort_offset + i * 8
                v_offset = udp_valid_offset + i * 8
                isvalid = ti = self.read(v_offset)
                if isvalid:
                    ti = self.read(ti_offset)
                    tp = self.read(tp_offset)
                    mp = self.read(mp_offset)
                    socket_dict['socket'][i] = dict()
                    socket_dict['socket'][i]['theirIP'] = \
                        str(ipaddress.IPv4Address(ti))
                    socket_dict['socket'][i]['theirPort'] = tp
                    socket_dict['socket'][i]['myPort'] = mp

            return socket_dict

    def readARPTable(self, num_entries=256) -> dict:
        """Read the ARP table from the FPGA return a dict

        Parameters
        ----------
        Optionals
        ---------
        num_entries: int
            number of entries in the table to be consider when printing

        Returns
        -------
        Prints the content of valid entries in the ARP in a friendly way
        """

        if not isinstance(num_entries, int):
            raise ValueError("Number of entries must be integer.")
        elif num_entries < 0:
            raise ValueError("Number of entries cannot be negative.")
        elif num_entries > 256:
            raise ValueError("Number of entries cannot be bigger than 256.")

        mac_addr_offset = self.register_map.arp_mac_addr_offset.address
        ip_addr_offset = self.register_map.arp_ip_addr_offset.address
        valid_addr_offset = self.register_map.arp_valid_offset.address

        table = dict()

        valid_entry = None
        for i in range(num_entries):
            if (i % 4) == 0:
                valid_entry = self.read(valid_addr_offset + (i // 4) * 4)

            isvalid = (valid_entry >> ((i % 4) * 8)) & 0x1
            if isvalid:
                mac_lsb = self.read(mac_addr_offset + (i * 2 * 4))
                mac_msb = self.read(mac_addr_offset + ((i * 2 + 1) * 4))
                ip_addr = self.read(ip_addr_offset + (i * 4))
                mac_addr = (2 ** 32) * mac_msb + mac_lsb
                mac_hex = "{:012x}".format(_byteOrderingEndianess(mac_addr, 6))
                mac_str = ":".join(
                    mac_hex[i: i + 2] for i in range(0, len(mac_hex), 2)
                )
                ip_addr_print = _byteOrderingEndianess(ip_addr)
                table[i] = {
                    "MAC address": mac_str,
                    "IP address": str(ipaddress.IPv4Address(ip_addr_print))
                }

        return table

    def write_arp_entry(self, mac, ip):
        """
        Add an entry to the ARP table

        Parameters
        ----------
        mac: str
            MAC address in the format XX:XX:XX:XX:XX:XX
        ip: str
            IP address in the format XXX.XXX.XXX.XXX

        Note, VNx requires all IPs in the ARP table to be in the same
        /24 subnet (mask 255.255.255.0) as the IP assigned to the FPGA port.

        There are 256 entries in the ARP table, one for each possible IP
        in the subnet, the least significant 8 bits of the IP are used to
        index into the ARP table.
        """

        if not isinstance(mac, str):
            raise ValueError("MAC address must be a string.")
        elif not isinstance(ip, str):
            raise ValueError("IP address must be a string.")

        mac_int = int("0x{}".format(mac.replace(":", "")), 16)
        big_mac_int = _byteOrderingEndianess(mac_int, 6)
        mac_msb = (big_mac_int >> 32) & 0xFFFFFFFF
        mac_lsb = big_mac_int & 0xFFFFFFFF

        ip_int = int(ipaddress.IPv4Address(ip))
        big_ip_int = _byteOrderingEndianess(ip_int, 4)

        mac_addr_offset = self.register_map.arp_mac_addr_offset.address
        ip_addr_offset = self.register_map.arp_ip_addr_offset.address
        valid_addr_offset = self.register_map.arp_valid_offset.address

        i = ip_int % 256
        self.write(ip_addr_offset + (i * 4), big_ip_int)
        self.write(mac_addr_offset + (i * 2 * 4), mac_lsb)
        self.write(mac_addr_offset + ((i * 2 + 1) * 4), mac_msb)

        # Valid
        old_valid_entry = self.read(valid_addr_offset + (i // 4) * 4)
        this_valid = 1 << ((i % 4) * 8)
        self.write(valid_addr_offset + (i // 4) * 4, old_valid_entry | this_valid)

    def invalidateARPTable(self):
        """
        Clear the ARP table
        """
        valid_addr_offset = self.register_map.arp_valid_offset.address

        for i in range(256):
            self.write(valid_addr_offset + (i // 4) * 4, 0)

    def arpDiscovery(self):
        """
        Launch ARP discovery
        """

        # The ARP discovery is trigger with the rising edge
        self.register_map.arp_discovery = 0
        self.register_map.arp_discovery = 1
        self.register_map.arp_discovery = 0

    def getNetworkInfo(self):
        """
        Returns a dictionary with the current configuration
        """
        mac_addr = int(self.register_map.mac_address)
        ip_addr = int(self.register_map.ip_address)
        ip_gw = int(self.register_map.gateway)
        ip_mask = int(self.register_map.ip_mask)

        mac_hex = "{:012x}".format(mac_addr)
        mac_str = ":".join(mac_hex[i: i + 2]
                           for i in range(0, len(mac_hex), 2))

        config = {
            "HWaddr": mac_str,
            "inet addr": str(ipaddress.IPv4Address(ip_addr)),
            "gateway addr": str(ipaddress.IPv4Address(ip_gw)),
            "Mask": str(ipaddress.IPv4Address(ip_mask)),
        }

        return config

    def updateIPAddress(self, ipaddrsrt, gwaddr="None", debug=False):
        """
        Update IP address as well as least significant octet of the
        MAC address with the least significant octet of the IP address

        Parameters
        ----------
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

        if not isinstance(ipaddrsrt, str):
            raise ValueError("ipaddrsrt must be an string type")

        if not isinstance(gwaddr, str):
            raise ValueError("gwaddr must be an string type")

        if not isinstance(debug, bool):
            raise ValueError("debug must be a bool type")

        ipaddr = int(ipaddress.IPv4Address(ipaddrsrt))
        self.register_map.ip_address = ipaddr
        if gwaddr == "None":
            self.register_map.gateway = (ipaddr & 0xFFFFFF00) + 1
        else:
            self.register_map.gateway = int(ipaddress.IPv4Address(gwaddr))

        currentMAC = int(self.register_map.mac_address)
        newMAC = (currentMAC & 0xFFFFFFFFF00) + (ipaddr & 0xFF)
        self.register_map.mac_address = newMAC

        if debug:
            return self.getNetworkInfo()

    def resetDebugProbes(self) -> None:
        """Reset debug probes
        """

        self.register_map.debug_reset_counters = 1

    @property
    def getDebugProbes(self) -> dict:
        """ Return a dictionary with the value of the Network Layer probes
        """

        rmap = self.register_map
        probes = dict()
        probes["tx_path"] = dict()
        probes["rx_path"] = dict()

        probes["rx_path"] = {
            "ethernet": {
                "packets": int(rmap.eth_in_packets),
                "bytes": int(rmap.eth_in_bytes),
                "cycles": int(rmap.eth_in_cycles)
            },
            "packet_handler": {
                "packets": int(rmap.pkth_in_packets),
                "bytes": int(rmap.pkth_in_bytes),
                "cycles": int(rmap.pkth_in_cycles)
            },
            "arp": {
                "packets": int(rmap.arp_in_packets),
                "bytes": int(rmap.arp_in_bytes),
                "cycles": int(rmap.arp_in_cycles)
            },
            "icmp": {
                "packets": int(rmap.icmp_in_packets),
                "bytes": int(rmap.icmp_in_bytes),
                "cycles": int(rmap.icmp_in_cycles)
            },
            "udp": {
                "packets": int(rmap.udp_in_packets),
                "bytes": int(rmap.udp_in_bytes),
                "cycles": int(rmap.udp_in_cycles)
            },
            "app": {
                "packets": int(rmap.app_in_packets),
                "bytes": int(rmap.app_in_bytes),
                "cycles": int(rmap.app_in_cycles)
            }
        }

        probes['tx_path'] = {
            "arp": {
                "packets": int(rmap.arp_out_packets),
                "bytes": int(rmap.arp_out_bytes),
                "cycles": int(rmap.arp_out_cycles)
            },
            "icmp": {
                "packets": int(rmap.icmp_out_packets),
                "bytes": int(rmap.icmp_out_bytes),
                "cycles": int(rmap.icmp_out_cycles)
            },
            "ethernet_header_inserter": {
                "packets": int(rmap.ethhi_out_packets),
                "bytes": int(rmap.ethhi_out_bytes),
                "cycles": int(rmap.ethhi_out_cycles)
            },
            "ethernet": {
                "packets": int(rmap.eth_out_packets),
                "bytes": int(rmap.eth_out_bytes),
                "cycles": int(rmap.eth_out_cycles)
            },
            "app": {
                "packets": int(rmap.app_out_packets),
                "bytes": int(rmap.app_out_bytes),
                "cycles": int(rmap.app_out_cycles)
            },
            "udp": {
                "packets": int(rmap.udp_out_packets),
                "bytes": int(rmap.udp_out_bytes),
                "cycles": int(rmap.udp_out_cycles)
            }
        }

        return ReprDict(probes, rootname='debug_probes')


benchmark_mode = ["PRODUCER", "LATENCY", "LOOPBACK", "CONSUMER"]


class tgmode(Enum):
    """Supported Traffic generator Modes"""
    PRODUCER = 0
    LATENCY = 1
    LOOPBACK = 2
    CONSUMER = 3


class TrafficGenerator(DefaultIP):
    """ This class wraps the common function of the Traffic Generator IP
    """

    bindto = ["xilinx.com:kernel:traffic_generator:1.0"]

    def __init__(self, description):
        super().__init__(description=description)
        self.freq = None

    def start(self, mode: tgmode, dest: int=0, packets: int=None,
              beats: int=None, tbwp: int=None):
        """Starts the Traffic generator

        Parameters
        ----------
        mode: tgmode
            Operation mode
        dest: int
            Index in the socket table

        Optional
        --------
        packets: int
            Number of packets
        num_beats: int
            Number of transactions per piece of payload
        tbwp:
            Clock ticks between two consecutive payload packets
        """

        if mode == tgmode.PRODUCER or mode == tgmode.LATENCY:
            if not packets:
                raise RuntimeError("packets must be specified when mode is {}"
                                   .format(mode))
            elif not beats:
                raise RuntimeError("beats must be specified when mode is {}"
                                   .format(mode))
            elif not tbwp:
                raise RuntimeError("tbwp must be specified when mode is {}"
                                   .format(mode))

            self.register_map.number_packets = packets
            self.register_map.number_beats = beats
            self.register_map.time_between_packets = tbwp

        self.register_map.mode = int(mode.value)
        self.register_map.dest_id = dest
        self.register_map.CTRL.AP_START = 1

    def reset_fsm(self):
        """Reset internal FSM"""
        self.register_map.reset_fsm = 1

    def computeThroughputApp(self, direction: str="rx") -> float:
        """
        Read the application monitoring registers and compute
        throughput, it also returns other useful information

        Parameters
        ----------
        direction: string
            'rx' or 'tx'

        Returns
        -------
        Total number of packets seen by the monitoring probe,
        throughput and total time
        """

        if direction not in ["rx", "tx"]:
            raise ValueError(
                "Only 'rx' and 'tx' strings are supported \
                on direction argument"
            )

        if direction == "rx":
            tot_bytes = int(self.register_map.in_traffic_bytes)
            tot_cycles = int(self.register_map.in_traffic_cycles)
            tot_pkts = int(self.register_map.in_traffic_packets)
        else:
            tot_bytes = int(self.register_map.out_traffic_bytes)
            tot_cycles = int(self.register_map.out_traffic_cycles)
            tot_pkts = int(self.register_map.out_traffic_packets)

        tot_time = (1 / (self.freq * 10 ** 6)) * tot_cycles
        thr_bs = (tot_bytes * 8) / tot_time

        return tot_pkts, thr_bs / (10 ** 9), tot_time

    def resetProbes(self):
        """
        Reset embedded probes
        """
        self.register_map.debug_reset = 1


class DataMover(DefaultIP):
    """This class is an enhancement to the DefaultIP class to verify that the
    underlaying hardware can work properly based on the provided arguments
    This driver is bind to:
        xilinx.com:hls:krnl_mm2s:1.0
        xilinx.com:hls:krnl_s2mm:1.0
    """
    bindto = ['xilinx.com:hls:krnl_mm2s:1.0', 'xilinx.com:hls:krnl_s2mm:1.0']

    def __init__(self, description):
        super().__init__(description=description)

    def start(self, *args, **kwargs):
        """Start the accelerator
        This function will configure the accelerator with the provided
        arguments and start the accelerator. Use the `wait` function to
        determine when execution has finished. Note that buffers should be
        flushed prior to starting the accelerator and any result buffers
        will need to be invalidated afterwards.
        For details on the function's signature use the `signature` property.
        The type annotations provide the C types that the accelerator
        operates on. Any pointer types should be passed as `ContiguousArray`
        objects created from the `pynq.allocate` class. Scalars should be
        passed as a compatible python type as used by the `struct` library.
        """

        for idx, i in enumerate(self.signature.parameters.items()):
            if i[0] == 'size' and args[idx] < 64:
                raise ValueError("size must be at least 64-Byte")
            elif i[0] == 'dest' and args[idx] > 15:
                raise ValueError("dest cannot be bigger than 15")

        return self._start(*args, **kwargs)


class CounterIP(DefaultIP):
    """ This class wraps the common function of counter IP

    """

    bindto = ["xilinx.com:hls:krnl_counters:1.0"]

    def __init__(self, description):
        super().__init__(description=description)
        self._fullpath = description['fullpath']
        self.start = self.start_sw = self.start_none = \
            self.start_ert = self.call

    def _setup_packet_prototype(self):
        pass

    def call(self, *args, **kwargs):
        raise RuntimeError("{} is a free running kernel and cannot be "
                           "starter or called".format(self._fullpath))

    @property
    def counters(self):
        """ Return counters

        """

        counters = {
            'packets': int(self.register_map.packets),
            'beats': int(self.register_map.beats),
            'bytes': int(self.register_map.bytes),
        }

        return counters

    def reset_counters(self):
        """ Reset internal counters

        """

        self.register_map.reset = 0
        self.register_map.reset = 1
        self.register_map.reset = 0


class CollectorIP(DefaultIP):
    """ This class wraps the common function the collector Kernel

    """

    bindto = ["xilinx.com:hls:collector:1.0"]

    def __init__(self, description):
        super().__init__(description=description)

    @property
    def received_packets(self):
        # When a register is written by the kernel for non free running kernels
        # the default offset refers to the value that the kernel reads
        # the actual register where the kernel writes is not exposed in the
        # signature, so we need to compute the offset and use mmio to read it

        rx_pkts_offset = self.register_map.received_packets.address + \
            self.register_map.received_packets.width//8 + 4
        return self.read(rx_pkts_offset)
