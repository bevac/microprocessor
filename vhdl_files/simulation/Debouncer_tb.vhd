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
-- DEBOUNCER TESTBENCH
----------------------------------------------------------------------------------
-- Tests the debounce circuit using a 10 MHz clock and a 17-bit counter.
-- This results in a debounce time of about 13 ms.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Debouncer_tb is
    Generic (
      g_bit_size_counter : positive := 17;
      g_clock_period : TIME := 100 ns
    );  
end Debouncer_tb;

architecture testbench of Debouncer_tb is

    component Debouncer
        Generic ( 
          g_bit_size_counter : positive
        ); 
        Port ( 
          i_IN : in STD_LOGIC;
          i_CLK : in STD_LOGIC;
          o_OUT : out STD_LOGIC
        );
    end component;

    signal r_IN: STD_LOGIC;
    signal r_CLK: STD_LOGIC;
    signal w_out: STD_LOGIC;

    signal stop_the_clock: boolean;

begin

  uut: Debouncer 
    generic map (
      g_bit_size_counter => g_bit_size_counter
    )
    port map ( 
      i_IN  => r_IN,
      i_CLK => r_CLK,
      o_OUT => w_out 
    );


  PROC_stim: process
  begin
  
    r_IN <= '0';
    wait for 1 ms;
    r_IN <= '1';
    wait for 8 ms;
    r_IN <= '0';
    wait for 1 ms;    
    r_IN <= '1';
    wait for 11 ms;
    r_IN <= '0';
    wait for 2 ms; 
    r_IN <= '1';
    wait for 15 ms;
    r_IN <= '0';
    wait for 5 ms; 
    r_IN <= '1';
    wait for 1 ms;
    r_IN <= '0';
    wait for 15 ms; 
    r_IN <= '1';
    wait for 15 ms;    
                
    stop_the_clock <= TRUE;
    wait;
  end process PROC_stim;


  PROC_clk: process
  begin
  
    while not stop_the_clock loop
      r_CLK <= '0';
      wait for g_clock_period/2;
      r_CLK <= '1';
      wait for g_clock_period/2;
    end loop;
    wait;
  end process PROC_clk;

end architecture;
