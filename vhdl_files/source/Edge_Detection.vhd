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
-- EDGE DETECTION (at beginning of input pulse)
----------------------------------------------------------------------------------
-- If the trigger input changes to high, at the first rising edge of the clock,
-- a pulse of one clock cycle occurs at the output. For the next output
-- the input has to change to low before a rising edge of the input can 
-- trigger the output again (pulse between two rising clock edges will not cause
-- a pulse on the output).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Edge_Detection is
    Port ( 
      i_IN : in STD_LOGIC;
      i_CLK : in STD_LOGIC;
      o_OUT : out STD_LOGIC
    );
end Edge_Detection;



architecture RTL of Edge_Detection is

    signal r_FF1 : STD_LOGIC := '0';
    signal r_FF2 : STD_LOGIC := '0';
    
begin

    process (i_CLK)
    begin
      if rising_edge(i_CLK) then
        r_FF1 <= i_IN;
        r_FF2 <= NOT(r_FF1) AND i_IN;
      end if;
    end process;
    
    o_OUT <= r_FF2;

end RTL;
