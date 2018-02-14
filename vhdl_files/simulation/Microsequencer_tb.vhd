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
-- MICROSEQUENCER TESTBENCH
----------------------------------------------------------------------------------
-- Testing the microsequencer (via Waveform Viewer)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Microsquencer_tb is
end Microsquencer_tb;



architecture testbench of Microsquencer_tb is

    component Microsequencer
        Port ( 
          i_Z : in STD_LOGIC;
          i_N : in STD_LOGIC;
          i_COND : in STD_LOGIC_VECTOR (1 downto 0);
          o_J : out STD_LOGIC 
        );
    end component;

    signal r_Z: STD_LOGIC := '0';
    signal r_N: STD_LOGIC := '0';
    signal r_COND: STD_LOGIC_VECTOR (1 downto 0) := "00";
    signal w_j: STD_LOGIC;

begin

    uut: Microsequencer
      port map ( 
        i_Z => r_Z,
        i_N => r_N,
        i_COND => r_COND,
        o_J => w_j 
      );


    PROC_stim: process
    begin
      -- iterate through the possible combinations
      for i in 0 to 3 loop
        r_COND <= STD_LOGIC_VECTOR(to_unsigned(i,2));
      
        for j in STD_LOGIC range '0' to '1' loop
          r_Z <= j;
          
          for k in STD_LOGIC range '0' to '1' loop
            r_N <= k;
      
          wait for 10 ns;
          
          end loop;
        end loop;
      end loop;
    wait;
  end process PROC_stim;

end testbench;
