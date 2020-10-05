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
/*

  Description   : This component transforms the passed information through the LBUS
			interface to the AXI4 Stream interface. Some assumptions has been made:
				1) The first byte of the packet is located at tdata[7:0], the second one in
              tdata[15:8] and so on...
              
*/
`timescale 1ns/1ps


module cmac_lbus2axi #(
	parameter C_TRANSMISSION_SEGMENTS = 4, 
	parameter C_DATA_WIDTH 	          = 512,
	parameter TIMESTAMP_WIDTH         = 64 
) (
	input  wire                                 CLK                    ,
	input  wire                                 RST_N                  ,
	input  wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_EN        ,
	input  wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_SOP       ,
	input  wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_EOP       ,
	input  wire [4*C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_MTY       ,
	input  wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_ERR       ,
	input  wire [             C_DATA_WIDTH-1:0] CMAC_LBUS_RX_DATA      ,
	output wire                                 CMAC_LBUS_RX_USER_RST_I,
	input  wire                                 CMAC_LBUS_RX_USER_RST_O,
	input  wire [          TIMESTAMP_WIDTH-1:0] RX_TIMESTAMP           ,
	output wire                                 LBUS2AXI_TVALID        ,
	output wire                                 LBUS2AXI_TLAST         ,
	output wire [         (C_DATA_WIDTH/8)-1:0] LBUS2AXI_TSTRB         ,
	output wire [             C_DATA_WIDTH-1:0] LBUS2AXI_TDATA         ,
	input  wire                                 LBUS2AXI_TREADY
);

	wire [  C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_en_aligned_s  ;
	wire [  C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_sop_aligned_s ;
	wire [  C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_eop_aligned_s ;
	wire [4*C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_mty_aligned_s ;
	wire [  C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_err_aligned_s ;
	wire [             C_DATA_WIDTH-1:0] cmac_lbus_rx_data_aligned_s;

	// Convert the LBUS transactions so no SOP and EOP converge in the same pulse
	cmac_lbus_aligner #(
		.C_TRANSMISSION_SEGMENTS(C_TRANSMISSION_SEGMENTS),
		.C_DATA_WIDTH           (C_DATA_WIDTH           ),
		.TIMESTAMP_WIDTH        (TIMESTAMP_WIDTH        )
	) cmac_lbus_aligner_i (
		.CLK                    (CLK                        ),
		.RST_N                  (RST_N                      ),
		.CMAC_LBUS_RX_EN        (CMAC_LBUS_RX_EN            ),
		.CMAC_LBUS_RX_SOP       (CMAC_LBUS_RX_SOP           ),
		.CMAC_LBUS_RX_EOP       (CMAC_LBUS_RX_EOP           ),
		.CMAC_LBUS_RX_MTY       (CMAC_LBUS_RX_MTY           ),
		.CMAC_LBUS_RX_ERR       (CMAC_LBUS_RX_ERR           ),
		.CMAC_LBUS_RX_DATA      (CMAC_LBUS_RX_DATA          ),
		.CMAC_LBUS_RX_USER_RST_I(CMAC_LBUS_RX_USER_RST_I    ),
		.CMAC_LBUS_RX_USER_RST_O(CMAC_LBUS_RX_USER_RST_O    ),
		.CMAC_LBUS_RX_EN_O      (cmac_lbus_rx_en_aligned_s  ),
		.CMAC_LBUS_RX_SOP_O     (cmac_lbus_rx_sop_aligned_s ),
		.CMAC_LBUS_RX_EOP_O     (cmac_lbus_rx_eop_aligned_s ),
		.CMAC_LBUS_RX_MTY_O     (cmac_lbus_rx_mty_aligned_s ),
		.CMAC_LBUS_RX_ERR_O     (cmac_lbus_rx_err_aligned_s ),
		.CMAC_LBUS_RX_DATA_O    (cmac_lbus_rx_data_aligned_s)
	);


	wire                    	lbus2axi_tvalid_s;
	wire                    	lbus2axi_tlast_s ;
	wire [(C_DATA_WIDTH/8)-1:0] lbus2axi_tstrb_s ;
	wire [    C_DATA_WIDTH-1:0] lbus2axi_tdata_s ;
	wire                    	lbus2axi_tready_s;

	// Convert the format from LBUS to Axi4-Stream. The tready signal is ignored inside this module.
	cmac_lbus_aligned_2_axi #(
		.C_TRANSMISSION_SEGMENTS(C_TRANSMISSION_SEGMENTS),
		.C_DATA_WIDTH           (C_DATA_WIDTH           )
	) cmac_lbus_aligned_2_axi_i (
		.CLK              (CLK                        ),
		.RST_N            (RST_N                      ),
		.CMAC_LBUS_RX_EN  (cmac_lbus_rx_en_aligned_s  ),
		.CMAC_LBUS_RX_SOP (cmac_lbus_rx_sop_aligned_s ),
		.CMAC_LBUS_RX_EOP (cmac_lbus_rx_eop_aligned_s ),
		.CMAC_LBUS_RX_MTY (cmac_lbus_rx_mty_aligned_s ),
		.CMAC_LBUS_RX_ERR (cmac_lbus_rx_err_aligned_s ),
		.CMAC_LBUS_RX_DATA(cmac_lbus_rx_data_aligned_s),
		.LBUS2AXI_TVALID  (lbus2axi_tvalid_s          ),
		.LBUS2AXI_TLAST   (lbus2axi_tlast_s           ),
		.LBUS2AXI_TSTRB   (lbus2axi_tstrb_s           ),
		.LBUS2AXI_TDATA   (lbus2axi_tdata_s           ),
		.LBUS2AXI_TREADY  (lbus2axi_tready_s          )
	);

	reg in_the_middle_of_a_packet_r;
	reg invalidate_packet_r           ;

	wire axis_prog_full;
	always @(posedge CLK) begin : proc_packet_detection
		if(~RST_N) begin
			in_the_middle_of_a_packet_r <= 0;
		end else begin
			if(lbus2axi_tvalid_s&lbus2axi_tlast_s&lbus2axi_tready_s) begin
				in_the_middle_of_a_packet_r <= 1'b0;
			end else if(lbus2axi_tvalid_s&lbus2axi_tready_s) begin
				in_the_middle_of_a_packet_r <= 1'b1;
			end
		end
	end

	always @(posedge CLK) begin : proc_packet_invalidation
		if(~RST_N) begin
			invalidate_packet_r <= 0;
		end else begin
			if(axis_prog_full && (!in_the_middle_of_a_packet_r||(lbus2axi_tvalid_s&lbus2axi_tlast_s&lbus2axi_tready_s))) begin
				invalidate_packet_r <= 1'b1;
			end else if(!in_the_middle_of_a_packet_r||(lbus2axi_tvalid_s&lbus2axi_tlast_s&lbus2axi_tready_s)) begin
				invalidate_packet_r <= 1'b0;
			end
		end
	end
	
	axi_fifo axi_fifo_i (
		.s_aclk        (CLK                                  ), // input wire s_axis_aresetn
		.s_aresetn     (RST_N                                ), // input wire s_axis_aclk
		.s_axis_tvalid (lbus2axi_tvalid_s & !invalidate_packet_r), // input wire s_axis_tvalid
		.s_axis_tready (lbus2axi_tready_s                    ), // output wire s_axis_tready
		.s_axis_tdata  (lbus2axi_tdata_s                     ), // input wire [511 : 0] s_axis_tdata
		.s_axis_tstrb  (lbus2axi_tstrb_s                     ), // input wire [63 : 0] s_axis_tstrb
		.s_axis_tlast  (lbus2axi_tlast_s                     ), // input wire s_axis_tlast
		.m_axis_tvalid (LBUS2AXI_TVALID                      ), // output wire m_axis_tvalid
		.m_axis_tready (LBUS2AXI_TREADY                      ), // input wire m_axis_tready
		.m_axis_tdata  (LBUS2AXI_TDATA                       ), // output wire [511 : 0] m_axis_tdata
		.m_axis_tstrb  (LBUS2AXI_TSTRB                       ), // output wire [63 : 0] m_axis_tstrb
		.m_axis_tlast  (LBUS2AXI_TLAST                       ), // output wire m_axis_tlast
		.axis_prog_full(axis_prog_full                       )  // output wire axis_prog_full
	);

endmodule