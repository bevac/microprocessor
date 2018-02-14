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
-- CLOCK GENERATOR TESTBENCH
----------------------------------------------------------------------------------
-- Tests the generated MMCM via Clocking Wizard + Block Design 
-- (via Waveform Viewer)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_logic_1164.all;


entity MMCM_unit_wrapper_tb is
    Generic (
      g_clock_period : TIME := 10 ns -- input clock 100 MHz
    );  
end;



architecture bench of MMCM_unit_wrapper_tb is

  component MMCM_unit_wrapper
    port (
      clk_in1 : in STD_LOGIC;
      reset : in STD_LOGIC;
      clk_out1 : out STD_LOGIC;
      clk_out2 : out STD_LOGIC;
      clk_out3 : out STD_LOGIC;
      clk_out4 : out STD_LOGIC;
      clk_out5 : out STD_LOGIC;
      clk_out6 : out STD_LOGIC;
      locked : out STD_LOGIC
    );
  end component;

  signal r_CLK_IN: STD_LOGIC;
  signal r_RESET: STD_LOGIC;
  signal w_clk_out1: STD_LOGIC;
  signal w_clk_out2: STD_LOGIC;
  signal w_clk_out3: STD_LOGIC;
  signal w_clk_out4: STD_LOGIC;
  signal w_clk_out5: STD_LOGIC;
  signal w_clk_out6: STD_LOGIC;
  signal w_locked: STD_LOGIC;
  
begin

  uut: MMCM_unit_wrapper 
    port map ( 
      clk_in1 => r_CLK_IN,
      reset => r_RESET,
      clk_out1  => w_clk_out1,
      clk_out2  => w_clk_out2,
      clk_out3  => w_clk_out3,
      clk_out4  => w_clk_out4,
      clk_out5  => w_clk_out5,
      clk_out6  => w_clk_out6,
      locked  => w_locked
    );

    PROC_stimulus: process
    begin
      r_RESET <= '0';
      wait for 2 us;
    
      -- MMCM process continues running, even if the PROC_clock process
      -- would be stopped, therefore stopped using assert FALSE.
      
      assert FALSE
      report "Simulation finished!"
      severity failure;
      
      wait;
     end process PROC_stimulus;


    PROC_clock: process
    begin
    
      while TRUE loop
       r_CLK_IN <= '0';
       wait for g_clock_period/2;
       r_CLK_IN <= '1';
       wait for g_clock_period/2;
      end loop;
      
      wait;
    end process PROC_clock;
    
end architecture;