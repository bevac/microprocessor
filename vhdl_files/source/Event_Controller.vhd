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
-- EVENT CONTROLLER
----------------------------------------------------------------------------------
-- included part(s): 
--    SYNCHRONIZER, DEBOUNCER, EDGE DETECTION
----------------------------------------------------------------------------------
-- Special defined reset-/interrupt controller. Inputs are one reset line and
-- at least one interrupt line. All inputs are synchronized to the input clock an
-- debounced. Using a module for detecting the rising edge of the input only
-- one pulse is generated per input-triggering.
-- The output is set based on the occurring inputs:
--   - reset has the highest priority (output is 0)
--   - lower interrupt line has higher priority (output is int line number + 1)
--   - if no input line is high, the MSB of the output is 1, the other bits are 0
-- If more events occur at the same time, only the event with the highest 
-- priority encodes the output. The higher the clock-speed, the less the 
-- possibility that an event is missed. 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Event_Controller is
    Generic ( 
      g_bit_size_counter : positive;  -- for debouncer
      g_bit_size : positive; -- bit size of output
      g_int_lines : positive
    );
    Port ( 
      i_RESET : in STD_LOGIC;
      i_CLK : in STD_LOGIC;
      i_INTERRUPT : in STD_LOGIC_VECTOR (1 to g_int_lines);
      o_EVENT_CONTROL : out STD_LOGIC_VECTOR (g_bit_size-1 downto 0) 
    );
end Event_Controller;



architecture Mixed of Event_Controller is

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
           
    component Edge_Detection
      Port ( 
        i_IN : in STD_LOGIC;
        i_CLK : in STD_LOGIC;
        o_OUT : out STD_LOGIC 
      );
    end component;
    
    component Synchronizer
      Port ( 
        i_IN : in STD_LOGIC;
        i_CLK : in STD_LOGIC;
        o_OUT : out STD_LOGIC
      );
    end component;

    -- bits which are input to the priority encoder
    signal w_priority_in : STD_LOGIC_VECTOR (0 to g_int_lines);
    
    -- connection between debouncer and edge detection
    signal w_connect_de : STD_LOGIC_VECTOR (0 to g_int_lines);
    
    -- connection between synchronizer and debouncer
    signal w_connect_sd : STD_LOGIC_VECTOR (0 to g_int_lines);

begin

    CON: for i in 0 to g_int_lines generate
      START: if(i = 0) generate  
       RESET: Synchronizer 
         port map ( 
           i_IN => i_RESET,
           i_CLK => i_CLK,
           o_OUT => w_connect_sd(i)
         );              
        RESET1: Debouncer 
          generic map ( 
            g_bit_size_counter => g_bit_size_counter
          )
          port map ( 
            i_IN => w_connect_sd(i),
            i_CLK => i_CLK,
            o_OUT => w_connect_de(i)
          );
        RESET2: Edge_Detection
          port map ( 
            i_IN => w_connect_de(i),
            i_CLK => i_CLK,
            o_OUT => w_priority_in(i)
          );
      end generate;
      REST: if(i >0) AND (i <= g_int_lines) generate
        INT: Synchronizer 
        port map ( 
          i_IN => i_INTERRUPT(i),
          i_CLK => i_CLK,
          o_OUT => w_connect_sd(i)
        );  
        INT1: Debouncer
          generic map ( 
            g_bit_size_counter => g_bit_size_counter
          )
          port map ( 
            i_IN => w_connect_sd(i),
            i_CLK => i_CLK,
            o_OUT => w_connect_de(i)
          );
        INT2: Edge_Detection
          port map ( 
            i_IN => w_connect_de(i),
            i_CLK => i_CLK,
            o_OUT => w_priority_in(i)
          );
      end generate;
    end generate;
    
    
    PROC_priority: process (w_priority_in)
    begin
      -- preload default (only MSB set)
      o_EVENT_CONTROL <= (others => '0');
      o_EVENT_CONTROL(g_bit_size-1) <= '1';
      
      -- write highest priority interrupt (if an interrupt occured)
      for j in g_int_lines downto 1 loop
        if w_priority_in(j) = '1' then
          o_EVENT_CONTROL <= STD_LOGIC_VECTOR(to_unsigned(j + 1, g_bit_size));
        end if;
      end loop;
    
      -- reset has highest priority
      if (w_priority_in(0) = '1') then
        o_EVENT_CONTROL <= (others => '0');
      end if;

    end process PROC_priority;

end Mixed;
