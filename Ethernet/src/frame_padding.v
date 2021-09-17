/************************************************
Copyright (c) 2021, Xilinx, Inc.
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
************************************************/

/* 
 * This module adds padding to frames shorter than 60-Byte.
 * This is to comply with Integrated 100G Ethernet Subsystem
 * minimum frame length, which is 60-Byte (without FCS)
 */

module frame_padding (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_ACLK CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET S_AXI_ARESETN" *)
    input wire  S_AXI_ACLK,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 S_AXI_ARESETN RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire  S_AXI_ARESETN,

    // Users to add ports here
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input wire [511:0]              S_AXIS_TDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
    input wire [ 63:0]              S_AXIS_TKEEP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input wire                      S_AXIS_TVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
    output wire                     S_AXIS_TREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *)
    input wire                      S_AXIS_TLAST,      

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output wire [511:0]             M_AXIS_TDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TKEEP" *)
    output wire [ 63:0]             M_AXIS_TKEEP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output wire                     M_AXIS_TVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
    input wire                      M_AXIS_TREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
    output wire                     M_AXIS_TLAST
);
    
    reg [511:0] data;
    reg [ 63:0] keep;
    reg         new_frame = 1'b1;
    integer i;

    // Flag when a new frame starts
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN) begin
            new_frame = 1'b1;
        end
        else begin
            if (S_AXIS_TVALID && S_AXIS_TREADY) begin
                new_frame = S_AXIS_TLAST;     
            end
        end
    end

    always @(*) begin
        // If keep[59] is 0, the frame is shorter than 60-Byte
        if (new_frame && (S_AXIS_TKEEP[59] == 0)) begin
            // Force frame to be 60-Byte
            keep = {4'h0,{60{1'b1}}};
            data[511:480] = 32'h0;
            // Pad remaining bytes with zeros
            for (i = 0; i < 60; i = i+1) begin
                if (S_AXIS_TKEEP[i])
                    data[i*8 +: 8] = S_AXIS_TDATA[i*8 +: 8];
                else
                    data[i*8 +: 8] = 8'h0;
            end
        end
        else begin
            data = S_AXIS_TDATA;
            keep = S_AXIS_TKEEP;
        end
    end


    // Valid, ready and last are bypassed unmodified
    assign S_AXIS_TREADY = M_AXIS_TREADY;
    assign M_AXIS_TVALID = S_AXIS_TVALID;
    assign M_AXIS_TLAST = S_AXIS_TLAST;
    // Assign padded frame
    assign M_AXIS_TDATA = data;
    assign M_AXIS_TKEEP = keep;


endmodule