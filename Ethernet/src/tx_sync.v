/************************************************
Copyright (c) 2020, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation 
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors 
may be used to endorse or promote products derived from this software 
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.// Copyright (c) 2020 Xilinx, Inc.
************************************************/

`timescale 1ps/1ps

module tx_sync (
    input  wire        clk                  ,
    input  wire        reset                ,
    input  wire        sys_reset            ,
    input  wire        stat_rx_aligned      ,
    input  wire        lbus_tx_rx_restart_in,
    output wire        ctl_tx_enable        ,
    output wire        ctl_tx_send_idle     ,
    output wire        ctl_tx_send_rfi      ,
    output wire        ctl_tx_test_pattern  ,
    output reg         tx_done_led          ,
    output reg         tx_busy_led
);

    //// Parameters Decleration
    parameter PKT_NUM  = 1000; //// 1 to 2^16-1
    parameter PKT_SIZE = 522 ; //// lbus_pkt_size_proc signal generation (64-16383)

    //// pkt_gen States
    parameter STATE_TX_IDLE           = 0;
    parameter STATE_GT_LOCKED         = 1;
    parameter STATE_WAIT_RX_ALIGNED   = 2;
    parameter STATE_PKT_TRANSFER_INIT = 3;
    parameter STATE_LBUS_TX_ENABLE    = 4;
    parameter STATE_LBUS_TX_HALT      = 5;
    parameter STATE_LBUS_TX_DONE      = 6;
    parameter STATE_WAIT_FOR_RESTART  = 7;

    ////State Registers for TX
    reg [3:0] tx_prestate;


    reg tx_restart_rise_edge, first_pkt, pkt_size_64, wait_to_restart;
    reg tx_done_reg_d, tx_fail_reg;
    reg tx_restart_1d, tx_restart_2d, tx_restart_3d, tx_restart_4d;


    reg       stat_rx_aligned_1d, reset_done;
    reg       ctl_tx_enable_r, ctl_tx_send_idle_r, ctl_tx_send_rfi_r, ctl_tx_test_pattern_r;
    reg       init_cntr_en;
    reg       gt_lock_led, rx_aligned_led, tx_done, tx_core_busy_led;
    reg       tx_gt_locked_led_1d, tx_done_led_1d, tx_core_busy_led_1d;
    reg       tx_gt_locked_led_2d, tx_done_led_2d, tx_core_busy_led_2d;
    reg       tx_gt_locked_led_3d, tx_done_led_3d, tx_core_busy_led_3d;

    ////----------------------------------------TX Module -----------------------//
    //////////////////////////////////////////////////
    ////registering input signal generation
    //////////////////////////////////////////////////
    always @( posedge clk )
        begin
            if ( reset == 1'b1 )
                begin
                    stat_rx_aligned_1d <= 1'b0;
                    reset_done         <= 1'b0;
                    tx_restart_1d      <= 1'b0;
                    tx_restart_2d      <= 1'b0;
                    tx_restart_3d      <= 1'b0;
                    tx_restart_4d      <= 1'b0;

                end
            else
                begin
                    stat_rx_aligned_1d <= stat_rx_aligned;
                    reset_done         <= 1'b1;
                    tx_restart_1d      <= lbus_tx_rx_restart_in;
                    tx_restart_2d      <= tx_restart_1d;
                    tx_restart_3d      <= tx_restart_2d;
                    tx_restart_4d      <= tx_restart_3d;
                end
        end

    //////////////////////////////////////////////////
    ////generating the tx_restart_rise_edge signal
    //////////////////////////////////////////////////
    always @( posedge clk )
        begin
            if  ( reset == 1'b1 )
                tx_restart_rise_edge <= 1'b0;
            else
                begin
                    if  (( tx_restart_3d == 1'b1) && ( tx_restart_4d == 1'b0))
                        tx_restart_rise_edge <= 1'b1;
                    else
                        tx_restart_rise_edge <= 1'b0;
                end
        end

    //////////////////////////////////////////////////
    ////State Machine
    //////////////////////////////////////////////////
    always @( posedge clk )
        begin
            if ( reset == 1'b1 )
                begin
                    tx_prestate <= STATE_TX_IDLE;
                    tx_done_reg_d <= 1'b0;

                    tx_fail_reg           <= 1'b0;
                    ctl_tx_enable_r       <= 1'b0;
                    ctl_tx_send_idle_r    <= 1'b0;
                    ctl_tx_send_rfi_r     <= 1'b0;
                    ctl_tx_test_pattern_r <= 1'b0;
                    gt_lock_led           <= 1'b0;
                    rx_aligned_led        <= 1'b0;
                    tx_core_busy_led      <= 1'b0;
                    wait_to_restart       <= 1'b0;
                    init_cntr_en          <= 1'b0;
                end
            else
                begin
                    case (tx_prestate)
                        STATE_TX_IDLE :
                            begin
                                ctl_tx_enable_r       <= 1'b0;
                                ctl_tx_send_idle_r    <= 1'b0;
                                ctl_tx_send_rfi_r     <= 1'b0;
                                ctl_tx_test_pattern_r <= 1'b0;


                                gt_lock_led           <= 1'b0;
                                rx_aligned_led        <= 1'b0;
                                tx_core_busy_led      <= 1'b0;
                                tx_fail_reg           <= 1'b0;
                                
                                tx_done_reg_d         <= 1'b0;
                                wait_to_restart       <= 1'b0;
                                init_cntr_en          <= 1'b0;

                                //// State transition
                                if  (reset_done == 1'b1)
                                    tx_prestate <= STATE_GT_LOCKED;
                                else
                                    tx_prestate <= STATE_TX_IDLE;
                            end
                        STATE_GT_LOCKED :
                            begin
                                gt_lock_led        <= 1'b1;
                                rx_aligned_led     <= 1'b0;
                                ctl_tx_enable_r    <= 1'b0;
                                ctl_tx_send_idle_r <= 1'b0;
                                ctl_tx_send_rfi_r  <= 1'b1;
                                tx_core_busy_led   <= 1'b0;

                                //// State transition
                                tx_prestate <= STATE_WAIT_RX_ALIGNED;
                            end
                        STATE_WAIT_RX_ALIGNED :
                            begin
                                wait_to_restart  <= 1'b0;
                                init_cntr_en     <= 1'b0;
                                rx_aligned_led   <= 1'b0;
                                tx_core_busy_led <= 1'b0;

                                //// State transition
                                if  (stat_rx_aligned_1d == 1'b1)
                                    begin
                                        tx_prestate <= STATE_PKT_TRANSFER_INIT;
                                    end
                                else
                                    tx_prestate <= STATE_WAIT_RX_ALIGNED;
                            end
                        STATE_PKT_TRANSFER_INIT :
                            begin
                                wait_to_restart      <= 1'b0;
                                init_cntr_en         <= 1'b1;
                                gt_lock_led          <= 1'b1;
                                rx_aligned_led       <= 1'b1;
                                tx_core_busy_led     <= 1'b1;
                                ctl_tx_send_idle_r   <= 1'b0;
                                ctl_tx_send_rfi_r    <= 1'b0;
                                ctl_tx_enable_r      <= 1'b1;
                                tx_done_reg_d        <= 1'b0;
                               

                                //// State transition
                                if  (stat_rx_aligned_1d == 1'b0)
                                    tx_prestate <= STATE_TX_IDLE;
                                else
                                    tx_prestate <= STATE_LBUS_TX_ENABLE;
                            end
                        STATE_LBUS_TX_ENABLE :
                            begin
                                init_cntr_en <= 1'b0;

                                //// State transition
                                if  (stat_rx_aligned_1d == 1'b0)
                                    tx_prestate <= STATE_TX_IDLE;
                                else
                                    tx_prestate <= STATE_LBUS_TX_ENABLE;
                            end
                 

                     
                        default :
                            begin
                                init_cntr_en          <= 1'b0;
                                wait_to_restart       <= 1'b0;
                                ctl_tx_enable_r       <= 1'b0;
                                ctl_tx_send_idle_r    <= 1'b0;
                                ctl_tx_send_rfi_r     <= 1'b0;
                                ctl_tx_test_pattern_r <= 1'b0;

                                gt_lock_led           <= 1'b0;
                                rx_aligned_led        <= 1'b0;
                                tx_core_busy_led      <= 1'b0;
                                first_pkt             <= 1'b0;
                                pkt_size_64           <= 1'd0;
                                tx_fail_reg           <= 1'b0;
                                                              
                                tx_prestate           <= STATE_TX_IDLE;
                            end
                    endcase
                end
        end

    //////////////////////////////////////////////////
    ////tx_done signal generation
    //////////////////////////////////////////////////
    always @( posedge clk )
        begin
            if ( reset == 1'b1 )
                tx_done <= 1'b0;
            else
                begin
                    if ((tx_restart_rise_edge == 1'b1) && (wait_to_restart == 1'b1))
                        tx_done <= 1'b0;
                    else if  (tx_done_reg_d == 1'b1)
                        tx_done <= 1'b1;
                end
        end

  
    //////////////////////////////////////////////////
    ////Assign TX LED Output ports with ASYN sys_reset
    //////////////////////////////////////////////////
    always @( posedge clk, posedge sys_reset )
        begin
            if ( sys_reset == 1'b1 )
                begin
                    tx_done_led <= 1'b0;
                    tx_busy_led <= 1'b0;
                end
            else
                begin
                    tx_done_led <= tx_done_led_3d;
                    tx_busy_led <= tx_core_busy_led_3d;
                end
        end

    //////////////////////////////////////////////////
    ////Registering the LED ports
    //////////////////////////////////////////////////
    always @( posedge clk )
        begin
            if ( reset == 1'b1 )
                begin
                    tx_gt_locked_led_1d <= 1'b0;
                    tx_gt_locked_led_2d <= 1'b0;
                    tx_gt_locked_led_3d <= 1'b0;
                    tx_done_led_1d      <= 1'b0;
                    tx_done_led_2d      <= 1'b0;
                    tx_done_led_3d      <= 1'b0;
                    tx_core_busy_led_1d <= 1'b0;
                    tx_core_busy_led_2d <= 1'b0;
                    tx_core_busy_led_3d <= 1'b0;
                end
            else
                begin
                    tx_gt_locked_led_1d <= gt_lock_led;
                    tx_gt_locked_led_2d <= tx_gt_locked_led_1d;
                    tx_gt_locked_led_3d <= tx_gt_locked_led_2d;
                    tx_done_led_1d      <= tx_done;
                    tx_done_led_2d      <= tx_done_led_1d;
                    tx_done_led_3d      <= tx_done_led_2d;
                    tx_core_busy_led_1d <= tx_core_busy_led;
                    tx_core_busy_led_2d <= tx_core_busy_led_1d;
                    tx_core_busy_led_3d <= tx_core_busy_led_2d;
                end
        end

    assign ctl_tx_enable       = ctl_tx_enable_r;
    assign ctl_tx_send_idle    = ctl_tx_send_idle_r;
    assign ctl_tx_send_rfi     = ctl_tx_send_rfi_r;
    assign ctl_tx_test_pattern = ctl_tx_test_pattern_r;

    ////----------------------------------------END TX Module-----------------------//

endmodule


