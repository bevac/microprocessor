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
-- SEVEN SEGMENT
----------------------------------------------------------------------------------
-- Gets as input a 4-bit value. For this value the corresponding hexadecimal
-- value for represenation on the 7-segment display of the Basys3 Board is 
-- determined. 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity seven_segment is
    Port ( 
      i_digit : in STD_LOGIC_VECTOR (3 downto 0);
      o_segments : out STD_LOGIC_VECTOR (6 downto 0)
    );
end seven_segment;



architecture Behavioral of seven_segment is

begin

  process (i_digit)
  begin
    case i_digit is
      when "0000" =>   -- 0
        o_segments <= NOT("1111110");
      when "0001" =>   -- 1
        o_segments <= NOT("0110000");  
      when "0010" =>   -- 2
        o_segments <= NOT("1101101");
      when "0011" =>   -- 3
        o_segments <= NOT("1111001");
      when "0100" =>   -- 4
        o_segments <= NOT("0110011");
      when "0101" =>   -- 5
        o_segments <= NOT("1011011"); 
      when "0110" =>   -- 6
        o_segments <= NOT("1011111");              
      when "0111" =>   -- 7        
        o_segments <= NOT("1110000");        
      when "1000" =>   -- 8
        o_segments <= NOT("1111111");      
      when "1001" =>   -- 9      
        o_segments <= NOT("1111011");      
      when "1010" =>   -- 10 (A)      
        o_segments <= NOT("1110111");              
      when "1011" =>   -- 11 (b)        
        o_segments <= NOT("0011111");        
      when "1100" =>   -- 12 (C)
        o_segments <= NOT("1001110");      
      when "1101" =>   -- 13 (d)     
        o_segments <= NOT("0111101");      
      when "1110" =>   -- 14 (E)             
        o_segments <= NOT("1001111");  
      when "1111" =>   -- 15 (F)
        o_segments <= NOT("1000111");     
      
      -- needed for simulation only       
      when others =>
        o_segments <= NOT("0000000");  
  
    end case;
  end process;

end Behavioral;
