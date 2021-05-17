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

module cmac_0_axi4_lite_user_if #(
    parameter integer SLAVE_CMAC_BASEADDR   = 12'h0
)(
    input  wire            gt_locked_sync,
    input  wire            stat_rx_aligned_sync,
    output wire            rx_busy_led,


    input wire             s_axi_aclk,
    input wire             s_axi_sreset,
    input  wire            s_axi_pm_tick,
    output wire [11:0]     s_axi_awaddr,
    output wire            s_axi_awvalid,
    input  wire            s_axi_awready,
    output wire [31:0]     s_axi_wdata,
    output wire [3:0]      s_axi_wstrb,
    output wire            s_axi_wvalid,
    input  wire            s_axi_wready,
    input  wire [1:0]      s_axi_bresp,
    input  wire            s_axi_bvalid,
    output wire            s_axi_bready,
    output wire [11:0]     s_axi_araddr,
    output wire            s_axi_arvalid,
    input  wire            s_axi_arready,
    input  wire [31:0]     s_axi_rdata,
    input  wire [1:0]      s_axi_rresp,
    input  wire            s_axi_rvalid,
    output wire            s_axi_rready

);


   //// axi_reg_map offset address
    localparam ADDR_CONFIG_TX_REG1                      =  12'h00C;
    localparam ADDR_CONFIG_RX_REG1                      =  12'h014;
    localparam ADDR_CORE_VERSION_REG                    =  12'h024;    

    ////State Registers for TX
    reg  [3:0]     axi_user_prestate;

    reg  [31:0]    axi_wr_data;
    reg  [31:0]    axi_read_data;
    wire [31:0]    axi_rd_data;
    reg  [11:0]    axi_wr_addr;
    reg  [11:0]    axi_rd_addr;
    reg  [3:0]     axi_wr_strobe;
    reg            axi_wr_data_valid;
    reg            axi_wr_addr_valid;
    reg            axi_rd_addr_valid;
    reg            axi_rd_req;
    reg            axi_wr_req;
    wire           axi_wr_ack;
    wire           axi_rd_ack;
    wire           axi_wr_err;
    wire           axi_rd_err;
    reg  [7:0]     rd_wr_cntr; 
    reg            init_rx_aligned;
    reg            init_data_sanity;
    reg            init_tx_rx_pause;
    reg            rx_busy_led_r;

    wire           pm_tick_r;

    //// axi_user_prestate
    localparam STATE_AXI_IDLE            = 0;
    localparam STATE_GT_LOCKED           = 1;
    localparam STATE_INIT_RX_ALIGNED     = 2;
    localparam STATE_WAIT_RX_ALIGNED     = 3;
    localparam STATE_AXI_RD_WR           = 4;
    localparam STATE_INIT_PKT_TRANSFER   = 5;
    localparam STATE_TEST_WAIT           = 6;
    localparam STATE_INVALID_AXI_RD_WR   = 7;

    ////----------------------------------------TX Module -----------------------//
    
    
    //////////////////////////////////////////////////
    ////State Machine 
    //////////////////////////////////////////////////
    always @( posedge s_axi_aclk )
    begin
        if ( s_axi_sreset == 1'b1 )begin
            axi_user_prestate         <= STATE_AXI_IDLE;
            axi_rd_addr               <= 12'd0;
            axi_rd_addr_valid         <= 1'b0;
            axi_wr_data               <= 32'd0;
            axi_read_data             <= 32'd0;
            axi_wr_addr               <= 12'd0;
            axi_wr_addr_valid         <= 1'b0;
            axi_wr_data_valid         <= 1'b0;
            axi_wr_strobe             <= 4'd0;
            axi_rd_req                <= 1'b0;
            axi_wr_req                <= 1'b0;
            rd_wr_cntr                <= 8'd0;
            init_rx_aligned           <= 1'b0;
            init_data_sanity          <= 1'b0;
            init_tx_rx_pause          <= 1'b0;            
            rx_busy_led_r             <= 1'b0;            
        end
        else begin
            case (axi_user_prestate)
                STATE_AXI_IDLE            : begin
                     axi_rd_addr               <= 12'd0;
                     axi_rd_addr_valid         <= 1'b0;
                     axi_wr_data               <= 32'd0;
                     axi_read_data             <= 32'd0;
                     axi_wr_addr               <= 12'd0;
                     axi_wr_addr_valid         <= 1'b0;
                     axi_wr_data_valid         <= 1'b0;
                     axi_wr_strobe             <= 4'd0;
                     axi_rd_req                <= 1'b0;
                     axi_wr_req                <= 1'b0;
                     rd_wr_cntr                <= 8'd0;
                     init_rx_aligned           <= 1'b0;
                     init_data_sanity          <= 1'b0;
                     init_tx_rx_pause          <= 1'b0;
                     rx_busy_led_r             <= 1'b0;
                     
                     //// State transition
                     if  (gt_locked_sync == 1'b1) begin
                         $display("INFO : GT LOCKED");
                         axi_user_prestate <= STATE_GT_LOCKED;
                     end
                     else
                         axi_user_prestate <= STATE_AXI_IDLE;
                 end
                STATE_GT_LOCKED          : begin
                     axi_rd_addr             <= 12'd0;
                     axi_rd_addr_valid       <= 1'b0;
                     axi_wr_data             <= 32'd0;
                     axi_read_data           <= 32'd0;
                     axi_wr_addr             <= 12'd0;
                     axi_wr_addr_valid       <= 1'b0;
                     axi_wr_data_valid       <= 1'b0;
                     axi_wr_strobe           <= 4'd0;
                     axi_rd_req              <= 1'b0;
                     axi_wr_req              <= 1'b0;
                     rd_wr_cntr              <= 8'd0;
                     rx_busy_led_r           <= 1'b1;
                     init_rx_aligned         <= 1'b0;
                     init_data_sanity        <= 1'b0;
                     init_tx_rx_pause        <= 1'b0;

                     //// State transition
                     if  (gt_locked_sync == 1'b0)
                         axi_user_prestate <= STATE_AXI_IDLE;
                     else 
                         axi_user_prestate <= STATE_INIT_RX_ALIGNED;
                 end
                STATE_INIT_RX_ALIGNED    : begin
                     rx_busy_led_r           <= 1'b1;
                     init_rx_aligned         <= 1'b1;

                    case (rd_wr_cntr)
                        'd0     : begin
                            $display( "           AXI4 Lite Write Started to Config the Core CTL_* Ports ..." );
                            axi_wr_data             <= 32'h00000001;           //// ctl_rx_enable
                            axi_wr_addr             <= ADDR_CONFIG_RX_REG1 + SLAVE_CMAC_BASEADDR;    //// CONFIGURATION_RX_REG1
                            axi_wr_addr_valid       <= 1'b1;
                            axi_wr_data_valid       <= 1'b1;
                            axi_wr_strobe           <= 4'hF;
                            axi_rd_req              <= 1'b0;
                            axi_wr_req              <= 1'b1;
                        end
                        'd1     : begin
                            axi_wr_data             <= 32'h00000010;          //// ctl_tx_send_rfi
                            axi_wr_addr             <= ADDR_CONFIG_TX_REG1 + SLAVE_CMAC_BASEADDR;   //// CONFIGURATION_TX_REG1
                            axi_wr_addr_valid       <= 1'b1;
                            axi_wr_data_valid       <= 1'b1;
                            axi_wr_strobe           <= 4'hF;
                            axi_rd_req              <= 1'b0;
                            axi_wr_req              <= 1'b1;
                        end
                        default : begin
                            axi_wr_data             <= 32'h0;
                            axi_wr_addr             <= 12'h0;
                            axi_wr_addr_valid       <= 1'b0;
                            axi_wr_data_valid       <= 1'b0;
                            axi_wr_strobe           <= 4'h0;
                            axi_rd_req              <= 1'b0;
                            axi_wr_req              <= 1'b0;
                        end
                    endcase

                    //// State transition
                    if  (gt_locked_sync == 1'b0)
                        axi_user_prestate <= STATE_AXI_IDLE;
                    else if  (rd_wr_cntr == 8'd2) begin
                        $display( "           AXI4 Lite Write Completed" );
                        $display("INFO : WAITING FOR CMAC RX_ALIGNED..........");
                        axi_user_prestate <= STATE_WAIT_RX_ALIGNED;
                    end
                    else
                        axi_user_prestate <= STATE_AXI_RD_WR;
                end
                STATE_AXI_RD_WR          : begin
                    if (s_axi_awready == 1'b1) begin
                        axi_wr_addr             <= 12'd0;
                        axi_wr_addr_valid       <= 1'b0;
                        axi_wr_req              <= 1'b0;
                    end
                    if (s_axi_wready == 1'b1) begin
                        axi_wr_data             <= 32'd0;
                        axi_wr_data_valid       <= 1'b0;
                        axi_wr_strobe           <= 4'd0;
                    end
                    if (s_axi_arready == 1'b1) begin
                        axi_rd_addr             <= 12'd0;
                        axi_rd_addr_valid       <= 1'b0;
                        axi_rd_req              <= 1'b0;
                    end

                    //// State transition
                    if  ((axi_wr_ack == 1'b1 && axi_wr_err == 1'b1) || (axi_rd_ack == 1'b1 && axi_rd_err == 1'b1)) begin
                        $display("ERROR : INVALID AXI4 Lite READ/WRITE OPERATION OCCURED, APPLY SYS_RESET TO RECOVER ..........");
                        axi_user_prestate <= STATE_INVALID_AXI_RD_WR;
                    end
                    else if  ((axi_wr_ack == 1'b1 && axi_wr_err == 1'b0) || (axi_rd_ack == 1'b1 && axi_rd_err == 1'b0)) begin
                        rd_wr_cntr              <= rd_wr_cntr + 8'd1;
                        axi_read_data           <= axi_rd_data;
                        if  (init_rx_aligned == 1'b1)
                            axi_user_prestate <= STATE_INIT_RX_ALIGNED;
                        else if  (init_data_sanity == 1'b1)
                            axi_user_prestate <= STATE_INIT_PKT_TRANSFER;
                        else
                            axi_user_prestate <= STATE_AXI_RD_WR;
                    end
                end
                STATE_WAIT_RX_ALIGNED    : begin
                    rx_busy_led_r           <= 1'b1;
                    axi_rd_addr             <= 12'd0;
                    axi_rd_addr_valid       <= 1'b0;
                    axi_wr_data             <= 32'd0;
                    axi_read_data           <= 32'd0;
                    axi_wr_addr             <= 12'd0;
                    axi_wr_addr_valid       <= 1'b0;
                    axi_wr_data_valid       <= 1'b0;
                    axi_wr_strobe           <= 4'd0;
                    axi_rd_req              <= 1'b0;
                    axi_wr_req              <= 1'b0;
                    rd_wr_cntr              <= 8'd0;
                    init_rx_aligned         <= 1'b0;
                    init_data_sanity        <= 1'b0;
                    init_tx_rx_pause        <= 1'b0;

                    //// State transition
                    if  (gt_locked_sync == 1'b0)
                        axi_user_prestate <= STATE_AXI_IDLE;
                    else if  (stat_rx_aligned_sync == 1'b1) begin
                        $display("INFO : RX-ALIGNED");
                        axi_user_prestate <= STATE_INIT_PKT_TRANSFER;
                    end
                    else
                        axi_user_prestate <= STATE_WAIT_RX_ALIGNED;
                end
                STATE_INIT_PKT_TRANSFER  : begin
                    rx_busy_led_r           <= 1'b1;
                    init_data_sanity        <= 1'b1;

                    case (rd_wr_cntr)
                        'd0     : begin
                            axi_wr_data             <= 32'h00000001;         //// ctl_tx_enable=1 and ctl_tx_send_rfi=0
                            axi_wr_addr             <= ADDR_CONFIG_TX_REG1 + SLAVE_CMAC_BASEADDR;  //// CONFIGURATION_TX_REG1
                            axi_wr_addr_valid       <= 1'b1;
                            axi_wr_data_valid       <= 1'b1;
                            axi_wr_strobe           <= 4'hF;
                            axi_wr_req              <= 1'b1;
                        end
                        default : begin
                            axi_wr_data             <= 32'h0;
                            axi_wr_addr             <= 12'h0;
                            axi_wr_addr_valid       <= 1'b0;
                            axi_wr_data_valid       <= 1'b0;
                            axi_wr_strobe           <= 4'h0;
                            axi_rd_addr_valid       <= 1'b0;
                            axi_rd_req              <= 1'b0;
                            axi_wr_req              <= 1'b0;
                        end
                    endcase

                    //// State transition
                    if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                        axi_user_prestate <= STATE_AXI_IDLE;
                    else if  (rd_wr_cntr == 8'd1) begin
                        $display( "           AXI4 Lite Write Completed" );
                        $display("INFO : Packet Generator and Monitor (SANITY Testing) STARTED");
                        axi_user_prestate <= STATE_TEST_WAIT;
                    end
                    else
                        axi_user_prestate <= STATE_AXI_RD_WR;
                end
                STATE_TEST_WAIT          : begin
                    rx_busy_led_r           <= 1'b1;
                    axi_rd_addr             <= 12'd0;
                    axi_rd_addr_valid       <= 1'b0;
                    axi_read_data           <= 32'd0;
                    axi_wr_data             <= 32'd0;
                    axi_wr_addr             <= 12'd0;
                    axi_wr_addr_valid       <= 1'b0;
                    axi_wr_data_valid       <= 1'b0;
                    axi_wr_strobe           <= 4'd0;
                    axi_rd_req              <= 1'b0;
                    axi_wr_req              <= 1'b0;
                    rd_wr_cntr              <= 8'd0;
                    init_rx_aligned         <= 1'b0;
                    init_data_sanity        <= 1'b0;
                    init_tx_rx_pause        <= 1'b0;

                    //// State transition
                    if  (gt_locked_sync == 1'b0 || stat_rx_aligned_sync == 1'b0)
                        axi_user_prestate <= STATE_AXI_IDLE;
                    else
                        axi_user_prestate <= STATE_TEST_WAIT;
                end
                STATE_INVALID_AXI_RD_WR : begin
                    rx_busy_led_r           <= 1'b0;
                    axi_rd_addr             <= 12'd0;
                    axi_rd_addr_valid       <= 1'b0;
                    axi_wr_data             <= 32'd0;
                    axi_wr_addr             <= 12'd0;
                    axi_wr_addr_valid       <= 1'b0;
                    axi_wr_data_valid       <= 1'b0;
                    axi_wr_strobe           <= 4'd0;
                    axi_rd_req              <= 1'b0;
                    axi_wr_req              <= 1'b0;
                    rd_wr_cntr              <= 8'd0;
                    init_rx_aligned         <= 1'b0;
                    init_data_sanity        <= 1'b0;
                    init_tx_rx_pause        <= 1'b0;

                    //// State transition
                    if  (gt_locked_sync == 1'b0)
                        axi_user_prestate <= STATE_AXI_IDLE;
                    else
                        axi_user_prestate <= STATE_INVALID_AXI_RD_WR;
                end
                default                  : begin
                    axi_rd_addr               <= 12'd0;
                    axi_rd_addr_valid         <= 1'b0;
                    axi_wr_data               <= 32'd0;
                    axi_read_data             <= 32'd0;
                    axi_wr_addr               <= 12'd0;
                    axi_wr_addr_valid         <= 1'b0;
                    axi_wr_data_valid         <= 1'b0;
                    axi_wr_strobe             <= 4'd0;
                    axi_rd_req                <= 1'b0;
                    axi_wr_req                <= 1'b0;
                    rd_wr_cntr                <= 8'd0;
                    init_rx_aligned           <= 1'b0;
                    init_data_sanity          <= 1'b0;
                    init_tx_rx_pause          <= 1'b0;
                    rx_busy_led_r             <= 1'b0;
                    axi_user_prestate         <= STATE_AXI_IDLE;
                end
            endcase
        end
    end

cmac_0_axi4_lite_rd_wr_if i_cmac_0_axi4_lite_rd_wr_if (
    .axi_aclk(s_axi_aclk),
    .axi_sreset(s_axi_sreset),
    .axi_bresp(s_axi_bresp),
    .axi_bvalid(s_axi_bvalid),
    .axi_bready(s_axi_bready),
    .axi_rdata(s_axi_rdata),
    .axi_rresp(s_axi_rresp),
    .axi_rvalid(s_axi_rvalid),
    .axi_rready(s_axi_rready),
    .axi_awaddr(s_axi_awaddr),
    .axi_awvalid(s_axi_awvalid),
    .axi_awready(s_axi_awready),
    .axi_wdata(s_axi_wdata),
    .axi_wstrb(s_axi_wstrb),
    .axi_wvalid(s_axi_wvalid),
    .axi_wready(s_axi_wready),
    .axi_araddr(s_axi_araddr),
    .axi_arvalid(s_axi_arvalid),
    .axi_arready(s_axi_arready),
    .usr_write_req(axi_wr_req),
    .usr_read_req(axi_rd_req),
    .usr_rdata(axi_rd_data),
    .usr_araddr(axi_rd_addr),
    .usr_arvalid(axi_rd_addr_valid),
    .usr_awaddr(axi_wr_addr),
    .usr_awvalid(axi_wr_addr_valid),
    .usr_wdata(axi_wr_data),
    .usr_wvalid(axi_wr_data_valid),
    .usr_wstrb(axi_wr_strobe),    
    .usr_wrack(axi_wr_ack),
    .usr_rdack(axi_rd_ack),
    .usr_wrerr(axi_wr_err),
    .usr_rderr(axi_rd_err)
);
 

  assign rx_busy_led      = rx_busy_led_r;

  assign pm_tick_r        = s_axi_pm_tick;
    ////----------------------------------------END TX Module-----------------------//

endmodule

module cmac_0_axi4_lite_rd_wr_if
  (

  input  wire                    axi_aclk,
  input  wire                    axi_sreset,

  input  wire                    usr_write_req,
  input  wire                    usr_read_req,

  //// write side from usr
  input  wire [11:0]             usr_awaddr,
  input  wire                    usr_awvalid,
  input  wire [31:0]             usr_wdata,
  input  wire                    usr_wvalid,
  input  wire [3:0]              usr_wstrb,

  //// write response from axi
  input  wire [1:0]              axi_bresp,
  input  wire                    axi_bvalid,
  output wire                    axi_bready,

  //// read side from usr
  input  wire [11:0]             usr_araddr,
  input  wire                    usr_arvalid,

  //// read side from axi
  input  wire [31:0]             axi_rdata,
  input  wire [1:0]              axi_rresp,
  
  input  wire                    axi_rvalid,
  output wire                    axi_rready,
  output wire                    axi_arvalid,
  input  wire                    axi_arready,

  //// write side to axi
  output wire [11:0]             axi_awaddr,
  output wire                    axi_awvalid,
  input  wire                    axi_awready,

  output wire [31:0]             axi_wdata,
  output wire [3:0]              axi_wstrb,
  output wire                    axi_wvalid,
  input  wire                    axi_wready,

  //// read side to usr
  output wire [31:0]             usr_rdata,
  output wire [11:0]             axi_araddr, 
  output wire                    usr_wrack,
  output wire                    usr_rdack,
  output wire                    usr_wrerr,
  output wire                    usr_rderr
  );

  //// States
  parameter IDLE_STATE  = 0;
  parameter WRITE_STATE = 1;
  parameter READ_STATE  = 2;
  parameter ACK_STATE   = 3;

  reg [2:0] pstate;

  reg [11:0]             axi_awaddr_r;
  reg                    axi_awvalid_r;
  reg [31:0]             axi_wdata_r;
  reg [31:0]             axi_rdata_r;
  reg [3:0]              axi_wstrb_r;
  reg                    axi_wvalid_r;

  reg [11:0]             usr_araddr_r;
  reg                    usr_wrack_r;
  reg                    usr_rdack_r;
  reg                    usr_wrerr_r;
  reg                    usr_rderr_r;

  reg                    axi_arvalid_r;
  reg                    axi_bready_r;
  reg                    axi_rready_r;

  assign axi_awaddr   =  axi_awaddr_r;
  assign axi_awvalid  =  axi_awvalid_r;
  assign axi_wdata    =  axi_wdata_r;
  assign axi_wstrb    =  axi_wstrb_r;
  assign axi_wvalid   =  axi_wvalid_r;

  assign usr_rdata    =  axi_rdata_r;
  assign axi_bready   =  axi_bready_r;
  assign axi_rready   =  axi_rready_r;
  assign axi_arvalid  =  axi_arvalid_r;
  assign axi_araddr   =  usr_araddr_r;

  assign usr_wrack    =  usr_wrack_r;
  assign usr_rdack    =  usr_rdack_r;
  assign usr_wrerr    =  usr_wrerr_r;
  assign usr_rderr    =  usr_rderr_r;

//////////////////////////////////////////////////////////////////////////////
//// Implement axi_bready generation
////
////  axi_bready is asserted for one s_axi_aclk clock cycle when 
////  axi_bvalid is asserted. axi_bready is
////  de-asserted when reset is low.
//////////////////////////////////////////////////////////////////////////////
  always @(posedge axi_aclk)
  begin
     if (axi_sreset == 1'b1)
     begin
        axi_bready_r  <=  1'b0;
     end
     else
     begin
        if ((~axi_bready_r) && (axi_bvalid))
           axi_bready_r  <=  1'b1;
        else
           axi_bready_r  <=  1'b0;
     end
  end

//////////////////////////////////////////////////////////////////////////////
//// Implement axi_rready generation
////
////  axi_rready is asserted for one axi_aclk clock cycle when
////  axi_rvalid is asserted. axi_rready is
////  de-asserted when reset (active low) is asserted.
//////////////////////////////////////////////////////////////////////////////
  always @(posedge axi_aclk)
  begin
     if (axi_sreset == 1'b1)
     begin
        axi_rready_r  <=  1'b0;
     end
     else
     begin
        if ((~axi_rready_r) && (axi_rvalid))
           axi_rready_r  <=  1'b1;
        else
           axi_rready_r  <=  1'b0;
     end
  end

//////////////////////////////////////////////////////////////////////////////
//// State machine flow
//////////////////////////////////////////////////////////////////////////////
  always @(posedge axi_aclk)
  begin
     if (axi_sreset == 1'b1)
     begin
        pstate        <=  IDLE_STATE;

        axi_arvalid_r <=  1'b0;
        usr_araddr_r  <=  12'd0;
        axi_rdata_r   <=  32'd0;

        axi_awvalid_r <=  1'b0;
        axi_awaddr_r  <=  12'd0;
        axi_wvalid_r  <=  1'b0;
        axi_wdata_r   <=  32'd0;
        axi_wstrb_r   <=  4'd0;

        usr_wrack_r   <=  1'b0;
        usr_rdack_r   <=  1'b0;
        usr_wrerr_r   <=  1'b0;
        usr_rderr_r   <=  1'b0;
     end
     else
     begin
        case (pstate)
                IDLE_STATE    : begin
                                    if (usr_read_req == 1'b1)
                                    begin
                                       pstate        <=  READ_STATE;
                                       axi_arvalid_r <=  usr_arvalid;
                                       usr_araddr_r  <=  usr_araddr;
                                    end
                                    else if (usr_write_req == 1'b1)
                                    begin
                                       pstate        <=  WRITE_STATE;
                                       axi_awvalid_r <=  usr_awvalid;
                                       axi_awaddr_r  <=  usr_awaddr;
                                       axi_wvalid_r  <=  usr_wvalid;
                                       axi_wdata_r   <=  usr_wdata;
                                       axi_wstrb_r   <=  usr_wstrb;
                                    end
                                    else
                                    begin
                                       pstate        <=  IDLE_STATE;
                                       axi_arvalid_r <=  1'b0;
                                       usr_araddr_r  <=  12'd0;
                                       axi_rdata_r   <=  32'd0;

                                       axi_awvalid_r <=  1'b0;
                                       axi_awaddr_r  <=  12'd0;
                                       axi_wvalid_r  <=  1'b0;
                                       axi_wdata_r   <=  32'd0;
                                       axi_wstrb_r   <=  4'd0;

                                       usr_wrack_r   <=  1'b0;
                                       usr_rdack_r   <=  1'b0;
                                       usr_wrerr_r   <=  1'b0;
                                       usr_rderr_r   <=  1'b0;
                                    end
                                 end

                WRITE_STATE    : begin
                                    if ((axi_bvalid == 1'b1) && (axi_bready_r == 1'b1))
                                    begin
                                       pstate        <=  ACK_STATE;
                                       usr_wrack_r   <=  1'b1;
                                       if (axi_bresp == 2'b10)
                                          usr_wrerr_r <=  1'b1;
                                       else
                                          usr_wrerr_r <=  1'b0;
                                    end
                                    else
                                    begin
                                       pstate        <=  WRITE_STATE;
                                       axi_awvalid_r <=  usr_awvalid;
                                       axi_awaddr_r  <=  usr_awaddr;
                                       axi_wvalid_r  <=  usr_wvalid;
                                       axi_wdata_r   <=  usr_wdata;
                                       axi_wstrb_r   <=  usr_wstrb;
                                    end
                                 end

                READ_STATE     : begin
                                    if ((axi_rvalid == 1'b1) && (axi_rready_r == 1'b1)) begin
                                       pstate        <=  ACK_STATE;
                                       axi_rdata_r   <=  axi_rdata;
                                       usr_rdack_r   <=  1'b1;
                                       if (axi_rresp == 2'b10)
                                          usr_rderr_r <=  1'b1;
                                       else
                                          usr_rderr_r <=  1'b0;
                                    end
                                    else
                                    begin
                                       pstate        <=  READ_STATE;
                                       axi_arvalid_r <=  usr_arvalid;
                                       usr_araddr_r  <=  usr_araddr;
                                    end
                                 end

                ACK_STATE      : begin
                                    pstate        <=  IDLE_STATE;
                                    usr_wrack_r   <=  1'b0;
                                    usr_rdack_r   <=  1'b0;
                                    usr_wrerr_r   <=  1'b0;
                                    usr_rderr_r   <=  1'b0;
                                 end

                default        : begin
                                    pstate        <=  IDLE_STATE;
                                    axi_arvalid_r <=  1'b0;
                                    usr_araddr_r  <=  12'd0;
                                    axi_rdata_r   <=  32'd0;
                                    
                                    axi_awvalid_r <=  1'b0;
                                    axi_awaddr_r  <=  12'd0;
                                    axi_wvalid_r  <=  1'b0;
                                    axi_wdata_r   <=  32'd0;
                                    axi_wstrb_r   <=  4'd0;
                                    
                                    usr_wrack_r   <=  1'b0;
                                    usr_rdack_r   <=  1'b0;
                                    usr_wrerr_r   <=  1'b0;
                                    usr_rderr_r   <=  1'b0;
                                 end
        endcase
     end
  end

endmodule