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

`ifndef TYPES_SVH_
`define TYPES_SVH_



parameter C_CAUI_4_SERDES_NUMBER  = 32'h4 ;
parameter C_CAUI_10_SERDES_NUMBER = 32'd10;
parameter C_TRANSMISSION_SEGMENTS = 32'd4 ;




/**
* @brief UltraScale Device 100G Ethernet Core Transceiver Ports
*/
interface transceiver_ports_t # (parameter LANES = 10);
    logic [LANES-1:0] rxn;
    logic [LANES-1:0] rxp;
    logic [LANES-1:0] txn;
    logic [LANES-1:0] txp;

    modport master(input rxn, rxp, output txn, txp);
endinterface


interface lbus_rx_t;
    /**
    * The value of
    * this bus is only valid in cycles that RX_ENAOUT0 is
    * sampled as 1
    */
    logic [127:0] data[C_TRANSMISSION_SEGMENTS-1:0]; // t_data

    /**
    * This signal qualifies
    * the other signals of the RX segmented LBUS Interface.
    * Signals of the RX LBUS Interface are only valid in cycles
    * in which RX_ENAOUT is sampled as a 1
    */
    logic [C_TRANSMISSION_SEGMENTS-1:0] en; // t_valid

    /**
    * This signal
    * indicates the Start Of Packet (SOP) when it is sampled as
    * a 1 and is only valid in cycles in which RX_ENAOUT is
    * sampled as a 1.
    */
    logic [C_TRANSMISSION_SEGMENTS-1:0] sop; // Start of packet

    /**
    * This signal
    * indicates the End Of Packet (EOP) when it is sampled as
    * a 1 and is only valid in cycles in which RX_ENAOUT is
    * sampled as a 1.
    */
    logic [C_TRANSMISSION_SEGMENTS-1:0] eop; // End of packet

    /**
    * This signal indicates
    * that the current packet being received has an error
    * when it is sampled as a 1. This signal is only valid in
    * cycles when both RX_ENAOUT and RX_EOPOUT are
    * sampled as a 1. When this signal is a value of 0, it
    * indicates that there is no error in the packet being
    * received.
    */
    logic [C_TRANSMISSION_SEGMENTS-1:0] err; // Error in packet

    /**
    * This bus indicates
    * how many bytes of the RX_DATAOUT bus are empty or
    * invalid for the last transfer of the current packet. This
    * bus is only valid in cycles when both RX_ENAOUT and
    * RX_EOPOUT are sampled as 1. When RX_ERROUT and
    * RX_ENAOUT are sampled as 1, the value of
    * RX_MTYOUT[3:0] is always 000. Other bits of
    * RX_MTYOUT are as usual.
    */
    logic [3:0] mty       [C_TRANSMISSION_SEGMENTS-1:0];
    logic       user_rst_o                             ;
    logic       user_rst_i                             ;
    logic       user_clk                               ;

    modport master (input user_rst_i, output user_rst_o, user_clk, data, en, sop, eop, err, mty);
    modport slave (output user_rst_i, input user_rst_o, user_clk, data, en, sop, eop, err, mty); 
endinterface


