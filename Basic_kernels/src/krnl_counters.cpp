/**********
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
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**********/

/* 
 * Streaming pass-through kernel that counts number of packets and beats
 * These counters can be reseted with a rising edge of reset 
 */


#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"

#define DWIDTH 512
#define TDWIDTH 16

typedef ap_axiu<DWIDTH, 96, 1, TDWIDTH> pkt;

ap_uint<7> keep2len(ap_uint<64> keepValue);

extern "C" {
void krnl_counters(
               hls::stream<pkt> &in,
               hls::stream<pkt> &out,
               unsigned int     &packets,
               unsigned int     &beats,
               unsigned int     &bytes,
               bool             &reset
               ) {
#pragma HLS INTERFACE axis port = out
#pragma HLS INTERFACE axis port = in
#pragma HLS INTERFACE s_axilite port = packets bundle = control
#pragma HLS INTERFACE s_axilite port = beats bundle = control
#pragma HLS INTERFACE s_axilite port = bytes bundle = control
#pragma HLS INTERFACE s_axilite port = reset bundle = control
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS PIPELINE II=1

    pkt word;
    static unsigned int pkts_i = 0;
    static unsigned int beats_i = 0;
    static unsigned int bytes_i = 0;
    static bool reset_1d = 0;

    if (!in.empty()){
        in.read(word);
        out.write(word);
        beats_i++;
        bytes_i += keep2len(word.keep);
        if (word.last) 
            pkts_i++;
    }
    // Only reset counters when rising edge
    else if (reset && !reset_1d) {
        pkts_i = 0;
        beats_i = 0;
        bytes_i = 0;
    }

    packets = pkts_i;
    beats = beats_i;
    bytes = bytes_i;
    reset_1d = reset;

}
}

ap_uint<7> keep2len(ap_uint<64> keepValue){
  if (keepValue.bit(63))
    return 64;
  else if (keepValue.bit(62))
    return 63;
  else if (keepValue.bit(61))
    return 62;
  else if (keepValue.bit(60))
    return 61;
  else if (keepValue.bit(59))
    return 60;
  else if (keepValue.bit(58))
    return 59;
  else if (keepValue.bit(57))
    return 58;
  else if (keepValue.bit(56))
    return 57;
  else if (keepValue.bit(55))
    return 56;
  else if (keepValue.bit(54))
    return 55;
  else if (keepValue.bit(53))
    return 54;
  else if (keepValue.bit(52))
    return 53;
  else if (keepValue.bit(51))
    return 52;
  else if (keepValue.bit(50))
    return 51;
  else if (keepValue.bit(49))
    return 50;
  else if (keepValue.bit(48))
    return 49;
  else if (keepValue.bit(47))
    return 48;
  else if (keepValue.bit(46))
    return 47;
  else if (keepValue.bit(45))
    return 46;
  else if (keepValue.bit(44))
    return 45;
  else if (keepValue.bit(43))
    return 44;
  else if (keepValue.bit(42))
    return 43;
  else if (keepValue.bit(41))
    return 42;
  else if (keepValue.bit(40))
    return 41;
  else if (keepValue.bit(39))
    return 40;
  else if (keepValue.bit(38))
    return 39;
  else if (keepValue.bit(37))
    return 38;
  else if (keepValue.bit(36))
    return 37;
  else if (keepValue.bit(35))
    return 36;
  else if (keepValue.bit(34))
    return 35;
  else if (keepValue.bit(33))
    return 34;
  else if (keepValue.bit(32))
    return 33;
  else if (keepValue.bit(31))
    return 32;
  else if (keepValue.bit(30))
    return 31;
  else if (keepValue.bit(29))
    return 30;
  else if (keepValue.bit(28))
    return 29;
  else if (keepValue.bit(27))
    return 28;
  else if (keepValue.bit(26))
    return 27;
  else if (keepValue.bit(25))
    return 26;
  else if (keepValue.bit(24))
    return 25;
  else if (keepValue.bit(23))
    return 24;
  else if (keepValue.bit(22))
    return 23;
  else if (keepValue.bit(21))
    return 22;
  else if (keepValue.bit(20))
    return 21;
  else if (keepValue.bit(19))
    return 20;
  else if (keepValue.bit(18))
    return 19;
  else if (keepValue.bit(17))
    return 18;
  else if (keepValue.bit(16))
    return 17;
  else if (keepValue.bit(15))
    return 16;
  else if (keepValue.bit(14))
    return 15;
  else if (keepValue.bit(13))
    return 14;
  else if (keepValue.bit(12))
    return 13;
  else if (keepValue.bit(11))
    return 12;
  else if (keepValue.bit(10))
    return 11;
  else if (keepValue.bit(9))
    return 10;
  else if (keepValue.bit(8))
    return 9;
  else if (keepValue.bit(7))
    return 8;
  else if (keepValue.bit(6))
    return 7;
  else if (keepValue.bit(5))
    return 6;
  else if (keepValue.bit(4))
    return 5;
  else if (keepValue.bit(3))
    return 4;
  else if (keepValue.bit(2))
    return 3;
  else if (keepValue.bit(1))
    return 2;
  else if (keepValue.bit(0))              
    return 1;
  else
    return 0;

}
