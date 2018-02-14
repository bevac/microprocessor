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
-- Communication
----------------------------------------------------------------------------------
-- This module is responsible for the communication between the processor an the
-- external RAM. Depending on the control bits the MAR can be loaded
-- with an address and the MBR can be loaded from the ALU (to store the content 
-- to RAM) or read from RAM into MBR.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Communication is
    Generic ( 
      g_bit : positive 
    );
    Port ( 
      i_CLK_MAR : in STD_LOGIC; -- CLK3
      i_CLK_MBR : in STD_LOGIC; -- CLK4
      i_CONTROL : in STD_LOGIC_VECTOR (3 downto 0); -- MBR MAR RD WR
      i_DATA_FROM_ALU : in STD_LOGIC_VECTOR (g_bit-1 downto 0);
      i_A_REG : in STD_LOGIC_VECTOR (g_bit-1 downto 0); -- laod MAR L
      i_B_REG : in STD_LOGIC_VECTOR (g_bit-1 downto 0); -- load MAR H
      o_DATA_TO_AMUX : out STD_LOGIC_VECTOR (g_bit-1 downto 0);
      o_ADDRESS : out STD_LOGIC_VECTOR (2*g_bit-1 downto 0);
      io_DATA_MEM : inout STD_LOGIC_VECTOR (g_bit-1 downto 0) -- from/to RAM
    );
end Communication;



architecture Behavioral of Communication is

    signal r_MBR : STD_LOGIC_VECTOR (g_bit-1 downto 0) := (others => '0');
    signal r_MAR : STD_LOGIC_VECTOR (2*g_bit-1 downto 0) := (others => '0');
    alias r_MAR_H : STD_LOGIC_VECTOR is r_mar(2*g_bit-1 downto g_bit);
    alias r_MAR_L : STD_LOGIC_VECTOR is r_mar(g_bit-1 downto 0);
	
    alias i_MBR_MIR : STD_LOGIC is i_CONTROL(3);
    alias i_MAR_MIR : STD_LOGIC is i_CONTROL(2);
    alias i_RD_MIR : STD_LOGIC is i_CONTROL(1);
    alias i_WR_MIR : STD_LOGIC is i_CONTROL(0);

begin


    -- synthesis translate_off
    -- checks if the control inputs are valid
    PROC_sim_check: process (i_CONTROL)
      variable v_old_control : STD_LOGIC_VECTOR(3 downto 0) := "0000";
      variable v_new_control : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    begin
      v_old_control := v_new_control;
      v_new_control := i_CONTROL;
		
      assert( 
        (v_new_control = "0000") OR (v_new_control = "0110") OR
        (v_new_control = "1010") OR (v_new_control = "0100") OR
        (v_new_control = "1001") OR (v_new_control = "0001") )
      report("Microde error: illegal read/write microcode")
      severity(error);
      
      if v_old_control = "0110" then
        assert(v_new_control = "1010")
        report("Microde error: read not performed correctly")
        severity(error);
      end if;
    
      if v_old_control = "0100" then
        assert(v_new_control = "1001")
        report("Microde error: write not performed correctly")
        severity(error);
      end if;
      
      if v_old_control = "1001" then
        assert(v_new_control = "0001")
        report("Microde error: write not performed correctly")
        severity(error);
      end if;
      
    end process PROC_sim_check;
    -- synthesis translate_on
  
  
    -- load MAR
    PROC_MAR: process (i_CLK_MAR)
    begin
      if rising_edge(i_CLK_MAR) then
        if i_MAR_MIR = '1' then
          r_MAR_H <= i_B_REG;
          r_MAR_L <= i_A_REG;
        end if;
      end if;
    end process PROC_MAR;   
	
    -- load MBR
    PROC_MBR: process (i_CLK_MBR)
    begin
      if rising_edge(i_CLK_MBR) then
        if i_MBR_MIR = '1' then
          if i_RD_MIR = '1' then
            r_MBR <= io_DATA_MEM;
          elsif i_WR_MIR = '1' then
            r_MBR <= i_DATA_FROM_ALU;
          end if;
        end if;

      end if;
    end process PROC_MBR;

    -- tristate logic
    io_DATA_MEM <= r_MBR when i_WR_MIR = '1' else (others => 'Z');
    
    o_DATA_TO_AMUX <= r_MBR;
    o_ADDRESS <= r_MAR;
  
end Behavioral;