interface lbus_tx_t;
    /**
    * Transmit segmented LBUS Data for segment0. This bus
    * receives input data from the user logic. The value of the
    * bus is captured in every cycle that TX_ENAIN is
    * sampled as 1.
    */
    logic [127:0] data[C_TRANSMISSION_SEGMENTS-1:0]; // t_data

    /**
    * Transmit LBUS Enable for segment0. This signal is used
    * to enable the TX LBUS Interface. All signals on this
    * interface are sampled only in cycles in which TX_ENAIN
    * is sampled as a 1.
    */
    logic [C_TRANSMISSION_SEGMENTS-1:0] en; // t_valid

    /**
    * Transmit LBUS Start Of Packet for segment0. This signal
    * is used to indicate the Start Of Packet (SOP) when it is
    * sampled as a 1 and is 0 for all other transfers of the
    * packet. This signal is sampled only in cycles in which
    * TX_ENAIN is sampled as a 1
    */
    logic [C_TRANSMISSION_SEGMENTS-1:0] sop; // Start of packet

    /**
    * Transmit LBUS End Of Packet for segment0. This signal
    * is used to indicate the End Of Packet (EOP) when it is
    * sampled as a 1 and is 0 for all other transfers of the
    * packet. This signal is sampled only in cycles in which
    * TX_ENAIN is sampled as a 1.
    */
    logic [C_TRANSMISSION_SEGMENTS-1:0] eop; // End of packet

    /**
    * Transmit LBUS Error for segment0. This signal is used to
    * indicate a packet contains an error when it is sampled as
    * a 1 and is 0 for all other transfers of the packet. This
    * signal is sampled only in cycles in which TX_ENAIN and
    * TX_EOPIN are sampled as 1. When this signal is
    * sampled as a 1, the last data word is replaced with the
    * 802.3ba Error Code control word that guarantees the
    * partner device receives the packet in error. If a packet is
    * input with this signal set to a 1, the FCS checking and
    * reporting is disabled (only for that packet).
    */
    logic [C_TRANSMISSION_SEGMENTS-1:0] err; // Error in packet

    /**
    * Transmit LBUS Empty for segment0. This bus is used to
    * indicate how many bytes of the TX_DATAIN bus are
    * empty or invalid for the last transfer of the current
    * packet. This bus is sampled only in cycles that
    * TX_ENAIN and TX_EOPIN are sampled as 1. When
    * TX_EOPIN and TX_ERRIN are sampled as 1, the value
    * of TX_MTYIN[2:0] is ignored as treated as if it was
    * 000. The other bits of TX_MTYIN are used as usual
    */
    logic [3:0] mty[C_TRANSMISSION_SEGMENTS-1:0];

    /**
    * Transmit LBUS Ready. This signal indicates whether the
    * dedicated 100G Ethernet core TX path is ready to accept
    * data and provides back-pressure to the user logic. A
    * value of 1 means the user logic can pass data to the
    * UltraScale architecture 100G Ethernet core. A value of 0
    * means the user logic must stop transferring data to the
    * UltraScale architecture 100G Ethernet core within a
    * certain number of cycles or there will be an overflow.
    */
    logic rdy;

    /**
    * Transmit LBUS Overflow. This signal indicates whether
    * you have violated the back pressure mechanism provided
    * by the TX_RDYOUT signal. If TX_OVFOUT is sampled as a
    * 1, a violation has occurred. It is up to you to design the
    * rest of the user logic to not overflow the TX interface. In
    * the event of an overflow condition, the TX path must be
    * reset.
    */
    logic ovf;

    /**
    * Transmit LBUS Underflow. This signal indicates whether
    * you have under-run the LBUS interface. If TX_UNFOUT is
    * sampled as 1, a violation has occurred meaning the
    * current packet is corrupted. Error control blocks are
    * transmitted as long as the underflow condition persists.
    * It is up to the user logic to ensure a complete packet is
    * input to the core without under-running the LBUS
    * interface.
    */
    logic unf       ;
    logic user_rst_i;
    logic user_rst_o;

    modport master (output data, en, sop, eop, err, mty, user_rst_i, input ovf, unf, rdy, user_rst_o );
    modport slave  (input data, en, sop, eop, err, mty, user_rst_i, output ovf, unf, rdy, user_rst_o);
endinterface

interface gt_drp_t;
    logic                               gt_txusrclk2                               ;
    logic                               gt_rxusrclk2                               ;
    logic [                      11 :0] gt_loopback_in                             ;
    logic [                       3 :0] gt_rxrecclkout                             ;
 


    modport master (input  gt_loopback_in, output gt_txusrclk2, gt_rxusrclk2, gt_rxrecclkout);    
endinterface



interface stat_t;
    logic                               stat_rx_aligned                            ;



    modport master (output stat_rx_aligned);    
    modport slave  (input  stat_rx_aligned);    
endinterface


