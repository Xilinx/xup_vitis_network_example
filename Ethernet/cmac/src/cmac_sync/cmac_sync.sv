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


`timescale 1ps/1ps
`default_nettype wire


module cmac_sync (
    input                gen_mon_clk          ,
    input                usr_tx_reset         ,
    input                usr_rx_reset         ,
    input                sys_reset            ,
    //// User Interface signals
    input                lbus_tx_rx_restart_in,
    stat_t.slave         cmac_stat            ,
    // Leds
    output logic         tx_done_led          ,
    output logic         tx_busy_led          ,
    output logic         rx_gt_locked_led     ,
    output logic         rx_aligned_led       ,
    output logic         rx_done_led          ,
    output logic         rx_data_fail_led     ,
    output logic         rx_busy_led
);


    // Sync mechanism
    rx_sync rx_sync_i (
        .clk                  (gen_mon_clk              ),
        .reset                (usr_rx_reset             ),
        .sys_reset            (sys_reset                ),
        
        .stat_rx_aligned      (cmac_stat.stat_rx_aligned),
        .ctl_rx_enable        (                         ),
        .ctl_rx_force_resync  (                         ),
        .ctl_rx_test_pattern  (                         ),
        .rx_gt_locked_led     (rx_gt_locked_led         ),
        .rx_aligned_led       (rx_aligned_led           ),
        .rx_done_led          (rx_done_led              ),
        .rx_data_fail_led     (rx_data_fail_led         ),
        .rx_busy_led          (rx_busy_led              )
    );


    tx_sync tx_sync_i (
        .clk                  (gen_mon_clk              ),
        .reset                (usr_tx_reset             ),
        .sys_reset            (sys_reset                ),
        
        .stat_rx_aligned      (cmac_stat.stat_rx_aligned),
        .lbus_tx_rx_restart_in(lbus_tx_rx_restart_in    ),
        .ctl_tx_enable        (                         ),
        .ctl_tx_send_idle     (                         ),
        .ctl_tx_send_rfi      (                         ),
        .ctl_tx_test_pattern  (                         ),
        
        .tx_done_led          (tx_done_led              ),
        .tx_busy_led          (tx_busy_led              )
    );

endmodule

