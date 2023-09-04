#   Copyright (c) 2023, Advanced Micro Devices, Inc.
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

from xilinx_xtlm import ipc_axis_master_util
from xilinx_xtlm import ipc_axis_slave_util
import argparse
import time
import threading
import queue
import os
import signal
import shutil

from scapy.all import *

cwd = os.getcwd()

# monkeypatch ipc_axis_master/slave_util to allow 
# them to connect to sockets in arbitrary folders
class monkeypatched_ipc_axis_master_util(ipc_axis_master_util):
    def __init__(self, name, sockdir):
        self._sock_dir = sockdir
        super().__init__(name)

    def _set_sock_path_and_change_directory(self):
        self._curr_dir = os.getcwd() # store current dir to revert
        os.chdir(self._sock_dir)
        self._socket_name = "unix_" + os.getenv("USER") + ":" +  self._name
        print("Connecting to socket "+self._sock_dir+"/"+self._socket_name)

class monkeypatched_ipc_axis_slave_util(ipc_axis_slave_util):
    def __init__(self, name, sockdir):
        self._sock_dir = sockdir
        super().__init__(name)

    def _set_sock_path_and_change_directory(self):
        self._curr_dir = os.getcwd() # store current dir to revert
        os.chdir(self._sock_dir)
        self._socket_name = "unix_" + os.getenv("USER") + ":" +  self._name
        print("Connecting to socket "+self._sock_dir+"/"+self._socket_name)



# Inject payloads into CMAC ethernet RX socket
def rx_forward(portidx):
    #Instantiating AXI Master Utilities 
    master_util = monkeypatched_ipc_axis_master_util(args.ipiname + "_ingress", xsim_socket_folders[portidx])

    while True:
        # check for stop
        if done.is_set():
            break
        if ingress_q[portidx].empty():
            time.sleep(0.1)
            continue
        print ("Port " + str(portidx) +": Sending Rxn ")
        master_util.b_transport(ingress_q[portidx].get())

    print("Exiting RX forward thread for FPGA "+str(portidx))
    #Wait sometime for kernel to process
    time.sleep(5)
    #If user want to end the simulation, user can use following API
    master_util.end_of_simulation()

# Forward payloads from CMAC ethernet TX socket to 
# correct input socket(s) by inspecting dst MAC
def tx_forward(portidx):
    #Instantiate AXI Stream Slave util
    slave_util = monkeypatched_ipc_axis_slave_util(args.ipiname + "_egress", xsim_socket_folders[portidx])

    while True:
        # check for stop
        if done.is_set():
            break
        egress_q[portidx].put(slave_util.sample_transaction())
        print("Port " + str(portidx) +": Sent Txn ")

    print("Exiting TX forward thread for FPGA "+str(portidx))

def forward_packets():
    while True:
        # check for stop
        if done.is_set():
            break
        for i in range(args.nports):
            # skip if target egress queue is empty
            if egress_q[i].empty():
                time.sleep(0.1)
                continue
            # TODO: pick up payloads from queues, convert their data to scapy packet objects
            payload = egress_q[i].get()
            packet = Ether(payload.data)
            if args.debug:
                packet.summary()
            if packet.haslayer(Ether):
                dst_mac = packet[Ether].dst
                if dst_mac in port_map:
                    output_port = port_map[dst_mac]
                    ingress_q[i].put(payload)
                elif dst_mac == "ff:ff:ff:ff:ff:ff":  # Check for broadcast address
                    for output_port in port_map.values():
                        if output_port != i:
                            ingress_q[output_port].put(payload)
                else:
                    # drop packet
                    print("Dropping packet on Port " + str(i))
    print("Exiting packet switch thread")

parser = argparse.ArgumentParser(description='Run simulated Ethernet switch for hardware emulation')
parser.add_argument('-n', '--nports', type=int, default=1,
                    help='Number of ports on the switch')
parser.add_argument('--macaddr', nargs='+', help='MAC addresses of each port')
parser.add_argument('-x', '--xclbin', required=True, help='name of xclbin')
parser.add_argument('--ipiname', default='cmac_0', help='name of CMAC instance in Vivado IPI')
parser.add_argument('-d', '--debug', action='store_true', default=False,
                    help='Enable printing detailed packet info')
args = parser.parse_args()

if args.macaddr is None:
    parser.print_help()
    sys.exit(0)
if len(args.macaddr) != args.nports:
    parser.print_help()
    sys.exit(0)

done = threading.Event()

# array of queues, two for each node (egress, ingress)
egress_q = [queue.Queue() for i in range(args.nports)]
ingress_q = [queue.Queue() for i in range(args.nports)]

# Dictionary of MAC addresses and corresponding output ports,
# filled in from user input: 
port_map = {}
for i in range(len(args.macaddr)):
    port_map[args.macaddr[i]] = i

print(args)
print(port_map)

xsim_processes = []
xsim_socket_folders = []
for idx in range(args.nports):
    xsim_socket_folders.append(os.path.join(os.getcwd(), "fpga"+str(idx)+"_sockets"))
    if os.path.exists(xsim_socket_folders[idx]):
        shutil.rmtree(xsim_socket_folders[idx])
    os.mkdir(xsim_socket_folders[idx])
    cmd = "XCL_EMULATION_MODE=hw_emu XTLM_IPC_SOCK_DIR="+xsim_socket_folders[idx]+" ./basic_hwemu "+args.xclbin+" "+str(idx)
    print("Starting command in subshell: "+cmd)
    xsim_processes.append(subprocess.Popen(cmd, shell=True, preexec_fn=os.setsid))

threads = []
for idx in range(args.nports):
    threads.append(threading.Thread(target=rx_forward, args=(idx,)))
    threads.append(threading.Thread(target=tx_forward, args=(idx,)))
threads.append(threading.Thread(target=forward_packets))

for t in threads:
    t.start()
    time.sleep(2)

while True:
    try:
        time.sleep(1)
    except KeyboardInterrupt:
        print("Exiting")
        done.set()
        for p in xsim_processes:
            os.killpg(os.getpgid(p.pid), signal.SIGTERM)
        for d in xsim_socket_folders:
            shutil.rmtree(d)
        for t in threads:
            t.join()
