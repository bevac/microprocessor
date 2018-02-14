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
-- SEGMENT DRIVER
----------------------------------------------------------------------------------
-- Can be used to drive the four 7-segment display digits (without point) on the 
-- Basys3 Board.
-- Using a state machine the states iterate through the different digits that
-- have to be displayed. After a counter overflows the state is changed in a cycle
-- of four states (one state for every digit).
-- mask: set 7-segment displays to 1, which should not light up
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Segment_Driver is
    Generic(
      g_counter_bit_size : positive := 15 -- ideal for 10 MHz clock input
    );
    Port ( 
      i_DIGIT0 : in STD_LOGIC_VECTOR (3 downto 0); -- LSB
      i_DIGIT1 : in STD_LOGIC_VECTOR (3 downto 0);
      i_DIGIT2 : in STD_LOGIC_VECTOR (3 downto 0);
      i_DIGIT3 : in STD_LOGIC_VECTOR (3 downto 0); -- MSB
      i_ACTIVE_DIGITS_MASK : in STD_LOGIC_VECTOR (3 downto 0);
      i_CLK : in STD_LOGIC;
      -- controls the output (which character)
      o_DIGIT : out STD_LOGIC_VECTOR (3 downto 0);
      -- controls which of the four 7-segment displays is affected
      o_SEGMENT : out STD_LOGIC_VECTOR (3 downto 0)
    );
end Segment_Driver;



architecture Behavioral of Segment_Driver is

    signal r_COUNT : STD_LOGIC_VECTOR (g_counter_bit_size downto 0) 
        := (others => '0');
       
    type t_STATE is (s_d0, s_d1, s_d2, s_d3);
    signal s_state : t_STATE := s_d0;
    
begin

  PROC_count: process (i_CLK)
  begin
    if rising_edge(i_CLK) then
      if r_COUNT(g_counter_bit_size) = '1' then -- counter overflow
        r_COUNT <= (others => '0'); -- reset counter
        
        case s_state is
          when s_d0 => s_state <= s_d1;
          when s_d1 => s_state <= s_d2;
          when s_d2 => s_state <= s_d3;
          when s_d3 => s_state <= s_d0;
        end case;
        
      else
        r_COUNT <= STD_LOGIC_VECTOR(UNSIGNED(r_COUNT) + 1);
      end if;     
    end if;
  end process PROC_count;
  
  
  PROC_output: process (
      i_DIGIT0, i_DIGIT1, i_DIGIT2, i_DIGIT3, i_ACTIVE_DIGITS_MASK, s_state
  )
  begin
    case s_state is
      when s_d0 => 
        o_DIGIT <= i_DIGIT0;
        o_SEGMENT <= "1110" OR i_ACTIVE_DIGITS_MASK;
      when s_d1 => 
        o_DIGIT <= i_DIGIT1;
        o_SEGMENT <= "1101" OR i_ACTIVE_DIGITS_MASK;
      when s_d2 => 
        o_DIGIT <= i_DIGIT2;
        o_SEGMENT <= "1011" OR i_ACTIVE_DIGITS_MASK;
      when s_d3 => 
        o_DIGIT <= i_DIGIT3;
        o_SEGMENT <= "0111" OR i_ACTIVE_DIGITS_MASK;
    end case;
  end process PROC_output;


end Behavioral;