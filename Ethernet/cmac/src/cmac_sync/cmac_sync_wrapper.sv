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


module cmac_sync_wrapper #(
        parameter integer ULTRASCALE_PLUS       = 0,
        parameter integer SLAVE_CMAC_BASEADDR   = 32'h0
    ) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 usr_tx_reset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input               usr_tx_reset             ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 usr_rx_reset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input               usr_rx_reset             ,
    //// User Interface signals
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 lbus_tx_rx_restart_in RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input               lbus_tx_rx_restart_in    ,
    // Control ports
    input               cmac_stat_stat_rx_aligned,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET s_axi_sreset" *)
    input               s_axi_aclk               ,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_sreset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input               s_axi_sreset             ,
    output       [31:0] s_axi_awaddr             ,
    output              s_axi_awvalid            ,
    input               s_axi_awready            ,
    output       [31:0] s_axi_wdata              ,
    output       [ 3:0] s_axi_wstrb              ,
    output              s_axi_wvalid             ,
    input               s_axi_wready             ,
    input        [ 1:0] s_axi_bresp              ,
    input               s_axi_bvalid             ,
    output              s_axi_bready             ,
    output       [31:0] s_axi_araddr             ,
    output              s_axi_arvalid            ,
    input               s_axi_arready            ,
    input        [31:0] s_axi_rdata              ,
    input        [ 1:0] s_axi_rresp              ,
    input               s_axi_rvalid             ,
    output              s_axi_rready             ,
    // Leds
    output logic        tx_done_led              ,
    output logic        tx_busy_led              ,
    output logic        rx_gt_locked_led         ,
    output logic        rx_aligned_led           ,
    output logic        rx_done_led              ,
    output logic        rx_data_fail_led         ,
    output logic        rx_busy_led              ,
    output logic        cmac_aligned_sync         
);

    stat_t cmac_stat ();

    wire rx_aligned_sync_i;
    wire usr_rx_reset_synq;
    wire usr_tx_reset_synq;
    wire lbus_tx_rst_synq;

    assign cmac_stat.stat_rx_aligned = rx_aligned_sync_i;
    assign cmac_aligned_sync = rx_aligned_sync_i;

    cmac_sync cmac_sync_i (
        .gen_mon_clk          (s_axi_aclk           ),
        .usr_tx_reset         (usr_tx_reset_synq    ),
        .usr_rx_reset         (usr_rx_reset_synq    ),
        .sys_reset            (s_axi_sreset         ),
        .lbus_tx_rx_restart_in(lbus_tx_rst_synq     ),
        .cmac_stat            (cmac_stat            ),
        .tx_done_led          (tx_done_led          ),
        .tx_busy_led          (tx_busy_led          ),
        .rx_gt_locked_led     (rx_gt_locked_led     ),
        .rx_aligned_led       (rx_aligned_led       ),
        .rx_done_led          (rx_done_led          ),
        .rx_data_fail_led     (rx_data_fail_led     )
    );

    cmac_0_axi4_lite_user_if  #(
        .ULTRASCALE_PLUS        (ULTRASCALE_PLUS          ),
        .SLAVE_CMAC_BASEADDR    (SLAVE_CMAC_BASEADDR      )
        )
    cmac_0_axi4_lite_user_if_i (
        .gt_locked_sync         (rx_gt_locked_led         ),
        .stat_rx_aligned_sync   (rx_aligned_sync_i        ),
        .rx_busy_led            (rx_busy_led              ),
        .s_axi_aclk             (s_axi_aclk               ),
        .s_axi_sreset           (s_axi_sreset             ),
        .s_axi_pm_tick          (1'b0                     ),
        .s_axi_awaddr           (s_axi_awaddr             ),
        .s_axi_awvalid          (s_axi_awvalid            ),
        .s_axi_awready          (s_axi_awready            ),
        .s_axi_wdata            (s_axi_wdata              ),
        .s_axi_wstrb            (s_axi_wstrb              ),
        .s_axi_wvalid           (s_axi_wvalid             ),
        .s_axi_wready           (s_axi_wready             ),
        .s_axi_bresp            (s_axi_bresp              ),
        .s_axi_bvalid           (s_axi_bvalid             ),
        .s_axi_bready           (s_axi_bready             ),
        .s_axi_araddr           (s_axi_araddr             ),
        .s_axi_arvalid          (s_axi_arvalid            ),
        .s_axi_arready          (s_axi_arready            ),
        .s_axi_rdata            (s_axi_rdata              ),
        .s_axi_rresp            (s_axi_rresp              ),
        .s_axi_rvalid           (s_axi_rvalid             ),
        .s_axi_rready           (s_axi_rready             )
    );

    /* Synchronizers */
    
    cmac_0_cdc_sync #(
        .ULTRASCALE_PLUS(ULTRASCALE_PLUS))
    i_cmac_0_sync_usr_tx_reset (
        .clk              (s_axi_aclk               ),
        .signal_in        (usr_tx_reset             ), 
        .signal_out       (usr_tx_reset_synq        )
    );

    cmac_0_cdc_sync #(
        .ULTRASCALE_PLUS(ULTRASCALE_PLUS))
    i_cmac_0_sync_usr_rx_reset (
        .clk              (s_axi_aclk               ),
        .signal_in        (usr_rx_reset             ), 
        .signal_out       (usr_rx_reset_synq        )
    );

    cmac_0_cdc_sync #(
        .ULTRASCALE_PLUS(ULTRASCALE_PLUS))
    i_cmac_0_mon_clk_stat_rx_aligned (
        .clk              (s_axi_aclk               ),
        .signal_in        (cmac_stat_stat_rx_aligned), 
        .signal_out       (rx_aligned_sync_i        )
    );

    cmac_0_cdc_sync  #(
        .ULTRASCALE_PLUS(ULTRASCALE_PLUS))
    i_cmac_0_sync_tx_rx_restart (
        .clk              (s_axi_aclk               ),
        .signal_in        (lbus_tx_rx_restart_in    ), 
        .signal_out       (lbus_tx_rst_synq         )
    );

endmodule