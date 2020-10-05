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

module cmac_wrapper (
    input wire                    CLK                   ,
    input wire                    refclk_p              ,
    input wire                    refclk_n              ,
    input wire                    RST_N                 ,
    gt_drp_t.master               cmac_drp              ,
    rx_timestamp_t.master         rx_timestamp          ,
    transceiver_ports_t.master    cmac_transceiver_ports,
    lbus_tx_t.slave               cmac_lbus_tx          ,
    lbus_rx_t.master              cmac_lbus_rx          ,
    stat_t.master                 cmac_stat             ,
    axi4_lite.slave               axi4_stat             ,
    input wire                    axi_pm_tick
);


    wire [127:0] cmac_lbus_rx_data_0_w;
    wire [127:0] cmac_lbus_rx_data_1_w;
    wire [127:0] cmac_lbus_rx_data_2_w;
    wire [127:0] cmac_lbus_rx_data_3_w;
    wire         cmac_lbus_rx_en_0_w  ;
    wire         cmac_lbus_rx_en_1_w  ;
    wire         cmac_lbus_rx_en_2_w  ;
    wire         cmac_lbus_rx_en_3_w  ;
    wire         cmac_lbus_rx_eop_0_w ;
    wire         cmac_lbus_rx_eop_1_w ;
    wire         cmac_lbus_rx_eop_2_w ;
    wire         cmac_lbus_rx_eop_3_w ;
    wire         cmac_lbus_rx_err_0_w ;
    wire         cmac_lbus_rx_err_1_w ;
    wire         cmac_lbus_rx_err_2_w ;
    wire         cmac_lbus_rx_err_3_w ;
    wire [  3:0] cmac_lbus_rx_mty_0_w ;
    wire [  3:0] cmac_lbus_rx_mty_1_w ;
    wire [  3:0] cmac_lbus_rx_mty_2_w ;
    wire [  3:0] cmac_lbus_rx_mty_3_w ;
    wire         cmac_lbus_rx_sop_0_w ;
    wire         cmac_lbus_rx_sop_1_w ;
    wire         cmac_lbus_rx_sop_2_w ;
    wire         cmac_lbus_rx_sop_3_w ;
    wire         usr_rx_reset_w;
    wire         core_tx_reset_w;
    reg          usr_rx_reset_r;
    reg          core_tx_reset_r;

    integer i;


    assign cmac_lbus_rx.data[0] = cmac_lbus_rx_data_0_w;
    assign cmac_lbus_rx.data[1] = cmac_lbus_rx_data_1_w;
    assign cmac_lbus_rx.data[2] = cmac_lbus_rx_data_2_w;
    assign cmac_lbus_rx.data[3] = cmac_lbus_rx_data_3_w;
    assign cmac_lbus_rx.en[0]   = cmac_lbus_rx_en_0_w;
    assign cmac_lbus_rx.en[1]   = cmac_lbus_rx_en_1_w;
    assign cmac_lbus_rx.en[2]   = cmac_lbus_rx_en_2_w;
    assign cmac_lbus_rx.en[3]   = cmac_lbus_rx_en_3_w;
    assign cmac_lbus_rx.eop[0]  = cmac_lbus_rx_eop_0_w;
    assign cmac_lbus_rx.eop[1]  = cmac_lbus_rx_eop_1_w;
    assign cmac_lbus_rx.eop[2]  = cmac_lbus_rx_eop_2_w;
    assign cmac_lbus_rx.eop[3]  = cmac_lbus_rx_eop_3_w;
    assign cmac_lbus_rx.err[0]  = cmac_lbus_rx_err_0_w;
    assign cmac_lbus_rx.err[1]  = cmac_lbus_rx_err_1_w;
    assign cmac_lbus_rx.err[2]  = cmac_lbus_rx_err_2_w;
    assign cmac_lbus_rx.err[3]  = cmac_lbus_rx_err_3_w;
    assign cmac_lbus_rx.mty[0]  = cmac_lbus_rx_mty_0_w;
    assign cmac_lbus_rx.mty[1]  = cmac_lbus_rx_mty_1_w;
    assign cmac_lbus_rx.mty[2]  = cmac_lbus_rx_mty_2_w;
    assign cmac_lbus_rx.mty[3]  = cmac_lbus_rx_mty_3_w;
    assign cmac_lbus_rx.sop[0]  = cmac_lbus_rx_sop_0_w;
    assign cmac_lbus_rx.sop[1]  = cmac_lbus_rx_sop_1_w;
    assign cmac_lbus_rx.sop[2]  = cmac_lbus_rx_sop_2_w;
    assign cmac_lbus_rx.sop[3]  = cmac_lbus_rx_sop_3_w;

    assign rx_timestamp.rx_ptp_tstamp_corrected       = 1'b0;
    assign rx_timestamp.rx_ptp_pcslane_out_int        = 4'b0;
    assign rx_timestamp.rx_ptp_tstamp_corrected_valid = 80'b0;

    assign cmac_lbus_rx.user_clk   = cmac_drp.gt_rxusrclk2;

    always @( posedge cmac_drp.gt_rxusrclk2 ) begin
        usr_rx_reset_r  <= usr_rx_reset_w;
    end

    always @( posedge cmac_drp.gt_txusrclk2 ) begin
        core_tx_reset_r <= core_tx_reset_w;
    end

    assign cmac_lbus_rx.user_rst_o = usr_rx_reset_r;

    assign cmac_lbus_tx.user_rst_o = core_tx_reset_r;

    cmac_uplus_0 cmac_i (
         

        .gt_rxp_in                    (cmac_transceiver_ports.rxp         ), // input  wire [3:0] gt_rxp_in
        .gt_rxn_in                    (cmac_transceiver_ports.rxn         ), // input  wire [3:0] gt_rxn_in
        .gt_txp_out                   (cmac_transceiver_ports.txp         ), // output wire [3:0] gt_txp_out
        .gt_txn_out                   (cmac_transceiver_ports.txn         ), // output wire [3:0] gt_txn_out
        
         /*   
        .gt0_rxp_in                    (cmac_transceiver_ports.rxp[0]      ),// input wire gt0_rxp_in
        .gt1_rxp_in                    (cmac_transceiver_ports.rxp[1]      ),// input wire gt1_rxp_in
        .gt2_rxp_in                    (cmac_transceiver_ports.rxp[2]      ),// input wire gt2_rxp_in
        .gt3_rxp_in                    (cmac_transceiver_ports.rxp[3]      ),// input wire gt3_rxp_in
        .gt0_rxn_in                    (cmac_transceiver_ports.rxn[0]      ),// input wire gt0_rxn_in
        .gt1_rxn_in                    (cmac_transceiver_ports.rxn[1]      ),// input wire gt1_rxn_in
        .gt2_rxn_in                    (cmac_transceiver_ports.rxn[2]      ),// input wire gt2_rxn_in
        .gt3_rxn_in                    (cmac_transceiver_ports.rxn[3]      ),// input wire gt3_rxn_in
        
        .gt0_txp_out                   (cmac_transceiver_ports.txp[0]      ),// output wire gt0_txp_out
        .gt1_txp_out                   (cmac_transceiver_ports.txp[1]      ),// output wire gt1_txp_out
        .gt2_txp_out                   (cmac_transceiver_ports.txp[2]      ),// output wire gt2_txp_out
        .gt3_txp_out                   (cmac_transceiver_ports.txp[3]      ),// output wire gt3_txp_out
        .gt0_txn_out                   (cmac_transceiver_ports.txn[0]      ),// output wire gt0_txn_out
        .gt1_txn_out                   (cmac_transceiver_ports.txn[1]      ),// output wire gt1_txn_out
        .gt2_txn_out                   (cmac_transceiver_ports.txn[2]      ),// output wire gt2_txn_out
        .gt3_txn_out                   (cmac_transceiver_ports.txn[3]      ),// output wire gt3_txn_out
        */

        .gt_txusrclk2                  (cmac_drp.gt_txusrclk2              ),
        .gt_loopback_in                (cmac_drp.gt_loopback_in            ),
        .gt_rxrecclkout                (cmac_drp.gt_rxrecclkout            ),
        
        .sys_reset                     (!RST_N                             ),
        .gtwiz_reset_tx_datapath       (!RST_N                             ),
        .gtwiz_reset_rx_datapath       (!RST_N                             ),
        
        .gt_ref_clk_p                  (refclk_p                           ),
        .gt_ref_clk_n                  (refclk_n                           ),
        .init_clk                      (CLK                                ),
        .rx_dataout0                   (cmac_lbus_rx_data_0_w              ),
        .rx_dataout1                   (cmac_lbus_rx_data_1_w              ),
        .rx_dataout2                   (cmac_lbus_rx_data_2_w              ),
        .rx_dataout3                   (cmac_lbus_rx_data_3_w              ),
        .rx_enaout0                    (cmac_lbus_rx_en_0_w                ),
        .rx_enaout1                    (cmac_lbus_rx_en_1_w                ),
        .rx_enaout2                    (cmac_lbus_rx_en_2_w                ),
        .rx_enaout3                    (cmac_lbus_rx_en_3_w                ),
        .rx_eopout0                    (cmac_lbus_rx_eop_0_w               ),
        .rx_eopout1                    (cmac_lbus_rx_eop_1_w               ),
        .rx_eopout2                    (cmac_lbus_rx_eop_2_w               ),
        .rx_eopout3                    (cmac_lbus_rx_eop_3_w               ),
        .rx_errout0                    (cmac_lbus_rx_err_0_w               ),
        .rx_errout1                    (cmac_lbus_rx_err_1_w               ),
        .rx_errout2                    (cmac_lbus_rx_err_2_w               ),
        .rx_errout3                    (cmac_lbus_rx_err_3_w               ),
        .rx_mtyout0                    (cmac_lbus_rx_mty_0_w               ),
        .rx_mtyout1                    (cmac_lbus_rx_mty_1_w               ),
        .rx_mtyout2                    (cmac_lbus_rx_mty_2_w               ),
        .rx_mtyout3                    (cmac_lbus_rx_mty_3_w               ),
        .rx_sopout0                    (cmac_lbus_rx_sop_0_w               ),
        .rx_sopout1                    (cmac_lbus_rx_sop_1_w               ),
        .rx_sopout2                    (cmac_lbus_rx_sop_2_w               ),
        .rx_sopout3                    (cmac_lbus_rx_sop_3_w               ),
        .usr_rx_reset                  (usr_rx_reset_w                     ),
        
        .gt_rxusrclk2                  (cmac_drp.gt_rxusrclk2              ),
        
        .stat_rx_aligned               (cmac_stat.stat_rx_aligned          ),
        .stat_rx_aligned_err           (                                   ),
        .stat_rx_bad_code              (                                   ),
        .stat_rx_bad_fcs               (                                   ),
        .stat_rx_bad_preamble          (                                   ),
        .stat_rx_bad_sfd               (                                   ),
        .stat_rx_bip_err_0             (                                   ),
        .stat_rx_bip_err_1             (                                   ),
        .stat_rx_bip_err_10            (                                   ),
        .stat_rx_bip_err_11            (                                   ),
        .stat_rx_bip_err_12            (                                   ),
        .stat_rx_bip_err_13            (                                   ),
        .stat_rx_bip_err_14            (                                   ),
        .stat_rx_bip_err_15            (                                   ),
        .stat_rx_bip_err_16            (                                   ),
        .stat_rx_bip_err_17            (                                   ),
        .stat_rx_bip_err_18            (                                   ),
        .stat_rx_bip_err_19            (                                   ),
        .stat_rx_bip_err_2             (                                   ),
        .stat_rx_bip_err_3             (                                   ),
        .stat_rx_bip_err_4             (                                   ),
        .stat_rx_bip_err_5             (                                   ),
        .stat_rx_bip_err_6             (                                   ),
        .stat_rx_bip_err_7             (                                   ),
        .stat_rx_bip_err_8             (                                   ),
        .stat_rx_bip_err_9             (                                   ),
        .stat_rx_block_lock            (                                   ),
        .stat_rx_broadcast             (                                   ),
        .stat_rx_fragment              (                                   ),
        .stat_rx_framing_err_0         (                                   ),
        .stat_rx_framing_err_1         (                                   ),
        .stat_rx_framing_err_10        (                                   ),
        .stat_rx_framing_err_11        (                                   ),
        .stat_rx_framing_err_12        (                                   ),
        .stat_rx_framing_err_13        (                                   ),
        .stat_rx_framing_err_14        (                                   ),
        .stat_rx_framing_err_15        (                                   ),
        .stat_rx_framing_err_16        (                                   ),
        .stat_rx_framing_err_17        (                                   ),
        .stat_rx_framing_err_18        (                                   ),
        .stat_rx_framing_err_19        (                                   ),
        .stat_rx_framing_err_2         (                                   ),
        .stat_rx_framing_err_3         (                                   ),
        .stat_rx_framing_err_4         (                                   ),
        .stat_rx_framing_err_5         (                                   ),
        .stat_rx_framing_err_6         (                                   ),
        .stat_rx_framing_err_7         (                                   ),
        .stat_rx_framing_err_8         (                                   ),
        .stat_rx_framing_err_9         (                                   ),
        .stat_rx_framing_err_valid_0   (                                   ),
        .stat_rx_framing_err_valid_1   (                                   ),
        .stat_rx_framing_err_valid_10  (                                   ),
        .stat_rx_framing_err_valid_11  (                                   ),
        .stat_rx_framing_err_valid_12  (                                   ),
        .stat_rx_framing_err_valid_13  (                                   ),
        .stat_rx_framing_err_valid_14  (                                   ),
        .stat_rx_framing_err_valid_15  (                                   ),
        .stat_rx_framing_err_valid_16  (                                   ),
        .stat_rx_framing_err_valid_17  (                                   ),
        .stat_rx_framing_err_valid_18  (                                   ),
        .stat_rx_framing_err_valid_19  (                                   ),
        .stat_rx_framing_err_valid_2   (                                   ),
        .stat_rx_framing_err_valid_3   (                                   ),
        .stat_rx_framing_err_valid_4   (                                   ),
        .stat_rx_framing_err_valid_5   (                                   ),
        .stat_rx_framing_err_valid_6   (                                   ),
        .stat_rx_framing_err_valid_7   (                                   ),
        .stat_rx_framing_err_valid_8   (                                   ),
        .stat_rx_framing_err_valid_9   (                                   ),
        .stat_rx_got_signal_os         (                                   ),
        .stat_rx_hi_ber                (                                   ),
        .stat_rx_inrangeerr            (                                   ),
        .stat_rx_internal_local_fault  (                                   ),
        .stat_rx_jabber                (                                   ),
        .stat_rx_local_fault           (                                   ),
        .stat_rx_mf_err                (                                   ),
        .stat_rx_mf_len_err            (                                   ),
        .stat_rx_mf_repeat_err         (                                   ),
        .stat_rx_misaligned            (                                   ),
        .stat_rx_multicast             (                                   ),
        .stat_rx_oversize              (                                   ),
        .stat_rx_packet_1024_1518_bytes(                                   ),
        .stat_rx_packet_128_255_bytes  (                                   ),
        .stat_rx_packet_1519_1522_bytes(                                   ),
        .stat_rx_packet_1523_1548_bytes(                                   ),
        .stat_rx_packet_1549_2047_bytes(                                   ),
        .stat_rx_packet_2048_4095_bytes(                                   ),
        .stat_rx_packet_256_511_bytes  (                                   ),
        .stat_rx_packet_4096_8191_bytes(                                   ),
        .stat_rx_packet_512_1023_bytes (                                   ),
        .stat_rx_packet_64_bytes       (                                   ),
        .stat_rx_packet_65_127_bytes   (                                   ),
        .stat_rx_packet_8192_9215_bytes(                                   ),
        .stat_rx_packet_bad_fcs        (                                   ),
        .stat_rx_packet_large          (                                   ),
        .stat_rx_packet_small          (                                   ),
        .core_rx_reset                 (cmac_lbus_rx.user_rst_i            ),
        .rx_clk                        (cmac_lbus_rx.user_clk              ),
        .stat_rx_received_local_fault  (                                   ),
        .stat_rx_remote_fault          (                                   ),
        .stat_rx_status                (                                   ),
        .stat_rx_stomped_fcs           (                                   ),
        .stat_rx_synced                (                                   ),
        .stat_rx_synced_err            (                                   ),
        .stat_rx_test_pattern_mismatch (                                   ),
        .stat_rx_toolong               (                                   ),
        .stat_rx_total_bytes           (                                   ),
        .stat_rx_total_good_bytes      (                                   ),
        .stat_rx_total_good_packets    (                                   ),
        .stat_rx_total_packets         (                                   ),
        .stat_rx_truncated             (                                   ),
        .stat_rx_undersize             (                                   ),
        .stat_rx_unicast               (                                   ),
        .stat_rx_vlan                  (                                   ),
        .stat_rx_pcsl_demuxed          (                                   ),
        .stat_rx_pcsl_number_0         (                                   ),
        .stat_rx_pcsl_number_1         (                                   ),
        .stat_rx_pcsl_number_10        (                                   ),
        .stat_rx_pcsl_number_11        (                                   ),
        .stat_rx_pcsl_number_12        (                                   ),
        .stat_rx_pcsl_number_13        (                                   ),
        .stat_rx_pcsl_number_14        (                                   ),
        .stat_rx_pcsl_number_15        (                                   ),
        .stat_rx_pcsl_number_16        (                                   ),
        .stat_rx_pcsl_number_17        (                                   ),
        .stat_rx_pcsl_number_18        (                                   ),
        .stat_rx_pcsl_number_19        (                                   ),
        .stat_rx_pcsl_number_2         (                                   ),
        .stat_rx_pcsl_number_3         (                                   ),
        .stat_rx_pcsl_number_4         (                                   ),
        .stat_rx_pcsl_number_5         (                                   ),
        .stat_rx_pcsl_number_6         (                                   ),
        .stat_rx_pcsl_number_7         (                                   ),
        .stat_rx_pcsl_number_8         (                                   ),
        .stat_rx_pcsl_number_9         (                                   ),
        
        .stat_tx_bad_fcs               (                                   ),
        .stat_tx_broadcast             (                                   ),
        .stat_tx_frame_error           (                                   ),
        .stat_tx_local_fault           (                                   ),
        .stat_tx_multicast             (                                   ),
        .stat_tx_packet_1024_1518_bytes(                                   ),
        .stat_tx_packet_128_255_bytes  (                                   ),
        .stat_tx_packet_1519_1522_bytes(                                   ),
        .stat_tx_packet_1523_1548_bytes(                                   ),
        .stat_tx_packet_1549_2047_bytes(                                   ),
        .stat_tx_packet_2048_4095_bytes(                                   ),
        .stat_tx_packet_256_511_bytes  (                                   ),
        .stat_tx_packet_4096_8191_bytes(                                   ),
        .stat_tx_packet_512_1023_bytes (                                   ),
        .stat_tx_packet_64_bytes       (                                   ),
        .stat_tx_packet_65_127_bytes   (                                   ),
        .stat_tx_packet_8192_9215_bytes(                                   ),
        .stat_tx_packet_large          (                                   ),
        .stat_tx_packet_small          (                                   ),
        .stat_tx_total_bytes           (                                   ),
        .stat_tx_total_good_bytes      (                                   ),
        .stat_tx_total_good_packets    (                                   ),
        .stat_tx_total_packets         (                                   ),
        .stat_tx_unicast               (                                   ),
        .stat_tx_vlan                  (                                   ),
        .core_tx_reset                 (cmac_lbus_tx.user_rst_i            ),

        .tx_ovfout                     (cmac_lbus_tx.ovf                   ),
        .tx_rdyout                     (cmac_lbus_tx.rdy                   ),
        .tx_unfout                     (cmac_lbus_tx.unf                   ),
        .tx_datain0                    (cmac_lbus_tx.data[0]               ),
        .tx_datain1                    (cmac_lbus_tx.data[1]               ),
        .tx_datain2                    (cmac_lbus_tx.data[2]               ),
        .tx_datain3                    (cmac_lbus_tx.data[3]               ),
        .tx_enain0                     (cmac_lbus_tx.en[0]                 ),
        .tx_enain1                     (cmac_lbus_tx.en[1]                 ),
        .tx_enain2                     (cmac_lbus_tx.en[2]                 ),
        .tx_enain3                     (cmac_lbus_tx.en[3]                 ),
        .tx_eopin0                     (cmac_lbus_tx.eop[0]                ),
        .tx_eopin1                     (cmac_lbus_tx.eop[1]                ),
        .tx_eopin2                     (cmac_lbus_tx.eop[2]                ),
        .tx_eopin3                     (cmac_lbus_tx.eop[3]                ),
        .tx_errin0                     (cmac_lbus_tx.err[0]                ),
        .tx_errin1                     (cmac_lbus_tx.err[1]                ),
        .tx_errin2                     (cmac_lbus_tx.err[2]                ),
        .tx_errin3                     (cmac_lbus_tx.err[3]                ),
        .tx_mtyin0                     (cmac_lbus_tx.mty[0]                ),
        .tx_mtyin1                     (cmac_lbus_tx.mty[1]                ),
        .tx_mtyin2                     (cmac_lbus_tx.mty[2]                ),
        .tx_mtyin3                     (cmac_lbus_tx.mty[3]                ),
        .tx_sopin0                     (cmac_lbus_tx.sop[0]                ),
        .tx_sopin1                     (cmac_lbus_tx.sop[1]                ),
        .tx_sopin2                     (cmac_lbus_tx.sop[2]                ),
        .tx_sopin3                     (cmac_lbus_tx.sop[3]                ),
        
        .usr_tx_reset                  (core_tx_reset_w                    ),
        
        .core_drp_reset                (1'b0                               ),
        .drp_clk                       (1'b0                               ),
        .drp_addr                      (10'b0                              ),
        .drp_di                        (16'b0                              ),
        .drp_en                        (1'b0                               ),
        .drp_do                        (                                   ),
        .drp_rdy                       (                                   ),
        .drp_we                        (1'b0                               ),
        .s_axi_aclk                    (CLK                                ),
        .s_axi_sreset                  (!RST_N                             ),
        .pm_tick                       (axi_pm_tick                        ),
        .s_axi_awaddr                  ({21'h0, axi4_stat.axi_awaddr[10:0]}),
        .s_axi_awvalid                 (axi4_stat.axi_awvalid              ),
        .s_axi_awready                 (axi4_stat.axi_awready              ),
        .s_axi_wdata                   (axi4_stat.axi_wdata                ),
        .s_axi_wstrb                   (axi4_stat.axi_wstrb                ),
        .s_axi_wvalid                  (axi4_stat.axi_wvalid               ),
        .s_axi_wready                  (axi4_stat.axi_wready               ),
        .s_axi_bresp                   (axi4_stat.axi_bresp                ),
        .s_axi_bvalid                  (axi4_stat.axi_bvalid               ),
        .s_axi_bready                  (axi4_stat.axi_bready               ),
        .s_axi_araddr                  ({21'h0, axi4_stat.axi_araddr[10:0]}),
        .s_axi_arvalid                 (axi4_stat.axi_arvalid              ),
        .s_axi_arready                 (axi4_stat.axi_arready              ),
        .s_axi_rdata                   (axi4_stat.axi_rdata                ),
        .s_axi_rresp                   (axi4_stat.axi_rresp                ),
        .s_axi_rvalid                  (axi4_stat.axi_rvalid               ),
        .s_axi_rready                  (axi4_stat.axi_rready               ),


        .rx_otn_bip8_0                 (                                   ),
        .rx_otn_bip8_1                 (                                   ),
        .rx_otn_bip8_2                 (                                   ),
        .rx_otn_bip8_3                 (                                   ),
        .rx_otn_bip8_4                 (                                   ),
        .rx_otn_data_0                 (                                   ),
        .rx_otn_data_1                 (                                   ),
        .rx_otn_data_2                 (                                   ),
        .rx_otn_data_3                 (                                   ),
        .rx_otn_data_4                 (                                   ),
        .rx_otn_ena                    (                                   ),
        .rx_otn_lane0                  (                                   ),
        .rx_otn_vlmarker               (                                   ),

        .rx_preambleout                (                                   ),
        .tx_preamblein                 (                    {55{1'b0}}     ),

        .gt_ref_clk_out                (                                   ),
        .gt_powergoodout               (                                   )
    );

endmodule