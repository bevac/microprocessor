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
-- SERIAL ADDER TESTBENCH
----------------------------------------------------------------------------------
-- Testing all possible inputs for an 8-bit serial adder.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Serial_Adder_tb is
    Generic( 
      g_bus_size: positive := 8
    );
end Serial_Adder_tb;



architecture testbench of Serial_Adder_tb is

    component Serial_Adder
        generic( 
          g_bit: positive 
        );
        port ( 
          i_A, i_B : in STD_LOGIC_VECTOR (g_bit-1 downto 0);
          i_Carry : in STD_LOGIC;
          o_Carry, o_V : out STD_LOGIC;
          o_Y : out STD_LOGIC_VECTOR (g_bit-1 downto 0) 
        );
      end component;
  
    signal r_A, r_B : STD_LOGIC_VECTOR (g_bus_size-1 downto 0) 
        := (others => '0');
    signal r_C_IN : STD_LOGIC := '0';
    signal w_y : STD_LOGIC_VECTOR (g_bus_size-1 downto 0);
    signal w_c_out, w_v_out : STD_LOGIC;
  
    constant zero: STD_LOGIC := '0';
    constant one: STD_LOGIC := '1';
  
    -- function that converts an STD_ULOGIC value to an unsigned value
    function stdul2uns (x: in STD_ULOGIC) return unsigned is
    begin
      if x='1' then 
        return to_unsigned(1,1); 
      else 
        return to_unsigned(0,1); 
      end if;
    end;
  
begin

    uut: Serial_Adder
      generic map( 
        g_bit => g_bus_size 
      ) 
      port map( 
        i_A => r_A, 
        i_B => r_B, 
        i_Carry => r_C_IN,
        o_Y => w_y, 
        o_Carry => w_c_out , 
        o_V => w_v_out
      ); 
    
    
    PROC_stim: process
    
      variable v_a, v_b: STD_LOGIC_VECTOR (g_bus_size-1 downto 0);
      variable v_y: STD_LOGIC_VECTOR (g_bus_size downto 0);
      variable v_v_check: STD_LOGIC;
      variable v_carry: STD_LOGIC;
      
    begin
    
      report "Validation starts...";
    
      for c in zero to one loop
        r_C_IN <= c; 
      
        for i in 0 to 2**g_bus_size-1 loop
          v_a := STD_LOGIC_VECTOR(to_unsigned(i, g_bus_size)); 
          for j in 0 to 2**g_bus_size-1 loop
            v_b := STD_LOGIC_VECTOR(to_unsigned(j, g_bus_size)); 
          
            v_y := STD_LOGIC_VECTOR((unsigned('0' & v_a) + unsigned('0' & v_b)) + 
                   stdul2uns(c));
          
            if( (v_a(g_bus_size-1) = v_b(g_bus_size-1)) AND 
                (v_a(g_bus_size-1) /= v_y(g_bus_size-1)) ) then
              v_v_check := '1';
            else
              v_v_check := '0';
            end if;
          
            r_A <= v_a;
            r_B <= v_b;
        
          wait for 10 ns;
          
          assert w_c_out = v_y(g_bus_size)
          report "Carry wrong calculated!";
          
          assert w_v_out = v_v_check
          report "Overflow wrong calculated!";
          
          assert w_y = v_y(g_bus_size-1 downto 0)
          report "Sum wrong calculated!";
          
        end loop;
      end loop;
    end loop;
  
    report "Validation finished!";
    wait;
  end process PROC_stim;
 
end testbench;
