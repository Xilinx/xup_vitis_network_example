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
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

************************************************/

`timescale 1ps/1ps


module rx_sync (
    input  wire clk                  ,
    input  wire reset                ,
    input  wire sys_reset            ,
    input  wire stat_rx_aligned      ,
    output wire ctl_rx_enable        ,
    output wire ctl_rx_force_resync  ,
    output wire ctl_rx_test_pattern  ,
    output reg  rx_gt_locked_led     ,
    output reg  rx_aligned_led       ,
    output reg  rx_done_led          ,
    output reg  rx_data_fail_led     ,
    output reg  rx_busy_led
);



    //// pkt_mon States
    parameter STATE_RX_IDLE           = 0;
    parameter STATE_GT_LOCKED         = 1;
    parameter STATE_WAIT_RX_ALIGNED   = 2;
    parameter STATE_PKT_TRANSFER_INIT = 3;
    parameter STATE_LBUS_RX_ENABLE    = 4;
    parameter STATE_LBUS_RX_DONE      = 5;
    parameter STATE_WAIT_FOR_RESTART  = 6;

    ////State Registers for RX
    reg [3:0] rx_prestate;


    reg rx_done_reg;
    reg stat_rx_aligned_1d, reset_done;


    reg ctl_rx_enable_r, ctl_rx_force_resync_r, ctl_rx_test_pattern_r;
    reg gt_lock_led, rx_aligned_led_c, rx_core_busy_led;
    reg rx_gt_locked_led_1d, stat_rx_aligned_led_1d, rx_done_led_1d, rx_core_busy_led_1d;
    reg rx_gt_locked_led_2d, stat_rx_aligned_led_2d, rx_done_led_2d, rx_core_busy_led_2d;
    reg rx_gt_locked_led_3d, stat_rx_aligned_led_3d, rx_done_led_3d, rx_core_busy_led_3d;

    ////----------------------------------------RX Module -----------------------//
    //////////////////////////////////////////////////
    ////registering input signal generation
    //////////////////////////////////////////////////
    always @( posedge clk ) begin
        if ( reset == 1'b1 ) begin
            reset_done         <= 1'b0;
            stat_rx_aligned_1d <= 1'b0;
        end
        else begin
            reset_done         <= 1'b1;
            stat_rx_aligned_1d <= stat_rx_aligned;
        end
    end


    //////////////////////////////////////////////////
    ////RX State Machine
    //////////////////////////////////////////////////
    always @( posedge clk ) begin
        if ( reset == 1'b1 ) begin
            rx_prestate           <= STATE_RX_IDLE;
            gt_lock_led           <= 1'b0;
            rx_aligned_led_c      <= 1'b0;
            rx_core_busy_led      <= 1'b0;
            ctl_rx_enable_r       <= 1'b0;
            ctl_rx_force_resync_r <= 1'b0;
            ctl_rx_test_pattern_r <= 1'b0;
        end
        else begin
            case (rx_prestate)
                STATE_RX_IDLE : begin
                    gt_lock_led           <= 1'b0;
                    rx_aligned_led_c      <= 1'b0;
                    rx_core_busy_led      <= 1'b0;
                    ctl_rx_enable_r       <= 1'b0;
                    ctl_rx_force_resync_r <= 1'b0;
                    ctl_rx_test_pattern_r <= 1'b0;
                    //// State transition
                    if  (reset_done == 1'b1)
                        rx_prestate <= STATE_GT_LOCKED;
                    else
                        rx_prestate <= STATE_RX_IDLE;
                end
                STATE_GT_LOCKED : begin
                    gt_lock_led           <= 1'b1;
                    rx_core_busy_led      <= 1'b0;
                    rx_aligned_led_c      <= 1'b0;
                    ctl_rx_enable_r       <= 1'b1;
                    ctl_rx_force_resync_r <= 1'b0;
                    ctl_rx_test_pattern_r <= 1'b0;

                    //// State transition
                    rx_prestate <= STATE_WAIT_RX_ALIGNED;
                end
                STATE_WAIT_RX_ALIGNED : begin
                    rx_aligned_led_c <= 1'b0;
                    rx_core_busy_led <= 1'b0;

                    //// State transition
                    if  (stat_rx_aligned_1d == 1'b1)
                        rx_prestate <= STATE_PKT_TRANSFER_INIT;
                    else
                        rx_prestate <= STATE_WAIT_RX_ALIGNED;
                end
                STATE_PKT_TRANSFER_INIT : begin
                    rx_aligned_led_c <= 1'b1;
                    rx_core_busy_led <= 1'b1;

                    //// State transition
                    if  (stat_rx_aligned_1d == 1'b0)
                        rx_prestate <= STATE_RX_IDLE;
                    else
                        rx_prestate <= STATE_LBUS_RX_ENABLE;
                end
                STATE_LBUS_RX_ENABLE : begin
                    //// State transition
                    if  (stat_rx_aligned_1d == 1'b0)
                        rx_prestate <= STATE_RX_IDLE;
                    else
                        rx_prestate <= STATE_LBUS_RX_ENABLE;
                end
                default : begin
                    gt_lock_led           <= 1'b0;
                    rx_aligned_led_c      <= 1'b0;
                    rx_core_busy_led      <= 1'b0;
                    ctl_rx_enable_r       <= 1'b0;
                    ctl_rx_force_resync_r <= 1'b0;
                    ctl_rx_test_pattern_r <= 1'b0;
                    rx_prestate           <= STATE_RX_IDLE;
                end
            endcase
        end
    end

    //////////////////////////////////////////////////
    ////rx_done_reg signal generation
    //////////////////////////////////////////////////
    always @( posedge clk ) begin
        rx_done_reg <= 1'b0; // Always accepting data.
    end



    //////////////////////////////////////////////////
    ////Assign RX LED Output ports with ASYN sys_reset
    //////////////////////////////////////////////////
    always @( posedge clk, posedge sys_reset  )begin
        if ( sys_reset == 1'b1 ) begin
            rx_gt_locked_led <= 1'b0;
            rx_aligned_led   <= 1'b0;
            rx_done_led      <= 1'b0;
            rx_data_fail_led <= 1'b0;
            rx_busy_led      <= 1'b0;
        end
        else begin
            rx_gt_locked_led <= rx_gt_locked_led_3d;
            rx_aligned_led   <= stat_rx_aligned_led_3d;
            rx_done_led      <= rx_done_led_3d;
            rx_data_fail_led <= 1'b0;
            rx_busy_led      <= rx_core_busy_led_3d;
        end
    end

    //////////////////////////////////////////////////
    ////Registering the LED ports
    //////////////////////////////////////////////////
    always @( posedge clk ) begin
        if ( reset == 1'b1 ) begin
            rx_gt_locked_led_1d    <= 1'b0;
            rx_gt_locked_led_2d    <= 1'b0;
            rx_gt_locked_led_3d    <= 1'b0;
            stat_rx_aligned_led_1d <= 1'b0;
            stat_rx_aligned_led_2d <= 1'b0;
            stat_rx_aligned_led_3d <= 1'b0;
            rx_done_led_1d         <= 1'b0;
            rx_done_led_2d         <= 1'b0;
            rx_done_led_3d         <= 1'b0;
            rx_core_busy_led_1d    <= 1'b0;
            rx_core_busy_led_2d    <= 1'b0;
            rx_core_busy_led_3d    <= 1'b0;
        end
        else begin
            rx_gt_locked_led_1d    <= gt_lock_led;
            rx_gt_locked_led_2d    <= rx_gt_locked_led_1d;
            rx_gt_locked_led_3d    <= rx_gt_locked_led_2d;
            stat_rx_aligned_led_1d <= rx_aligned_led_c;
            stat_rx_aligned_led_2d <= stat_rx_aligned_led_1d;
            stat_rx_aligned_led_3d <= stat_rx_aligned_led_2d;
            rx_done_led_1d         <= rx_done_reg;
            rx_done_led_2d         <= rx_done_led_1d;
            rx_done_led_3d         <= rx_done_led_2d;
            rx_core_busy_led_1d    <= rx_core_busy_led;
            rx_core_busy_led_2d    <= rx_core_busy_led_1d;
            rx_core_busy_led_3d    <= rx_core_busy_led_2d;
        end
    end



    assign ctl_rx_enable       = ctl_rx_enable_r;
    assign ctl_rx_force_resync = ctl_rx_force_resync_r;
    assign ctl_rx_test_pattern = ctl_rx_test_pattern_r;
    ////----------------------------------------END RX Module-----------------------//

endmodule


