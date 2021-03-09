# Network layer kernel

The network layer kernel is a collection of HLS modules to provide basic network functionality. It exposes two 512-bit (with 16-bit TDEST) AXI4-Stream to the application, S_AXIS_sk2nl and M_AXIS_nl2sk.

### ARP
It provides a translation between IP addresses and MAC addresses. This table has 256 elements and it is accessible using AXI4-Lite. It also has ARP discovery capability to map IP addresses on its subnetwork.

```C
struct arpTableEntry {
  ap_uint<48> macAddress;
  ap_uint<32> ipAddress;
  ap_uint<1>  valid;
}
```

### ICMP
It provides ping capability. It is useful to check if the design is *up* when using standard network equipment such as, routers or NICs.

### UDP

It provides UDP transport layer functionality. It has a 16-element socket table, which must be filled from the host side in order to receive and send data. 

```C
struct socket_table {
  ap_uint<32>     theirIP;
  ap_uint<16>     theirPort;
  ap_uint<16>     myPort;
  ap_uint< 1>     valid;
}
```

The user application communicates with this module using the *S_AXIS_sk2nl* and *M_AXIS_nl2sk* AXI4-Stream interface.

In the transmitting side, the application sends the payload identifying the socket using `dest`. If the socket is valid, an UDP packet containing the payload is populated to the network. If the socket is not valid, the payload is dropped.

In the receiving side UDP packets are parsed and the socket information is compared against the socket table. If the socket information is valid, the UDP will populate the payload to the application setting `dest` accordingly, the `user` signal will also contains metadata pertaining to source and destination IP address as well as source and destination port.

Currently, to simplify the receiver side logic, valid incoming connections must be fully specified in the socket table. 


The structure for these two interfaces are specified below.

#### User kernel to network layer (S_AXIS_sk2nl)

```C
struct udp_app2nl {
  ap_uint<512>    data;
  ap_uint< 64>    keep;
  ap_uint< 16>    dest;
  ap_uint<  1>    last;
}
```

#### Network layer to user kernel (M_AXIS_nl2sk)

```C

struct userMetadata {
    ap_uint<32>     myIP;
    ap_uint<32>     theirIP;
    ap_uint<16>     myPort;
    ap_uint<16>     theirPort;
};

struct udp_nl2app {
  ap_uint<512>    data;
  ap_uint< 64>    keep;
  ap_uint< 16>    dest;
  ap_uint<  1>    last;
  userMetadata    user;
}
```



------------------------------------------------------
<p align="center">Copyright&copy; 2021 Xilinx</p>