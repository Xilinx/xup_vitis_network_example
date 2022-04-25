/************************************************
Copyright (c) 2021, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

3.  Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
************************************************/

`default_nettype wire
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module placeholder #(
  parameter integer AXIL_CTRL_ADDR_WIDTH  =  13,
  parameter integer AXIL_CTRL_DATA_WIDTH  =  32,
  parameter integer AXIS_TDATA_WIDTH      = 512
)
(
  // System clocks and resets
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS:M_AXIS:S_AXILITE, ASSOCIATED_RESET ap_rst_n" *)
  input  wire                                 ap_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ap_rst_n RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire                                 ap_rst_n,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk_gt_freerun CLK" *)
  input wire                                  clk_gt_freerun,

  input  wire                                 S_AXIS_tvalid,
  output wire                                 S_AXIS_tready,
  input  wire       [AXIS_TDATA_WIDTH-1:0]    S_AXIS_tdata,
  input  wire     [AXIS_TDATA_WIDTH/8-1:0]    S_AXIS_tkeep,
  input  wire                                 S_AXIS_tlast,

  output wire                                 M_AXIS_tvalid,
  input  wire                                 M_AXIS_tready,
  output wire       [AXIS_TDATA_WIDTH-1:0]    M_AXIS_tdata,
  output wire     [AXIS_TDATA_WIDTH/8-1:0]    M_AXIS_tkeep,
  output wire                                 M_AXIS_tlast,

  input  wire                                 S_AXILITE_awvalid,
  output wire                                 S_AXILITE_awready,
  input  wire   [AXIL_CTRL_ADDR_WIDTH-1:0]    S_AXILITE_awaddr,
  input  wire                                 S_AXILITE_wvalid,
  output wire                                 S_AXILITE_wready,
  input  wire   [AXIL_CTRL_DATA_WIDTH-1:0]    S_AXILITE_wdata,
  input  wire [AXIL_CTRL_DATA_WIDTH/8-1:0]    S_AXILITE_wstrb,
  input  wire                                 S_AXILITE_arvalid,
  output wire                                 S_AXILITE_arready,
  input  wire   [AXIL_CTRL_ADDR_WIDTH-1:0]    S_AXILITE_araddr,
  output wire                                 S_AXILITE_rvalid,
  input  wire                                 S_AXILITE_rready,
  output wire   [AXIL_CTRL_DATA_WIDTH-1:0]    S_AXILITE_rdata,
  output wire                        [1:0]    S_AXILITE_rresp,
  output wire                                 S_AXILITE_bvalid,
  input  wire                                 S_AXILITE_bready,
  output wire                        [1:0]    S_AXILITE_bresp,

  // GT interfaces
  input  wire                        [3:0]    gt_rxp_in,
  input  wire                        [3:0]    gt_rxn_in,
  output wire                        [3:0]    gt_txp_out,
  output wire                        [3:0]    gt_txn_out,
  input  wire                                 gt_placeholder_clk_p,
  input  wire                                 gt_placeholder_clk_n
);


  cmac_bd placeholder  (
    .ap_clk               (              ap_clk),
    .ap_rst_n             (            ap_rst_n),

    .clk_gt_freerun       (      clk_gt_freerun),

    .gt_ref_clk_clk_n     (        gt_placeholder_clk_n),
    .gt_ref_clk_clk_p     (        gt_placeholder_clk_p),
    .gt_serial_port_grx_n (           gt_rxn_in),
    .gt_serial_port_grx_p (           gt_rxp_in),
    .gt_serial_port_gtx_n (          gt_txn_out),
    .gt_serial_port_gtx_p (          gt_txp_out),

    .S_AXIS_tdata         (        S_AXIS_tdata),
    .S_AXIS_tkeep         (        S_AXIS_tkeep),
    .S_AXIS_tlast         (        S_AXIS_tlast),
    .S_AXIS_tready        (       S_AXIS_tready),
    .S_AXIS_tvalid        (       S_AXIS_tvalid),

    .M_AXIS_tdata         (        M_AXIS_tdata),
    .M_AXIS_tkeep         (        M_AXIS_tkeep),
    .M_AXIS_tlast         (        M_AXIS_tlast),
    .M_AXIS_tready        (       M_AXIS_tready),
    .M_AXIS_tvalid        (       M_AXIS_tvalid),

    .S_AXILITE_awvalid    (   S_AXILITE_awvalid),
    .S_AXILITE_awready    (   S_AXILITE_awready),
    .S_AXILITE_awaddr     (    S_AXILITE_awaddr),
    .S_AXILITE_wvalid     (    S_AXILITE_wvalid),
    .S_AXILITE_wready     (    S_AXILITE_wready),
    .S_AXILITE_wdata      (     S_AXILITE_wdata),
    .S_AXILITE_wstrb      (     S_AXILITE_wstrb),
    .S_AXILITE_arvalid    (   S_AXILITE_arvalid),
    .S_AXILITE_arready    (   S_AXILITE_arready),
    .S_AXILITE_araddr     (    S_AXILITE_araddr),
    .S_AXILITE_rvalid     (    S_AXILITE_rvalid),
    .S_AXILITE_rready     (    S_AXILITE_rready),
    .S_AXILITE_rdata      (     S_AXILITE_rdata),
    .S_AXILITE_rresp      (     S_AXILITE_rresp),
    .S_AXILITE_bvalid     (    S_AXILITE_bvalid),
    .S_AXILITE_bready     (    S_AXILITE_bready),
    .S_AXILITE_bresp      (     S_AXILITE_bresp),
    .S_AXILITE_arprot     (                3'b0),
    .S_AXILITE_awprot     (                3'b0)
  );


endmodule