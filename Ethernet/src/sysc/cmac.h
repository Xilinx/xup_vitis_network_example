// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#include "xtlm.h"
#include "xtlm_ap_ctrl.h"
#include "ipc2axis_socket.h"
#include "axis2ipc_socket.h"

#define cfgaddr_gt_reset_reg 0x0000
#define cfgaddr_reset_reg 0x0004
#define cfgaddr_mode 0x0008
#define cfgaddr_conf_tx 0x000C
#define cfgaddr_conf_rx 0x0014
#define cfgaddr_core_mode 0x0020
#define cfgaddr_version 0x0024
#define cfgaddr_gt_loopback 0x0090
#define cfgaddr_user_reg0 0x00CC
#define cfgaddr_stat_tx_status 0x0200
#define cfgaddr_stat_rx_status 0x0204
#define cfgaddr_stat_status 0x0208
#define cfgaddr_stat_rx_block_lock 0x020C
#define cfgaddr_stat_rx_lane_sync 0x0210
#define cfgaddr_stat_rx_lane_sync_err 0x0214
#define cfgaddr_stat_an_link_ctl 0x0260
#define cfgaddr_stat_lt_status 0x0264
#define cfgaddr_stat_pm_tick 0x02B0
#define cfgaddr_stat_cycle_count 0x02B8
#define cfgaddr_stat_tx_total_packets 0x0500
#define cfgaddr_stat_tx_total_good_packets 0x0508
#define cfgaddr_stat_tx_total_bytes 0x0510
#define cfgaddr_stat_tx_total_good_bytes 0x0518
#define cfgaddr_stat_tx_total_packets_64B 0x0520
#define cfgaddr_stat_tx_total_packets_65_127B 0x0528
#define cfgaddr_stat_tx_total_packets_128_255B 0x0530
#define cfgaddr_stat_tx_total_packets_256_511B 0x0538
#define cfgaddr_stat_tx_total_packets_512_1023B 0x0540
#define cfgaddr_stat_tx_total_packets_1024_1518B 0x0548
#define cfgaddr_stat_tx_total_packets_1519_1522B 0x0550
#define cfgaddr_stat_tx_total_packets_1523_1548B 0x0558
#define cfgaddr_stat_tx_total_packets_1549_2047B 0x0560
#define cfgaddr_stat_tx_total_packets_2048_4095B 0x0568
#define cfgaddr_stat_tx_total_packets_4096_8191B 0x0570
#define cfgaddr_stat_tx_total_packets_8192_9215B 0x0578
#define cfgaddr_stat_tx_total_packets_large 0x0580
#define cfgaddr_stat_tx_total_packets_small 0x0588
#define cfgaddr_stat_tx_total_bad_fcs 0x05B8
#define cfgaddr_stat_tx_pause 0x05F0
#define cfgaddr_stat_tx_user_pause 0x05F8
#define cfgaddr_stat_rx_total_packets 0x0608
#define cfgaddr_stat_rx_total_good_packets 0x0610
#define cfgaddr_stat_rx_total_bytes 0x0618
#define cfgaddr_stat_rx_total_good_bytes 0x0620
#define cfgaddr_stat_rx_total_packets_64B 0x0628
#define cfgaddr_stat_rx_total_packets_65_127B 0x0630
#define cfgaddr_stat_rx_total_packets_128_255B 0x0638
#define cfgaddr_stat_rx_total_packets_256_511B 0x0640
#define cfgaddr_stat_rx_total_packets_512_1023B 0x0648
#define cfgaddr_stat_rx_total_packets_1024_1518B 0x0650
#define cfgaddr_stat_rx_total_packets_1519_1522B 0x0658
#define cfgaddr_stat_rx_total_packets_1523_1548B 0x0660
#define cfgaddr_stat_rx_total_packets_1549_2047B 0x0668
#define cfgaddr_stat_rx_total_packets_2048_4095B 0x0670
#define cfgaddr_stat_rx_total_packets_4096_8191B 0x0678
#define cfgaddr_stat_rx_total_packets_8192_9215B 0x0680
#define cfgaddr_stat_rx_total_packets_large 0x0688
#define cfgaddr_stat_rx_total_packets_small 0x0690
#define cfgaddr_stat_rx_total_packets_undersize 0x0698
#define cfgaddr_stat_rx_total_packets_fragmented 0x06A0
#define cfgaddr_stat_rx_total_packets_oversize 0x06A8
#define cfgaddr_stat_rx_total_packets_toolong 0x06B0
#define cfgaddr_stat_rx_total_packets_jabber 0x06B8
#define cfgaddr_stat_rx_total_bad_fcs 0x06C0
#define cfgaddr_stat_rx_packets_bad_fcs 0x06C8
#define cfgaddr_stat_rx_stomped_fcs 0x06D0
#define cfgaddr_stat_rx_pause 0x06F8
#define cfgaddr_stat_rx_user_pause 0x0700
#define cfgaddr_rsfec_config_ind_corr 0x1000
#define cfgaddr_rsfec_config_enable 0x107C

#define PADDING_NONE 0
#define PADDING_60B 1
#define PADDING_64B 2

class cmac : public xsc::xtlm_ap_ctrl_none {
    enum {
        REG_MEM_SIZE = 8192
    };
    public:
        SC_HAS_PROCESS(cmac);
        cmac(sc_module_name name, xsc::common_cpp::properties& _properties);
        ~cmac();

        //! Declare interfaces..
        xtlm::xtlm_aximm_target_socket* S_AXILITE_rd_socket;
        xtlm::xtlm_aximm_target_socket* S_AXILITE_wr_socket;

        xtlm::xtlm_axis_target_socket *S_AXIS_socket;
        xtlm::xtlm_axis_target_socket_util *S_AXIS_util;
        xtlm::xtlm_axis_initiator_socket *M_AXIS_socket;
        xtlm::xtlm_axis_initiator_socket_util *M_AXIS_util;

        // Declare interface-independent dummy ports
        sc_in<bool> clk_gt_freerun;
        sc_in<sc_bv<4> > gt_rxp_in;
        sc_in<sc_bv<4> > gt_rxn_in;
        sc_out<sc_bv<4> > gt_txp_out;
        sc_out<sc_bv<4> > gt_txn_out;
    private:
    	xsc::ipc2axis_socket *ipc2axis_socket;
    	xsc::axis2ipc_socket *axis2ipc_socket;
        void ipc2axis_receive();
        void axis2ipc_send();
	    void send_response();
        std::string get_ipi_name(std::string s);
        sc_core::sc_event trigger_till_sock_connected; 
        unsigned int stream_width_bytes;

        void kernel_config_write();
        void kernel_status_read();

        unsigned int padding_mode;
        bool loopback;

        //axilite memory and args overlapped onto it
        unsigned char reg_mem[REG_MEM_SIZE];

        xtlm::xtlm_aximm_target_wr_socket_util*  S_AXILITE_wr_util;
        xtlm::xtlm_aximm_target_rd_socket_util*  S_AXILITE_rd_util;

        void log(std::string msg);
};