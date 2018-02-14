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
-- This debouncer component was inspired by the work at
-- https://eewiki.net/pages/viewpage.action?pageId=4980758
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- DEBOUNCER
----------------------------------------------------------------------------------
-- Changes the output only if the input stays at the same level for
-- a certain number of clock cycles (using a counter). 
-- Used to detect only one trigger-pulse if a button is pressed, as a button
-- can bounce a few times until it reaches its final value.
-- The bit-size of the used counter equates the generic
-- value g_bit_size_counter  (g_bit_size_counter-1 downto 0). The additional bit 
-- is used as a carry-output of the counter to indicate when a counter
-- overflow occurs. Max. counter value: 2**g_bit_size_counter-1
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Debouncer is
    Generic ( 
      g_bit_size_counter : positive
    ); 
    Port ( 
      i_IN : in STD_LOGIC;
      i_CLK : in STD_LOGIC;
      o_OUT : out STD_LOGIC
    );
end Debouncer;



architecture Behavioral of Debouncer is

    signal r_FF1_OUT : STD_LOGIC := '0';
    signal r_FF2_OUT : STD_LOGIC := '0';
    signal r_FF3_OUT : STD_LOGIC := '0';
    
    signal w_clear_counter : STD_LOGIC;
    signal w_output_en : STD_LOGIC;

    signal r_COUNT : STD_LOGIC_VECTOR(g_bit_size_counter downto 0) 
      := (others => '0');
    
begin

    process (i_CLK)
    begin
      if rising_edge(i_CLK) then
        r_FF1_OUT <= i_IN;
        r_FF2_OUT <= r_FF1_OUT;
        
        -- counter
        if w_clear_counter = '1' then
          r_COUNT <= (others => '0');
        elsif w_output_en /= '1' then
          r_COUNT <= STD_LOGIC_VECTOR(UNSIGNED(r_COUNT) + 1);
        else
          r_FF3_OUT <= r_FF2_OUT;
        end if;      
      end if;
    end process;
    
    w_output_en <= r_COUNT(g_bit_size_counter);
    w_clear_counter <= r_FF1_OUT XOR r_FF2_OUT;
    
    o_OUT  <= r_FF3_OUT;

end Behavioral;
