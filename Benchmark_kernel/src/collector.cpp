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
               ap_uint<40>            &received_packets) {

  ap_uint<VECTOR_WIDTH>   local_mem[LOCAL_MEM_DEPTH];
  ap_uint<VECTOR_WIDTH>   vector_word;
  ap_uint< 32>            global_memory_offset = 0;
  ap_uint< 40>            total_pkts_reg    = 0;
  ap_uint< 40>            total_consecutive = 0;
  ap_uint< 40>            nextId = 0;
  ap_uint< 32>            latency = 0;
  bool                    move_data = false;
  bool                    end_loop  = false;
  pkt                     currWord;
  unsigned int            max_elements_local_memory = (VECTOR_WIDTH/32) * LOCAL_MEM_DEPTH;
  unsigned int            local_occupancy;

#pragma HLS BIND_STORAGE variable=local_mem type=ram_2p impl=bram
  while (!end_loop) {
    if (move_data) {
      move_data = false;
      // Move local memory to global memory to get ready for the next batch
      // This stall in data consumption should be buffered by the input FIFO
      data_mover:
      for(unsigned int m = 0; m < LOCAL_MEM_DEPTH; m++){
      #pragma HLS PIPELINE
        out[global_memory_offset] = local_mem[m];
        global_memory_offset++;
      }

    }
    else if (!summary.empty()){
      summary.read(currWord);
      // tlast indicates the end of a test and the content is dummy
      if (currWord.last){ 
        end_loop = true;
      }
      else {
        ap_uint< 40> currId = currWord.data(39,0);
        if (currId == nextId){
          total_consecutive++;
        }
        nextId = currId + 1;
        latency = currWord.data(119,80) - currWord.data( 79, 40);
        unsigned int i = total_pkts_reg(3,0);   // Get position in the vector
        unsigned int j = total_pkts_reg(9,4);   // Get position in the local memory
        vector_word((i * 32) + 31 ,(i * 32)) = latency;
        // Store vector word in local memory even though it may not be full
        local_mem[j] = vector_word;
        total_pkts_reg++;
        // If the local memory is full prepare to move it next cycle
        if ((total_pkts_reg % (max_elements_local_memory)) == 0) {
          move_data = true;
        }
      }
    }
  }

  // Get the amount of rows to be moved, number of full occupied rows + a potential half-full row
  local_occupancy = total_pkts_reg(9,4) + ((total_pkts_reg(3,0) != 0) ? 1 : 0); 
  // Move remaining rows if any
  data_mover_partial:
  for(unsigned int m = 0; m < local_occupancy; m++){
  #pragma HLS LOOP_TRIPCOUNT max=64 min=1
  #pragma HLS PIPELINE
    out[global_memory_offset] = local_mem[m];
    global_memory_offset++;
  }

  received_packets    = total_pkts_reg;

}