interface rx_timestamp_t;
    logic [79:0]    rx_ptp_tstamp_corrected;
    logic [4:0]     rx_ptp_pcslane_out_int;
    logic           rx_ptp_tstamp_corrected_valid;


    modport master(output rx_ptp_tstamp_corrected, rx_ptp_pcslane_out_int, rx_ptp_tstamp_corrected_valid);    
    modport slave (input  rx_ptp_tstamp_corrected, rx_ptp_pcslane_out_int, rx_ptp_tstamp_corrected_valid);    
endinterface



interface axi4_stream # (parameter TDATA_WIDTH = 512, parameter TKEEP_WIDTH=TDATA_WIDTH/8, parameter TUSER_WIDTH=1);
    logic                   tvalid;
    logic                   tlast ;
    logic                   tready;
    logic [TKEEP_WIDTH-1:0] tstrb ;
    logic [TDATA_WIDTH-1:0] tdata ;
    
    logic [TUSER_WIDTH-1:0] tuser ;
    
    modport master (output tvalid, tlast, tstrb, tdata, tuser, input tready);
    modport slave  (input tvalid, tlast, tstrb, tdata, tuser, output tready);
endinterface


interface axi4_lite # (parameter C_S_AXI_DATA_WIDTH = 32, parameter C_S_AXI_ADDR_WIDTH=32);
        // Write address (issued by master, acceped by Slave)
        logic [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
        // Write channel Protection type. This signal indicates the
            // privilege and security level of the transaction, and whether
            // the transaction is a data access or an instruction access.
        logic [2 : 0] axi_awprot=0;
        // Write address valid. This signal indicates that the master signaling
            // valid write address and control information.
        logic  axi_awvalid;
        // Write address ready. This signal indicates that the slave is ready
            // to accept an address and associated control signals.
        logic  axi_awready;
        // Write data (issued by master, acceped by Slave) 
        logic [C_S_AXI_DATA_WIDTH-1 : 0] axi_wdata;
        // Write strobes. This signal indicates which byte lanes hold
            // valid data. There is one write strobe bit for each eight
            // bits of the write data bus.    
        logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] axi_wstrb;
        // Write valid. This signal indicates that valid write
            // data and strobes are available.
        logic  axi_wvalid;
        // Write ready. This signal indicates that the slave
            // can accept the write data.
        logic  axi_wready;
        // Write response. This signal indicates the status
            // of the write transaction.
        logic [1 : 0] axi_bresp;
        // Write response valid. This signal indicates that the channel
            // is signaling a valid write response.
        logic  axi_bvalid;
        // Response ready. This signal indicates that the master
            // can accept a write response.
        logic  axi_bready;
        // Read address (issued by master, acceped by Slave)
        logic [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
        // Protection type. This signal indicates the privilege
            // and security level of the transaction, and whether the
            // transaction is a data access or an instruction access.
        logic [2 : 0] axi_arprot;
        // Read address valid. This signal indicates that the channel
            // is signaling valid read address and control information.
        logic  axi_arvalid;
        // Read address ready. This signal indicates that the slave is
            // ready to accept an address and associated control signals.
        logic  axi_arready;
        // Read data (issued by slave)
        logic [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
        // Read response. This signal indicates the status of the
            // read transfer.
        logic [1 : 0] axi_rresp;
        // Read valid. This signal indicates that the channel is
            // signaling the required read data.
        logic  axi_rvalid;
        // Read ready. This signal indicates that the master can
            // accept the read data and response information.
        logic  axi_rready;


        modport  slave (input axi_awaddr, axi_awprot, axi_awvalid, axi_wdata, axi_wstrb, axi_wvalid, axi_bready, axi_araddr, axi_arprot, axi_arvalid, axi_rready,
                  output axi_awready, axi_wready, axi_bresp,axi_bvalid,axi_arready,axi_rdata, axi_rresp, axi_rvalid);

        modport  master (output axi_awaddr, axi_awprot, axi_awvalid, axi_wdata, axi_wstrb, axi_wvalid, axi_bready, axi_araddr, axi_arprot, axi_arvalid, axi_rready, 
                  input axi_awready, axi_wready, axi_bresp,axi_bvalid,axi_arready,axi_rdata, axi_rresp, axi_rvalid);

endinterface



`define sizeof(OBJECT) ($bits(OBJECT)/8)


`endif


