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

`default_nettype wire
`timescale 1 ps / 1 ps

module switch_wrapper (
  // System clock and reset
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_rx_in:m_rx_out0:m_rx_out1:m_rx_out2:m_rx_out3:s_tx_in0:s_tx_in1:s_tx_in2:s_tx_in3:m_tx_out, ASSOCIATED_RESET ap_rst_n" *)
  input  wire         ap_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ap_rst_n RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire         ap_rst_n,

  // Rx path
  input  wire [511:0] s_rx_in_tdata,
  input  wire  [63:0] s_rx_in_tkeep,
  input  wire         s_rx_in_tvalid,
  input  wire         s_rx_in_tlast,
  input  wire  [15:0] s_rx_in_tdest,
  output wire         s_rx_in_tready,

  output wire [511:0] m_rx_out0_tdata,
  output wire  [63:0] m_rx_out0_tkeep,
  output wire         m_rx_out0_tvalid,
  output wire         m_rx_out0_tlast,
  output wire  [15:0] m_rx_out0_tdest,
  input  wire         m_rx_out0_tready,

  output wire [511:0] m_rx_out1_tdata,
  output wire  [63:0] m_rx_out1_tkeep,
  output wire         m_rx_out1_tvalid,
  output wire         m_rx_out1_tlast,
  output wire  [15:0] m_rx_out1_tdest,
  input  wire         m_rx_out1_tready,

  output wire [511:0] m_rx_out2_tdata,
  output wire  [63:0] m_rx_out2_tkeep,
  output wire         m_rx_out2_tvalid,
  output wire         m_rx_out2_tlast,
  output wire  [15:0] m_rx_out2_tdest,
  input  wire         m_rx_out2_tready,

  output wire [511:0] m_rx_out3_tdata,
  output wire  [63:0] m_rx_out3_tkeep,
  output wire         m_rx_out3_tvalid,
  output wire         m_rx_out3_tlast,
  output wire  [15:0] m_rx_out3_tdest,
  input  wire         m_rx_out3_tready,

  // Tx path
  input  wire [511:0] s_tx_in0_tdata,
  input  wire  [63:0] s_tx_in0_tkeep,
  input  wire         s_tx_in0_tvalid,
  input  wire         s_tx_in0_tlast,
  input  wire  [15:0] s_tx_in0_tdest,
  output wire         s_tx_in0_tready,

  input  wire [511:0] s_tx_in1_tdata,
  input  wire  [63:0] s_tx_in1_tkeep,
  input  wire         s_tx_in1_tvalid,
  input  wire         s_tx_in1_tlast,
  input  wire  [15:0] s_tx_in1_tdest,
  output wire         s_tx_in1_tready,

  input  wire [511:0] s_tx_in2_tdata,
  input  wire  [63:0] s_tx_in2_tkeep,
  input  wire         s_tx_in2_tvalid,
  input  wire         s_tx_in2_tlast,
  input  wire  [15:0] s_tx_in2_tdest,
  output wire         s_tx_in2_tready,

  input  wire [511:0] s_tx_in3_tdata,
  input  wire  [63:0] s_tx_in3_tkeep,
  input  wire         s_tx_in3_tvalid,
  input  wire         s_tx_in3_tlast,
  input  wire  [15:0] s_tx_in3_tdest,
  output wire         s_tx_in3_tready,

  output wire [511:0] m_tx_out_tdata,
  output wire  [63:0] m_tx_out_tkeep,
  output wire         m_tx_out_tvalid,
  output wire         m_tx_out_tlast,
  output wire  [15:0] m_tx_out_tdest,
  input  wire         m_tx_out_tready
);


  switch_bd switch_bd_i (
    .ap_clk         (           ap_clk),
    .ap_rst_n       (         ap_rst_n),

    .rx_in_tdata    (    s_rx_in_tdata),
    .rx_in_tkeep    (    s_rx_in_tkeep),
    .rx_in_tvalid   (   s_rx_in_tvalid),
    .rx_in_tlast    (    s_rx_in_tlast),
    .rx_in_tdest    (    s_rx_in_tdest),
    .rx_in_tready   (   s_rx_in_tready),

    .rx_out0_tdata  (  m_rx_out0_tdata),
    .rx_out0_tkeep  (  m_rx_out0_tkeep),
    .rx_out0_tvalid ( m_rx_out0_tvalid),
    .rx_out0_tlast  (  m_rx_out0_tlast),
    .rx_out0_tdest  (  m_rx_out0_tdest),
    .rx_out0_tready ( m_rx_out0_tready),

    .rx_out1_tdata  (  m_rx_out1_tdata),
    .rx_out1_tkeep  (  m_rx_out1_tkeep),
    .rx_out1_tvalid ( m_rx_out1_tvalid),
    .rx_out1_tlast  (  m_rx_out1_tlast),
    .rx_out1_tdest  (  m_rx_out1_tdest),
    .rx_out1_tready ( m_rx_out1_tready),

    .rx_out2_tdata  (  m_rx_out2_tdata),
    .rx_out2_tkeep  (  m_rx_out2_tkeep),
    .rx_out2_tvalid ( m_rx_out2_tvalid),
    .rx_out2_tlast  (  m_rx_out2_tlast),
    .rx_out2_tdest  (  m_rx_out2_tdest),
    .rx_out2_tready ( m_rx_out2_tready),

    .rx_out3_tdata  (  m_rx_out3_tdata),
    .rx_out3_tkeep  (  m_rx_out3_tkeep),
    .rx_out3_tvalid ( m_rx_out3_tvalid),
    .rx_out3_tlast  (  m_rx_out3_tlast),
    .rx_out3_tdest  (  m_rx_out3_tdest),
    .rx_out3_tready ( m_rx_out3_tready),

    .tx_in0_tdata   (   s_tx_in0_tdata),
    .tx_in0_tkeep   (   s_tx_in0_tkeep),
    .tx_in0_tvalid  (  s_tx_in0_tvalid),
    .tx_in0_tlast   (   s_tx_in0_tlast),
    .tx_in0_tdest   (   s_tx_in0_tdest),
    .tx_in0_tready  (  s_tx_in0_tready),

    .tx_in1_tdata   (   s_tx_in1_tdata),
    .tx_in1_tkeep   (   s_tx_in1_tkeep),
    .tx_in1_tvalid  (  s_tx_in1_tvalid),
    .tx_in1_tlast   (   s_tx_in1_tlast),
    .tx_in1_tdest   (   s_tx_in1_tdest),
    .tx_in1_tready  (  s_tx_in1_tready),

    .tx_in2_tdata   (   s_tx_in2_tdata),
    .tx_in2_tkeep   (   s_tx_in2_tkeep),
    .tx_in2_tvalid  (  s_tx_in2_tvalid),
    .tx_in2_tlast   (   s_tx_in2_tlast),
    .tx_in2_tdest   (   s_tx_in2_tdest),
    .tx_in2_tready  (  s_tx_in2_tready),

    .tx_in3_tdata   (   s_tx_in3_tdata),
    .tx_in3_tkeep   (   s_tx_in3_tkeep),
    .tx_in3_tvalid  (  s_tx_in3_tvalid),
    .tx_in3_tlast   (   s_tx_in3_tlast),
    .tx_in3_tdest   (   s_tx_in3_tdest),
    .tx_in3_tready  (  s_tx_in3_tready),

    .tx_out_tdata   (   m_tx_out_tdata),
    .tx_out_tkeep   (   m_tx_out_tkeep),
    .tx_out_tvalid  (  m_tx_out_tvalid),
    .tx_out_tlast   (   m_tx_out_tlast),
    .tx_out_tdest   (   m_tx_out_tdest),
    .tx_out_tready  (  m_tx_out_tready)
  );

endmodule
