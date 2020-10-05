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

module cmac_connector (
	transceiver_ports_t.master    	cmac_transceiver_ports,
	input              				gt_ref_clk_p  ,
	input              				gt_ref_clk_n  ,
	input              				CLK           ,
	input              				RST_N         ,
	axi4_stream.master 				LBUS2AXI      ,
	axi4_stream.slave  				AXI2LBUS      ,
	stat_t.master   				CMAC_STAT     ,
	output             				usr_clk_tx    ,
	output             				usr_clk_rx    ,
	output             				tx_rst        ,
	output             				rx_rst        ,
	output logic [9:0] 				gt_rxrecclkout,
	axi4_lite.slave    				axi4_stat     
);

	gt_drp_t 		cmac_drp ();
	lbus_tx_t 		cmac_lbus_tx ();
	lbus_rx_t 		cmac_lbus_rx ();
	rx_timestamp_t 	rx_ts ();
	logic [63: 0]	tx_timestamp_cdc = 64'h0;

	cmac_wrapper cmac_wrapper_i (
		.CLK                   (CLK                   ),
		.RST_N                 (RST_N                 ),
		.refclk_p              (gt_ref_clk_p          ),
		.refclk_n              (gt_ref_clk_n          ),
		.cmac_drp              (cmac_drp              ),
		.cmac_transceiver_ports(cmac_transceiver_ports),
		.cmac_lbus_tx          (cmac_lbus_tx          ),
		.cmac_lbus_rx          (cmac_lbus_rx          ),
		.cmac_stat             (CMAC_STAT             ),
		.rx_timestamp          (rx_ts                 ),
		.axi4_stat             (axi4_stat             ),
		.axi_pm_tick           (1'b0                  )
	);

	assign usr_clk_tx     = cmac_drp.gt_txusrclk2;
	assign usr_clk_rx     = cmac_drp.gt_rxusrclk2;
	assign gt_rxrecclkout = cmac_drp.gt_rxrecclkout;
	assign tx_rst         = cmac_lbus_tx.user_rst_o;
	assign rx_rst         = cmac_lbus_rx.user_rst_o;

	(* ASYNC_REG="true" *) logic  rst_rx_n_1d, rst_rx_n_2d, rst_rx_n_3d;

	// CDC for rx user reset 
	always_ff @(posedge usr_clk_rx) begin
		rst_rx_n_1d <= RST_N;				
		rst_rx_n_2d <= rst_rx_n_1d;
		rst_rx_n_3d <= rst_rx_n_2d;
	end

	cmac_lbus2axi cmac_lbus2axi_i (
		.CLK                    (usr_clk_rx                                                                           ),
		.RST_N                  (rst_rx_n_3d                                                                          ),
		.CMAC_LBUS_RX_EN        (cmac_lbus_rx.en                                                                      ),
		.CMAC_LBUS_RX_SOP       (cmac_lbus_rx.sop                                                                     ),
		.CMAC_LBUS_RX_EOP       (cmac_lbus_rx.eop                                                                     ),
		.CMAC_LBUS_RX_MTY       ({cmac_lbus_rx.mty[3],cmac_lbus_rx.mty[2],cmac_lbus_rx.mty[1],cmac_lbus_rx.mty[0]}    ),
		.CMAC_LBUS_RX_ERR       ({cmac_lbus_rx.err[0],cmac_lbus_rx.err[1],cmac_lbus_rx.err[2],cmac_lbus_rx.err[3]}    ),
		.CMAC_LBUS_RX_DATA      ({cmac_lbus_rx.data[0],cmac_lbus_rx.data[1],cmac_lbus_rx.data[2],cmac_lbus_rx.data[3]}),
		.CMAC_LBUS_RX_USER_RST_I(cmac_lbus_rx.user_rst_i                                                              ),
		.CMAC_LBUS_RX_USER_RST_O(cmac_lbus_rx.user_rst_o                                                              ),
		.RX_TIMESTAMP           (rx_ts.rx_ptp_tstamp_corrected                                                        ),
		.LBUS2AXI_TVALID        (LBUS2AXI.tvalid                                                                      ),
		.LBUS2AXI_TLAST         (LBUS2AXI.tlast                                                                       ),
		.LBUS2AXI_TSTRB         (LBUS2AXI.tstrb                                                                       ),
		.LBUS2AXI_TDATA         (LBUS2AXI.tdata                                                                       ),
		.LBUS2AXI_TREADY        (LBUS2AXI.tready                                                                      )
	);

	(* ASYNC_REG="true" *)  logic rst_tx_n_1d, rst_tx_n_2d, rst_tx_n_3d;

	// CDC for tx user reset 
	always_ff @(posedge usr_clk_tx) begin
		rst_tx_n_1d <= RST_N;				
		rst_tx_n_2d <= rst_tx_n_1d;
		rst_tx_n_3d <= rst_tx_n_2d;
  	end

	cmac_axi2lbus cmac_axi2lbus_i (
		.CLK         (usr_clk_tx      ),
		.RST_N       (rst_tx_n_3d     ),
		.CMAC_LBUS_TX(cmac_lbus_tx    ),
		.TX_TIMESTAMP(tx_timestamp_cdc),
		.AXI2LBUS    (AXI2LBUS        )
	);

	assign cmac_drp.gt_loopback_in = 12'd0;

endmodule // cmac_connector
