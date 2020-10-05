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


module cmac_lbus_aligned_2_axi #(
	parameter C_TRANSMISSION_SEGMENTS = 4, 
	parameter C_DATA_WIDTH            = 512, 
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
	output reg                                  LBUS2AXI_TVALID        ,
	output reg                                  LBUS2AXI_TLAST         ,
	output reg  [         (C_DATA_WIDTH/8)-1:0] LBUS2AXI_TSTRB         ,
	output reg  [             C_DATA_WIDTH-1:0] LBUS2AXI_TDATA         ,
	input  wire                                 LBUS2AXI_TREADY
);

	localparam C_STRB_WIDTH = C_DATA_WIDTH/8;

 	/**
 	* Given the enable mask and the mty (values not used in a segment of 16B), generate a STRB signal with granularity of Bytes
 	*/
 	function [C_STRB_WIDTH-1:0] strb_from_mty(input [C_TRANSMISSION_SEGMENTS-1:0] en, input [C_TRANSMISSION_SEGMENTS*4-1:0] mty);
 		integer i,j;
 		for (i = 0 ; i < C_TRANSMISSION_SEGMENTS; i=i+1) begin
 			if(en[i]) begin
 				for(j=(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS/8); j>0; j=j-1) begin
 					if( mty[4*i +: 4] < j ) begin
 						strb_from_mty[ C_STRB_WIDTH/C_TRANSMISSION_SEGMENTS*i + (C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS/8) - j ] = 1'b1;
 					end else begin
 						strb_from_mty[ C_STRB_WIDTH/C_TRANSMISSION_SEGMENTS*i + (C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS/8) - j ] = 1'b0;
 					end
 				end
 			end else begin
 				strb_from_mty[ C_STRB_WIDTH/C_TRANSMISSION_SEGMENTS*i +: C_STRB_WIDTH/C_TRANSMISSION_SEGMENTS] = 0;
 			end
 		end
 	endfunction

 	integer j;
 	always_ff @(posedge CLK) begin : main_proc
 		if(~RST_N) begin
			LBUS2AXI_TVALID <= 'h0;
			LBUS2AXI_TLAST <= 'h0;
			LBUS2AXI_TSTRB <= 'h0;
			LBUS2AXI_TDATA <= 'h0;
 		end else begin
 			
 			
			LBUS2AXI_TVALID <= CMAC_LBUS_RX_EN!=0;
			LBUS2AXI_TLAST  <= CMAC_LBUS_RX_EOP!=0;

			case(CMAC_LBUS_RX_EOP)
				4'b0001: begin
					LBUS2AXI_TSTRB <= strb_from_mty(4'b0001, CMAC_LBUS_RX_MTY); 
				end
				4'b0010: begin
					LBUS2AXI_TSTRB <= strb_from_mty(4'b0011, CMAC_LBUS_RX_MTY);
				end
				4'b0100: begin
					LBUS2AXI_TSTRB <= strb_from_mty(4'b0111, CMAC_LBUS_RX_MTY);
				end
				4'b1000: begin
					LBUS2AXI_TSTRB <= strb_from_mty(4'b1111, CMAC_LBUS_RX_MTY);
				end
				default: begin
					LBUS2AXI_TSTRB <= {64{1'b1}};
				end
			endcase
					
			for (j = 0 ; j < (C_DATA_WIDTH/8); j=j+1) begin
		 		LBUS2AXI_TDATA[8*j+:8] <= CMAC_LBUS_RX_DATA[C_DATA_WIDTH-8*(j+1)+:8];
 			end

 		end
 	end


endmodule 