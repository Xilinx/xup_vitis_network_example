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

module cmac_lbus_aligner #(
  parameter C_TRANSMISSION_SEGMENTS = 4  ,
  parameter C_DATA_WIDTH            = 512,  // I would not change these parameters...
  parameter TIMESTAMP_WIDTH         = 64 
) (
  input  wire                                 CLK                    ,
  input  wire                                 RST_N                  ,
  input  wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_EN        ,
  input  wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_SOP       ,
  input  wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_EOP       ,
  input  wire [4*C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_MTY       ,
  input  wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_ERR       ,
  input  wire [             C_DATA_WIDTH-1:0] CMAC_LBUS_RX_DATA      ,
  output wire                                 CMAC_LBUS_RX_USER_RST_I,
  input  wire                                 CMAC_LBUS_RX_USER_RST_O,
  output wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_EN_O      ,
  output wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_SOP_O     ,
  output wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_EOP_O     ,
  output wire [4*C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_MTY_O     ,
  output wire [  C_TRANSMISSION_SEGMENTS-1:0] CMAC_LBUS_RX_ERR_O     ,
  output wire [             C_DATA_WIDTH-1:0] CMAC_LBUS_RX_DATA_O    
);


  assign CMAC_LBUS_RX_USER_RST_I = 1'b0;

  wire user_rst;
  assign user_rst = CMAC_LBUS_RX_USER_RST_O | !RST_N;


  reg [C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_en_r   ;
  reg [C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_en_p1_r;
  assign CMAC_LBUS_RX_EN_O = cmac_lbus_rx_en_p1_r;
  reg [C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_sop_r   ;
  reg [C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_sop_p1_r;
  assign CMAC_LBUS_RX_SOP_O = cmac_lbus_rx_sop_p1_r;
  reg [C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_eop_r   ;
  reg [C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_eop_p1_r;
  assign CMAC_LBUS_RX_EOP_O = cmac_lbus_rx_eop_p1_r;
  reg [4*C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_mty_r   ;
  reg [4*C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_mty_p1_r;
  assign CMAC_LBUS_RX_MTY_O = cmac_lbus_rx_mty_p1_r;
  reg [C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_err_r   ;
  reg [C_TRANSMISSION_SEGMENTS-1:0] cmac_lbus_rx_err_p1_r;
  assign CMAC_LBUS_RX_ERR_O = cmac_lbus_rx_err_p1_r;
  reg [C_DATA_WIDTH-1:0] cmac_lbus_rx_data_r   ;
  reg [C_DATA_WIDTH-1:0] cmac_lbus_rx_data_p1_r;
  assign CMAC_LBUS_RX_DATA_O = cmac_lbus_rx_data_p1_r;

  // Current state of the FSM
  reg [2:0] pkt_state  ;
  reg [2:0] pkt_state_r;

  localparam IDLE                       = 3'b000;
  localparam PKT_IN_BURST               = 3'b011;
  localparam END_PKT_NO_BURST           = 3'b100;
  localparam END_PKT_IN_BURST           = 3'b101;
  localparam FIRST_PART_OF_PKT_IN_BURST = 3'b110;

  // Some definitions of the module. They are not supposed to change, so they are not configure
  // as global parameters.
  localparam c_circular_buffer_size = 8;


  integer i;
  function [1:0] onedigit2number_func(input  [3:0] number);
    begin
      onedigit2number_func = 0;
      for (i = 0 ; i < 4; i=i+1) begin
        if(number[i])
          onedigit2number_func = i;
      end
    end
  endfunction

  function integer clog;
    input [31:0] value;
    integer  i;
    begin
      clog = 0;
      for(i = 0; 2**i < value; i = i + 1)
        clog = i + 1;
    end
  endfunction

  localparam buffer_size_clog_c = clog(c_circular_buffer_size);
  localparam buffer_size_c      = (1<<buffer_size_clog_c)     ;


  // Buffer
  reg [C_DATA_WIDTH+(4+1+1+1+1)*C_TRANSMISSION_SEGMENTS+64-1:0] data_buffer[buffer_size_c-1:0];
  // Number of elements inside the buffer
  wire [buffer_size_clog_c:0] bufd_occupancy;
  // Is the buffer full?
  wire bufd_full;
  // Next element to read
  reg [buffer_size_clog_c:0] bufd_rd_ptr;
  // Next position where it is possible to write
  reg [buffer_size_clog_c:0] bufd_wr_ptr;



  // Define some constants
  assign bufd_full      = bufd_occupancy[buffer_size_clog_c];
  assign bufd_occupancy = bufd_wr_ptr - bufd_rd_ptr;

  // And the function that truncates the vectors
  function [buffer_size_clog_c-1:0] trunc(input [buffer_size_clog_c:0] value);
    trunc = value[buffer_size_clog_c-1:0];
  endfunction


  wire   [C_DATA_WIDTH+(4+1+1+1+1)*C_TRANSMISSION_SEGMENTS -1:0] wdata_s        ;
  wire   [C_DATA_WIDTH+(4+1+1+1+1)*C_TRANSMISSION_SEGMENTS -1:0] fifo_rdata_s   ;
  reg    [C_DATA_WIDTH+(4+1+1+1+1)*C_TRANSMISSION_SEGMENTS -1:0] fifo_wdata_r   ;
  reg                                                            fifo_wr_en_r   ;
  reg                                                            fifo_rd_en_r   ;
  reg                                                            fifo_rd_en_p1_r;
  reg                                                            fifo_rd_en_p2_r;
  wire                                                           fifo_empty_s   ;

  assign wdata_s = {
    CMAC_LBUS_RX_ERR[0],CMAC_LBUS_RX_ERR[1],CMAC_LBUS_RX_ERR[2],CMAC_LBUS_RX_ERR[3],
    CMAC_LBUS_RX_EN[0],CMAC_LBUS_RX_EN[1],CMAC_LBUS_RX_EN[2],CMAC_LBUS_RX_EN[3],
    CMAC_LBUS_RX_SOP[0],CMAC_LBUS_RX_SOP[1],CMAC_LBUS_RX_SOP[2],CMAC_LBUS_RX_SOP[3],
    CMAC_LBUS_RX_EOP[0],CMAC_LBUS_RX_EOP[1],CMAC_LBUS_RX_EOP[2],CMAC_LBUS_RX_EOP[3],
    CMAC_LBUS_RX_MTY[0+:4],CMAC_LBUS_RX_MTY[4+:4],CMAC_LBUS_RX_MTY[8+:4],CMAC_LBUS_RX_MTY[12+:4],
    CMAC_LBUS_RX_DATA};

  wire [C_TRANSMISSION_SEGMENTS-1:0] en_s           ;
  reg                                fifo_empty_r   ;
  reg                                fifo_empty_p2_r;



  wire [C_DATA_WIDTH-1:0] prev_packet_data_s; // prev_packet_data_s will contain the data of the buffered transaction
  wire [C_DATA_WIDTH-1:0] curr_packet_data_s; // curr_packet_data_s will contain the data of the current transaction

  wire [C_TRANSMISSION_SEGMENTS-1:0] prev_lbus_packet_rx_err_s                             ;
  wire [C_TRANSMISSION_SEGMENTS-1:0] prev_lbus_packet_rx_en_s                              ;
  wire [C_TRANSMISSION_SEGMENTS-1:0] prev_lbus_packet_rx_sop_s                             ;
  reg  [C_TRANSMISSION_SEGMENTS-1:0] prev_lbus_packet_rx_sop_r                             ;
  wire [C_TRANSMISSION_SEGMENTS-1:0] prev_lbus_packet_rx_eop_s                             ;
  wire [                        3:0] prev_lbus_packet_rx_mty_s[C_TRANSMISSION_SEGMENTS-1:0];


  wire [C_TRANSMISSION_SEGMENTS-1:0] curr_lbus_packet_rx_err_s                             ;
  wire [C_TRANSMISSION_SEGMENTS-1:0] curr_lbus_packet_rx_en_s                              ;
  wire [C_TRANSMISSION_SEGMENTS-1:0] curr_lbus_packet_rx_sop_s                             ;
  wire [C_TRANSMISSION_SEGMENTS-1:0] curr_lbus_packet_rx_eop_s                             ;
  wire [                        3:0] curr_lbus_packet_rx_mty_s[C_TRANSMISSION_SEGMENTS-1:0];

  wire [C_TRANSMISSION_SEGMENTS-1:0] next_lbus_packet_rx_en_s ;
  wire [C_TRANSMISSION_SEGMENTS-1:0] next_lbus_packet_rx_eop_s;
  assign en_s = CMAC_LBUS_RX_EN;

  always @(posedge CLK) begin
    if(user_rst) begin
      fifo_wdata_r    <= 0;
      fifo_empty_r    <= 1'b1;
      fifo_empty_p2_r <= 1'b1;
    end else begin
      fifo_empty_r    <= fifo_empty_s;
      fifo_empty_p2_r <= fifo_empty_r;
      fifo_wdata_r    <= wdata_s;
    end
  end

  always @(posedge CLK) begin
    if(user_rst) begin
      bufd_wr_ptr <= 0;
      for(i=0;i<buffer_size_c;i=i+1) begin
        data_buffer[i] <= 'h0;
      end
    end else begin
      if(fifo_rd_en_p2_r & !fifo_empty_p2_r) begin
        data_buffer[trunc(bufd_wr_ptr)] <= fifo_rdata_s;
        bufd_wr_ptr                     <= bufd_wr_ptr +1;
      end
    end
  end

  always @(posedge CLK) begin
    if(user_rst) begin
      fifo_rd_en_r    <= 1'h0;
      fifo_rd_en_p1_r <= 1'h0;
      fifo_rd_en_p2_r <= 1'h0;
    end else begin
      if(bufd_occupancy<=(c_circular_buffer_size-2) && !fifo_empty_s) begin
        fifo_rd_en_r <= 1'h1;
      end else begin
        fifo_rd_en_r <= 1'h0;
      end
      fifo_rd_en_p1_r <= fifo_rd_en_r;
      fifo_rd_en_p2_r <= fifo_rd_en_p1_r;
    end
  end


  always @(posedge CLK) begin
    if(user_rst) begin
      fifo_wr_en_r <= 1'b0;
    end else begin
      if(en_s) begin
        fifo_wr_en_r <= 1'h1;
      end else begin
        fifo_wr_en_r <= 1'h0;
      end
    end
  end

  lbus_fifo lbus_fifo_i (
    .clk  (CLK         ), // input wire clk
    .rst  (user_rst    ), // input wire srst
    .din  (fifo_wdata_r), // input wire [535 : 0] din
    .wr_en(fifo_wr_en_r), // input wire wr_en
    .rd_en(fifo_rd_en_r), // input wire rd_en
    .dout (fifo_rdata_s), // output wire [531 : 0] dout
    .full (            ), // output wire full
    .empty(fifo_empty_s)
  );

  /**
  * Circular buffer. Reading the data. As we present an AXI4-Stream bus, we have to wait until the previous operation
  * is finished. However, there is a pair of special states (END_PKT_NO_BURST) that do not require of this measure.
  *
  * This is explained because the previous state (PKT_IN_BURST) checked for the validity of two segments,
  * the buffered one and the last fragment of the packet.
  */
  reg  [ 1:0] misaligned               ; // Padding in the LBUS bus
  wire        pkt_available_in_buffer_s;
  wire        is_end_of_fragment_s     ;
  wire        is_start_of_fragment_s   ;
  assign pkt_available_in_buffer_s = bufd_occupancy>0;

  assign prev_packet_data_s = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][511:0];
  assign curr_packet_data_s = data_buffer[trunc(bufd_rd_ptr)][511:0];


  assign prev_lbus_packet_rx_err_s[0] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+31];
  assign prev_lbus_packet_rx_err_s[1] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+30];
  assign prev_lbus_packet_rx_err_s[2] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+29];
  assign prev_lbus_packet_rx_err_s[3] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+28];
  assign prev_lbus_packet_rx_en_s[0]  = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+27];
  assign prev_lbus_packet_rx_en_s[1]  = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+26];
  assign prev_lbus_packet_rx_en_s[2]  = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+25];
  assign prev_lbus_packet_rx_en_s[3]  = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+24];
  assign prev_lbus_packet_rx_sop_s[0] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+23];
  assign prev_lbus_packet_rx_sop_s[1] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+22];
  assign prev_lbus_packet_rx_sop_s[2] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+21];
  assign prev_lbus_packet_rx_sop_s[3] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+20];
  assign prev_lbus_packet_rx_eop_s[0] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+19];
  assign prev_lbus_packet_rx_eop_s[1] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+18];
  assign prev_lbus_packet_rx_eop_s[2] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+17];
  assign prev_lbus_packet_rx_eop_s[3] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+16];
  assign prev_lbus_packet_rx_mty_s[0] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+12 +:4];
  assign prev_lbus_packet_rx_mty_s[1] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+8 +:4];
  assign prev_lbus_packet_rx_mty_s[2] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+4 +:4];
  assign prev_lbus_packet_rx_mty_s[3] = data_buffer[trunc(bufd_rd_ptr+c_circular_buffer_size-1)][512+0 +:4];

  assign curr_lbus_packet_rx_err_s[0] = data_buffer[trunc(bufd_rd_ptr)][512+31];
  assign curr_lbus_packet_rx_err_s[1] = data_buffer[trunc(bufd_rd_ptr)][512+30];
  assign curr_lbus_packet_rx_err_s[2] = data_buffer[trunc(bufd_rd_ptr)][512+29];
  assign curr_lbus_packet_rx_err_s[3] = data_buffer[trunc(bufd_rd_ptr)][512+28];
  assign curr_lbus_packet_rx_en_s[0]  = data_buffer[trunc(bufd_rd_ptr)][512+27];
  assign curr_lbus_packet_rx_en_s[1]  = data_buffer[trunc(bufd_rd_ptr)][512+26];
  assign curr_lbus_packet_rx_en_s[2]  = data_buffer[trunc(bufd_rd_ptr)][512+25];
  assign curr_lbus_packet_rx_en_s[3]  = data_buffer[trunc(bufd_rd_ptr)][512+24];
  assign curr_lbus_packet_rx_sop_s[0] = data_buffer[trunc(bufd_rd_ptr)][512+23];
  assign curr_lbus_packet_rx_sop_s[1] = data_buffer[trunc(bufd_rd_ptr)][512+22];
  assign curr_lbus_packet_rx_sop_s[2] = data_buffer[trunc(bufd_rd_ptr)][512+21];
  assign curr_lbus_packet_rx_sop_s[3] = data_buffer[trunc(bufd_rd_ptr)][512+20];
  assign curr_lbus_packet_rx_eop_s[0] = data_buffer[trunc(bufd_rd_ptr)][512+19];
  assign curr_lbus_packet_rx_eop_s[1] = data_buffer[trunc(bufd_rd_ptr)][512+18];
  assign curr_lbus_packet_rx_eop_s[2] = data_buffer[trunc(bufd_rd_ptr)][512+17];
  assign curr_lbus_packet_rx_eop_s[3] = data_buffer[trunc(bufd_rd_ptr)][512+16];
  assign curr_lbus_packet_rx_mty_s[0] = data_buffer[trunc(bufd_rd_ptr)][512+12 +:4];
  assign curr_lbus_packet_rx_mty_s[1] = data_buffer[trunc(bufd_rd_ptr)][512+8 +:4];
  assign curr_lbus_packet_rx_mty_s[2] = data_buffer[trunc(bufd_rd_ptr)][512+4 +:4];
  assign curr_lbus_packet_rx_mty_s[3] = data_buffer[trunc(bufd_rd_ptr)][512+0 +:4];

  assign is_end_of_fragment_s   = (curr_lbus_packet_rx_en_s && (curr_lbus_packet_rx_eop_s || curr_lbus_packet_rx_err_s));
  assign is_start_of_fragment_s = (curr_lbus_packet_rx_en_s && curr_lbus_packet_rx_sop_s);

  always @(posedge CLK) begin
    if(user_rst) begin
      cmac_lbus_rx_en_p1_r        <= 'h0;
      cmac_lbus_rx_sop_p1_r       <= 'h0;
      cmac_lbus_rx_eop_p1_r       <= 'h0;
      cmac_lbus_rx_mty_p1_r       <= 'h0;
      cmac_lbus_rx_err_p1_r       <= 'h0;
      cmac_lbus_rx_data_p1_r      <= 'h0;
    end else begin
      cmac_lbus_rx_en_p1_r        <= cmac_lbus_rx_en_r;
      cmac_lbus_rx_sop_p1_r       <= cmac_lbus_rx_sop_r;
      cmac_lbus_rx_eop_p1_r       <= cmac_lbus_rx_eop_r;
      cmac_lbus_rx_mty_p1_r       <= cmac_lbus_rx_mty_r;
      cmac_lbus_rx_err_p1_r       <= cmac_lbus_rx_err_r;
      cmac_lbus_rx_data_p1_r      <= cmac_lbus_rx_data_r;
    end
  end

  always @(posedge CLK) begin
    if(user_rst) begin
      cmac_lbus_rx_en_r   <= 'h0;
      cmac_lbus_rx_sop_r  <= 'h0;
      cmac_lbus_rx_eop_r  <= 'h0;
      cmac_lbus_rx_mty_r  <= 'h0;
      cmac_lbus_rx_err_r  <= 'h0;
      cmac_lbus_rx_data_r <= 'h0;
    end else begin
      cmac_lbus_rx_en_r   <= 'h0;
      cmac_lbus_rx_sop_r  <= 'h0;
      cmac_lbus_rx_eop_r  <= 'h0;
      cmac_lbus_rx_mty_r  <= 'h0;
      cmac_lbus_rx_err_r  <= 'h0;
      cmac_lbus_rx_data_r <= 'h0;

      case (pkt_state)
        // Everything is aligned, so by the time the first that a fragment arrives we can deliver it
        IDLE : begin
          if(pkt_available_in_buffer_s) begin
            cmac_lbus_rx_en_r   <= curr_lbus_packet_rx_en_s;
            cmac_lbus_rx_sop_r  <= curr_lbus_packet_rx_sop_s;
            cmac_lbus_rx_eop_r  <= curr_lbus_packet_rx_eop_s;
            cmac_lbus_rx_mty_r  <= {curr_lbus_packet_rx_mty_s[3],curr_lbus_packet_rx_mty_s[2],curr_lbus_packet_rx_mty_s[1],curr_lbus_packet_rx_mty_s[0]};
            cmac_lbus_rx_err_r  <= curr_lbus_packet_rx_err_s;
            cmac_lbus_rx_data_r <= curr_packet_data_s;
          end
        end
        PKT_IN_BURST : begin
          case(misaligned)
            2'b11 : begin
              cmac_lbus_rx_en_r[0]  <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[3];
              cmac_lbus_rx_en_r[1]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[0] & !curr_lbus_packet_rx_sop_s[0];
              cmac_lbus_rx_en_r[2]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[1] & !curr_lbus_packet_rx_sop_s[0] & !curr_lbus_packet_rx_sop_s[1];
              cmac_lbus_rx_en_r[3]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[2] & !curr_lbus_packet_rx_sop_s[0] & !curr_lbus_packet_rx_sop_s[1]& !curr_lbus_packet_rx_sop_s[2];
              cmac_lbus_rx_sop_r[0] <= prev_lbus_packet_rx_sop_s[3];
              cmac_lbus_rx_sop_r[1] <= curr_lbus_packet_rx_sop_s[0] & !curr_lbus_packet_rx_sop_s[0];
              cmac_lbus_rx_sop_r[2] <= curr_lbus_packet_rx_sop_s[1] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1];
              cmac_lbus_rx_sop_r[3] <= curr_lbus_packet_rx_sop_s[2] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1]& !curr_lbus_packet_rx_sop_s[2];
              cmac_lbus_rx_eop_r    <= {curr_lbus_packet_rx_eop_s[2:0], prev_lbus_packet_rx_eop_s[3]};
              cmac_lbus_rx_mty_r    <= {curr_lbus_packet_rx_mty_s[2],curr_lbus_packet_rx_mty_s[1],curr_lbus_packet_rx_mty_s[0], prev_lbus_packet_rx_mty_s[3]};
              cmac_lbus_rx_err_r    <= {curr_lbus_packet_rx_err_s[2:0], prev_lbus_packet_rx_err_s[3]};
              cmac_lbus_rx_data_r   <= {prev_packet_data_s[0+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], curr_packet_data_s[(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)*1+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)]};

            end
            2'b10 : begin
              cmac_lbus_rx_en_r[0]  <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[1];
              cmac_lbus_rx_en_r[1]  <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[3];
              cmac_lbus_rx_en_r[2]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[0] & !curr_lbus_packet_rx_sop_s[0];
              cmac_lbus_rx_en_r[3]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[1] & !curr_lbus_packet_rx_sop_s[0] & !curr_lbus_packet_rx_sop_s[1];
              cmac_lbus_rx_sop_r[0] <= prev_lbus_packet_rx_sop_s[2];
              cmac_lbus_rx_sop_r[1] <= prev_lbus_packet_rx_sop_s[3];
              cmac_lbus_rx_sop_r[2] <= curr_lbus_packet_rx_sop_s[0] & !curr_lbus_packet_rx_sop_s[0];
              cmac_lbus_rx_sop_r[3] <= curr_lbus_packet_rx_sop_s[1] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1];

              cmac_lbus_rx_eop_r  <= {curr_lbus_packet_rx_eop_s[1:0], prev_lbus_packet_rx_eop_s[3:2]};
              cmac_lbus_rx_mty_r  <= {curr_lbus_packet_rx_mty_s[1],curr_lbus_packet_rx_mty_s[0], prev_lbus_packet_rx_mty_s[3], prev_lbus_packet_rx_mty_s[2]};
              cmac_lbus_rx_err_r  <= {curr_lbus_packet_rx_err_s[1:0], prev_lbus_packet_rx_err_s[3:2]};
              cmac_lbus_rx_data_r <= {prev_packet_data_s[0+:2*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], curr_packet_data_s[(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)*2+:2*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)]};
            end
            2'b01 : begin
              cmac_lbus_rx_en_r[0]  <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[1];
              cmac_lbus_rx_en_r[1]  <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[2];
              cmac_lbus_rx_en_r[2]  <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[3];
              cmac_lbus_rx_en_r[3]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[0] & !curr_lbus_packet_rx_sop_s[0];
              cmac_lbus_rx_sop_r[0] <= prev_lbus_packet_rx_sop_s[1];
              cmac_lbus_rx_sop_r[1] <= prev_lbus_packet_rx_sop_s[2];
              cmac_lbus_rx_sop_r[2] <= prev_lbus_packet_rx_sop_s[3];
              cmac_lbus_rx_sop_r[3] <= curr_lbus_packet_rx_sop_s[0] & !curr_lbus_packet_rx_sop_s[0];

              cmac_lbus_rx_eop_r  <= {curr_lbus_packet_rx_eop_s[0], prev_lbus_packet_rx_eop_s[3:1]};
              cmac_lbus_rx_mty_r  <= {curr_lbus_packet_rx_mty_s[0], prev_lbus_packet_rx_mty_s[3],prev_lbus_packet_rx_mty_s[2],prev_lbus_packet_rx_mty_s[1]};
              cmac_lbus_rx_err_r  <= {curr_lbus_packet_rx_err_s[0], prev_lbus_packet_rx_err_s[3:1]};
              cmac_lbus_rx_data_r <= {prev_packet_data_s[0+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], curr_packet_data_s[(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)*3+:(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)]};

            end
            default : begin
              cmac_lbus_rx_en_r[0]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[0] ;
              cmac_lbus_rx_en_r[1]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[1] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1];
              cmac_lbus_rx_en_r[2]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[2] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1]& !curr_lbus_packet_rx_sop_s[2];
              cmac_lbus_rx_en_r[3]  <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[3] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1]& !curr_lbus_packet_rx_sop_s[2]& !curr_lbus_packet_rx_sop_s[3];
              cmac_lbus_rx_sop_r[0] <= curr_lbus_packet_rx_sop_s[0] ;
              cmac_lbus_rx_sop_r[1] <= curr_lbus_packet_rx_sop_s[1] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1];;
              cmac_lbus_rx_sop_r[2] <= curr_lbus_packet_rx_sop_s[2] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1]& !curr_lbus_packet_rx_sop_s[2];;
              cmac_lbus_rx_sop_r[3] <= curr_lbus_packet_rx_sop_s[3] & !curr_lbus_packet_rx_sop_s[0]& !curr_lbus_packet_rx_sop_s[1]& !curr_lbus_packet_rx_sop_s[2]& !curr_lbus_packet_rx_sop_s[3];;

              cmac_lbus_rx_eop_r  <= curr_lbus_packet_rx_eop_s;
              cmac_lbus_rx_mty_r  <= {curr_lbus_packet_rx_mty_s[3],curr_lbus_packet_rx_mty_s[2],curr_lbus_packet_rx_mty_s[1],curr_lbus_packet_rx_mty_s[0]};
              cmac_lbus_rx_err_r  <= curr_lbus_packet_rx_err_s;
              cmac_lbus_rx_data_r <= curr_packet_data_s;
            end
          endcase
        end
        FIRST_PART_OF_PKT_IN_BURST : begin
          case(misaligned)
            2'b11 : begin
              cmac_lbus_rx_en_r[0] <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[3];
              cmac_lbus_rx_en_r[1] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[0];
              cmac_lbus_rx_en_r[2] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[1];
              cmac_lbus_rx_en_r[3] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[2];
              cmac_lbus_rx_sop_r   <= {curr_lbus_packet_rx_sop_s[2:0], prev_lbus_packet_rx_sop_s[3]};
              cmac_lbus_rx_eop_r   <= {curr_lbus_packet_rx_eop_s[2:0], prev_lbus_packet_rx_eop_s[3]};
              cmac_lbus_rx_mty_r   <= {curr_lbus_packet_rx_mty_s[2],curr_lbus_packet_rx_mty_s[1],curr_lbus_packet_rx_mty_s[0], prev_lbus_packet_rx_mty_s[3]};
              cmac_lbus_rx_err_r   <= {curr_lbus_packet_rx_err_s[2:0], prev_lbus_packet_rx_err_s[3]};
              cmac_lbus_rx_data_r  <= {prev_packet_data_s[0+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], curr_packet_data_s[(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)*1+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)]};
            end
            2'b10 : begin
              cmac_lbus_rx_en_r[0] <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[2];
              cmac_lbus_rx_en_r[1] <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[3];
              cmac_lbus_rx_en_r[2] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[0];
              cmac_lbus_rx_en_r[3] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[1];
              cmac_lbus_rx_sop_r   <= {curr_lbus_packet_rx_sop_s[1:0], prev_lbus_packet_rx_sop_s[3:2]};


              cmac_lbus_rx_eop_r  <= {curr_lbus_packet_rx_eop_s[1:0], prev_lbus_packet_rx_eop_s[3:2]};
              cmac_lbus_rx_mty_r  <= {curr_lbus_packet_rx_mty_s[1],curr_lbus_packet_rx_mty_s[0], prev_lbus_packet_rx_mty_s[3], prev_lbus_packet_rx_mty_s[2]};
              cmac_lbus_rx_err_r  <= {curr_lbus_packet_rx_err_s[1:0], prev_lbus_packet_rx_err_s[3:2]};
              cmac_lbus_rx_data_r <= {prev_packet_data_s[0+:2*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], curr_packet_data_s[(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)*2+:2*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)]};

            end
            2'b01 : begin
              cmac_lbus_rx_en_r[0] <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[1];
              cmac_lbus_rx_en_r[1] <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[2];
              cmac_lbus_rx_en_r[2] <= pkt_available_in_buffer_s & prev_lbus_packet_rx_en_s[3];
              cmac_lbus_rx_en_r[3] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[0];
              cmac_lbus_rx_sop_r   <= {curr_lbus_packet_rx_sop_s[0], prev_lbus_packet_rx_sop_s[3:1]};


              cmac_lbus_rx_eop_r  <= {curr_lbus_packet_rx_eop_s[0], prev_lbus_packet_rx_eop_s[3:1]};
              cmac_lbus_rx_mty_r  <= {curr_lbus_packet_rx_mty_s[0], prev_lbus_packet_rx_mty_s[3],prev_lbus_packet_rx_mty_s[2],prev_lbus_packet_rx_mty_s[1]};
              cmac_lbus_rx_err_r  <= {curr_lbus_packet_rx_err_s[0], prev_lbus_packet_rx_err_s[3:1]};
              cmac_lbus_rx_data_r <= {prev_packet_data_s[0+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], curr_packet_data_s[(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)*3+:C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS]};

            end
            default : begin
              cmac_lbus_rx_en_r[0] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[0] ;
              cmac_lbus_rx_en_r[1] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[1];
              cmac_lbus_rx_en_r[2] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[2];
              cmac_lbus_rx_en_r[3] <= pkt_available_in_buffer_s & curr_lbus_packet_rx_en_s[3];
              cmac_lbus_rx_sop_r   <= 4'h1;

              cmac_lbus_rx_eop_r  <= curr_lbus_packet_rx_eop_s;
              cmac_lbus_rx_mty_r  <= {curr_lbus_packet_rx_mty_s[3],curr_lbus_packet_rx_mty_s[2],curr_lbus_packet_rx_mty_s[1],curr_lbus_packet_rx_mty_s[0]};
              cmac_lbus_rx_err_r  <= curr_lbus_packet_rx_err_s;
              cmac_lbus_rx_data_r <= curr_packet_data_s;
            end
          endcase
        end

        END_PKT_NO_BURST : begin
          case(misaligned)
            2'b11 : begin
              cmac_lbus_rx_en_r   <= {3'b0,curr_lbus_packet_rx_en_s[3]};
              cmac_lbus_rx_sop_r  <= 4'b0;
              cmac_lbus_rx_eop_r  <= {3'b0, curr_lbus_packet_rx_eop_s[3]};
              cmac_lbus_rx_mty_r  <= {12'h0, curr_lbus_packet_rx_mty_s[3]};
              cmac_lbus_rx_err_r  <= {3'b0, curr_lbus_packet_rx_err_s[3]};
              cmac_lbus_rx_data_r <= {curr_packet_data_s[0+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], {3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS){1'b0}}};
            end
            2'b10 : begin
              cmac_lbus_rx_en_r   <= {2'b0,curr_lbus_packet_rx_en_s[3:2]};
              cmac_lbus_rx_sop_r  <= 4'b0;
              cmac_lbus_rx_eop_r  <= {2'b0, curr_lbus_packet_rx_eop_s[3:2]};
              cmac_lbus_rx_mty_r  <= {8'h0, curr_lbus_packet_rx_mty_s[3],curr_lbus_packet_rx_mty_s[2]};
              cmac_lbus_rx_err_r  <= {2'b0, curr_lbus_packet_rx_err_s[3:2]};
              cmac_lbus_rx_data_r <= {curr_packet_data_s[0+:2*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], {2*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS){1'b0}}};
            end
            //  2'b01 : begin
            default : begin
              cmac_lbus_rx_en_r   <= {1'b0,curr_lbus_packet_rx_en_s[3:1]};
              cmac_lbus_rx_sop_r  <= 4'b0;
              cmac_lbus_rx_eop_r  <= {1'b0, curr_lbus_packet_rx_eop_s[3:1]};
              cmac_lbus_rx_mty_r  <= {4'h0, curr_lbus_packet_rx_mty_s[3],curr_lbus_packet_rx_mty_s[2],curr_lbus_packet_rx_mty_s[1]};
              cmac_lbus_rx_err_r  <= {1'b0, curr_lbus_packet_rx_err_s[3:1]};
              cmac_lbus_rx_data_r <= {curr_packet_data_s[0+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], {(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS){1'b0}}};
            end
            //  end
          endcase
        end
        END_PKT_IN_BURST : begin
          case(misaligned)
            2'b11 : begin
              cmac_lbus_rx_en_r[0] <= curr_lbus_packet_rx_en_s[3] & !curr_lbus_packet_rx_sop_s[3];
              cmac_lbus_rx_en_r[1] <= 1'b0;
              cmac_lbus_rx_en_r[2] <= 1'b0;
              cmac_lbus_rx_en_r[3] <= 1'b0;

              cmac_lbus_rx_sop_r  <= 4'b0;
              cmac_lbus_rx_eop_r  <= {3'b0, curr_lbus_packet_rx_eop_s[3]};
              cmac_lbus_rx_mty_r  <= {12'h0, curr_lbus_packet_rx_mty_s[3]};
              cmac_lbus_rx_err_r  <= {3'b0, curr_lbus_packet_rx_err_s[3]};
              cmac_lbus_rx_data_r <= {curr_packet_data_s[0+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], {3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS){1'b0}}};
            end
            2'b10 : begin
              cmac_lbus_rx_en_r[0] <= curr_lbus_packet_rx_en_s[2] & !curr_lbus_packet_rx_sop_s[2];
              cmac_lbus_rx_en_r[1] <= curr_lbus_packet_rx_en_s[3] & !curr_lbus_packet_rx_sop_s[3]& !curr_lbus_packet_rx_sop_s[2];
              cmac_lbus_rx_en_r[2] <= 1'b0;
              cmac_lbus_rx_en_r[3] <= 1'b0;

              cmac_lbus_rx_sop_r  <= 4'b0;
              cmac_lbus_rx_eop_r  <= {2'b0, curr_lbus_packet_rx_eop_s[3:2]};
              cmac_lbus_rx_mty_r  <= {8'h0, curr_lbus_packet_rx_mty_s[3],curr_lbus_packet_rx_mty_s[2]};
              cmac_lbus_rx_err_r  <= {2'b0, curr_lbus_packet_rx_err_s[3:2]};
              cmac_lbus_rx_data_r <= {curr_packet_data_s[0+:2*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], {2*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS){1'b0}}};
            end
            //2'b01 : begin
            default : begin
              cmac_lbus_rx_en_r[0] <= curr_lbus_packet_rx_en_s[1] & !curr_lbus_packet_rx_sop_s[1];
              cmac_lbus_rx_en_r[1] <= curr_lbus_packet_rx_en_s[2] & !curr_lbus_packet_rx_sop_s[1]& !curr_lbus_packet_rx_sop_s[2];
              cmac_lbus_rx_en_r[2] <= curr_lbus_packet_rx_en_s[3] & !curr_lbus_packet_rx_sop_s[1]& !curr_lbus_packet_rx_sop_s[2]& !curr_lbus_packet_rx_sop_s[3];
              cmac_lbus_rx_en_r[3] <= 1'b0;

              cmac_lbus_rx_sop_r  <= 4'b0;
              cmac_lbus_rx_eop_r  <= {1'b0, curr_lbus_packet_rx_eop_s[3:1]};
              cmac_lbus_rx_mty_r  <= {4'h0, curr_lbus_packet_rx_mty_s[3],curr_lbus_packet_rx_mty_s[2],curr_lbus_packet_rx_mty_s[1]};
              cmac_lbus_rx_err_r  <= {1'b0, curr_lbus_packet_rx_err_s[3:1]};
              cmac_lbus_rx_data_r <= {curr_packet_data_s[0+:3*(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS)], {(C_DATA_WIDTH/C_TRANSMISSION_SEGMENTS){1'b0}}};
            end
            //end
          endcase
        end
        default : begin
          cmac_lbus_rx_en_r   <= 'h0;
          cmac_lbus_rx_sop_r  <= 'h0;
          cmac_lbus_rx_eop_r  <= 'h0;
          cmac_lbus_rx_mty_r  <= 'h0;
          cmac_lbus_rx_err_r  <= 'h0;
          cmac_lbus_rx_data_r <= 'h0;
        end
      endcase
    end
  end

  always @(posedge CLK) begin
    if(user_rst) begin
      pkt_state       <= IDLE;
      misaligned      <= 0;
      bufd_rd_ptr     <= 0;
    end else begin

      case (pkt_state)
        IDLE : begin
          if(pkt_available_in_buffer_s) begin
            if(is_end_of_fragment_s) begin // Do we complete the packet in one pulse? Go directly to  IDLE
              pkt_state       <= IDLE;
              bufd_rd_ptr     <= bufd_rd_ptr+1;
            end else begin
              bufd_rd_ptr     <= bufd_rd_ptr+1;
              pkt_state       <= PKT_IN_BURST;
            end
          end
        end
        PKT_IN_BURST : begin
          if(pkt_available_in_buffer_s) begin
            case({is_start_of_fragment_s, is_end_of_fragment_s})
              2'b11 : begin
                case(misaligned)
                  2'b01 : begin
                    if(curr_lbus_packet_rx_eop_s>='h2) begin
                      pkt_state <= END_PKT_IN_BURST;
                    end else begin
                      pkt_state   <= FIRST_PART_OF_PKT_IN_BURST;
                      misaligned  <= onedigit2number_func(curr_lbus_packet_rx_sop_s);
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  2'b10 : begin
                    if(curr_lbus_packet_rx_eop_s>='h4) begin
                      pkt_state <= END_PKT_IN_BURST;
                    end else begin
                      pkt_state   <= FIRST_PART_OF_PKT_IN_BURST;
                      misaligned  <= onedigit2number_func(curr_lbus_packet_rx_sop_s);
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  default : begin
                    pkt_state   <= FIRST_PART_OF_PKT_IN_BURST;
                    misaligned  <= onedigit2number_func(curr_lbus_packet_rx_sop_s);
                    bufd_rd_ptr <= bufd_rd_ptr+1;
                  end
                endcase
              end
              2'b01 : begin
                case(misaligned)
                  2'b01 : begin
                    if(curr_lbus_packet_rx_eop_s>='h2) begin
                      pkt_state <= END_PKT_NO_BURST;
                    end else begin
                      pkt_state   <= IDLE;
                      misaligned  <= 2'h0;
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  2'b10 : begin
                    if(curr_lbus_packet_rx_eop_s>='h4) begin
                      pkt_state <= END_PKT_NO_BURST;
                    end else begin
                      pkt_state   <= IDLE;
                      misaligned  <= 2'h0;
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  2'b11 : begin
                    if(curr_lbus_packet_rx_eop_s=='h8) begin
                      pkt_state <= END_PKT_NO_BURST;
                    end else begin
                      pkt_state   <= IDLE;
                      misaligned  <= 2'h0;
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  default : begin
                    pkt_state   <= IDLE;
                    misaligned  <= 2'h0;
                    bufd_rd_ptr <= bufd_rd_ptr+1;
                  end
                endcase
              end
              //2'b?0: begin
              default : begin
                // Do nothing
                bufd_rd_ptr <= bufd_rd_ptr+1;
              end
            endcase
          end
        end
        FIRST_PART_OF_PKT_IN_BURST : begin
          if(pkt_available_in_buffer_s) begin
            case({is_start_of_fragment_s, is_end_of_fragment_s})
              2'b11 : begin
                case(misaligned)
                  2'b01 : begin
                    if(curr_lbus_packet_rx_eop_s>='h2) begin
                      pkt_state <= END_PKT_IN_BURST;
                    end else begin
                      pkt_state   <= FIRST_PART_OF_PKT_IN_BURST;
                      misaligned  <= onedigit2number_func(curr_lbus_packet_rx_sop_s);
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  2'b10 : begin
                    if(curr_lbus_packet_rx_eop_s>='h4) begin
                      pkt_state <= END_PKT_IN_BURST;
                    end else begin
                      pkt_state   <= FIRST_PART_OF_PKT_IN_BURST;
                      misaligned  <= onedigit2number_func(curr_lbus_packet_rx_sop_s);
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  default : begin
                    pkt_state   <= FIRST_PART_OF_PKT_IN_BURST;
                    misaligned  <= onedigit2number_func(curr_lbus_packet_rx_sop_s);
                    bufd_rd_ptr <= bufd_rd_ptr+1;
                  end
                endcase
              end
              2'b01 : begin
                case(misaligned)
                  2'b01 : begin
                    if(curr_lbus_packet_rx_eop_s>='h2) begin
                      pkt_state <= END_PKT_NO_BURST;
                    end else begin
                      pkt_state   <= IDLE;
                      misaligned  <= 2'h0;
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  2'b10 : begin
                    if(curr_lbus_packet_rx_eop_s>='h4) begin
                      pkt_state <= END_PKT_NO_BURST;
                    end else begin
                      pkt_state   <= IDLE;
                      misaligned  <= 2'h0;
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  2'b11 : begin
                    if(curr_lbus_packet_rx_eop_s=='h8) begin
                      pkt_state <= END_PKT_NO_BURST;
                    end else begin
                      pkt_state   <= IDLE;
                      misaligned  <= 2'h0;
                      bufd_rd_ptr <= bufd_rd_ptr+1;
                    end
                  end
                  default : begin
                    pkt_state   <= IDLE;
                    misaligned  <= 2'h0;
                    bufd_rd_ptr <= bufd_rd_ptr+1;
                  end
                endcase
              end
              //2'b?0: begin
              default : begin
                // Do nothing
                pkt_state   <= PKT_IN_BURST;
                bufd_rd_ptr <= bufd_rd_ptr+1;
              end
            endcase
          end
        end

        END_PKT_NO_BURST : begin
          bufd_rd_ptr <= bufd_rd_ptr+1;
          pkt_state   <= IDLE;
          misaligned  <= 2'h0;
        end
        END_PKT_IN_BURST : begin
          bufd_rd_ptr <= bufd_rd_ptr+1;
          pkt_state   <= FIRST_PART_OF_PKT_IN_BURST;
          misaligned  <= onedigit2number_func(curr_lbus_packet_rx_sop_s);
        end
        default : begin
          pkt_state       <= IDLE;
        end
      endcase
    end
  end

endmodule