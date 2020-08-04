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
Copyright (c) 2020 Xilinx, Inc.
************************************************/

`timescale 1ns/1ps

module segment_generator_tb_producer ();

  parameter integer AXIS_TDATA_WIDTH      = 512;
  parameter integer STREAMING_TDEST_WIDTH =  16;
  parameter integer AXIS_SUMMARY_WIDTH    = 128;

  wire                                 S_AXIS_n2k_tvalid;
  wire       [AXIS_TDATA_WIDTH-1:0]    S_AXIS_n2k_tdata;
  wire     [AXIS_TDATA_WIDTH/8-1:0]    S_AXIS_n2k_tkeep;
  wire                                 S_AXIS_n2k_tlast;
  wire  [STREAMING_TDEST_WIDTH-1:0]    S_AXIS_n2k_tdest;
  wire                                 S_AXIS_n2k_tready;

  wire                                 M_AXIS_k2n_tready;
  wire       [AXIS_TDATA_WIDTH-1:0]    M_AXIS_k2n_tdata;
  wire                                 M_AXIS_k2n_tvalid;
  wire                                 M_AXIS_k2n_tlast;
  wire     [AXIS_TDATA_WIDTH/8-1:0]    M_AXIS_k2n_tkeep;
  wire  [STREAMING_TDEST_WIDTH-1:0]    M_AXIS_k2n_tdest;

  wire     [AXIS_SUMMARY_WIDTH-1:0]    M_AXIS_summary_tdata;
  wire                                 M_AXIS_summary_tvalid;
  wire                                 M_AXIS_summary_tlast;
  wire                                 M_AXIS_summary_tready;
  reg                                  start_kernel= 1'b0;

  reg     ap_clk;
  reg     ap_rst_n = 1'b0;
  reg     ap_start = 1'b0;

  wire    ap_done;
  wire    ap_idle;

  initial begin
      ap_clk   = 1'b0;
      ap_rst_n = 1'b0;
      ap_start = 1'b0;
      #16;
      ap_rst_n = 1'b1;
      #75;
      start_kernel <= 1'b1;
      #150;
      ap_start = 1'b1;
      #12;
      ap_start = 1'b0;
  end

  /*Create clock*/
  always @(*)
      ap_clk <= #2 ~ap_clk;


  localparam MODE_PRODUCER = 0,
             MODE_LATENCY  = 1,
             MODE_LOOPBACK = 2,
             MODE_CONSUMER = 3;


  segment_generator #(
    .AXIS_TDATA_WIDTH     (     AXIS_TDATA_WIDTH),
    .STREAMING_TDEST_WIDTH(STREAMING_TDEST_WIDTH)
  ) segment_generator_i (
    .ap_clk                   (                ap_clk),
    .ap_rst_n                 (              ap_rst_n),

    .S_AXIS_n2k_tdata         (      S_AXIS_n2k_tdata),
    .S_AXIS_n2k_tkeep         (      S_AXIS_n2k_tkeep),
    .S_AXIS_n2k_tvalid        (     S_AXIS_n2k_tvalid),
    .S_AXIS_n2k_tlast         (      S_AXIS_n2k_tlast),
    .S_AXIS_n2k_tdest         (      S_AXIS_n2k_tdest),
    .S_AXIS_n2k_tready        (     S_AXIS_n2k_tready),

    .M_AXIS_k2n_tdata         (      M_AXIS_k2n_tdata),
    .M_AXIS_k2n_tkeep         (      M_AXIS_k2n_tkeep),
    .M_AXIS_k2n_tvalid        (     M_AXIS_k2n_tvalid),
    .M_AXIS_k2n_tlast         (      M_AXIS_k2n_tlast),
    .M_AXIS_k2n_tdest         (      M_AXIS_k2n_tdest),
    .M_AXIS_k2n_tready        (     M_AXIS_k2n_tready),

    .M_AXIS_summary_tdata     (  M_AXIS_summary_tdata),
    .M_AXIS_summary_tvalid    ( M_AXIS_summary_tvalid),
    .M_AXIS_summary_tlast     (  M_AXIS_summary_tlast),
    .M_AXIS_summary_tready    ( M_AXIS_summary_tready),

    .number_packets           (                   160),
    .number_beats             (                     2),
    .time_between_packets     (                     0),
    .dest_id                  (                     5),
    .mode                     (          MODE_LATENCY),
    .ap_start                 (              ap_start),
    .ap_done                  (               ap_done),
    .ap_idle                  (               ap_idle)   
  );


  fifo_generator_0 fifo_i (
    .s_aclk        (            ap_clk),
    .s_aresetn     (          ap_rst_n),

    .s_axis_tdata  (  M_AXIS_k2n_tdata),
    .s_axis_tkeep  (  M_AXIS_k2n_tkeep),
    .s_axis_tvalid ( M_AXIS_k2n_tvalid),
    .s_axis_tlast  (  M_AXIS_k2n_tlast),
    .s_axis_tdest  (  M_AXIS_k2n_tdest),
    .s_axis_tready ( M_AXIS_k2n_tready),

    .m_axis_tdata  (  S_AXIS_n2k_tdata),
    .m_axis_tkeep  (  S_AXIS_n2k_tkeep),
    .m_axis_tvalid ( S_AXIS_n2k_tvalid),
    .m_axis_tlast  (  S_AXIS_n2k_tlast),
    .m_axis_tdest  (  S_AXIS_n2k_tdest),
    .m_axis_tready ( S_AXIS_n2k_tready) 
  );


  reg  [5:0]  s_axi_control_AWADDR = 6'h0;
  reg         s_axi_control_AWVALID = 1'b0;
  reg [31:0]  s_axi_control_WDATA = 32'h0;
  reg [ 3:0]  s_axi_control_WSTRB = 4'hF;
  reg         s_axi_control_WVALID = 1'b0;
  reg [5:0]   s_axi_control_ARADDR = 6'h0;
  reg         s_axi_control_ARVALID = 1'b0;
  reg         s_axi_control_RREADY = 1'b1;
  wire        s_axi_control_AWREADY;
  wire        s_axi_control_WREADY;
  wire        s_axi_control_ARREADY;
  reg         start_kernel_1d;
/*
  collector_0 collector_i (
    .ap_clk     (  ap_clk),                               
    .ap_rst_n   (ap_rst_n),                       
    .interrupt  (        ),                          

    //Stream interface
    .summary_TDATA (M_AXIS_summary_tdata),
    .summary_TVALID(M_AXIS_summary_tvalid),
    .summary_TREADY(M_AXIS_summary_tready),
    .summary_TLAST (M_AXIS_summary_tlast),
    .summary_TKEEP(16'h0),
    .summary_TSTRB(16'h0),

    //Memory mapped interfaces*
    .s_axi_control_AWADDR (s_axi_control_AWADDR),
    .s_axi_control_AWVALID(s_axi_control_AWVALID),
    .s_axi_control_AWREADY(s_axi_control_AWREADY),
    .s_axi_control_WDATA  (s_axi_control_WDATA),
    .s_axi_control_WSTRB  (s_axi_control_WSTRB),
    .s_axi_control_WVALID (s_axi_control_WVALID),
    .s_axi_control_WREADY (s_axi_control_WREADY),
    .s_axi_control_BRESP  (    ),
    .s_axi_control_BVALID (    ),
    .s_axi_control_BREADY (1'b1),
    .s_axi_control_ARADDR (s_axi_control_ARADDR),
    .s_axi_control_ARVALID(s_axi_control_ARVALID),
    .s_axi_control_ARREADY(s_axi_control_ARREADY),
    .s_axi_control_RDATA  (),
    .s_axi_control_RRESP  (),
    .s_axi_control_RVALID (),
    .s_axi_control_RREADY (s_axi_control_RREADY),
    .m_axi_gmem_AWREADY(1'b1),
    .m_axi_gmem_WREADY(1'b1),
    .m_axi_gmem_BRESP(2'h0),
    .m_axi_gmem_BVALID(1'b0),
    .m_axi_gmem_ARREADY(1'b1),
    .m_axi_gmem_RDATA('h0),
    .m_axi_gmem_RRESP('h0),
    .m_axi_gmem_RLAST('h0),
    .m_axi_gmem_RVALID('h0)

  );
  */

  design_2 bd_i (
    .ap_clk   (  ap_clk),
    .ap_rst_n (ap_rst_n),
    .s_axi_control_araddr   (s_axi_control_ARADDR),
    .s_axi_control_arready  (s_axi_control_ARREADY),
    .s_axi_control_arvalid  (s_axi_control_ARVALID),
    .s_axi_control_awaddr   (s_axi_control_AWADDR),
    .s_axi_control_awready  (s_axi_control_AWREADY),
    .s_axi_control_awvalid  (s_axi_control_AWVALID),
    .s_axi_control_bready   (1'b1),
    .s_axi_control_bresp    (),
    .s_axi_control_bvalid   (),
    .s_axi_control_rdata    (),
    .s_axi_control_rready   (s_axi_control_ARREADY),
    .s_axi_control_rresp    (),
    .s_axi_control_rvalid   (),
    .s_axi_control_wdata    (s_axi_control_WDATA),
    .s_axi_control_wready   (s_axi_control_WREADY),
    .s_axi_control_wstrb    (s_axi_control_WSTRB),
    .s_axi_control_wvalid   (s_axi_control_WVALID),
    .summary_tdata  (M_AXIS_summary_tdata),
    .summary_tvalid (M_AXIS_summary_tvalid),
    .summary_tready (M_AXIS_summary_tready),
    .summary_tlast  (M_AXIS_summary_tlast),
    .summary_tkeep  (16'h0),
    .summary_tstrb  (16'h0)
    );

  localparam SUBMIT_START = 0,
             DONE         = 1;

  reg       fsm_state = SUBMIT_START;

  always @(posedge ap_clk) begin
    if (~ap_rst_n) begin
      s_axi_control_AWVALID <= 1'b0;
      s_axi_control_WVALID  <= 1'b0;
      fsm_state <= SUBMIT_START;
    end
    else begin
      s_axi_control_AWVALID <= s_axi_control_AWVALID & ~ s_axi_control_AWREADY;
      s_axi_control_WVALID  <= s_axi_control_WVALID  & ~ s_axi_control_WREADY;
      start_kernel_1d <= start_kernel;
      
      case(fsm_state)
      SUBMIT_START : begin
        if (start_kernel && !start_kernel_1d) begin
          // Write 1 to address 0 to start kernel
          s_axi_control_AWADDR  <= 6'h0;
          s_axi_control_WDATA   <= 32'h1;
          s_axi_control_AWVALID <=1'b1;
          s_axi_control_WVALID  <=1'b1;
          fsm_state             <= DONE;
        end
      end
      DONE : begin
        // Do nothing for ever
      end
      endcase

    end
  end

endmodule
