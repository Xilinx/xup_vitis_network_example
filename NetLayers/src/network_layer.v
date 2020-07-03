/* (c) Copyright 2020 Xilinx, Inc. All rights reserved.
 This file contains confidential and proprietary information 
 of Xilinx, Inc. and is protected under U.S. and
 international copyright and other intellectual property 
 laws.
 
 DISCLAIMER
 This disclaimer is not a license and does not grant any 
 rights to the materials distributed herewith. Except as 
 otherwise provided in a valid license issued to you by 
 Xilinx, and to the maximum extent permitted by applicable
 law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
 WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES 
 AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING 
 BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
 INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and 
 (2) Xilinx shall not be liable (whether in contract or tort, 
 including negligence, or under any other theory of 
 liability) for any loss or damage of any kind or nature 
 related to, arising under or in connection with these 
 materials, including for any direct, or any indirect, 
 special, incidental, or consequential loss or damage 
 (including loss of data, profits, goodwill, or any type of 
 loss or damage suffered as a result of any action brought 
 by a third party) even if such damage or loss was 
 reasonably foreseeable or Xilinx had been advised of the 
 possibility of the same.
 
 CRITICAL APPLICATIONS
 Xilinx products are not designed or intended to be fail-
 safe, or for use in any application requiring fail-safe
 performance, such as life-support or safety devices or 
 systems, Class III medical devices, nuclear facilities, 
 applications related to the deployment of airbags, or any 
 other applications that could lead to death, personal 
 injury, or severe property or environmental damage 
 (individually and collectively, "Critical 
 Applications"). Customer assumes the sole risk and 
 liability of any use of Xilinx products in Critical 
 Applications, subject only to applicable laws and 
 regulations governing limitations on product liability.
 
 THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS 
 PART OF THIS FILE AT ALL TIMES.
*/

`default_nettype wire
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module networklayer #(
  parameter integer AXIL_CTRL_ADDR_WIDTH  =  16,
  parameter integer AXIL_CTRL_DATA_WIDTH  =  32,
  parameter integer AXIS_TDATA_WIDTH      = 512,
  parameter integer STREAMING_TUSER_WIDTH =  16
)
(
  // System clocks and resets
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS_sk2nl:M_AXIS_nl2sk:S_AXIL_nl, ASSOCIATED_RESET ap_rst_n" *)
  input  wire                                 ap_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ap_rst_n RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire                                 ap_rst_n,
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk_gt_freerun CLK" *)
  input  wire                                 clk_gt_freerun,

  // AXI4-Stream streaming kernel 2 network layer
  input  wire                                 S_AXIS_sk2nl_tvalid,
  output wire                                 S_AXIS_sk2nl_tready,
  input  wire       [AXIS_TDATA_WIDTH-1:0]    S_AXIS_sk2nl_tdata,
  input  wire     [AXIS_TDATA_WIDTH/8-1:0]    S_AXIS_sk2nl_tkeep,
  input  wire                                 S_AXIS_sk2nl_tlast,
  input  wire  [STREAMING_TUSER_WIDTH-1:0]    S_AXIS_sk2nl_tuser,
  // AXI4-Stream network layer to streaming kernel 
  output wire                                 M_AXIS_nl2sk_tvalid,
  input  wire                                 M_AXIS_nl2sk_tready,
  output wire       [AXIS_TDATA_WIDTH-1:0]    M_AXIS_nl2sk_tdata,
  output wire     [AXIS_TDATA_WIDTH/8-1:0]    M_AXIS_nl2sk_tkeep,
  output wire                                 M_AXIS_nl2sk_tlast,
  output wire  [STREAMING_TUSER_WIDTH-1:0]    M_AXIS_nl2sk_tuser,

  // AXI4-Lite Kernel to Ethernet slave interface
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
  output wire                        [1:0]    S_AXIL_nl_bresp,

  // GT interfaces
  input  wire                        [3:0]    gt_rxp_in,
  input  wire                        [3:0]    gt_rxn_in,
  output wire                        [3:0]    gt_txp_out,
  output wire                        [3:0]    gt_txn_out, 
  input  wire                                 gt_refclk0_p,
  input  wire                                 gt_refclk0_n
);


  network_layer_bd network_layer_bd_i  (
    .ap_clk               (              ap_clk),
    .ap_rst_n             (            ap_rst_n),
    .clk_gt_freerun       (      clk_gt_freerun),
    
    .gt_ref_clk_clk_n     (        gt_refclk0_n),
    .gt_ref_clk_clk_p     (        gt_refclk0_p),
    .gt_rx_gtx_n          (           gt_rxn_in),
    .gt_rx_gtx_p          (           gt_rxp_in),
    .gt_tx_gtx_n          (          gt_txn_out),
    .gt_tx_gtx_p          (          gt_txp_out),
    
    .S_AXIS_sk2nl_tdata   (  S_AXIS_sk2nl_tdata),
    .S_AXIS_sk2nl_tkeep   (  S_AXIS_sk2nl_tkeep),
    .S_AXIS_sk2nl_tlast   (  S_AXIS_sk2nl_tlast),
    .S_AXIS_sk2nl_tready  ( S_AXIS_sk2nl_tready),
    .S_AXIS_sk2nl_tuser   (  S_AXIS_sk2nl_tuser),
    .S_AXIS_sk2nl_tvalid  ( S_AXIS_sk2nl_tvalid),
    
    .M_AXIS_nl2sk_tdata   (  M_AXIS_nl2sk_tdata),
    .M_AXIS_nl2sk_tkeep   (  M_AXIS_nl2sk_tkeep),
    .M_AXIS_nl2sk_tlast   (  M_AXIS_nl2sk_tlast),
    .M_AXIS_nl2sk_tready  ( M_AXIS_nl2sk_tready),
    .M_AXIS_nl2sk_tuser   (  M_AXIS_nl2sk_tuser),
    .M_AXIS_nl2sk_tvalid  ( M_AXIS_nl2sk_tvalid),
    
    .S_AXIL_nl_awvalid    (   S_AXIL_nl_awvalid),
    .S_AXIL_nl_awready    (   S_AXIL_nl_awready),
    .S_AXIL_nl_awaddr     (    S_AXIL_nl_awaddr),
    .S_AXIL_nl_wvalid     (    S_AXIL_nl_wvalid),
    .S_AXIL_nl_wready     (    S_AXIL_nl_wready),
    .S_AXIL_nl_wdata      (     S_AXIL_nl_wdata),
    .S_AXIL_nl_wstrb      (     S_AXIL_nl_wstrb),
    .S_AXIL_nl_arvalid    (   S_AXIL_nl_arvalid),
    .S_AXIL_nl_arready    (   S_AXIL_nl_arready),
    .S_AXIL_nl_araddr     (    S_AXIL_nl_araddr),
    .S_AXIL_nl_rvalid     (    S_AXIL_nl_rvalid),
    .S_AXIL_nl_rready     (    S_AXIL_nl_rready),
    .S_AXIL_nl_rdata      (     S_AXIL_nl_rdata),
    .S_AXIL_nl_rresp      (     S_AXIL_nl_rresp),
    .S_AXIL_nl_bvalid     (    S_AXIL_nl_bvalid),
    .S_AXIL_nl_bready     (    S_AXIL_nl_bready),
    .S_AXIL_nl_bresp      (     S_AXIL_nl_bresp),
    .S_AXIL_nl_arprot     (                3'b0),
    .S_AXIL_nl_awprot     (                3'b0)
  );


endmodule