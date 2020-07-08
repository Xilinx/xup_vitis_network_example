`default_nettype wire
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module traffic_generator #(
      // Width of S_AXIS_n2k and M_AXIS_k2n interfaces
      parameter integer AXIS_TDATA_WIDTH      = 512,
      // Width of M_AXIS_summary interface
      parameter integer AXIS_SUMMARY_WIDTH    = 160,
      // Width of TDEST address bus
      parameter integer STREAMING_TDEST_WIDTH =  16,
      // Width of S_AXIL data bus
      parameter integer AXIL_DATA_WIDTH       = 32,
      // Width of S_AXIL address bus
      parameter integer AXIL_ADDR_WIDTH       =  7
)(
    // System clocks and resets
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS_n2k:M_AXIS_k2n:M_AXIS_summary:S_AXIL, ASSOCIATED_RESET ap_rst_n" *)
    input  wire                                 ap_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ap_rst_n RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire                                 ap_rst_n,

    // AXI4-Stream network layer to streaming kernel 
    input  wire       [AXIS_TDATA_WIDTH-1:0]    S_AXIS_n2k_tdata,
    input  wire     [AXIS_TDATA_WIDTH/8-1:0]    S_AXIS_n2k_tkeep,
    input  wire                                 S_AXIS_n2k_tvalid,
    input  wire                                 S_AXIS_n2k_tlast,
    input  wire  [STREAMING_TDEST_WIDTH-1:0]    S_AXIS_n2k_tdest,
    output wire                                 S_AXIS_n2k_tready,
    // AXI4-Stream streaming kernel to network layer
    output wire       [AXIS_TDATA_WIDTH-1:0]    M_AXIS_k2n_tdata,
    output wire     [AXIS_TDATA_WIDTH/8-1:0]    M_AXIS_k2n_tkeep,
    output wire                                 M_AXIS_k2n_tvalid,
    output wire                                 M_AXIS_k2n_tlast,
    output wire  [STREAMING_TDEST_WIDTH-1:0]    M_AXIS_k2n_tdest,
    input  wire                                 M_AXIS_k2n_tready,

    // AXI4-Stream kernel to summary collector
    output wire     [AXIS_SUMMARY_WIDTH-1:0]    M_AXIS_summary_tdata,
    output wire                                 M_AXIS_summary_tvalid,
    output wire                                 M_AXIS_summary_tlast,
    input  wire                                 M_AXIS_summary_tready,
    
    input  wire      [AXIL_ADDR_WIDTH-1 : 0]    S_AXIL_AWADDR,
    input  wire                                 S_AXIL_AWVALID,
    output wire                                 S_AXIL_AWREADY,
    input  wire      [AXIL_DATA_WIDTH-1 : 0]    S_AXIL_WDATA,
    input  wire  [(AXIL_DATA_WIDTH/8)-1 : 0]    S_AXIL_WSTRB,
    input  wire                                 S_AXIL_WVALID,
    output wire                                 S_AXIL_WREADY,
    output wire                      [1 : 0]    S_AXIL_BRESP,
    output wire                                 S_AXIL_BVALID,
    input  wire                                 S_AXIL_BREADY,
    input  wire      [AXIL_ADDR_WIDTH-1 : 0]    S_AXIL_ARADDR,
    input  wire                                 S_AXIL_ARVALID,
    output wire                                 S_AXIL_ARREADY,
    output wire      [AXIL_DATA_WIDTH-1 : 0]    S_AXIL_RDATA,
    output wire                      [1 : 0]    S_AXIL_RRESP,
    output wire                                 S_AXIL_RVALID,
    input  wire                                 S_AXIL_RREADY


);

    wire                                 ap_done_w;
    wire                                 ap_idle_w;
    wire                                 ap_start_w;
    wire                         [1:0]   mode_w;
    wire   [STREAMING_TDEST_WIDTH-1:0]   dest_id_w;
    wire                        [39:0]   number_packets_w;
    wire                        [15:0]   number_beats_w;
    wire                        [31:0]   time_between_packets_w;
    wire                       [191:0]   debug_slot_producer;
    wire                       [191:0]   debug_slot_consumer;
    wire                       [191:0]   debug_slot_summary;
    wire                                 debug_reset_n;

    segment_generator #(
        .AXIS_TDATA_WIDTH      (       AXIS_TDATA_WIDTH),
        .AXIS_SUMMARY_WIDTH    (     AXIS_SUMMARY_WIDTH),
        .STREAMING_TDEST_WIDTH (  STREAMING_TDEST_WIDTH)
    ) sgmt_gen_i (
        .ap_clk                (                 ap_clk),
        .ap_rst_n              (               ap_rst_n),
        
        .S_AXIS_n2k_tdata      (       S_AXIS_n2k_tdata),
        .S_AXIS_n2k_tkeep      (       S_AXIS_n2k_tkeep),
        .S_AXIS_n2k_tvalid     (      S_AXIS_n2k_tvalid),
        .S_AXIS_n2k_tlast      (       S_AXIS_n2k_tlast),
        .S_AXIS_n2k_tdest      (       S_AXIS_n2k_tdest),
        .S_AXIS_n2k_tready     (      S_AXIS_n2k_tready),
        
        .M_AXIS_k2n_tdata      (       M_AXIS_k2n_tdata),
        .M_AXIS_k2n_tkeep      (       M_AXIS_k2n_tkeep),
        .M_AXIS_k2n_tvalid     (      M_AXIS_k2n_tvalid),
        .M_AXIS_k2n_tlast      (       M_AXIS_k2n_tlast),
        .M_AXIS_k2n_tdest      (       M_AXIS_k2n_tdest),
        .M_AXIS_k2n_tready     (      M_AXIS_k2n_tready),
        
        .M_AXIS_summary_tdata  (   M_AXIS_summary_tdata),
        .M_AXIS_summary_tvalid (  M_AXIS_summary_tvalid),
        .M_AXIS_summary_tlast  (   M_AXIS_summary_tlast),
        .M_AXIS_summary_tready (  M_AXIS_summary_tready),

        .number_packets        (       number_packets_w),
        .number_beats          (         number_beats_w),
        .time_between_packets  ( time_between_packets_w),
        .dest_id               (              dest_id_w),
        .mode                  (                 mode_w),
        .ap_start              (             ap_start_w),
        .ap_idle               (              ap_idle_w),
        .ap_done               (              ap_done_w)
    );

    axi4lite #(
        .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
        .AXIL_ADDR_WIDTH  (AXIL_ADDR_WIDTH),
        .STREAMING_TDEST_WIDTH(STREAMING_TDEST_WIDTH)
    ) axi4lite_i (
        .S_AXIL_ACLK          (                ap_clk),
        .S_AXIL_ARESETN       (              ap_rst_n),
        .S_AXIL_AWADDR        (         S_AXIL_AWADDR),
        .S_AXIL_AWVALID       (        S_AXIL_AWVALID),
        .S_AXIL_AWREADY       (        S_AXIL_AWREADY),
        .S_AXIL_WDATA         (          S_AXIL_WDATA),
        .S_AXIL_WSTRB         (          S_AXIL_WSTRB),
        .S_AXIL_WVALID        (         S_AXIL_WVALID),
        .S_AXIL_WREADY        (         S_AXIL_WREADY),
        .S_AXIL_BRESP         (          S_AXIL_BRESP),
        .S_AXIL_BVALID        (         S_AXIL_BVALID),
        .S_AXIL_BREADY        (         S_AXIL_BREADY),
        .S_AXIL_ARADDR        (         S_AXIL_ARADDR),
        .S_AXIL_ARVALID       (        S_AXIL_ARVALID),
        .S_AXIL_ARREADY       (        S_AXIL_ARREADY),
        .S_AXIL_RDATA         (          S_AXIL_RDATA),
        .S_AXIL_RRESP         (          S_AXIL_RRESP),
        .S_AXIL_RVALID        (         S_AXIL_RVALID),
        .S_AXIL_RREADY        (         S_AXIL_RREADY),
        .ap_done              (             ap_done_w),
        .ap_idle              (             ap_idle_w),
        .ap_start             (            ap_start_w),
        .mode                 (                mode_w),
        .dest_id              (             dest_id_w),
        .number_packets       (      number_packets_w),
        .number_beats         (        number_beats_w),
        .time_between_packets (time_between_packets_w),
        .debug_reset_n        (         debug_reset_n),
        .debug_slot_producer  (   debug_slot_producer),
        .debug_slot_consumer  (   debug_slot_consumer),
        .debug_slot_summary   (    debug_slot_summary)
    );

    bandwith_reg #(
        .C_AXIS_DATA_WIDTH(AXIS_TDATA_WIDTH)
    ) bw_producer_i (
        .S_AXI_ACLK    (                   ap_clk),
        .S_AXI_ARESETN (                 ap_rst_n),

        .S_AXIS_TDATA  ( {AXIS_TDATA_WIDTH{1'b0}}),
        .S_AXIS_TKEEP  (         M_AXIS_k2n_tkeep),
        .S_AXIS_TVALID (        M_AXIS_k2n_tvalid),
        .M_AXIS_TREADY (        M_AXIS_k2n_tready),
        .S_AXIS_TLAST  (         M_AXIS_k2n_tlast),
        .S_AXIS_TUSER  (                        0),
        .S_AXIS_TDEST  (                        0),

        .debug_slot    (      debug_slot_producer),
        .user_rst_n    (            debug_reset_n)
    );

    bandwith_reg #(
        .C_AXIS_DATA_WIDTH(AXIS_TDATA_WIDTH)
    ) bw_consumer_i (
        .S_AXI_ACLK    (                   ap_clk),
        .S_AXI_ARESETN (                 ap_rst_n),

        .S_AXIS_TDATA  ( {AXIS_TDATA_WIDTH{1'b0}}),
        .S_AXIS_TKEEP  (         S_AXIS_n2k_tkeep),
        .S_AXIS_TVALID (        S_AXIS_n2k_tvalid),
        .M_AXIS_TREADY (        S_AXIS_n2k_tready),
        .S_AXIS_TLAST  (         S_AXIS_n2k_tlast),
        .S_AXIS_TUSER  (                        0),
        .S_AXIS_TDEST  (                        0),

        .debug_slot    (      debug_slot_consumer),
        .user_rst_n    (            debug_reset_n)
    );

    bandwith_reg #(
        .C_AXIS_DATA_WIDTH(AXIS_SUMMARY_WIDTH)
    ) bw_summary_i (
        .S_AXI_ACLK    (                         ap_clk),
        .S_AXI_ARESETN (                       ap_rst_n),

        .S_AXIS_TDATA  (     {AXIS_SUMMARY_WIDTH{1'b0}}),
        .S_AXIS_TKEEP  ( {(AXIS_SUMMARY_WIDTH/8){1'b1}}),
        .S_AXIS_TVALID (          M_AXIS_summary_tvalid),
        .M_AXIS_TREADY (          M_AXIS_summary_tready),
        .S_AXIS_TLAST  (                           1'b1),
        .S_AXIS_TUSER  (                              0),
        .S_AXIS_TDEST  (                              0),

        .debug_slot    (             debug_slot_summary),
        .user_rst_n    (                  debug_reset_n)
    );


endmodule