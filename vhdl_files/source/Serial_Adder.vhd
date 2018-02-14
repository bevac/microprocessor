-- BSD 3-Clause License
-- 
-- Copyright (c) 2018, Bernhard Vacarescu
-- All rights reserved.
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


----------------------------------------------------------------------------------
-- SERIAL ADDER
----------------------------------------------------------------------------------
-- included part(s): 
--    FULL ADDER
----------------------------------------------------------------------------------
-- Calculates the sum of two numbers (the bit-length is a generic value).
-- The serial adder also includes a carry-input and a carry-output.
-- Also an overflow-output is included. the overflow-bit is set if both operands
-- have the same MSB, but the MSB of the output is different. (Changed sign if
-- interpretation as 2's complement signed number.)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Serial_Adder is
    Generic( 
      g_bit : positive
    );
    Port( 
      i_A, i_B : in STD_LOGIC_VECTOR (g_bit-1 downto 0); 
      i_CARRY : in STD_LOGIC;           
      o_CARRY : out STD_LOGIC;
      o_V : out STD_LOGIC; 
      o_Y : out STD_LOGIC_VECTOR (g_bit-1 downto 0)
    );
end Serial_Adder;



architecture Structural of Serial_Adder is

    component Full_Adder
      Port( 
        i_A, i_B, i_CARRY : in STD_LOGIC;
        o_CARRY, o_Y  : out STD_LOGIC 
      );
    end component;
           
    -- connection between the full adders
    signal w_connect: STD_LOGIC_VECTOR(g_bit-1 downto 0);

begin

    SEC0: for i in g_bit-1 downto 0 generate    
      SEC1: if (i > 0) AND (i < g_bit) generate
        BITmsb_down: Full_Adder
          port map( 
            i_A => i_A(i), 
            i_B => i_B(i), 
            i_CARRY => w_connect(i-1), 
            o_CARRY => w_connect(i), 
            o_Y => o_Y(i) 
          );
      end generate;
      SEC2: if (i = 0) generate
        BIT0: Full_Adder
          port map( 
            i_A => i_A(0), 
            i_B => i_B(0), 
            i_CARRY => i_CARRY, 
            o_CARRY => w_connect(0), 
            o_Y => o_Y(0) 
          );
      end generate;   
    end generate;
  
    o_V <= w_connect(g_bit-1) XOR w_connect(g_bit-2);
    o_Carry <= w_connect(g_bit-1);

end Structural;
