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
  input  wire                                 clk_gt_freerun,

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
  input  wire                                 gt_refclk_p,
  input  wire                                 gt_refclk_n
);


  cmac_bd placeholder  (
    .ap_clk               (              ap_clk),
    .ap_rst_n             (            ap_rst_n),
    .clk_gt_freerun       (      clk_gt_freerun),
    
    .gt_ref_clk_clk_n     (        gt_refclk_n),
    .gt_ref_clk_clk_p     (        gt_refclk_p),
    .gt_rx_gtx_n          (           gt_rxn_in),
    .gt_rx_gtx_p          (           gt_rxp_in),
    .gt_tx_gtx_n          (          gt_txn_out),
    .gt_tx_gtx_p          (          gt_txp_out),
    
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