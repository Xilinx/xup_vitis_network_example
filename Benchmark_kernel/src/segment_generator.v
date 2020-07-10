/* (c) Copyright 2020 Xilinx, Inc. All rights reserved.
 This file contains confidential and proprietary information 
 of Xilinx, Inc. and is protected under U.S. and
 international copyright and other intellectual property 
 laws.
 
 DISCLAIMER
 This disclaimer is not a license and does not grant any 
 rights to the materials distributed herewith. Except as 
 otherwise provided in a valid license issued to you by 
 Xilinx, and to the maximum extent permitted by applicable
 law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
 WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES 
 AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING 
 BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
 INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and 
 (2) Xilinx shall not be liable (whether in contract or tort, 
 including negligence, or under any other theory of 
 liability) for any loss or damage of any kind or nature 
 related to, arising under or in connection with these 
 materials, including for any direct, or any indirect, 
 special, incidental, or consequential loss or damage 
 (including loss of data, profits, goodwill, or any type of 
 loss or damage suffered as a result of any action brought 
 by a third party) even if such damage or loss was 
 reasonably foreseeable or Xilinx had been advised of the 
 possibility of the same.
 
 CRITICAL APPLICATIONS
 Xilinx products are not designed or intended to be fail-
 safe, or for use in any application requiring fail-safe
 performance, such as life-support or safety devices or 
 systems, Class III medical devices, nuclear facilities, 
 applications related to the deployment of airbags, or any 
 other applications that could lead to death, personal 
 injury, or severe property or environmental damage 
 (individually and collectively, "Critical 
 Applications"). Customer assumes the sole risk and 
 liability of any use of Xilinx products in Critical 
 Applications, subject only to applicable laws and 
 regulations governing limitations on product liability.
 
 THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS 
 PART OF THIS FILE AT ALL TIMES.
*/

`define MODE_PRODUCER 0
`define MODE_LATENCY  1
`define MODE_LOOPBACK 2
`define MODE_CONSUMER 3

