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
-- EVENT CONTROLLER TESTBENCH
----------------------------------------------------------------------------------
-- Tests the event controller using two interrupt lines and a output bus size
-- of 8 bit. (via Waveform Viewer)
-- For testing just a 5 bit counter is used (better inspection in Waveform
-- Viewer possible).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity EventController_tb is
  Generic( 
    g_bit_size_counter : positive := 5;
    g_clock_period : TIME := 100 ns; -- 10 MHz
    g_bit_size : positive := 8;
    g_int_lines : positive := 2 
  );
end EventController_tb;



architecture testbench of EventController_tb is

    component Event_Controller
      Generic( 
        g_bit_size_counter : positive;
        g_bit_size : positive;
        g_int_lines : positive
      );
      Port ( 
        i_RESET : in STD_LOGIC;
        i_CLK : in STD_LOGIC;
        i_INTERRUPT : in STD_LOGIC_VECTOR (1 to g_int_lines);
        o_event_control : out STD_LOGIC_VECTOR (g_bit_size-1 downto 0) 
      );
    end component;

    signal r_RESET : STD_LOGIC;
    signal r_INTERRUPT : STD_LOGIC_VECTOR (1 to g_int_lines);
    signal r_CLK : STD_LOGIC;
    signal w_event_control : STD_LOGIC_VECTOR (g_bit_size-1 downto 0);
    
    signal stop_the_clock: BOOLEAN;
    
begin

  uut: Event_Controller 
    generic map ( 
      g_bit_size_counter => g_bit_size_counter,
      g_bit_size => g_bit_size, 
      g_int_lines => g_int_lines 
    ) 
    port map ( 
      i_RESET => r_RESET, 
      i_CLK => r_CLK,
      i_INTERRUPT => r_INTERRUPT,
      o_event_control =>  w_event_control
    );


  PROC_stim: process
  begin

    for i in 0 to 2**g_int_lines-1 loop
        for j in STD_LOGIC range '0' to '1'  loop
          r_INTERRUPT <= STD_LOGIC_VECTOR(to_unsigned(i, g_int_lines));
          r_RESET <= j;
          wait for 4 us;
          
          r_INTERRUPT <= STD_LOGIC_VECTOR(to_unsigned(0, g_int_lines));
          r_RESET <= '0';
          wait for 4 us;
        end loop;
    end loop;

    -- dicrete extra tests for two interrupt lines
    
    r_INTERRUPT(2) <= '1';
    r_INTERRUPT(1) <= '0';
    r_RESET <= '0';
    wait for 4 us;
    r_INTERRUPT(1) <= '1';
    wait for 4 us;
    r_RESET <= '1';
    wait for 4 us;
    r_INTERRUPT(1) <= '1';
    r_INTERRUPT(2) <= '0';
    r_RESET <= '0';
    wait for 2 us;
    r_INTERRUPT(1) <= '0';
    r_INTERRUPT(2) <= '1';
    wait for 3 us;
    r_RESET <= '1';
    wait for 3 us;
    r_INTERRUPT(1) <= '0';
    r_INTERRUPT(2) <= '0';
    r_RESET <= '0';
    wait for 6 us;
    r_INTERRUPT(2) <= '1';
    wait for 1 us;
    r_INTERRUPT(1) <= '1';
    wait for 6 us;
        
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
