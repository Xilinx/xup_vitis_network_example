/************************************************
BSD 3-Clause License

Copyright (c) 2019, 
Naudit HPCN, Spain (naudit.es)
HPCN Group, UAM Spain (hpcn-uam.es)
All rights reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

************************************************/

`timescale 1ns/1ps
`include "types.svh"


module cmac_connector_wrapper #(
	parameter integer  C_S_AXI4_LITE_DATA_WIDTH = 32,
	parameter integer  C_S_AXI_LITE_ADDR_WIDTH  = 12
) (
	(* X_INTERFACE_INFO = "xilinx.com:interface:gt:1.0 gt_rx GTX_P" *)
	input        [                             3:0] gt_rxp_in                ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:gt:1.0 gt_rx GTX_N" *)
	input        [                             3:0] gt_rxn_in                ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:gt:1.0 gt_tx GTX_P" *)
	output       [                             3:0] gt_txp_out               ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:gt:1.0 gt_tx GTX_N" *)
	output       [                             3:0] gt_txn_out               ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 gt_ref_clk CLK_P" *)
	input                                           gt_ref_clk_p             ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 gt_ref_clk CLK_N" *)
	input                                           gt_ref_clk_n             ,
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	
	/*AXI4-Stream Master*/
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 LBUS2AXI TDATA" *)
	output       [                           511:0] LBUS2AXI_tdata           ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 LBUS2AXI TVALID" *)
	output                                          LBUS2AXI_tvalid          ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 LBUS2AXI TLAST" *)
	output                                          LBUS2AXI_tlast           ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 LBUS2AXI TKEEP" *)
	output       [                            63:0] LBUS2AXI_tstrb           ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 LBUS2AXI TREADY" *)
	input                                           LBUS2AXI_tready          ,
	/*AXI4-Stream Slave*/
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 AXI2LBUS TDATA" *)
	input        [                           511:0] AXI2LBUS_tdata           ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 AXI2LBUS TVALID" *)
	input                                           AXI2LBUS_tvalid          ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 AXI2LBUS TLAST" *)
	input                                           AXI2LBUS_tlast           ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 AXI2LBUS TKEEP" *)
	input        [                            63:0] AXI2LBUS_tstrb           ,
	(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 AXI2LBUS TREADY" *)
	output                                          AXI2LBUS_tready          ,

	output                                          CMAC_STAT_stat_rx_aligned,
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 usr_tx_clk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF AXI2LBUS, ASSOCIATED_RESET tx_rst, FREQ_HZ 322265625" *)
	output                                          usr_tx_clk               ,
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 usr_rx_clk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF LBUS2AXI, ASSOCIATED_RESET rx_rst, FREQ_HZ 322265625" *)
	output                                          usr_rx_clk               ,
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 tx_rst RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	output                                          tx_rst                   ,
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rx_rst RST" *)
	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	output                                          rx_rst                   ,
	output logic [                             9:0] gt_rxrecclkout           ,
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF AXI4_STATISTICS, ASSOCIATED_RESET s_axi_reset_n" *)
	input                                           s_axi_aclk               ,
  	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_reset_n RST" *)
  	(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
	input                                           s_axi_reset_n             ,
	input        [     C_S_AXI_LITE_ADDR_WIDTH-1:0] s_axi4_lite_awaddr       ,
	input                                           s_axi4_lite_awvalid      ,
	output logic                                    s_axi4_lite_awready      ,
	input        [    C_S_AXI4_LITE_DATA_WIDTH-1:0] s_axi4_lite_wdata        ,
	input        [(C_S_AXI4_LITE_DATA_WIDTH/8)-1:0] s_axi4_lite_wstrb        ,
	input                                           s_axi4_lite_wvalid       ,
	output logic                                    s_axi4_lite_wready       ,
	output logic [                             1:0] s_axi4_lite_bresp        ,
	output logic                                    s_axi4_lite_bvalid       ,
	input                                           s_axi4_lite_bready       ,
	input        [     C_S_AXI_LITE_ADDR_WIDTH-1:0] s_axi4_lite_araddr       ,
	input                                           s_axi4_lite_arvalid      ,
	output logic                                    s_axi4_lite_arready      ,
	output logic [    C_S_AXI4_LITE_DATA_WIDTH-1:0] s_axi4_lite_rdata        ,
	output logic [                             1:0] s_axi4_lite_rresp        ,
	output logic                                    s_axi4_lite_rvalid       ,
	input                                           s_axi4_lite_rready       
);

	axi4_stream #(.TDATA_WIDTH(512), .TKEEP_WIDTH(64), .TUSER_WIDTH(0)) LBUS2AXI ();
	axi4_stream #(.TDATA_WIDTH(512), .TKEEP_WIDTH(64)) AXI2LBUS ();
	axi4_lite #(.C_S_AXI_DATA_WIDTH(C_S_AXI4_LITE_DATA_WIDTH), .C_S_AXI_ADDR_WIDTH(C_S_AXI_LITE_ADDR_WIDTH)) AXI4_STAT ();
	stat_t CMAC_STAT ();
	transceiver_ports_t  #(.LANES(C_CAUI_4_SERDES_NUMBER)) cmac_transceiver_ports();

	assign LBUS2AXI_tvalid = LBUS2AXI.tvalid;
	assign LBUS2AXI_tlast  = LBUS2AXI.tlast;
	assign LBUS2AXI_tstrb  = LBUS2AXI.tstrb;
	assign LBUS2AXI_tdata  = LBUS2AXI.tdata;
	assign LBUS2AXI.tready = LBUS2AXI_tready;

	assign AXI2LBUS.tvalid = AXI2LBUS_tvalid;
	assign AXI2LBUS.tlast  = AXI2LBUS_tlast;
	assign AXI2LBUS.tstrb  = AXI2LBUS_tstrb;
	assign AXI2LBUS.tdata  = AXI2LBUS_tdata;
	assign AXI2LBUS_tready = AXI2LBUS.tready;

	assign CMAC_STAT_stat_rx_aligned = CMAC_STAT.stat_rx_aligned;


	// AXI4 Lite assignations

	assign AXI4_STAT.axi_awaddr  = s_axi4_lite_awaddr;
	assign AXI4_STAT.axi_awvalid = s_axi4_lite_awvalid;
	assign AXI4_STAT.axi_wdata   = s_axi4_lite_wdata;
	assign AXI4_STAT.axi_wstrb   = s_axi4_lite_wstrb;
	assign AXI4_STAT.axi_wvalid  = s_axi4_lite_wvalid;
	assign AXI4_STAT.axi_bready  = s_axi4_lite_bready;
	assign AXI4_STAT.axi_araddr  = s_axi4_lite_araddr;
	assign AXI4_STAT.axi_arvalid = s_axi4_lite_arvalid;
	assign AXI4_STAT.axi_rready  = s_axi4_lite_rready;

	assign s_axi4_lite_awready = AXI4_STAT.axi_awready;
	assign s_axi4_lite_wready  = AXI4_STAT.axi_wready;
	assign s_axi4_lite_bresp   = AXI4_STAT.axi_bresp;
	assign s_axi4_lite_bvalid  = AXI4_STAT.axi_bvalid;
	assign s_axi4_lite_arready = AXI4_STAT.axi_arready;
	assign s_axi4_lite_rdata   = AXI4_STAT.axi_rdata;
	assign s_axi4_lite_rresp   = AXI4_STAT.axi_rresp;
	assign s_axi4_lite_rvalid  = AXI4_STAT.axi_rvalid;



	cmac_connector cmac_connector_i (
		.cmac_transceiver_ports(cmac_transceiver_ports),
		.gt_ref_clk_p  (gt_ref_clk_p       ),
		.gt_ref_clk_n  (gt_ref_clk_n       ),
		.CLK           (s_axi_aclk         ),
		.RST_N         (s_axi_reset_n      ),
		.LBUS2AXI      (LBUS2AXI           ),
		.AXI2LBUS      (AXI2LBUS           ),
		.CMAC_STAT     (CMAC_STAT          ),
		.usr_clk_tx    (usr_tx_clk         ),
		.usr_clk_rx    (usr_rx_clk         ),
		.tx_rst        (tx_rst             ),
		.rx_rst        (rx_rst             ),
		.gt_rxrecclkout(gt_rxrecclkout     ),
		.axi4_stat     (AXI4_STAT          )
	);

	// Transceivers assignation
	assign cmac_transceiver_ports.rxp = gt_rxp_in;
	assign cmac_transceiver_ports.rxn = gt_rxn_in;

	assign gt_txn_out = cmac_transceiver_ports.txn;
	assign gt_txp_out = cmac_transceiver_ports.txp;


endmodule // cmac_connector_wrapper