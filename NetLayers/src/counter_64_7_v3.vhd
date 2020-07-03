-- /************************************************
-- BSD 3-Clause License
-- 
-- Copyright (c) 2019, HPCN Group, UAM Spain (hpcn-uam.es)
-- and Systems Group, ETH Zurich (systems.ethz.ch)
-- All rights reserved.
-- 
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
-- 
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
-- 
-- * Neither the name of the copyright holder nor the names of its
--   contributors may be used to endorse or promote products derived from
--   this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- ************************************************/


--------------------------------------------------------------
-- 64 bit counter
--
--------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity counter64_7_v3 is port (
  x: in std_logic_vector (63 downto 0);
  s: out std_logic_vector (6 downto 0)
);
end counter64_7_v3 ;

architecture rtl_3 of counter64_7_v3 is

  COMPONENT reducer_6to3 is port (
      x: in std_logic_vector (5 downto 0);
      s: out std_logic_vector (2 downto 0)
    );
  END COMPONENT;
  
  
  type sums_L1 is array (0 to 10) of STD_LOGIC_VECTOR(2 downto 0);
  signal sum_L1: sums_L1;
  
  signal L1_vert0: STD_LOGIC_VECTOR(10 downto 0);
  signal L1_vert1: STD_LOGIC_VECTOR(10 downto 0);
  signal L1_vert2: STD_LOGIC_VECTOR(10 downto 0);
  signal sum_L2_0, sum_L2_1, sum_L2_2: STD_LOGIC_VECTOR(2 downto 0);
  signal sum_L2_3, sum_L2_4, sum_L2_5: STD_LOGIC_VECTOR(2 downto 0);

  signal sum_L3_0: STD_LOGIC_VECTOR(3 downto 0);
  signal sum_L3_1: STD_LOGIC_VECTOR(3 downto 0);  
  signal sum_L3_2: STD_LOGIC_VECTOR(3 downto 0);    
  signal sum_L4: STD_LOGIC_VECTOR(6 downto 0);   
  
  signal xx, xx1, xx2, xx3: STD_LOGIC_VECTOR(5 downto 0);  

begin

  -- First level of reduction
  L_1: for i in 0 to 9 generate 
    reduc: reducer_6to3 port map( x => x(i*6+5 downto i*6), s => sum_L1(i) );
  end generate;
   xx <= x(63 downto 60)&"00";
  reduc10: reducer_6to3 port map( x => xx, s => sum_L1(10) );
  

  -- grouped vertically result of first level of reduction
  L_1a: for i in 0 to 10 generate 
    L1_vert0(i) <= sum_L1(i)(0);    
    L1_vert1(i) <= sum_L1(i)(1);    
    L1_vert2(i) <= sum_L1(i)(2);
  end generate; 
  
  -- Second level of reduction
    -- reduce complete 6 to 3
    L_2b: reducer_6to3 port map( x => L1_vert0(5 downto 0), s => sum_L2_0 );
    L_2c: reducer_6to3 port map( x => L1_vert1(5 downto 0), s => sum_L2_1 );
    L_2d: reducer_6to3 port map( x => L1_vert2(5 downto 0), s => sum_L2_2 );
  
    -- reduce partial 5 to 3
    xx1 <= L1_vert0(10 downto 6)&'0';
    xx2 <= L1_vert1(10 downto 6)&'0';
    xx3 <= L1_vert2(10 downto 6)&'0';
        
    L_2e: reducer_6to3 port map( x => xx1, s => sum_L2_3 );
    L_2f: reducer_6to3 port map( x => xx2, s => sum_L2_4 );
    L_2g: reducer_6to3 port map( x => xx3, s => sum_L2_5 );


  
      -- sum result of second level reduction
      sum_L3_0 <= sum_L2_0 + ('0' & sum_L2_3);
      sum_L3_1 <= sum_L2_1 + ('0' & sum_L2_4);
      sum_L3_2 <= sum_L2_2 + ('0' & sum_L2_5);   
    
  --L4
  sum_L4 <= ('0' & sum_L3_2 & "00") + (sum_L3_1 & '0') + (sum_L3_0);
  
  s <= sum_L4;
end rtl_3;

