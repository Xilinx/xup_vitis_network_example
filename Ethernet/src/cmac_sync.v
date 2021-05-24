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


module cmac_sync (
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 usr_tx_reset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input wire          usr_tx_reset             ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 usr_rx_reset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input wire          usr_rx_reset             ,
    // Control ports
    input wire          stat_rx_aligned,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET s_axi_sreset" *)
    input wire          s_axi_aclk               ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_sreset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input wire          s_axi_sreset             ,
    output wire  [11:0] s_axi_awaddr             ,
    output wire         s_axi_awvalid            ,
    input wire          s_axi_awready            ,
    output wire  [31:0] s_axi_wdata              ,
    output wire  [ 3:0] s_axi_wstrb              ,
    output wire         s_axi_wvalid             ,
    input wire          s_axi_wready             ,
    input wire   [ 1:0] s_axi_bresp              ,
    input wire          s_axi_bvalid             ,
    output wire         s_axi_bready             ,
    output wire  [11:0] s_axi_araddr             ,
    output wire         s_axi_arvalid            ,
    input wire          s_axi_arready            ,
    input wire   [31:0] s_axi_rdata              ,
    input wire   [ 1:0] s_axi_rresp              ,
    input wire          s_axi_rvalid             ,
    output wire         s_axi_rready             ,
    // Leds
    output wire         rx_gt_locked_led         ,
    output wire         rx_aligned_led           ,
    output wire         rx_done_led              ,
    output wire         rx_data_fail_led         ,
    output wire         rx_busy_led              ,
    output wire         cmac_aligned_sync
);

    wire usr_rx_reset_synq;

    // Sync mechanism
    rx_sync rx_sync_i (
        .clk                  (s_axi_aclk               ),
        .reset                (usr_rx_reset_synq        ),
        .sys_reset            (s_axi_sreset             ),
        
        .stat_rx_aligned      (cmac_aligned_sync        ),
        .rx_gt_locked_led     (rx_gt_locked_led         ),
        .rx_aligned_led       (rx_aligned_led           ),
        .rx_done_led          (rx_done_led              ),
        .rx_data_fail_led     (rx_data_fail_led         )
    );


    cmac_0_axi4_lite_user_if cmac_0_axi4_lite_user_if_i (
        .gt_locked_sync         (rx_gt_locked_led       ),
        .stat_rx_aligned_sync   (cmac_aligned_sync      ),
        .rx_busy_led            (rx_busy_led            ),
        .s_axi_aclk             (s_axi_aclk             ),
        .s_axi_sreset           (s_axi_sreset           ),
        .s_axi_pm_tick          (1'b0                   ),
        .s_axi_awaddr           (s_axi_awaddr           ),
        .s_axi_awvalid          (s_axi_awvalid          ),
        .s_axi_awready          (s_axi_awready          ),
        .s_axi_wdata            (s_axi_wdata            ),
        .s_axi_wstrb            (s_axi_wstrb            ),
        .s_axi_wvalid           (s_axi_wvalid           ),
        .s_axi_wready           (s_axi_wready           ),
        .s_axi_bresp            (s_axi_bresp            ),
        .s_axi_bvalid           (s_axi_bvalid           ),
        .s_axi_bready           (s_axi_bready           ),
        .s_axi_araddr           (s_axi_araddr           ),
        .s_axi_arvalid          (s_axi_arvalid          ),
        .s_axi_arready          (s_axi_arready          ),
        .s_axi_rdata            (s_axi_rdata            ),
        .s_axi_rresp            (s_axi_rresp            ),
        .s_axi_rvalid           (s_axi_rvalid           ),
        .s_axi_rready           (s_axi_rready           )
    );

    /* Synchronizers */
    
    cdc_sync i_cmac_0_sync_usr_rx_reset (
        .clk              (s_axi_aclk               ),
        .signal_in        (usr_rx_reset             ), 
        .signal_out       (usr_rx_reset_synq        )
    );

    cdc_sync i_cmac_0_mon_clk_stat_rx_aligned (
        .clk              (s_axi_aclk               ),
        .signal_in        (stat_rx_aligned          ), 
        .signal_out       (cmac_aligned_sync        )
    );

endmodule

module cdc_sync (
    input  wire clk,
    (* ASYNC_REG = "TRUE" *)
    input  wire signal_in,
    output wire signal_out
);

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


endmodule    