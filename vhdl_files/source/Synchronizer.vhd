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
-- SYNCHRONIZER
----------------------------------------------------------------------------------
-- included part(s): 
--    FLIP FLOP
----------------------------------------------------------------------------------
-- Synchronizes an input signal to a clock domain.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Synchronizer is
    Generic ( 
      g_block_length : positive := 2
    );
    Port ( 
      i_IN : in STD_LOGIC;
      i_CLK : in STD_LOGIC;
      o_OUT : out STD_LOGIC
    );
end Synchronizer;



architecture Structural of Synchronizer is

    component Flip_Flop_Init
      Port (
        i_IN : in STD_LOGIC;
        i_CLK : in STD_LOGIC;
        o_OUT : out STD_LOGIC
      );
    end component;
    
    signal w_connect : STD_LOGIC_VECTOR (1 to g_block_length-1);

begin

    CON: for i in 1 to g_block_length generate
      CON1: if (i = 1) generate
        START: Flip_Flop_Init
          port map ( 
            i_IN => i_IN,
            i_CLK => i_CLK,
            o_OUT => w_connect(i)
          );
      end generate;
      CON2: if (i > 1) AND (i < g_block_length) generate
        MIDDLE: Flip_Flop_Init
          port map (
            i_IN => w_connect(i-1),
            i_CLK => i_CLK,
            o_OUT => w_connect(i)
          );
      end generate;
      CON3: if (i = g_block_length) generate
        ENDING: Flip_Flop_Init
          port map (
            i_IN => w_connect(i-1),
            i_CLK => i_CLK,
            o_OUT => o_OUT
          );
      end generate;
    end generate;
    
end Structural;
