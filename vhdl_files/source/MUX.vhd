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
-- MUX (Multiplexer)
----------------------------------------------------------------------------------
-- A very general description of a multiplexer. Bus width and number of select 
-- lines can be set as generic values.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.datatypes.all; -- includes t_MUX_ARRAY type


entity MUX is
    Generic ( 
      g_bus_size : positive;
      g_sel_size : positive --  2**g_sel_size input devices
    );
    Port ( 
      i_SELECT : in STD_LOGIC_VECTOR (g_sel_size-1 downto 0);
      i_INPUTS : in t_MUX_ARRAY (0 to 2**g_sel_size-1, g_bus_size-1 downto 0);
      o_OUTPUT : out STD_LOGIC_VECTOR (g_bus_size-1 downto 0) 
    );
end MUX;



architecture Behavioral of MUX is

begin

    PROC_output: process (i_SELECT, i_INPUTS)
    begin
      for i in 0 to g_bus_size-1 loop
        o_OUTPUT(i) <= i_INPUTS(to_integer(unsigned(i_SELECT)),i);
      end loop;
    end process PROC_output;

end Behavioral;
