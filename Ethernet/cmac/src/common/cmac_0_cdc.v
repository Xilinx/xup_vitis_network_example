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

module cmac_0_cdc_sync #(
    parameter integer ULTRASCALE_PLUS = 0
)(
    input  wire clk,
    (* ASYNC_REG = "TRUE" *)
    input  wire signal_in,
    output wire signal_out
);

    generate
        if (ULTRASCALE_PLUS==1) begin : ultrascale_plus_arch
            HARD_SYNC #(
              .INIT             (1'b0),     // Initial values, 1'b0, 1'b1
              .IS_CLK_INVERTED  (1'b0),     // Programmable inversion on CLK input
              .LATENCY             (3)      // 2-3
            )
            HARD_SYNC_i (
              .CLK  (          clk),        // 1-bit input: Clock
              .DIN  (    signal_in),        // 1-bit input: Data
              .DOUT (   signal_out)         // 1-bit output: Data
            );
        end
        else begin : ultrascale_arch
            
            wire sig_in_cdc_from ;
            (* ASYNC_REG = "TRUE" *)
            reg  s_out_d2_cdc_to;
            (* ASYNC_REG = "TRUE" *)
            reg  s_out_d3;

            assign sig_in_cdc_from = signal_in;
            assign signal_out      = s_out_d3;

            always @(posedge clk) 
            begin
              s_out_d2_cdc_to  <= sig_in_cdc_from;
              s_out_d3         <= s_out_d2_cdc_to;
            end
        end
    endgenerate
endmodule    