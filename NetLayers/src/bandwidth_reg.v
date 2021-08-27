/************************************************
BSD 3-Clause License

Copyright (c) 2019, HPCN Group, UAM Spain (hpcn-uam.es)
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

/*
 * The  debug_slot is arranged as follow
 * 
 * -------------------------------------------------------------
 * |  Time   |  Time   | Bytes   | Bytes   | Packets | Packets |
 * |  LSB    |  MSB    |  LSB    |  MSB    |   LSB   |   MSB   |
 * -------------------------------------------------------------
 * 191       159       127       95        63        31        0
 * 
 * 
 */
 
module bandwidth_reg #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line

        // Width of S_AXI data bus
        parameter C_AXIS_DATA_WIDTH             = 512,
        parameter TUSER_WIDTH                   =  0,
        parameter TDEST_WIDTH                   =  0

        // Width of S_AXI address bus

        )
    (
        // Users to add ports here
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 IN_DBG TDATA" *)
        input wire [C_AXIS_DATA_WIDTH-1:0]                  S_AXIS_TDATA,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 IN_DBG TKEEP" *)
        input wire [(C_AXIS_DATA_WIDTH/8)-1:0]              S_AXIS_TKEEP,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 IN_DBG TVALID" *)
        input wire                                          S_AXIS_TVALID,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 IN_DBG TREADY" *)
        output wire                                         S_AXIS_TREADY,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 IN_DBG TLAST" *)
        input wire                                          S_AXIS_TLAST,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 IN_DBG TUSER" *)
        input wire [TUSER_WIDTH-1:0]                        S_AXIS_TUSER,     
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 IN_DBG TDEST" *)
        input wire [TDEST_WIDTH-1:0]                        S_AXIS_TDEST,       

        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 OUT_DBG TDATA" *)
        output wire [C_AXIS_DATA_WIDTH-1:0]                 M_AXIS_TDATA,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 OUT_DBG TKEEP" *)
        output wire [(C_AXIS_DATA_WIDTH/8)-1:0]             M_AXIS_TKEEP,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 OUT_DBG TVALID" *)
        output wire                                         M_AXIS_TVALID,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 OUT_DBG TREADY" *)
        input wire                                          M_AXIS_TREADY,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 OUT_DBG TLAST" *)
        output wire                                         M_AXIS_TLAST,
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 OUT_DBG TUSER" *)
        output wire [TUSER_WIDTH-1:0]                       M_AXIS_TUSER,     
        (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 OUT_DBG TDEST" *)
        output wire [TDEST_WIDTH-1:0]                       M_AXIS_TDEST,               

        (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_ACLK CLK" *)
        (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF IN_DBG:OUT_DBG, ASSOCIATED_RESET S_AXI_ARESETN" *)
        input wire  S_AXI_ACLK,
        // Global Reset Signal. This Signal is Active LOW
        input wire  S_AXI_ARESETN,

        output reg  [191:0]                                 debug_slot,
        input wire                                          user_rst_n  
        

    );
    
        reg [63:0]                          time_counter;
        reg [63:0]                          byte_counter;
        reg [63:0]                          pkt_counter;
        reg                                 active_counter;
        wire [6:0]                          number_of_ones;
        reg  [6:0]                          number_of_ones_1d;  
        reg                                 tvalid_1d;
        reg                                 tready_1d;
        reg                                 tlast_1d;
    
        reg  [31:0]                         time_counter_lsb;
        reg  [31:0]                         time_counter_msb;


        always @( posedge S_AXI_ACLK ) begin
            if ( S_AXI_ARESETN == 1'b0 || user_rst_n== 1'b0) begin
                byte_counter        <= {64{1'b0}};
                time_counter        <= {64{1'b0}};
                active_counter      <= 1'b0;
                pkt_counter         <= {64{1'b0}};
                tvalid_1d           <= 1'b0;
                tready_1d           <= 1'b0;
                tlast_1d            <= 1'b0;
                number_of_ones_1d   <= {7{1'b0}};
                time_counter_lsb    <= {32{1'b0}};
                time_counter_msb    <= {32{1'b0}};
            end 
            else begin    

                time_counter    <= (active_counter) ? time_counter + 1  : time_counter;

                if (S_AXIS_TVALID && S_AXIS_TREADY) begin
                    active_counter  <= 1'b1;
                end

                if (tvalid_1d && tready_1d) begin
                    byte_counter        <= byte_counter + number_of_ones_1d;
                    {time_counter_msb,time_counter_lsb}    <= time_counter + 1; // this +1 is because active_counter is behind one cycle
                end

                if (tvalid_1d && tready_1d && tlast_1d) begin
                    pkt_counter     <= pkt_counter + 1;
                end 

                number_of_ones_1d   <= number_of_ones;
                tvalid_1d    <= S_AXIS_TVALID;
                tready_1d    <= S_AXIS_TREADY;
                tlast_1d     <= S_AXIS_TLAST; 
               
            end
        end    

        always @( posedge S_AXI_ACLK ) begin
            debug_slot <={time_counter_lsb,time_counter_msb, byte_counter[31:0],byte_counter[63:32],pkt_counter[31:0],pkt_counter[63:32]};
        end

        counter64_7_v3 counter64_7_v3_i (
            .x(S_AXIS_TKEEP         ),
            .s(number_of_ones)
        );

        // make bridge connections

        assign M_AXIS_TDATA     =   S_AXIS_TDATA;
        assign M_AXIS_TKEEP     =   S_AXIS_TKEEP;
        assign M_AXIS_TVALID    =   S_AXIS_TVALID;
        assign S_AXIS_TREADY    =   M_AXIS_TREADY;
        assign M_AXIS_TLAST     =   S_AXIS_TLAST;
        assign M_AXIS_TUSER     =   S_AXIS_TUSER;
        assign M_AXIS_TDEST     =   S_AXIS_TDEST;


endmodule
