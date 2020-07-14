
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
  reg                                  M_AXIS_summary_tready = 1'b1;

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
      #150;
      ap_start = 1'b1;
      #12;
      ap_start = 1'b0;
  end

  /*Create clock*/
  always @(*)
      ap_clk <= #2 ~ap_clk;


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

    .number_packets           (                    10),
    .number_beats             (                     7),
    .time_between_packets     (                    12),
    .dest_id                  (                     5),
    .mode                     (                     1),
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


endmodule
