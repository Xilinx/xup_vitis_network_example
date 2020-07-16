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
 * The input debug port must be arranged as follow
 * 
 * -------------------------------------------------------------
 * |  Time   |  Time   | Bytes   | Bytes   | Packets | Packets |
 * |  LSB    |  MSB    |  LSB    |  MSB    |   LSB   |   MSB   |
 * -------------------------------------------------------------
 * 191       159       127       95        63        31        0
 *   r(5+i)    r(4+i)    r(3+i)    r(2+i)     r(1+i)    r(i)
 * 
 * Where i steps in 6, 0,6,12,18,24,30,36,42,48,54
 * i = port_number * 6
*/
`timescale 1 ns / 1 ps



module performance_debug_reg #(
  // Number of port to monitorize each port has 6 32-bit register bytes-packets-time
  parameter integer C_PORTS           = 12 ,
  // User parameters ends
  // Do not modify the parameters beyond this line
  // Width of S_AXI data bus
  parameter integer C_S_AXI_DATA_WIDTH = 32,
  // Width of S_AXI address bus
  parameter integer C_S_AXI_ADDR_WIDTH = 9,  // up to 64 registers 12 ports plus 4 extra registers
  parameter integer CLOCK_FREQUENCY    = 322265624
) (
  // Users to add ports here
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT0       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT1       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT2       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT3       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT4       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT5       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT6       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT7       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT8       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT9       ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT10      ,
  input  wire [(C_S_AXI_DATA_WIDTH*6)-1:0] PORT11      ,

  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 user_rst_n RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)   
  output reg                               user_rst_n   , 
  // User ports ends
  // Do not modify the ports beyond this line
  // Global Clock Signal
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_ACLK CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET S_AXI_ARESETN,user_rst_n" *)
  input  wire                              S_AXI_ACLK   ,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 S_AXI_ARESETN RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *) 
  // Global Reset Signal. This Signal is Active LOW
  input  wire                              S_AXI_ARESETN,
  // Write address (issued by master, acceped by Slave)
  input  wire [    C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR ,
  // Write channel Protection type. This signal indicates the
  // privilege and security level of the transaction, and whether
  // the transaction is a data access or an instruction access.
  input  wire [                       2:0] S_AXI_AWPROT ,
  // Write address valid. This signal indicates that the master signaling
  // valid write address and control information.
  input  wire                              S_AXI_AWVALID,
  // Write address ready. This signal indicates that the slave is ready
  // to accept an address and associated control signals.
  output wire                              S_AXI_AWREADY,
  // Write data (issued by master, acceped by Slave)
  input  wire [    C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA  ,
  // Write strobes. This signal indicates which byte lanes hold
  // valid data. There is one write strobe bit for each eight
  // bits of the write data bus.
  input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB  ,
  // Write valid. This signal indicates that valid write
  // data and strobes are available.
  input  wire                              S_AXI_WVALID ,
  // Write ready. This signal indicates that the slave
  // can accept the write data.
  output wire                              S_AXI_WREADY ,
  // Write response. This signal indicates the status
  // of the write transaction.
  output wire [                       1:0] S_AXI_BRESP  ,
  // Write response valid. This signal indicates that the channel
  // is signaling a valid write response.
  output wire                              S_AXI_BVALID ,
  // Response ready. This signal indicates that the master
  // can accept a write response.
  input  wire                              S_AXI_BREADY ,
  // Read address (issued by master, acceped by Slave)
  input  wire [    C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR ,
  // Protection type. This signal indicates the privilege
  // and security level of the transaction, and whether the
  // transaction is a data access or an instruction access.
  input  wire [                       2:0] S_AXI_ARPROT ,
  // Read address valid. This signal indicates that the channel
  // is signaling valid read address and control information.
  input  wire                              S_AXI_ARVALID,
  // Read address ready. This signal indicates that the slave is
  // ready to accept an address and associated control signals.
  output wire                              S_AXI_ARREADY,
  // Read data (issued by slave)
  output wire [    C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA  ,
  // Read response. This signal indicates the status of the
  // read transfer.
  output wire [                       1:0] S_AXI_RRESP  ,
  // Read valid. This signal indicates that the channel is
  // signaling the required read data.
  output wire                              S_AXI_RVALID ,
  // Read ready. This signal indicates that the master can
  // accept the read data and response information.
  input  wire                              S_AXI_RREADY
);

  // AXI4LITE signals
  reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr ;
  reg                            axi_awready;
  reg                            axi_wready ;
  reg [                   1 : 0] axi_bresp  ;
  reg                            axi_bvalid ;
  reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr ;
  reg                            axi_arready;
  reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata  ;
  reg [                   1 : 0] axi_rresp  ;
  reg                            axi_rvalid ;

  // Example-specific design signals
  // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
  // ADDR_LSB is used for addressing 32/64 bit registers/memories
  // ADDR_LSB = 2 for 32 bits (n downto 2)
  // ADDR_LSB = 3 for 64 bits (n downto 3)
  localparam integer ADDR_LSB          = (C_S_AXI_DATA_WIDTH/32) + 1;
  localparam integer OPT_MEM_ADDR_BITS = 6                          ;
  //----------------------------------------------
  //-- Signals for user logic register space example
  //------------------------------------------------
  //-- Number of Slave Registers 32
  genvar i;

  localparam integer MAX_PORTS = 10;

  reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg_reset;
  // this register is used to hold the value of the ports using one bit per port
  // the number of the port is the position of the bit associated
  reg  [3:0]                    rst_counter;
  reg                           slv_reg_reset_1d;

  wire                             slv_reg_rden;
  wire                             slv_reg_wren;
  reg     [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
  integer                          byte_index  ;

  // I/O Connections assignments

  assign S_AXI_AWREADY = axi_awready;
  assign S_AXI_WREADY  = axi_wready;
  assign S_AXI_BRESP   = axi_bresp;
  assign S_AXI_BVALID  = axi_bvalid;
  assign S_AXI_ARREADY = axi_arready;
  assign S_AXI_RDATA   = axi_rdata;
  assign S_AXI_RRESP   = axi_rresp;
  assign S_AXI_RVALID  = axi_rvalid;


  // Implement axi_awready generation
  // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
  // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
  // de-asserted when reset is low.

  always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_awready <= 1'b0;
        end
      else
        begin
          if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
            begin
              // slave is ready to accept write address when
              // there is a valid write address and write data
              // on the write address and data bus. This design
              // expects no outstanding transactions.
              axi_awready <= 1'b1;
            end
          else
            begin
              axi_awready <= 1'b0;
            end
        end
    end

  // Implement axi_awaddr latching
  // This process is used to latch the address when both
  // S_AXI_AWVALID and S_AXI_WVALID are valid.

  always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_awaddr <= 0;
        end
      else
        begin
          if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
            begin
              // Write Address latching
              axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

  // Implement axi_wready generation
  // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
  // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
  // de-asserted when reset is low.

  always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_wready <= 1'b0;
        end
      else
        begin
          if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
            begin
              // slave is ready to accept write data when
              // there is a valid write address and write data
              // on the write address and data bus. This design
              // expects no outstanding transactions.
              axi_wready <= 1'b1;
            end
          else
            begin
              axi_wready <= 1'b0;
            end
        end
    end

  // Implement write response logic generation
  // The write response and response valid signals are asserted by the slave
  // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
  // This marks the acceptance of address and indicates the status of
  // write transaction.

  always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_bvalid <= 0;
          axi_bresp  <= 2'b0;
        end
      else
        begin
          if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
            begin
              // indicates a valid write response is available
              axi_bvalid <= 1'b1;
              axi_bresp  <= 2'b0; // 'OKAY' response
            end                   // work error responses in future
          else
            begin
              if (S_AXI_BREADY && axi_bvalid)
                //check if bready is asserted while bvalid is high)
                //(there is a possibility that bready is always asserted high)
                begin
                  axi_bvalid <= 1'b0;
                end
            end
        end
    end

  // Implement memory mapped register select and write logic generation
  // The write data is accepted and written to memory mapped registers when
  // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
  // select byte enables of slave registers while writing.
  // These registers are cleared when reset (active low) is applied.
  // Slave register write enable is asserted when valid address and data are available
  // and the slave is ready to accept the write address and write data.
  assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

  always @(posedge S_AXI_ACLK) begin
    user_rst_n       <= slv_reg_reset_1d;
    slv_reg_reset_1d <= ~slv_reg_reset[0];
  end


  always @( posedge S_AXI_ACLK ) begin
    if ( S_AXI_ARESETN == 1'b0 ) begin
        slv_reg_reset <= 32'h0;
        rst_counter   <= 4'h0;
      end 
    else begin
      if (slv_reg_wren) begin
          case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
            'h7c: begin
              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
                if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  // Respective byte enables are asserted as per write strobes 
                  // Slave register 0
                  slv_reg_reset[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
              end  
            end   
            default : begin
              slv_reg_reset <= slv_reg_reset;
            end
          endcase
      end
      else if (slv_reg_reset[0]) begin    // keep reset enable for ten cycles
        rst_counter <= rst_counter + 1;
        if (rst_counter==9) begin
          rst_counter   <= 4'h0;
          slv_reg_reset <= 32'h0;
        end
      end

    end
  end    

  // Implement axi_arready generation
  // axi_arready is asserted for one S_AXI_ACLK clock cycle when
  // S_AXI_ARVALID is asserted. axi_awready is
  // de-asserted when reset (active low) is asserted.
  // The read address is also latched when S_AXI_ARVALID is
  // asserted. axi_araddr is reset to zero on reset assertion.

  always @( posedge S_AXI_ACLK ) begin
    if ( S_AXI_ARESETN == 1'b0 ) begin
      axi_arready <= 1'b0;
      axi_araddr  <= 32'b0;
    end else begin
      if (~axi_arready && S_AXI_ARVALID) begin
        // indicates that the slave has acceped the valid read address
        axi_arready <= 1'b1;
        // Read address latching
        axi_araddr  <= S_AXI_ARADDR;
      end else begin
        axi_arready <= 1'b0;
      end
    end
  end

  // Implement axi_arvalid generation
  // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
  // S_AXI_ARVALID and axi_arready are asserted. The slave registers
  // data are available on the axi_rdata bus at this instance. The
  // assertion of axi_rvalid marks the validity of read data on the
  // bus and axi_rresp indicates the status of read transaction.axi_rvalid
  // is deasserted on reset (active low). axi_rresp and axi_rdata are
  // cleared to zero on reset (active low).
  always @( posedge S_AXI_ACLK ) begin
    if ( S_AXI_ARESETN == 1'b0 ) begin
      axi_rvalid <= 0;
      axi_rresp  <= 0;
    end else begin
      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
        // Valid read data is available at the read data bus
        axi_rvalid <= 1'b1;
        axi_rresp  <= 2'b0; // 'OKAY' response
      end else if (axi_rvalid && S_AXI_RREADY) begin
        // Read data is accepted by the master
        axi_rvalid <= 1'b0;
      end
    end
  end

  // Implement memory mapped register select and read logic generation
  // Slave register read enable is asserted when valid address is available
  // and the slave is ready to accept the read address.
  assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
  always @(*)
    begin
      // Address decoding for reading registers
      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
        'h00 : reg_data_out <= PORT0[160 +: 32];
        'h01 : reg_data_out <= PORT0[128 +: 32];
        'h02 : reg_data_out <= PORT0[ 96 +: 32];
        'h03 : reg_data_out <= PORT0[ 64 +: 32];
        'h04 : reg_data_out <= PORT0[ 32 +: 32];
        'h05 : reg_data_out <= PORT0[  0 +: 32];
        'h06 : reg_data_out <= PORT1[160 +: 32];
        'h07 : reg_data_out <= PORT1[128 +: 32];
        'h08 : reg_data_out <= PORT1[ 96 +: 32];
        'h09 : reg_data_out <= PORT1[ 64 +: 32];
        'h0A : reg_data_out <= PORT1[ 32 +: 32];
        'h0B : reg_data_out <= PORT1[  0 +: 32];
        'h0C : reg_data_out <= PORT2[160 +: 32];
        'h0D : reg_data_out <= PORT2[128 +: 32];
        'h0E : reg_data_out <= PORT2[ 96 +: 32];
        'h0F : reg_data_out <= PORT2[ 64 +: 32];
        'h10 : reg_data_out <= PORT2[ 32 +: 32];
        'h11 : reg_data_out <= PORT2[  0 +: 32];
        'h12 : reg_data_out <= PORT3[160 +: 32];
        'h13 : reg_data_out <= PORT3[128 +: 32];
        'h14 : reg_data_out <= PORT3[ 96 +: 32];
        'h15 : reg_data_out <= PORT3[ 64 +: 32];
        'h16 : reg_data_out <= PORT3[ 32 +: 32];
        'h17 : reg_data_out <= PORT3[  0 +: 32];
        'h18 : reg_data_out <= PORT4[160 +: 32];
        'h19 : reg_data_out <= PORT4[128 +: 32];
        'h1A : reg_data_out <= PORT4[ 96 +: 32];
        'h1B : reg_data_out <= PORT4[ 64 +: 32];
        'h1C : reg_data_out <= PORT4[ 32 +: 32];
        'h1D : reg_data_out <= PORT4[  0 +: 32];
        'h1E : reg_data_out <= PORT5[160 +: 32];
        'h1F : reg_data_out <= PORT5[128 +: 32];
        'h20 : reg_data_out <= PORT5[ 96 +: 32];
        'h21 : reg_data_out <= PORT5[ 64 +: 32];
        'h22 : reg_data_out <= PORT5[ 32 +: 32];
        'h23 : reg_data_out <= PORT5[  0 +: 32];
        'h24 : reg_data_out <= PORT6[160 +: 32];
        'h25 : reg_data_out <= PORT6[128 +: 32];
        'h26 : reg_data_out <= PORT6[ 96 +: 32];
        'h27 : reg_data_out <= PORT6[ 64 +: 32];
        'h28 : reg_data_out <= PORT6[ 32 +: 32];
        'h29 : reg_data_out <= PORT6[  0 +: 32];
        'h2A : reg_data_out <= PORT7[160 +: 32];
        'h2B : reg_data_out <= PORT7[128 +: 32];
        'h2C : reg_data_out <= PORT7[ 96 +: 32];
        'h2D : reg_data_out <= PORT7[ 64 +: 32];
        'h2E : reg_data_out <= PORT7[ 32 +: 32];
        'h2F : reg_data_out <= PORT7[  0 +: 32];
        'h30 : reg_data_out <= PORT8[160 +: 32];
        'h31 : reg_data_out <= PORT8[128 +: 32];
        'h32 : reg_data_out <= PORT8[ 96 +: 32];
        'h33 : reg_data_out <= PORT8[ 64 +: 32];
        'h34 : reg_data_out <= PORT8[ 32 +: 32];
        'h35 : reg_data_out <= PORT8[  0 +: 32];
        'h36 : reg_data_out <= PORT9[160 +: 32];
        'h37 : reg_data_out <= PORT9[128 +: 32];
        'h38 : reg_data_out <= PORT9[ 96 +: 32];
        'h39 : reg_data_out <= PORT9[ 64 +: 32];
        'h3A : reg_data_out <= PORT9[ 32 +: 32];
        'h3B : reg_data_out <= PORT9[  0 +: 32];
        'h3C : reg_data_out <= PORT10[160 +: 32];
        'h3D : reg_data_out <= PORT10[128 +: 32];
        'h3E : reg_data_out <= PORT10[ 96 +: 32];
        'h3F : reg_data_out <= PORT10[ 64 +: 32];
        'h40 : reg_data_out <= PORT10[ 32 +: 32];
        'h41 : reg_data_out <= PORT10[  0 +: 32];
        'h42 : reg_data_out <= PORT11[160 +: 32];
        'h43 : reg_data_out <= PORT11[128 +: 32];
        'h44 : reg_data_out <= PORT11[ 96 +: 32];
        'h45 : reg_data_out <= PORT11[ 64 +: 32];
        'h46 : reg_data_out <= PORT11[ 32 +: 32];
        'h47 : reg_data_out <= PORT11[  0 +: 32];
        // TODO  
        'h7D : reg_data_out <= CLOCK_FREQUENCY;  // Assign the clock frequency
        'h7E : reg_data_out <=         C_PORTS;  // Assign the number of ports
        'h7F : reg_data_out <=      32'hADACED;       //  advanced
        default : reg_data_out <= 0;
      endcase
    end

    // Output register or memory read data
    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
        axi_rdata <= 0;
      end 
      else begin
        // When there is a valid read address (S_AXI_ARVALID) with
        // acceptance of read address by the slave (axi_arready),
        // output the read data
        if (slv_reg_rden) begin
          axi_rdata <= reg_data_out;     // register read data
        end
      end
    end

    // Add user logic here

    // User logic ends

  endmodule
