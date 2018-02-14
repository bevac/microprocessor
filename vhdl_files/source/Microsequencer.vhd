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
-- MICROSEQUENCER
----------------------------------------------------------------------------------
-- Based on the jump-condition of a microinstruction and the Z-flag-
-- and N-flag value (from the ALU) it is determined if a jump in the 
-- micro-program-memory should be performed.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Microsequencer is
    Port ( 
      i_Z : in STD_LOGIC;
      i_N : in STD_LOGIC;
      i_COND : in STD_LOGIC_VECTOR (1 downto 0);
      o_J : out STD_LOGIC 
    );
end Microsequencer;



architecture Behavioral of Microsequencer is

begin
 
    process (i_Z, i_N, i_COND)
    begin
      o_J <= '0'; -- default
    
      case i_COND is
        when "00" =>
          o_J <= '0';
        when "01" =>
          if i_N = '1' then  
            o_J <= '1';     
          end if;
          -- no else necessary, because default value used
          -- (otherwise latch would be inferred)
        when "10" =>
          if i_Z = '1' then 
            o_J <= '1';
          end if;      
        when "11" =>
          o_J <= '1';
        when others =>
          o_J <= '0';
       end case;

    end process;

end Behavioral;
