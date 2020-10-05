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
  Description   : This component transforms the information passed through the AXI4 Stream 
			interface to the LBUS interface. Some assumptions has been made:
				1) The first byte of the packet is located at tdata[7:0], the second one in  
              tdata[15:8] and so on...

*/

`timescale 1ns/1ps

module cmac_axi2lbus (
	input wire        			CLK         ,
	input wire        			RST_N       ,
	lbus_tx_t.master  			CMAC_LBUS_TX,
	input wire       [63: 0] 	TX_TIMESTAMP,
	axi4_stream.slave  			AXI2LBUS
);


	logic is_new_packet_r;

	localparam c_data_width            = 512    ;
	localparam c_strb_width            = (512/8);
	localparam c_transmission_segments = 4      ;


	logic [c_data_width-1:0] invert_data_s;
	logic [c_data_width-1:0] original_data_s;
	// The LBUS endianess is disgusting at least. The first byte of a packet occupies the position
	// 512-1:504 of the bus ???!!!!.
	// Because of this we have to reorder the data bus.

	assign original_data_s = AXI2LBUS.tdata;

	always_comb begin
		for (int i = 0 ; i < (c_data_width/8); i++) begin
			invert_data_s[8*i+:8] = original_data_s[c_data_width-8*(i+1)+:8];
		end
	end



	function [3:0] invalid_bytes_segment_func(input [(c_strb_width/c_transmission_segments)-1:0] strobe);
		invalid_bytes_segment_func = 0;
		for (int i = 0 ; i < (c_strb_width/c_transmission_segments); i++) begin    // Increment the return value when it is 0.
			if(strobe[i]==1'b0) begin
				invalid_bytes_segment_func = invalid_bytes_segment_func + 1;
			end
		end
	endfunction : invalid_bytes_segment_func

	logic user_rst;
	assign user_rst = CMAC_LBUS_TX.user_rst_o || !RST_N;

	assign AXI2LBUS.tready = CMAC_LBUS_TX.rdy & CMAC_LBUS_TX.user_rst_o==1'b0;
	always_ff @(posedge CLK) begin : proc_distribution
		if(user_rst) begin
			for (int i = 0 ; i < c_transmission_segments; i++) begin    // Default values
				CMAC_LBUS_TX.data[i] <= 0;
				CMAC_LBUS_TX.err[i]  <= 0;
				CMAC_LBUS_TX.sop[i]  <= 0;
				CMAC_LBUS_TX.eop[i]  <= 0;
				CMAC_LBUS_TX.mty[i]  <= 0;
				CMAC_LBUS_TX.en[i]   <= 0;
			end
			is_new_packet_r <= 1'b1;
		end else begin
			for (int i = 0 ; i < c_transmission_segments; i++) begin    // Default values
				CMAC_LBUS_TX.data[i] <= invert_data_s[c_data_width -(c_data_width/c_transmission_segments)*(i+1)+:(c_data_width/c_transmission_segments)];
				CMAC_LBUS_TX.err[i]  <= 0;
				CMAC_LBUS_TX.sop[i]  <= 0;
				CMAC_LBUS_TX.eop[i]  <= 0;
				CMAC_LBUS_TX.mty[i]  <= invalid_bytes_segment_func(AXI2LBUS.tstrb[(c_strb_width/c_transmission_segments)*i+:c_strb_width/c_transmission_segments]);
				CMAC_LBUS_TX.en[i]   <= 1'b0;
			end

      		/**
      		*  A new piece of packet has arrived. It must be aligned to the lowest position in the bus. It cannot contain disruptions
      		*  and just one packet is allowed per cycle (multiple packets cannot be mixed).
      		*/
      		if( CMAC_LBUS_TX.rdy & AXI2LBUS.tready ) begin
				CMAC_LBUS_TX.sop[0] <= is_new_packet_r;
				is_new_packet_r <= AXI2LBUS.tvalid ? AXI2LBUS.tlast : is_new_packet_r;
				for (int i = 0 ; i < c_transmission_segments; i++) begin    // Default values
					/**
					*  Every segment has a data width of (c_data_width/c_transmission_segments) bits. The strobe signal indicates a valid byte.
					*  (c_strb_width/c_transmission_segments) * i checks the initial valid byte of every segment: 0, 16, 32 and 48
					*/
					CMAC_LBUS_TX.en[i] <=  AXI2LBUS.tvalid & AXI2LBUS.tstrb[(c_strb_width/c_transmission_segments)*i];
				end

				if(AXI2LBUS.tlast) begin
					for (int i = 0 ; i < c_transmission_segments-1; i++) begin
						// This segment contains information and the first strobe bit for the next segment is 0.
						CMAC_LBUS_TX.eop[i] <= (AXI2LBUS.tstrb[(c_strb_width/c_transmission_segments)*i] & !AXI2LBUS.tstrb[(c_strb_width/c_transmission_segments)*(i+1)]);
					end
					CMAC_LBUS_TX.eop[c_transmission_segments-1] <= AXI2LBUS.tstrb[(c_strb_width/c_transmission_segments)*(c_transmission_segments-1)];
				end

			end
		end
	end


	assign CMAC_LBUS_TX.user_rst_i = !RST_N;

endmodule
