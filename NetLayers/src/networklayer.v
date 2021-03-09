/************************************************
Copyright (c) 2020, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation 
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors 
may be used to endorse or promote products derived from this software 
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
Copyright (c) 2020 Xilinx, Inc.
************************************************/

`default_nettype wire
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module networklayer #(
  parameter integer AXIL_CTRL_ADDR_WIDTH  =  16,
  parameter integer AXIL_CTRL_DATA_WIDTH  =  32,
  parameter integer AXIS_TDATA_WIDTH      = 512,
  parameter integer STREAMING_TDEST_WIDTH =  16,
  parameter integer STREAMING_TUSER_WIDTH =  96
)
(
  // System clocks and resets
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS_eth2nl:M_AXIS_nl2eth:S_AXIS_sk2nl:M_AXIS_nl2sk:S_AXIL_nl, ASSOCIATED_RESET ap_rst_n" *)
  input  wire                                 ap_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ap_rst_n RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire                                 ap_rst_n,

  // AXI4-Stream streaming ethenet 2 network layer
  input  wire                                 S_AXIS_eth2nl_tvalid,
  output wire                                 S_AXIS_eth2nl_tready,
  input  wire       [AXIS_TDATA_WIDTH-1:0]    S_AXIS_eth2nl_tdata,
  input  wire     [AXIS_TDATA_WIDTH/8-1:0]    S_AXIS_eth2nl_tkeep,
  input  wire                                 S_AXIS_eth2nl_tlast,
  // AXI4-Stream network layer to ethernet 
  output wire                                 M_AXIS_nl2eth_tvalid,
  input  wire                                 M_AXIS_nl2eth_tready,
  output wire       [AXIS_TDATA_WIDTH-1:0]    M_AXIS_nl2eth_tdata,
  output wire     [AXIS_TDATA_WIDTH/8-1:0]    M_AXIS_nl2eth_tkeep,
  output wire                                 M_AXIS_nl2eth_tlast,
  // AXI4-Stream streaming kernel 2 network layer
  input  wire                                 S_AXIS_sk2nl_tvalid,
  output wire                                 S_AXIS_sk2nl_tready,
  input  wire       [AXIS_TDATA_WIDTH-1:0]    S_AXIS_sk2nl_tdata,
  input  wire     [AXIS_TDATA_WIDTH/8-1:0]    S_AXIS_sk2nl_tkeep,
  input  wire                                 S_AXIS_sk2nl_tlast,
  input  wire  [STREAMING_TDEST_WIDTH-1:0]    S_AXIS_sk2nl_tdest,
  // AXI4-Stream network layer to streaming kernel 
  output wire                                 M_AXIS_nl2sk_tvalid,
  input  wire                                 M_AXIS_nl2sk_tready,
  output wire       [AXIS_TDATA_WIDTH-1:0]    M_AXIS_nl2sk_tdata,
  output wire     [AXIS_TDATA_WIDTH/8-1:0]    M_AXIS_nl2sk_tkeep,
  output wire                                 M_AXIS_nl2sk_tlast,
  output wire  [STREAMING_TDEST_WIDTH-1:0]    M_AXIS_nl2sk_tdest,
  output wire  [STREAMING_TUSER_WIDTH-1:0]    M_AXIS_nl2sk_tuser,
  // AXI4-Lite
  input  wire                                 S_AXIL_nl_awvalid,
  output wire                                 S_AXIL_nl_awready,
  input  wire   [AXIL_CTRL_ADDR_WIDTH-1:0]    S_AXIL_nl_awaddr,
  input  wire                                 S_AXIL_nl_wvalid,
  output wire                                 S_AXIL_nl_wready,
  input  wire   [AXIL_CTRL_DATA_WIDTH-1:0]    S_AXIL_nl_wdata,
  input  wire [AXIL_CTRL_DATA_WIDTH/8-1:0]    S_AXIL_nl_wstrb,
  input  wire                                 S_AXIL_nl_arvalid,
  output wire                                 S_AXIL_nl_arready,
  input  wire   [AXIL_CTRL_ADDR_WIDTH-1:0]    S_AXIL_nl_araddr,
  output wire                                 S_AXIL_nl_rvalid,
  input  wire                                 S_AXIL_nl_rready,
  output wire   [AXIL_CTRL_DATA_WIDTH-1:0]    S_AXIL_nl_rdata,
  output wire                        [1:0]    S_AXIL_nl_rresp,
  output wire                                 S_AXIL_nl_bvalid,
  input  wire                                 S_AXIL_nl_bready,
  output wire                        [1:0]    S_AXIL_nl_bresp
);


  network_layer_bd network_layer_bd_i  (
    .ap_clk               (               ap_clk),
    .ap_rst_n             (             ap_rst_n),
    // AXI4-Stream streaming ethenet 2 network layer
    .S_AXIS_eth2nl_tvalid ( S_AXIS_eth2nl_tvalid),
    .S_AXIS_eth2nl_tready ( S_AXIS_eth2nl_tready),
    .S_AXIS_eth2nl_tdata  (  S_AXIS_eth2nl_tdata),
    .S_AXIS_eth2nl_tkeep  (  S_AXIS_eth2nl_tkeep),
    .S_AXIS_eth2nl_tlast  (  S_AXIS_eth2nl_tlast),
    // AXI4-Stream network layer to ethernet
    .M_AXIS_nl2eth_tvalid ( M_AXIS_nl2eth_tvalid),
    .M_AXIS_nl2eth_tready ( M_AXIS_nl2eth_tready),
    .M_AXIS_nl2eth_tdata  (  M_AXIS_nl2eth_tdata),
    .M_AXIS_nl2eth_tkeep  (  M_AXIS_nl2eth_tkeep),
    .M_AXIS_nl2eth_tlast  (  M_AXIS_nl2eth_tlast),
    // AXI4-Stream streaming kernel 2 network layer
    .S_AXIS_sk2nl_tdata   (   S_AXIS_sk2nl_tdata),
    .S_AXIS_sk2nl_tkeep   (   S_AXIS_sk2nl_tkeep),
    .S_AXIS_sk2nl_tlast   (   S_AXIS_sk2nl_tlast),
    .S_AXIS_sk2nl_tready  (  S_AXIS_sk2nl_tready),
    .S_AXIS_sk2nl_tdest   (   S_AXIS_sk2nl_tdest),
    .S_AXIS_sk2nl_tvalid  (  S_AXIS_sk2nl_tvalid),
    // AXI4-Stream network layer to streaming kernel 
    .M_AXIS_nl2sk_tdata   (   M_AXIS_nl2sk_tdata),
    .M_AXIS_nl2sk_tkeep   (   M_AXIS_nl2sk_tkeep),
    .M_AXIS_nl2sk_tlast   (   M_AXIS_nl2sk_tlast),
    .M_AXIS_nl2sk_tready  (  M_AXIS_nl2sk_tready),
    .M_AXIS_nl2sk_tdest   (   M_AXIS_nl2sk_tdest),
    .M_AXIS_nl2sk_tuser   (   M_AXIS_nl2sk_tuser),
    .M_AXIS_nl2sk_tvalid  (  M_AXIS_nl2sk_tvalid),
    // AXI4-Lite
    .S_AXIL_nl_awvalid    (    S_AXIL_nl_awvalid),
    .S_AXIL_nl_awready    (    S_AXIL_nl_awready),
    .S_AXIL_nl_awaddr     (     S_AXIL_nl_awaddr),
    .S_AXIL_nl_wvalid     (     S_AXIL_nl_wvalid),
    .S_AXIL_nl_wready     (     S_AXIL_nl_wready),
    .S_AXIL_nl_wdata      (      S_AXIL_nl_wdata),
    .S_AXIL_nl_wstrb      (      S_AXIL_nl_wstrb),
    .S_AXIL_nl_arvalid    (    S_AXIL_nl_arvalid),
    .S_AXIL_nl_arready    (    S_AXIL_nl_arready),
    .S_AXIL_nl_araddr     (     S_AXIL_nl_araddr),
    .S_AXIL_nl_rvalid     (     S_AXIL_nl_rvalid),
    .S_AXIL_nl_rready     (     S_AXIL_nl_rready),
    .S_AXIL_nl_rdata      (      S_AXIL_nl_rdata),
    .S_AXIL_nl_rresp      (      S_AXIL_nl_rresp),
    .S_AXIL_nl_bvalid     (     S_AXIL_nl_bvalid),
    .S_AXIL_nl_bready     (     S_AXIL_nl_bready),
    .S_AXIL_nl_bresp      (      S_AXIL_nl_bresp),
    .S_AXIL_nl_arprot     (                 3'b0),
    .S_AXIL_nl_awprot     (                 3'b0)
  );


endmodule