`default_nettype wire
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module segment_generator #(
  parameter integer AXIS_TDATA_WIDTH      = 512,
  parameter integer AXIS_SUMMARY_WIDTH    = 128,
  parameter integer STREAMING_TDEST_WIDTH =  16
)(
  // System clocks and resets
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS_n2k:M_AXIS_k2n:M_AXIS_summary, ASSOCIATED_RESET ap_rst_n" *)
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
  output  reg                                 S_AXIS_n2k_tready,
  // AXI4-Stream streaming kernel to network layer
  output  reg       [AXIS_TDATA_WIDTH-1:0]    M_AXIS_k2n_tdata,
  output  reg     [AXIS_TDATA_WIDTH/8-1:0]    M_AXIS_k2n_tkeep,
  output  reg                                 M_AXIS_k2n_tvalid,
  output  reg                                 M_AXIS_k2n_tlast,
  output wire  [STREAMING_TDEST_WIDTH-1:0]    M_AXIS_k2n_tdest,
  input  wire                                 M_AXIS_k2n_tready,

  // AXI4-Stream kernel to summary collector
  output  reg     [AXIS_SUMMARY_WIDTH-1:0]    M_AXIS_summary_tdata,
  output  reg                                 M_AXIS_summary_tvalid,
  output  reg                                 M_AXIS_summary_tlast,
  input  wire                                 M_AXIS_summary_tready,

  input wire                        [39:0]    number_packets,
  input wire                        [15:0]    number_beats,
  input wire                        [31:0]    time_between_packets,
  input wire   [STREAMING_TDEST_WIDTH-1:0]    dest_id,
  input wire                         [1:0]    mode,
  input wire                                  ap_start,
  output reg                                  ap_idle,
  output reg                                  ap_done
);


  reg                      [63:0] free_running_counter = 64'h0;
  reg                      [39:0] number_packets_1d, packet_counter;
  reg                      [31:0] time_between_packets_1d, time_between_packets_counter;
  reg                      [15:0] number_beats_1d, number_beats_counter;
  reg [STREAMING_TDEST_WIDTH-1:0] dest_id_1d;
  reg                             ap_start_1d = 1'b0;
  reg                             axis_switch = 1'b0;
  reg                       [1:0] mode_1d = 2'h0;

  reg       [AXIS_TDATA_WIDTH-1:0]    producer_tdata  = {(AXIS_TDATA_WIDTH/8){1'b1}};
  reg     [AXIS_TDATA_WIDTH/8-1:0]    producer_tkeep  = {((AXIS_TDATA_WIDTH/8)){1'b1}};
  reg                                 producer_tvalid = 1'b0;
  reg                                 producer_tlast  = 1'b0;
  reg                                 summary_idle = 1'b1; 
  reg                                 summary_done = 1'b0; 

  wire                                axis_producer_free;
  wire                                axis_summary_free;

  assign axis_producer_free = M_AXIS_k2n_tready     | ~M_AXIS_k2n_tvalid;
  assign axis_summary_free  = M_AXIS_summary_tready | ~M_AXIS_summary_tvalid;
  assign M_AXIS_k2n_tdest   = dest_id;
  
  always @(*) begin
    if (axis_switch == 0) begin
      M_AXIS_k2n_tdata  <= producer_tdata;
      M_AXIS_k2n_tkeep  <= producer_tkeep;
      M_AXIS_k2n_tvalid <= producer_tvalid;
      M_AXIS_k2n_tlast  <= producer_tlast;
      if ((mode_1d == `MODE_LATENCY) || (mode_1d == `MODE_CONSUMER))
        S_AXIS_n2k_tready <= M_AXIS_summary_tready;
      else
        S_AXIS_n2k_tready <= 1'b1;
    end
    else begin
      M_AXIS_k2n_tdata  <= S_AXIS_n2k_tdata;
      M_AXIS_k2n_tvalid <= S_AXIS_n2k_tvalid;
      S_AXIS_n2k_tready <= M_AXIS_k2n_tready;
      M_AXIS_k2n_tkeep  <= S_AXIS_n2k_tkeep;
      M_AXIS_k2n_tlast  <= S_AXIS_n2k_tlast;
    end
  end


  localparam      GET_CONFIGURATION           = 0,
                  PRODUCE_PAYLOAD_HEADER      = 1,
                  PRODUCE_PAYLOAD_REMAINING   = 2,
                  WAIT_N_CYCLES               = 3,
                  FSM_DONE                    = 4,
                  PRODUCE_SMALL               = 5,
                  WAIT_N_CYCLES_LATENCY       = 6,
                  FSM_SUMMARY_DONE            = 7;

  
  reg [3:0]      fsm_state = GET_CONFIGURATION;

  always @(posedge ap_clk) begin
    if (~ap_rst_n) begin
      ap_done            <= 1'b0;
      ap_idle            <= 1'b1;
      producer_tdata     <= {(AXIS_TDATA_WIDTH/8){1'b1}};
      producer_tvalid    <= 1'b0;
      producer_tlast     <= 1'b0;
      packet_counter     <= 40'h0;
      mode_1d            <= 2'h0;
      fsm_state          <= GET_CONFIGURATION;
    end
    else begin
      producer_tvalid <= producer_tvalid & ~M_AXIS_k2n_tready;
      producer_tlast  <= producer_tlast  & ~M_AXIS_k2n_tready;
  
      case (fsm_state)
        GET_CONFIGURATION : begin
          ap_done            <= 1'b0;
          ap_idle            <= 1'b1;
          if (ap_start == 1'b0 && ap_start_1d == 1'b1) begin
            number_packets_1d             <= number_packets;
            number_beats_1d               <= number_beats;

            time_between_packets_1d       <= time_between_packets;
            time_between_packets_counter  <= time_between_packets;
            dest_id_1d                    <= dest_id;
            packet_counter                <= 40'h0;
            ap_done                       <= 1'b0;
            ap_idle                       <= 1'b0;
            axis_switch                   <= 1'b0;
            mode_1d                       <= mode;
            case (mode)
              `MODE_PRODUCER: begin
                fsm_state   <= PRODUCE_PAYLOAD_HEADER;
              end
              `MODE_LATENCY: begin
                fsm_state   <= PRODUCE_SMALL;
              end
              `MODE_LOOPBACK: begin
                axis_switch <= 1'b1;
                fsm_state   <= FSM_SUMMARY_DONE;
              end
              `MODE_CONSUMER: begin
                fsm_state   <= FSM_SUMMARY_DONE;
              end
            endcase
          end
        end
        PRODUCE_PAYLOAD_HEADER : begin
          if (axis_producer_free) begin
            producer_tdata[ 39:  0]      <= packet_counter;
            producer_tdata[ 79: 40]      <= free_running_counter[39:0];
            producer_tdata[119: 80]      <= number_packets_1d;
            producer_tkeep               <= {((AXIS_TDATA_WIDTH/8)){1'b1}};
            producer_tvalid              <= 1'b1;

            packet_counter               <= packet_counter + 1;

            time_between_packets_counter <= time_between_packets_1d - 1;
            number_beats_counter         <= number_beats_1d - 1;
            
            if (number_beats_1d == 1) begin
              producer_tlast <= 1'b1;
              if ((packet_counter + 1) == number_packets_1d)
                fsm_state                    <= FSM_DONE;
              else if (time_between_packets_1d != 0)
                fsm_state                    <= WAIT_N_CYCLES;
            end
            else if (number_beats_1d > 1) begin
                fsm_state                    <= PRODUCE_PAYLOAD_REMAINING;
            end
            else 
              fsm_state       <= PRODUCE_PAYLOAD_HEADER;
          end
        end
        PRODUCE_PAYLOAD_REMAINING : begin
          if (axis_producer_free) begin
            producer_tvalid              <= 1'b1;
            number_beats_counter         <= number_beats_counter - 1;
            time_between_packets_counter <= time_between_packets_1d - 1;
            if (number_beats_counter == 1) begin
              producer_tlast <= 1'b1;
              if (packet_counter == number_packets_1d) begin
                fsm_state                    <= FSM_DONE;
              end
              else if (time_between_packets_1d != 0)
                fsm_state                    <= WAIT_N_CYCLES;
              else
                fsm_state                    <= PRODUCE_PAYLOAD_HEADER;
            end
          end
        end
        WAIT_N_CYCLES: begin
          time_between_packets_counter <= time_between_packets_counter - 1;
          if (time_between_packets_counter == 0)
              fsm_state                    <= PRODUCE_PAYLOAD_HEADER;
          
        end
        PRODUCE_SMALL: begin
          if (axis_producer_free) begin
            producer_tdata[ 39:  0]      <= packet_counter;
            producer_tdata[ 79: 40]      <= free_running_counter[39:0];
            producer_tdata[119: 80]      <= number_packets_1d;
            producer_tkeep               <= {18{1'b1}};                   // Produce minimum packet for latency
            producer_tvalid              <= 1'b1;
            producer_tlast               <= 1'b1;

            packet_counter               <= packet_counter + 1;
            time_between_packets_counter <= time_between_packets_1d - 1;
            
            if ((packet_counter + 1) == number_packets_1d)
              fsm_state                    <= FSM_SUMMARY_DONE;
            else if (time_between_packets_1d != 0)
              fsm_state                    <= WAIT_N_CYCLES_LATENCY;


          end
        end
        WAIT_N_CYCLES_LATENCY: begin
          time_between_packets_counter <= time_between_packets_counter - 1;
          if (time_between_packets_counter == 0)
              fsm_state                    <= PRODUCE_SMALL;
        end
        FSM_DONE: begin
          ap_done            <= 1'b1;
          fsm_state       <= GET_CONFIGURATION;
        end
        FSM_SUMMARY_DONE: begin
          if (summary_idle == 1'b0 && summary_done== 1'b1) begin
            ap_done         <= 1'b1;
            fsm_state       <= GET_CONFIGURATION;
          end
        end
      endcase
    end
  end                  

  always @(posedge ap_clk) begin
    ap_start_1d <= ap_start;
  end

  always @(posedge ap_clk) begin
    if (ap_start == 1'b0 && ap_start_1d == 1'b1) begin        // Reset counter with rising edge of ap_start
      free_running_counter <= 64'h0;
    end
    else begin
      free_running_counter <= free_running_counter + 1;
    end
  end


  localparam      WAIT_UNTIL_MODE  = 0,
                  WAIT_PACKET      = 1,
                  CONSUME_PACKET   = 2,
                  SUMMARY_DONE     = 3;

  reg      [1:0]  fsm_summary_state = WAIT_UNTIL_MODE;
  reg             output_summary_mask;
  reg             end_of_stream = 1'b0;
  reg             ap_idle_1d = 1'b0;
  reg     [31:0]  timeout_counter = 32'h0;
  localparam      MAX_TIMEOUT = 150000000;


  always @(posedge ap_clk) begin
    if (~ap_rst_n) begin
      M_AXIS_summary_tdata  <= {AXIS_SUMMARY_WIDTH{1'b0}};
      M_AXIS_summary_tvalid <= 1'b0;
      M_AXIS_summary_tlast  <= 1'b0;
      summary_idle          <= 1'b1; 
      summary_done          <= 1'b0; 
      output_summary_mask   <= 1'b0;
      ap_idle_1d            <= 1'b0;
      fsm_summary_state     <= WAIT_UNTIL_MODE;
    end
    else begin
      M_AXIS_summary_tvalid <= M_AXIS_summary_tvalid & ~M_AXIS_summary_tready;
      M_AXIS_summary_tlast  <= M_AXIS_summary_tlast  & ~M_AXIS_summary_tready;
      ap_idle_1d            <= ap_idle;
      case (fsm_summary_state)
        WAIT_UNTIL_MODE : begin
          summary_idle <= 1'b1;
          if ((ap_idle == 1'b0) && (ap_idle_1d == 1'b1)) begin
            if ((mode_1d == `MODE_LATENCY) || (mode_1d == `MODE_CONSUMER)) begin
              output_summary_mask <= (mode_1d == `MODE_CONSUMER) ? 1'b0 : 1'b1;
              summary_idle        <= 1'b0;
              summary_done        <= 1'b0;
              end_of_stream       <= 1'b0;
              timeout_counter     <= 32'h0;
              fsm_summary_state   <= WAIT_PACKET;
            end
          end
        end
        WAIT_PACKET : begin
          if (end_of_stream || (timeout_counter == MAX_TIMEOUT)) begin
            fsm_summary_state <= SUMMARY_DONE;
          end
          else if (axis_summary_free && S_AXIS_n2k_tvalid) begin
            timeout_counter <= 32'h0;
            M_AXIS_summary_tdata[ 79:  0] <= S_AXIS_n2k_tdata[79:0];
            M_AXIS_summary_tdata[119: 80] <= free_running_counter[39:0];
            M_AXIS_summary_tvalid         <= output_summary_mask;
            if (S_AXIS_n2k_tdata[39:0] == (S_AXIS_n2k_tdata[119:80] - 1)) begin
              end_of_stream <= 1'b1;
            end
            if (!S_AXIS_n2k_tlast) begin
              fsm_summary_state <= CONSUME_PACKET;
            end
          end
          else begin
            timeout_counter <= timeout_counter + 1;
          end
        end
        CONSUME_PACKET : begin
          if (S_AXIS_n2k_tvalid && S_AXIS_n2k_tready && S_AXIS_n2k_tlast) begin
              fsm_summary_state <= WAIT_PACKET;
          end
        end
        SUMMARY_DONE: begin
          if (axis_summary_free) begin
            M_AXIS_summary_tvalid <= output_summary_mask;
            M_AXIS_summary_tlast  <= output_summary_mask;
            summary_done          <= 1'b1;
            fsm_summary_state     <= WAIT_UNTIL_MODE;
          end
        end
      endcase
    end
  end



endmodule