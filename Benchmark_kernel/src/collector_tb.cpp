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

#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"

#define DWIDTH 128
#define LOCAL_MEM_DEPTH 64
#define VECTOR_WIDTH 512

typedef ap_axiu<DWIDTH, 0, 0, 0> pkt;


void collector(ap_uint<VECTOR_WIDTH>  *out,           
               hls::stream<pkt>       &summary,
               ap_uint<40>            &received_packets);

hls::stream<pkt>        summary("summary");

void fillStream (void){
  unsigned int num_pkts = 33;
  pkt currWord;
  for (unsigned int i = 0 ; i < num_pkts; i++){
    currWord.data( 39,  0) = (ap_uint<40>) i;
    currWord.data( 79, 40) = 0x57438 + i * 8;  // Fake tx timestamp
    currWord.data(119, 80) = 0x57738 + i * 15; // Fake rx timestamp
    currWord.last = 0;
    summary.write(currWord);
  }
  // Send dummy word to finish processing
  currWord.last = 1;
  summary.write(currWord);
}

int main (void){

  ap_uint<VECTOR_WIDTH>   global_memory[2048];
  ap_uint<40>             received_packets;

  std::cout << "Stating simulation " << std::endl;
  fillStream();

  collector(global_memory,
            summary,
            received_packets);

  std::cout << "Total received packets " << received_packets << std::endl;

  unsigned int addr = 0;
  unsigned int m;

  for (unsigned int i = 0; i < received_packets ; i++){
    m = i % 16;
    std::cout << "Packet ["<< std::setw(4) << i << "] Address [" << std::setw(3) << addr << "] position [";
    std::cout << std::setw(2) << m << "] value: " << global_memory[addr]((m*32) + 31,m*32) << std::endl;
    if (((i+1) % 16) == 0)
      addr++;
  }

  return 0;
}
